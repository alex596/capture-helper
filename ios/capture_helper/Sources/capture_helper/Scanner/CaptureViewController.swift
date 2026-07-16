import UIKit
import AVFoundation

/// Mode de capture
@available(iOS 13.0, *)
enum CaptureMode {
    case auto    // Capture auto après stabilisation + bouton manuel
    case manual  // Bouton manuel uniquement
}

/// Configuration de la capture
@available(iOS 13.0, *)
struct CaptureConfiguration {
    var mode: CaptureMode = .manual
    var autoCaptureDelay: TimeInterval = 1.0
    var minSharpness: Int = 0
    var minBrightness: Int = 0
    var minDocumentCoverage: Int = 15  // 15% permet de scanner de plus loin

    static let `default` = CaptureConfiguration()
}

/// Protocole pour les événements du scanner
@available(iOS 13.0, *)
protocol CaptureViewControllerDelegate: AnyObject {
    func captureViewController(_ controller: CaptureViewController, didCaptureImage image: UIImage, withDocument document: DocumentDetector.DetectedDocument?, quality: ImageQualityAnalyzer.QualityResult)
    func captureViewControllerDidCancel(_ controller: CaptureViewController)
}

/// ViewController pour la capture de documents avec preview caméra
@available(iOS 13.0, *)
class CaptureViewController: UIViewController {

    weak var delegate: CaptureViewControllerDelegate?

    /// Configuration de la capture
    var configuration = CaptureConfiguration.default

    /// Numéro de page actuelle (pour multi-pages)
    var currentPageNumber: Int = 1

    /// Nombre total de pages à capturer
    var totalPages: Int = 1

