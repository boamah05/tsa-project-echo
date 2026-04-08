import UIKit
import AVFoundation
import CoreML

class LiveAudioClassifierViewController: UIViewController, AVAudioRecorderDelegate {

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Listening..."
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.layer.borderWidth = 4
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }()
    
    var audioRecorder: AVAudioRecorder?
    let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
    
    let model = SoundClassifier()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(resultLabel)
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultLabel.widthAnchor.constraint(equalToConstant: 250),
            resultLabel.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        startRecordingLoop()
    }
    
    func startRecordingLoop() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record(forDuration: 4) // 4 seconds
        } catch {
            print("Failed to start recording:", error)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            classifyAudio()
        }
        startRecordingLoop()
    }
    
    func classifyAudio() {
        do {
            let audioFile = try AVAudioFile(forReading: audioFilename)
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))!
            try audioFile.read(into: buffer)
            
            let input = SoundClassifierInput(audio: buffer)
            
            guard let prediction = try? model.prediction(input: input) else { return }
            
            let category = prediction.label
            DispatchQueue.main.async {
                self.updateUI(for: category)
            }
        } catch {
            print("Error processing audio:", error)
        }
    }
    
    func updateUI(for category: String) {
        resultLabel.text = category.capitalized
        
        switch category.lowercased() {
        case "silent":
            resultLabel.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        case "passive":
            resultLabel.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        case "attention":
            resultLabel.layer.borderColor = UIColor.yellow.cgColor
        case "critical":
            resultLabel.layer.borderColor = UIColor(red: 0.6, green: 0, blue: 0, alpha: 1).cgColor
        default:
            resultLabel.layer.borderColor = UIColor.gray.cgColor
        }
    }
}