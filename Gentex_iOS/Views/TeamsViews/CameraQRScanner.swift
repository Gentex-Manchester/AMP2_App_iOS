//
//  CameraQRScanner.swift
//  Gentex_iOS
//
//  UIViewControllerRepresentable wrapping AVFoundation for live QR code
//  scanning. Provides a camera preview with automatic QR detection and
//  permission handling.
//

import SwiftUI
import AVFoundation

// MARK: - CameraQRScanner

struct CameraQRScanner: UIViewControllerRepresentable {
    var onDetected: ((String) -> Void)?

    @Binding var permissionState: CameraPermissionState

    /// `false` pauses the capture session.
    var isScanning: Bool = true

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> CameraQRViewController {
        let controller = CameraQRViewController()
        controller.delegate = context.coordinator
        context.coordinator.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraQRViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CameraQRViewControllerDelegate {
        let parent: CameraQRScanner
        weak var controller: CameraQRViewController?

        init(parent: CameraQRScanner) {
            self.parent = parent
        }

        func cameraQRViewController(
            _ controller: CameraQRViewController,
            didDetect code: String
        ) {
            parent.onDetected?(code)
        }

        func cameraQRViewController(
            _ controller: CameraQRViewController,
            didChangePermission state: CameraPermissionState
        ) {
            parent.permissionState = state
        }
    }
}

// MARK: - Camera Permission State

enum CameraPermissionState {
    case notDetermined
    case authorized
    case denied
    case restricted

    var isAuthorized: Bool {
        if case .authorized = self { return true }
        return false
    }
}

// MARK: - CameraQRViewControllerDelegate

protocol CameraQRViewControllerDelegate: AnyObject {
    func cameraQRViewController(
        _ controller: CameraQRViewController,
        didDetect code: String
    )
    func cameraQRViewController(
        _ controller: CameraQRViewController,
        didChangePermission state: CameraPermissionState
    )
}

// MARK: - CameraQRViewController

class CameraQRViewController: UIViewController {
    weak var delegate: CameraQRViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastDetectedCode: String?
    private var lastDetectionTime: Date = .distantPast
    private var isSessionConfigured = false
    private var isObserving = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndSetup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    // MARK: - Permission

    private func checkPermissionAndSetup() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            delegate?.cameraQRViewController(self, didChangePermission: .authorized)
            setupCaptureSession()
        case .notDetermined:
            delegate?.cameraQRViewController(self, didChangePermission: .notDetermined)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.delegate?.cameraQRViewController(
                            self!, didChangePermission: .authorized
                        )
                        self?.setupCaptureSession()
                    } else {
                        self?.delegate?.cameraQRViewController(
                            self!, didChangePermission: .denied
                        )
                    }
                }
            }
        case .denied:
            delegate?.cameraQRViewController(self, didChangePermission: .denied)
        case .restricted:
            delegate?.cameraQRViewController(self, didChangePermission: .restricted)
        @unknown default:
            delegate?.cameraQRViewController(self, didChangePermission: .notDetermined)
        }
    }

    // MARK: - Session Setup

    private func setupCaptureSession() {
        guard !isSessionConfigured else { return }

        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back
        ) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)
        } catch {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        isSessionConfigured = true

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    // MARK: - Scanning Control

    func startScanning() {
        lastDetectedCode = nil
        lastDetectionTime = .distantPast
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    func stopScanning() {
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraQRViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue
        else { return }

        // Debounce repeat scans of the same code for 2s.
        let now = Date()
        if code == lastDetectedCode && now.timeIntervalSince(lastDetectionTime) < 2.0 {
            return
        }

        lastDetectedCode = code
        lastDetectionTime = now

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        delegate?.cameraQRViewController(self, didDetect: code)
    }
}
