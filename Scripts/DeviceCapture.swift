//
//  DeviceCapture.swift
//  Bloom
//
//  Minimal macOS CLI that grabs a screenshot or a short recording from an iPhone
//  connected by USB, without QuickTime and without sudo.
//
//  Build:  swiftc -O Scripts/DeviceCapture.swift -o build/device-capture \
//            -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist \
//            -Xlinker Scripts/DeviceCapture-Info.plist
//  Usage:  build/device-capture --list
//          build/device-capture --screenshot build/screen.png
//          build/device-capture --record 4 build/capture.mov
//
//  The first run needs Camera and Screen Recording permission for the terminal
//  (System Settings > Privacy & Security). Without them AVFoundation sees no device.
//

import AVFoundation
import CoreImage
import CoreMediaIO
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Screen capture devices

/// Screen-capture devices (iPhone, iPad, Apple TV) are hidden from AVFoundation until this
/// CoreMediaIO switch is on; QuickTime flips it when it opens "New Movie Recording".
private func allowScreenCaptureDevices() {
    var allow: UInt32 = 1
    var address = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    CMIOObjectSetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &address,
        0,
        nil,
        UInt32(MemoryLayout<UInt32>.size),
        &allow
    )
}

/// The USB iPhone is an `.external` device with the `.muxed` media type; `.video` finds nothing.
private func externalDevices(mediaType: AVMediaType?) -> [AVCaptureDevice] {
    AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external],
        mediaType: mediaType,
        position: .unspecified
    ).devices
}

private func looksLikeIOSDevice(_ device: AVCaptureDevice) -> Bool {
    device.modelID.contains("iOS")
        || device.localizedName.contains("iPhone")
        || device.localizedName.contains("iPad")
}

/// CMIO enumerates the phone asynchronously after the switch above: the first query is usually
/// empty. Poll the same discovery sessions (creating a new one each tick restarts enumeration).
private func waitForExternalDevices() -> [AVCaptureDevice] {
    allowScreenCaptureDevices()
    let muxed = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external],
        mediaType: .muxed,
        position: .unspecified
    )
    let anyMedia = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external],
        mediaType: nil,
        position: .unspecified
    )
    // The DAL publishes the phone a moment after the switch, so poll instead of failing fast.
    for _ in 0 ..< 40 {
        if !muxed.devices.isEmpty { return muxed.devices }
        if let phone = anyMedia.devices.first(where: looksLikeIOSDevice) { return [phone] }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
    if ProcessInfo.processInfo.environment["BLOOM_CAPTURE_DEBUG"] != nil {
        print("gave up: muxed=\(muxed.devices.count) any=\(anyMedia.devices.map(\.localizedName))")
    }
    return muxed.devices
}

private func findPhone() -> AVCaptureDevice? {
    let external = waitForExternalDevices()
    return external.first(where: looksLikeIOSDevice)
        ?? externalDevices(mediaType: nil).first(where: looksLikeIOSDevice)
        ?? external.first
}

private func allDevices() -> [AVCaptureDevice] {
    let types: [AVCaptureDevice.DeviceType] = [
        .external, .continuityCamera, .deskViewCamera, .builtInWideAngleCamera,
    ]
    return AVCaptureDevice.DiscoverySession(
        deviceTypes: types,
        mediaType: nil,
        position: .unspecified
    ).devices
}

private func printDevices() {
    let external = waitForExternalDevices()
    let devices = allDevices().filter { $0.deviceType != .external } + external
    if devices.isEmpty {
        print("no capture devices visible")
    }
    for (index, device) in devices.enumerated() {
        let media = device.hasMediaType(.muxed) ? "muxed" : (device.hasMediaType(.video) ? "video" : "other")
        print(
            "\(index): \(device.localizedName) type=\(device.deviceType.rawValue) media=\(media)"
                + " model=\(device.modelID)"
        )
    }
}

// MARK: - Session

