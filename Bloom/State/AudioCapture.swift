//
//  AudioCapture.swift
//  Bloom
//

import AVFoundation
import OSLog

enum AudioCaptureError: LocalizedError {
    case failedToStart

    var errorDescription: String? {
        "The recorder did not start."
    }
}

/// Owns the audio session, the `AVAudioRecorder` and metering, so none of it runs
/// on the main actor. Levels are published at 10 Hz through `AsyncStream`.
actor AudioCapture {
    private static let sampleInterval = Duration.milliseconds(100)
    private static let minDecibels: Float = -50

    private var recorder: AVAudioRecorder?
    private var meteringTask: Task<Void, Never>?
    private var levels: AsyncStream<CGFloat>.Continuation?
    private var fileURL: URL?
    private var lastLevel: CGFloat = 0

    deinit {
        meteringTask?.cancel()
        recorder?.stop()
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func start() throws -> AsyncStream<CGFloat> {
        discardPrevious()

        let session = AVAudioSession.sharedInstance()
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory.appendingPathComponent("voice-recording.m4a")

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setActive(true)

            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            _ = fileManager.createFile(atPath: url.path, contents: nil)
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )

            let recorder = try AVAudioRecorder(url: url, settings: Self.settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else { throw AudioCaptureError.failedToStart }

            self.recorder = recorder
            self.fileURL = url
            lastLevel = 0

            let (stream, continuation) = AsyncStream.makeStream(of: CGFloat.self)
            levels = continuation
            startMetering()
            return stream
        } catch {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            throw error
        }
    }

    func stop() {
        meteringTask?.cancel()
        meteringTask = nil

        levels?.finish()
        levels = nil

        recorder?.stop()
        recorder = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            Logger.bloom.error("audio session deactivate failed: \(error, privacy: .public)")
        }
    }

    private func discardPrevious() {
        if recorder != nil {
            stop()
        }
    }

    private func startMetering() {
        meteringTask?.cancel()
        meteringTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.sampleInterval)
                await self?.publishLevel()
            }
        }
    }

    private func publishLevel() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()

        let power = recorder.averagePower(forChannel: 0)
        let normalized = min(max((power - Self.minDecibels) / -Self.minDecibels, 0), 1)
        let target = pow(CGFloat(normalized), 1.25)
        lastLevel = lastLevel * 0.1 + target * 0.9
        levels?.yield(lastLevel)
    }

    private static var settings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
    }
}
