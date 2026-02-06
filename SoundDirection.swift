import Foundation
import AVFoundation

final class SoundDirection {

    enum Direction: String {
        case left
        case right
        case center
        case unknown
    }

    func estimateDirection(from buffer: AVAudioPCMBuffer) -> Direction {

        guard let channelData = buffer.floatChannelData else {
            return .unknown
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        if channelCount < 2 || frameLength <= 0 {
            return .unknown
        }

        let leftChannel = channelData[0]
        let rightChannel = channelData[1]

        var leftEnergy: Float = 0
        var rightEnergy: Float = 0

        for i in 0..<frameLength {
            let l = leftChannel[i]
            let r = rightChannel[i]
            leftEnergy += l * l
            rightEnergy += r * r
        }

        let total = leftEnergy + rightEnergy
        if total < 0.00001 {
            return .unknown
        }

        let diff = leftEnergy - rightEnergy

        let threshold: Float = 0.10 * max(leftEnergy, rightEnergy)

        if abs(diff) < threshold {
            return .center
        } else if diff > 0 {
            return .left
        } else {
            return .right
        }
    }
}