private func makeSession(device: AVCaptureDevice) throws -> AVCaptureSession {
    let session = AVCaptureSession()
    if session.canSetSessionPreset(.high) {
        session.sessionPreset = .high
    }
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else { throw CaptureError.cannotAddInput }
    session.addInput(input)
    return session
}

private enum CaptureError: Error, CustomStringConvertible {
    case cannotAddInput
    case cannotAddOutput
    case noFrame

    var description: String {
        switch self {
        case .cannotAddInput: "the capture session rejected the device input"
        case .cannotAddOutput: "the capture session rejected the output"
        case .noFrame: "no video frame arrived"
        }
    }
}

private func permissionName(_ status: AVAuthorizationStatus) -> String {
    switch status {
    case .authorized: "authorized"
    case .denied: "denied"
    case .restricted: "restricted"
    case .notDetermined: "notDetermined"
    @unknown default: "unknown"
    }
}

/// Reports the real TCC state instead of guessing from an empty device list.
private func ensureCameraAccess() -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    print("camera permission: \(permissionName(status))")
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        var granted = false
        let semaphore = DispatchSemaphore(value: 0)
        AVCaptureDevice.requestAccess(for: .video) { allowed in
            granted = allowed
            semaphore.signal()
        }
        while semaphore.wait(timeout: .now() + 0.05) == .timedOut {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        print("camera permission after request: \(granted ? "authorized" : "denied")")
        return granted
    case .denied, .restricted:
        return false
    @unknown default:
        return false
    }
}

private func finish(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8) ?? Data())
    exit(code)
}

// MARK: - Screenshot

private final class FrameGrabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let onImage: (CGImage) -> Void
    private let context = CIContext()
    private var done = false

    init(onImage: @escaping (CGImage) -> Void) {
        self.onImage = onImage
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !done, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
        done = true
        onImage(cgImage)
    }
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw CaptureError.noFrame
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CaptureError.noFrame }
}

/// `AVCapturePhotoOutput` is not supported on the `.muxed` USB stream, so take the first frame.
private func screenshot(from device: AVCaptureDevice, to url: URL) throws {
    let session = try makeSession(device: device)
    let output = AVCaptureVideoDataOutput()
    output.alwaysDiscardsLateVideoFrames = true
    guard session.canAddOutput(output) else { throw CaptureError.cannotAddOutput }
    session.addOutput(output)

    let grabber = FrameGrabber { image in
        session.stopRunning()
        do {
            try writePNG(image, to: url)
            print("saved \(url.path)")
            exit(0)
        } catch {
            finish("error: \(error)", code: 1)
        }
    }
    output.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "bloom.capture"))

    session.startRunning()
    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
        session.stopRunning()
        finish("error: no frame arrived in 15 s", code: 2)
    }
    RunLoop.main.run()
}

// MARK: - Recording

private final class MovieRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let seconds: Double
    private let onDone: (URL) -> Void

    init(seconds: Double, onDone: @escaping (URL) -> Void) {
        self.seconds = seconds
        self.onDone = onDone
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            finish("error: recording failed: \(error.localizedDescription)", code: 3)
        }
        onDone(outputFileURL)
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("recording \(seconds)s to \(fileURL.path)")
    }
}

private func record(from device: AVCaptureDevice, seconds: Double, to url: URL) throws {
    let session = try makeSession(device: device)
    let output = AVCaptureMovieFileOutput()
    guard session.canAddOutput(output) else { throw CaptureError.cannotAddOutput }
    session.addOutput(output)

    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try? FileManager.default.removeItem(at: url)

    let recorder = MovieRecorder(seconds: seconds) { finishedURL in
        session.stopRunning()
        print("saved \(finishedURL.path)")
        exit(0)
    }
    session.startRunning()
    output.startRecording(to: url, recordingDelegate: recorder)

    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        output.stopRecording()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 10) {
        finish("error: recording did not finish in time", code: 4)
    }
    RunLoop.main.run()
}

