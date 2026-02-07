import Foundation
import AVFoundation
import SoundAnalysis
import CoreML

final class SurroundSoundClassifier: NSObject {

    struct Result {
        let label: String
        let confidence: Double
        let direction: SoundDirectionManager.Direction
    }

    var onResult: ((Result) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private var classificationRequest: SNClassifySoundRequest?

    private let directionManager = SoundDirectionManager()
    private var latestDirection: SoundDirectionManager.Direction = .unknown

    private var lastLabel: String?
    private var lastEmitTime: Date = .distantPast


    private let activeDuration: TimeInterval = 5.0

    private let restDuration: TimeInterval = 5.0

    private var isClassificationActive: Bool = false
    private var intervalTimer: DispatchSourceTimer?


    func start() throws {
        try configureAudioSession()
        try setupAnalyzer()
        installAudioTap()
        try startEngine()

        startIntervalLoop()

        print(" SurroundSoundClassifier started yo yo")
    }

    func stop() {
        intervalTimer?.cancel()
        intervalTimer = nil

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        analyzer = nil
        classificationRequest = nil

        print(" SurroundSoundClassifier stopped stop stop")
    }


    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func setupAnalyzer() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        analyzer = SNAudioStreamAnalyzer(format: inputFormat)

        let config = MLModelConfiguration()
        let model = try ProjectEchoSoundClassifier(configuration: config)

        classificationRequest = try SNClassifySoundRequest(mlModel: model.model)

        guard let analyzer = analyzer,
              let classificationRequest = classificationRequest else {
            throw NSError(domain: "SurroundSoundClassifier", code: -1)
        }

        try analyzer.add(classificationRequest, withObserver: ResultsObserver { [weak self] label, confidence in
            self?.handleClassification(label: label, confidence: confidence)
        })
    }

    private func installAudioTap() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 8192, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }

            self.latestDirection = self.directionManager.estimateDirection(from: buffer)

            guard self.isClassificationActive else { return }

            self.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
    }

    private func startEngine() throws {
        audioEngine.prepare()
        try audioEngine.start()
    }

    // Interval Loop

    private func startIntervalLoop() {
        isClassification = true

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        let cycle = activeDuration + restDuration

        let startTime = Date()

        timer.schedule(deadline: .now(), repeating: 0.25)

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let position = elapsed.truncatingRemainder(dividingBy: cycle)

            let shouldBeActive = position < self.activeDuration

            if self.isClassification != shouldBeActive {
                self.isClassification = shouldBeActive

                if shouldBeActive {
                    print("Classification ACTIVE (5s)")
                } else {
                    print("Classification PAUSED (5s)")
                }
            }
        }

        intervalTimer = timer
        timer.resume()
    }


    private func handleClassification(label: String, confidence: Double) {
        if confidence < 0.40 { return }

        let now = Date()
        let timeSinceLast = now.timeIntervalSince(lastEmitTime)

        if label == lastLabel && timeSinceLast < 0.8 {
            return
        }

        lastLabel = label
        lastEmitTime = now

        let result = Result(
            label: label,
            confidence: confidence,
            direction: latestDirection
        )

        DispatchQueue.main.async { [weak self] in
            self?.onResult?(result)
        }
    }
}


private final class ResultsObserver: NSObject, SNResultsObserving {

    private let handler: (String, Double) -> Void

    init(handler: @escaping (String, Double) -> Void) {
        self.handler = handler
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult,
              let top = classificationResult.classifications.first else {
            return
        }

        handler(top.identifier, Double(top.confidence))
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print(" SoundAnalysis failed:", error)
    }

    func requestDidComplete(_ request: SNRequest) {
        print(" SoundAnalysis request completed")
    }
}