    // MARK: - Composants UI

    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var overlayView: DocumentOverlayView = {
        let view = DocumentOverlayView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor

        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 28
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        innerCircle.tag = 100
        button.addSubview(innerCircle)

        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56)
        ])

        button.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Annuler", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var instructionLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Positionnez le document dans le cadre"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ""
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private lazy var pageCounterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var autoCaptureProgressView: CircularProgressView = {
        let view = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var processingOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.isHidden = true

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()

        let label = UILabel()
        label.text = "Traitement en cours..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)

        stackView.addArrangedSubview(spinner)
        stackView.addArrangedSubview(label)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }()

    // MARK: - Capture Session

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let captureQueue = DispatchQueue(label: "com.capturehelper.capture", qos: .userInteractive)

    // MARK: - Détection et qualité

    private let documentDetector = DocumentDetector()
    private let qualityAnalyzer = ImageQualityAnalyzer()
    private var lastDetectedDocument: DocumentDetector.DetectedDocument?
    private var isCapturing = false
    private var videoBufferSize: CGSize = .zero
    private var pendingPhotoCapture: ((UIImage?) -> Void)?

    // MARK: - Auto-capture

    private var autoCaptureTimer: Timer?
    private var autoCaptureProgress: CGFloat = 0
    private var isDocumentStable = false
    private var stableStartTime: Date?

    // MARK: - Haptique

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCaptureSession()
        configureQualityAnalyzer()
        feedbackGenerator.prepare()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetCaptureState()
        startCapture()
        updatePageCounter()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Marquer comme en cours de capture pour éviter les callbacks de détection
        isCapturing = true
        stopAutoCaptureTimer()
        stopCapture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Configuration

    private func configureQualityAnalyzer() {
        qualityAnalyzer.setThresholds(
            minSharpness: configuration.minSharpness,
            minBrightness: configuration.minBrightness,
            minCoverage: configuration.minDocumentCoverage
        )
    }

    private func resetCaptureState() {
        isCapturing = false
        lastDetectedDocument = nil
        isDocumentStable = false
        stableStartTime = nil
        autoCaptureProgress = 0
        overlayView.hideOverlay(animated: false)
        autoCaptureProgressView.setProgress(0, animated: false)
        autoCaptureProgressView.isHidden = true
        processingOverlay.isHidden = true
        updateCaptureButtonState(detected: false, stable: false)

        // Réactiver les boutons
        captureButton.isEnabled = true
        cancelButton.isEnabled = true
    }

    private func updatePageCounter() {
        if totalPages > 1 {
            pageCounterLabel.text = "  \(currentPageNumber)/\(totalPages)  "
            pageCounterLabel.isHidden = false
        } else {
            pageCounterLabel.isHidden = true
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(previewView)
        view.addSubview(overlayView)
        view.addSubview(captureButton)
        view.addSubview(autoCaptureProgressView)
        view.addSubview(cancelButton)
        view.addSubview(instructionLabel)
        view.addSubview(statusLabel)
        view.addSubview(pageCounterLabel)
        view.addSubview(processingOverlay)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: previewView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),

            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            autoCaptureProgressView.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            autoCaptureProgressView.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            autoCaptureProgressView.widthAnchor.constraint(equalToConstant: 80),
            autoCaptureProgressView.heightAnchor.constraint(equalToConstant: 80),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),

            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),

            pageCounterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pageCounterLabel.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            pageCounterLabel.heightAnchor.constraint(equalToConstant: 30),

            processingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            processingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            processingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            processingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Capture Session Setup

    private func setupCaptureSession() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showError("Impossible d'accéder à la caméra")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video output pour la détection de document
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Photo output pour la capture instantanée
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = previewView.bounds

        if let previewLayer = previewLayer {
            previewView.layer.addSublayer(previewLayer)
        }

        do {
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            camera.unlockForConfiguration()
        } catch {
            print("Erreur configuration caméra: \(error)")
        }
    }

    private func startCapture() {
        captureQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func stopCapture() {
        captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Auto-capture

    private func startAutoCaptureTimer() {
        guard configuration.mode == .auto else { return }
        guard autoCaptureTimer == nil else { return }

        stableStartTime = Date()
        autoCaptureProgressView.isHidden = false

        // Forcer l'affichage immédiat de la vue de progression
        view.bringSubviewToFront(autoCaptureProgressView)

        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAutoCaptureProgress()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoCaptureTimer = timer
    }

    private func stopAutoCaptureTimer() {
        autoCaptureTimer?.invalidate()
        autoCaptureTimer = nil
        stableStartTime = nil
        autoCaptureProgress = 0
        autoCaptureProgressView.setProgress(0, animated: true)
        autoCaptureProgressView.isHidden = true
    }

    private func updateAutoCaptureProgress() {
        guard let startTime = stableStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        autoCaptureProgress = CGFloat(elapsed / configuration.autoCaptureDelay)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.autoCaptureProgressView.setProgress(self.autoCaptureProgress, animated: false)

            if self.autoCaptureProgress >= 1.0 {
                self.triggerAutoCapture()
            }
        }
    }

    private func triggerAutoCapture() {
        stopAutoCaptureTimer()
        performCapture()
    }

    // MARK: - Actions

    @objc private func captureButtonTapped() {
        feedbackGenerator.impactOccurred()
        stopAutoCaptureTimer()
        performCapture()
    }

    @objc private func cancelButtonTapped() {
        // Désactiver le bouton pour éviter les doubles clics
        cancelButton.isEnabled = false
        captureButton.isEnabled = false

        // Arrêter l'auto-capture d'abord
        stopAutoCaptureTimer()

        // Marquer comme en cours de capture pour ignorer les frames
        isCapturing = true

        // Arrêter la caméra de manière sécurisée, puis notifier le delegate
        stopCaptureAndNotify { [weak self] in
            guard let self = self else { return }
            self.delegate?.captureViewControllerDidCancel(self)
        }
    }

    private func stopCaptureAndNotify(completion: @escaping () -> Void) {
        captureQueue.async { [weak self] in
            self?.captureSession.stopRunning()

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    private func performCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        // Désactiver les boutons pendant la capture
        captureButton.isEnabled = false
        cancelButton.isEnabled = false

        overlayView.showCaptureFlash()
        notificationGenerator.notificationOccurred(.success)

        capturePhoto()
    }

    // MARK: - Capture

    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        pendingPhotoCapture = { [weak self] image in
            guard let self = self else { return }

            if let image = image {
                self.processAndDeliverImage(image)
            } else {
                self.isCapturing = false
                self.captureButton.isEnabled = true
                self.cancelButton.isEnabled = true
                self.showError("Impossible de capturer l'image")
            }
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func processAndDeliverImage(_ image: UIImage) {
        let document = lastDetectedDocument
        let analyzer = qualityAnalyzer

        // Afficher l'overlay de traitement
        processingOverlay.isHidden = false

        // Analyser la qualité en background pour ne pas bloquer l'UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var documentBounds: CGRect? = nil
            if let doc = document {
                let coverage = analyzer.calculateDocumentCoverage(
                    topLeft: doc.topLeft,
                    topRight: doc.topRight,
                    bottomLeft: doc.bottomLeft,
                    bottomRight: doc.bottomRight
                )
                documentBounds = CGRect(x: 0, y: 0, width: CGFloat(coverage), height: CGFloat(coverage))
            }

            let quality = analyzer.analyzeQuality(of: image, documentBounds: documentBounds)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.processingOverlay.isHidden = true
                self.stopCapture()
                self.delegate?.captureViewController(self, didCaptureImage: image, withDocument: document, quality: quality)
            }
        }
    }

    // MARK: - UI Updates

    private func updateCaptureButtonState(detected: Bool, stable: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if detected {
                if stable {
                    self.captureButton.layer.borderColor = UIColor.systemGreen.cgColor
                    self.overlayView.detectedColor = UIColor.systemGreen.withAlphaComponent(0.2)
                    self.overlayView.borderColor = .systemGreen
                } else {
                    self.captureButton.layer.borderColor = UIColor.systemYellow.cgColor
                    self.overlayView.detectedColor = UIColor.systemYellow.withAlphaComponent(0.2)
                    self.overlayView.borderColor = .systemYellow
                }
            } else {
                self.captureButton.layer.borderColor = UIColor.white.cgColor
                self.overlayView.detectedColor = UIColor.gray.withAlphaComponent(0.2)
                self.overlayView.borderColor = .gray
            }
        }
    }

    private func updateStatus(documentDetected: Bool, isStable: Bool, coverage: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if documentDetected {
                if isStable {
                    if self.configuration.mode == .auto {
                        self.statusLabel.text = "Restez stable..."
                        self.statusLabel.textColor = .systemGreen
                    } else {
                        self.statusLabel.text = "Document détecté"
                        self.statusLabel.textColor = .systemGreen
                    }
                } else {
                    if coverage < self.configuration.minDocumentCoverage && self.configuration.minDocumentCoverage > 0 {
                        self.statusLabel.text = "Rapprochez le document"
                        self.statusLabel.textColor = .systemYellow
                    } else {
                        self.statusLabel.text = "Stabilisez..."
                        self.statusLabel.textColor = .systemYellow
                    }
                }
            } else {
                self.statusLabel.text = ""
            }

            self.updateCaptureButtonState(detected: documentDetected, stable: isStable)
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Erreur",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.captureViewControllerDidCancel(self)
            })
            self?.present(alert, animated: true)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