// MARK: - QuickTime fallback

/// Best-effort fallback for the case where the CMIO device never shows up: QuickTime records
/// the iPhone screen itself. Stopping the recording is scripted, but QuickTime may still ask
/// the user to confirm where the file goes.
private func quickTimeFallback(seconds: Double, to url: URL) {
    print("fallback: recording \(seconds)s through QuickTime Player")
    let script = """
    tell application "QuickTime Player"
        activate
        new movie recording
    end tell
    """
    run(osascript: script)
    Thread.sleep(forTimeInterval: seconds)
    run(osascript: """
    tell application "System Events"
        tell process "QuickTime Player"
            try
                click menu item "Stop Recording" of menu 1 of menu bar item "File" of menu bar 1
            end try
        end tell
    end tell
    """)
    Thread.sleep(forTimeInterval: 1)
    print("""
    If QuickTime is still recording, press the stop button yourself.
    Save the clip as \(url.path) or pass --video <file> to anim_sheet.py.
    """)
}

private func run(osascript script: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    try? process.run()
    process.waitUntilExit()
}

// MARK: - Entry point

private func printUsage() {
    print("""
    usage: device-capture --list
           device-capture --screenshot <out.png>
           device-capture --record <seconds> <out.mov>
    flags: --quicktime-fallback  use QuickTime Player when no device is visible
    """)
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
    printUsage()
    exit(64)
}

let wantsQuickTime = arguments.contains("--quicktime-fallback")

func permissionFailure() -> Never {
    print("""
    Camera access for this terminal is not allowed — this is a permission problem, not a device one.
      System Settings > Privacy & Security > Camera: enable your terminal, then restart it.
      The prompt appears the first time the tool runs; deny it and this message stays.
    """)
    exit(1)
}

func failOrFallback(_ message: String, seconds: Double = 0, url: URL? = nil) -> Never {
    print("error: \(message)")
    if wantsQuickTime, let url, seconds > 0 {
        quickTimeFallback(seconds: seconds, to: url)
        exit(0)
    }
    print("""
    No iPhone screen-capture device is visible. AVFoundation sees: \
    \(allDevices().map(\.localizedName).joined(separator: ", ")).
    Check, in this order:
      1. System Settings > Privacy & Security > Screen Recording: enable your terminal, restart it.
      2. The iPhone is connected by cable, its screen is on and unlocked, and the Mac is trusted.
         A sleeping phone drops out of the list; launch the app or tap the screen and retry.
      3. QuickTime > File > New Movie Recording sees the iPhone; close it and retry.
    """)
    exit(1)
}

if arguments.contains("--list") {
    print("camera permission: \(permissionName(AVCaptureDevice.authorizationStatus(for: .video)))")
    printDevices()
    exit(0)
}

if !ensureCameraAccess() {
    permissionFailure()
}

do {
    if let flag = arguments.firstIndex(of: "--screenshot") {
        let out = arguments.count > flag + 1 ? arguments[flag + 1] : "build/screen.png"
        guard let phone = findPhone() else { failOrFallback("no iPhone screen-capture device") }
        print("using \(phone.localizedName) type=\(phone.deviceType.rawValue) model=\(phone.modelID)")
        try screenshot(from: phone, to: URL(fileURLWithPath: out))
    } else if let flag = arguments.firstIndex(of: "--record") {
        guard arguments.count > flag + 2 else { printUsage(); exit(64) }
        let seconds = Double(arguments[flag + 1]) ?? 4
        let url = URL(fileURLWithPath: arguments[flag + 2])
        guard let phone = findPhone() else {
            failOrFallback("no iPhone screen-capture device", seconds: seconds, url: url)
        }
        print("using \(phone.localizedName) type=\(phone.deviceType.rawValue) model=\(phone.modelID)")
        try record(from: phone, seconds: seconds, to: url)
    } else {
        printUsage()
        exit(64)
    }
} catch {
    finish("error: \(error)", code: 5)
}
