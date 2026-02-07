import Foundation
import AVFoundation
import SoundAnalysis
import CoreML

final class SurroundSoundClassifier: NSObject {

    struct Result {
        let label: String
        let confidence: Double
        let direction: SoundDirection.Direction
    }

    var onResult: ((Result) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private var classificationRequest: SNClassifySoundRequest?

    private let directionEstimator = SoundDirection()
    private var latestDirection: SoundDirection.Direction = .unknown

    private var lastLabel: String?
    private var lastEmitTime: Date = .distantPast

    private let activeDuration: TimeInterval = 5.0
    private let restDuration: TimeInterval = 5.0

    private var isClassificationActive: Bool = false
    private var intervalTimer: DispatchSourceTimer?

    private var isRunning: Bool = false

    func start() throws {
        guard !isRunning else { return }
        isRunning = true

        try configureAudioSession()
        try setupAnalyzer()
        installAudioTap()
        try startEngine()

        startIntervalLoop()

        print("SurroundSoundClassifier started")
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        intervalTimer?.cancel()
        intervalTimer = nil

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        analyzer = nil
        classificationRequest = nil

        print("SurroundSoundClassifier stopped")
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func setupAnalyzer() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        analyzer = streamAnalyzer

        let config = MLModelConfiguration()
        let model = try ProjectEchoSoundClassifier(configuration: config)

        let request = try SNClassifySoundRequest(mlModel: model.model)
        classificationRequest = request

        guard let analyzer, let classificationRequest else {
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
            guard let self else { return }

            self.latestDirection = self.directionEstimator.estimateDirection(from: buffer)

            // Only run ML during active windows
            guard self.isClassificationActive else { return }

            self.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
    }

    private func startEngine() throws {
        audioEngine.prepare()
        try audioEngine.start()
    }


    private func startIntervalLoop() {
        isClassificationActive = true

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        let cycle = activeDuration + restDuration
        let startTime = Date()

        timer.schedule(deadline: .now(), repeating: 0.25)

        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.isRunning else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let position = elapsed.truncatingRemainder(dividingBy: cycle)
            let shouldBeActive = position < self.activeDuration

            if self.isClassificationActive != shouldBeActive {
                self.isClassificationActive = shouldBeActive

                if shouldBeActive {
                    print("Classification ACTIVE (\(Int(self.activeDuration))s)")
                } else {
                    print("Classification PAUSED (\(Int(self.restDuration))s)")
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
        print("SoundAnalysis failed:", error.localizedDescription)
    }

    func requestDidComplete(_ request: SNRequest) {
        print("SoundAnalysis request completed")
    }
}
