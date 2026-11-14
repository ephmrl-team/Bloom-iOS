//
//  AudioRecorderManager.swift
//  Bloom
//
//  Created by Аскольд on 16.08.2026.
//

import AVFoundation
import OSLog
import SwiftUI

struct AudioSample: Identifiable, Equatable {
    let id = UUID()
    let value: CGFloat
}

@Observable
@MainActor
final class AudioRecorderManager {
    private(set) var samples: [AudioSample] = []
    private(set) var isRecording = false
    private(set) var permissionDenied = false
    private(set) var recordingStartDate: Date?
    private(set) var lastRecordedDuration: TimeInterval = 0

    @ObservationIgnored private let capture = AudioCapture()
    @ObservationIgnored private var levelTask: Task<Void, Never>?

    private let maxMemorySamples = 55

    func startRecording() async {
        guard !isRecording else { return }

        guard await Self.requestPermission() else {
            permissionDenied = true
            return
        }
        permissionDenied = false

        do {
            let levels = try await capture.start()

            samples.removeAll()
            recordingStartDate = .now
            isRecording = true

            levelTask = Task { @MainActor [weak self] in
                for await level in levels {
                    self?.appendSample(level)
                }
            }
        } catch {
            Logger.bloom.error("recording failed to start: \(error, privacy: .public)")
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        lastRecordedDuration = recordingStartDate.map { Date.now.timeIntervalSince($0) } ?? 0
        recordingStartDate = nil

        levelTask?.cancel()
        levelTask = nil

        Task { await capture.stop() }
    }

    private func appendSample(_ level: CGFloat) {
        withAnimation(.smooth(duration: 0.25)) {
            samples.append(AudioSample(value: level))
            if samples.count > maxMemorySamples {
                samples.removeFirst(samples.count - maxMemorySamples)
            }
        }
    }

    private static func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await AVAudioApplication.requestRecordPermission()
        @unknown default:
            return false
        }
    }
}