@available(iOS 13.0, *)
extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ne pas traiter si on est en train de capturer ou d'annuler
        guard !isCapturing else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        videoBufferSize = CGSize(width: bufferHeight, height: bufferWidth)

        // Détection de document uniquement (pas de copie de buffer)
        documentDetector.detectDocument(in: sampleBuffer) { [weak self] document in
            guard let self = self, !self.isCapturing else { return }

            self.lastDetectedDocument = document

            // Toutes les mises à jour UI sur le main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isCapturing else { return }

                let previouslyStable = self.isDocumentStable

                if let document = document {
                    let points = self.convertVisionPointsToViewPoints(document: document)
                    self.overlayView.updateDocumentBounds(points: points, animated: true)

                    let coverage = self.qualityAnalyzer.calculateDocumentCoverage(
                        topLeft: document.topLeft,
                        topRight: document.topRight,
                        bottomLeft: document.bottomLeft,
                        bottomRight: document.bottomRight
                    )

                    let meetsMinCoverage = coverage >= self.configuration.minDocumentCoverage || self.configuration.minDocumentCoverage == 0
                    self.isDocumentStable = document.isStable && meetsMinCoverage

                    self.updateStatus(documentDetected: true, isStable: self.isDocumentStable, coverage: coverage)

                    // Gestion auto-capture
                    if self.configuration.mode == .auto {
                        if self.isDocumentStable && !previouslyStable {
                            self.startAutoCaptureTimer()
                        } else if !self.isDocumentStable && previouslyStable {
                            self.stopAutoCaptureTimer()
                        }
                    }
                } else {
                    self.isDocumentStable = false
                    self.overlayView.hideOverlay(animated: true)
                    self.updateStatus(documentDetected: false, isStable: false, coverage: 0)

                    if self.configuration.mode == .auto {
                        self.stopAutoCaptureTimer()
                    }
                }
            }
        }
    }

    private func convertVisionPointsToViewPoints(document: DocumentDetector.DetectedDocument) -> [CGPoint] {
        guard let previewLayer = previewLayer else {
            return document.points(in: overlayView.bounds.size)
        }

        let visionPoints = [
            document.topLeft,
            document.topRight,
            document.bottomRight,
            document.bottomLeft
        ]

        // Avec orientation .right dans Vision (caméra arrière portrait):
        // Les coordonnées Vision sont pivotées de 90°
        return visionPoints.map { visionPoint in
            let capteurPoint = CGPoint(x: visionPoint.y, y: 1 - visionPoint.x)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: capteurPoint)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
@available(iOS 13.0, *)
extension CaptureViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let error = error {
                print("Erreur capture photo: \(error)")
                self.pendingPhotoCapture?(nil)
                self.pendingPhotoCapture = nil
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.pendingPhotoCapture?(nil)
                self.pendingPhotoCapture = nil
                return
            }

            self.pendingPhotoCapture?(image)
            self.pendingPhotoCapture = nil
        }
    }
}

// MARK: - Helper Views

/// Label avec padding
class PaddedLabel: UILabel {
    var padding = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
    }
}

/// Vue de progression circulaire pour l'auto-capture
@available(iOS 13.0, *)
class CircularProgressView: UIView {

    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private var hasSetupLayers = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        backgroundLayer.lineWidth = 5
        layer.addSublayer(backgroundLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemGreen.cgColor
        progressLayer.lineWidth = 5
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0 && bounds.height > 0 else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        backgroundLayer.frame = bounds
        progressLayer.frame = bounds
        backgroundLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        let clampedProgress = max(0, min(1, progress))

        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(0.1)
        } else {
            CATransaction.setDisableActions(true)
        }
        progressLayer.strokeEnd = clampedProgress
        CATransaction.commit()
    }
}
