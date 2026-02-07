import SwiftUI
import AVFoundation
import SwiftData

struct LiveAwarenessView: View {

    struct DetectedPerson: Identifiable {
        let id = UUID()
        var rect: CGRect
        var label: String
    }

    @Environment(\.modelContext) private var modelContext

    @StateObject private var vm = LiveAwarenessViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.black.opacity(0.92)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 14) {
                unifiedStatusBar

                GeometryReader { geo in
                    let minSide = min(geo.size.width, geo.size.height)
                    let ringSize = minSide * 0.92

                    VStack {
                        Spacer(minLength: 6)

                        ZStack {
                            DirectionalAwarenessRing(
                                soundAngleDeg: vm.soundAngleDeg,
                                soundActive: vm.soundActive,
                                urgency: vm.urgency,
                                zones: vm.visionZones,
                                arrowPulse: vm.soundActive
                            )
                            .frame(width: ringSize, height: ringSize)

                            if vm.visionDataVisible {
                                BoundingBoxesLayer(people: vm.people, urgency: vm.urgency)
                                    .frame(width: ringSize, height: ringSize)
                            }

                            EmotionCenterBadge(
                                topEmotion: vm.topEmotionDisplay,
                                isLive: vm.visionActive,
                                urgency: vm.urgency,
                                showEmotion: vm.visionDataVisible
                            )
                            .frame(width: ringSize, height: ringSize)
                        }

                        Spacer(minLength: 6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                bottomChips
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .onAppear {
            vm.onEventForHistory = { event in
                modelContext.insert(event)
                try? modelContext.save()
            }
            vm.start()
        }
        .onDisappear {
            vm.stop()
        }
    }

    // MARK: - Unified Status Bar
    private var unifiedStatusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(vm.urgency.color)
                .frame(width: 10, height: 10)
                .shadow(color: vm.urgency.color.opacity(0.6), radius: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(vm.visionStatusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    if vm.visionActive { vm.stopVision() } else { vm.startVision() }
                } label: {
                    Image(systemName: vm.visionActive ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                }

                Button {
                    if vm.soundActive { vm.stopSound() } else { vm.startSound() }
                } label: {
                    Image(systemName: vm.soundActive ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Bottom Chips
    private var bottomChips: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                chip(icon: "speaker.wave.2.fill", text: vm.soundActive ? "Sound: Live" : "Sound: Off")
                chip(icon: "waveform", text: vm.lastSoundLabel.isEmpty ? "No label" : vm.lastSoundLabel)
                chip(icon: "location.north.fill", text: "Dir: \(vm.lastDirection.rawValue)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                chip(icon: "eye.fill", text: vm.visionActive ? "Vision: Live" : "Vision: Off")

                if vm.visionDataVisible {
                    chip(icon: "person.fill", text: "People: \(vm.visionPersonCount)")
                    chip(icon: "face.smiling.fill",
                         text: vm.topEmotionDisplay.isEmpty ? "Emotion: —" : "Emotion: \(vm.topEmotionDisplay)")
                    chip(icon: "chart.bar.fill", text: "Samples: \(vm.emotionHistoryCount)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if vm.visionDataVisible, !vm.latestEmotionChips.isEmpty {
                FlowChips(items: vm.latestEmotionChips) { item in
                    chip(icon: "sparkles", text: item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }
}

@MainActor
final class LiveAwarenessViewModel: ObservableObject {

    enum Urgency: String {
        case passive, attention, critical

        var color: Color {
            switch self {
            case .passive: return .green
            case .attention: return .yellow
            case .critical: return .red
            }
        }
    }

    // UI state
    @Published var statusText: String = "Listening…"
    @Published var visionStatusText: String = "Vision ready"
    @Published var urgency: Urgency = .passive

    // Sound UI
    @Published var soundActive: Bool = false
    @Published var soundAngleDeg: Double = 0
    @Published var lastSoundLabel: String = ""
    @Published var lastDirection: ManualSoundClassifier.HeadingDirection = .unknown

    // Vision emotion UI
    @Published var visionActive: Bool = false
    @Published var topEmotionDisplay: String = ""
    @Published var latestEmotionChips: [String] = []
    @Published var emotionHistoryCount: Int = 0


    @Published var visionPersonCount: Int = 0
    @Published var visionDataVisible: Bool = false

    @Published var visionZones: [ClosedRange<Double>] = [20...55, 205...245]
    @Published var people: [LiveAwarenessView.DetectedPerson] = []

    private let classifier = ManualSoundClassifier()

    private let emotionClient = EmotionAPIClient()
    private var emotionTask: Task<Void, Never>?
    private var emotionHistory: [String] = []
    private let maxEmotionHistory = 120
    private let pollIntervalNs: UInt64 = 15_000_000_000 // 15 seconds

    var onEventForHistory: ((AwarenessEvent) -> Void)?

    // MARK: - Lifecycle
    func start() {
        startSound()
        startVision()
    }

    func stop() {
        stopSound()
        stopVision()
    }

    // MARK: - Sound Control
    func startSound() {
        Task {
            let allowed = await requestMicPermissionIfNeeded()
            guard allowed else {
                statusText = "Microphone permission needed"
                urgency = .attention
                soundActive = false
                return
            }

            classifier.onResult = { [weak self] result in
                guard let self else { return }
                self.applySoundResult(result)
            }

            do {
                try classifier.start()
                soundActive = true
                statusText = "Listening…"
                if urgency == .passive { urgency = .passive }
            } catch {
                soundActive = false
                statusText = "Audio error: \(error.localizedDescription)"
                urgency = .attention
            }
        }
    }

    func stopSound() {
        classifier.stop()
        soundActive = false
        statusText = "Sound paused"
        if !visionActive { urgency = .passive }
    }

    // MARK: - Vision Control
    func startVision() {
        guard !visionActive else { return }
        visionActive = true
        visionStatusText = "Connecting to vision…"

        emotionTask?.cancel()
        emotionTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled, self.visionActive {
                do {
                    let emotions = try await self.emotionClient.getEmotionLoop()
                    await self.applyEmotionResult(emotions)
                } catch {
                    await MainActor.run {
                
                        self.visionStatusText = "Vision live • waiting"
                        self.visionDataVisible = false
                        self.topEmotionDisplay = ""
                        self.latestEmotionChips = []
                        self.visionPersonCount = 0
                        self.people = []
                        if !self.soundActive { self.urgency = .passive }
                    }
                }

                try? await Task.sleep(nanoseconds: self.pollIntervalNs)
            }
        }
    }

    func stopVision() {
        visionActive = false
        visionStatusText = "Vision paused"
        emotionTask?.cancel()
        emotionTask = nil

        
        visionDataVisible = false
        visionPersonCount = 0
        topEmotionDisplay = ""
        latestEmotionChips = []
        emotionHistoryCount = 0
        emotionHistory.removeAll()
        people = []

        if !soundActive { urgency = .passive }
    }

    private func applySoundResult(_ result: ManualSoundClassifier.Result) {
        lastSoundLabel = result.label
        lastDirection = result.direction

        switch result.direction {
        case .left:   soundAngleDeg = 270
        case .right:  soundAngleDeg = 90
        case .front:  soundAngleDeg = 0
        case .back:   soundAngleDeg = 180
        case .unknown: break
        }

        let (msg, u) = interpret(label: result.label, direction: result.direction)
        statusText = msg
        urgency = u

        let dirString = result.direction.rawValue.uppercased()
        let urgencyString: String = {
            switch u {
            case .passive: return "Passive"
            case .attention: return "Attention"
            case .critical: return "Critical"
            }
        }()

        let emotionSnapshot = topEmotionDisplay.isEmpty ? nil : topEmotionDisplay

        let event = AwarenessEvent(
            timestamp: Date(),
            kind: normalizedKind(from: result.label),
            direction: dirString,
            urgency: urgencyString,
            emotion: emotionSnapshot,
            visionPersonCount: visionPersonCount == 0 ? nil : visionPersonCount,
            notes: "Sound: \(result.label) (\(Int(result.confidence * 100))%)"
        )
        onEventForHistory?(event)
    }

    private func interpret(label: String, direction: ManualSoundClassifier.HeadingDirection) -> (String, Urgency) {
        let dirText: String = {
            switch direction {
            case .left: return "LEFT"
            case .right: return "RIGHT"
            case .front: return "AHEAD"
            case .back: return "BEHIND"
            case .unknown: return "NEARBY"
            }
        }()

        let l = label.lowercased()

        if l.contains("siren") || l.contains("alarm") || l.contains("smoke") {
            return ("🚨 Alarm from \(dirText)", .critical)
        }
        if l.contains("car") || l.contains("vehicle") || l.contains("truck") || l.contains("engine") {
            return ("Vehicle approaching from \(dirText)", .attention)
        }
        if l.contains("speech") || l.contains("shout") || l.contains("yell") {
            return ("Voice from \(dirText)", .attention)
        }

        return ("Sound detected from \(dirText)", .passive)
    }

    private func normalizedKind(from label: String) -> String {
        let l = label.lowercased()
        if l.contains("siren") || l.contains("alarm") { return "Alarm" }
        if l.contains("car") || l.contains("vehicle") || l.contains("truck") || l.contains("engine") { return "Vehicle" }
        if l.contains("speech") || l.contains("shout") || l.contains("yell") { return "Voice" }
        return "Sound"
    }


    private func applyEmotionResult(_ emotions: [String]) async {
        await MainActor.run {

            func isValidEmotionToken(_ s: String) -> Bool {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { return false }

                let lower = trimmed.lowercased()

            
                if lower.contains("<html") || lower.contains("<!doctype") || lower.contains("ngrok")
                    || lower.contains("<head") || lower.contains("<body")
                    || lower.contains("<link") || lower.contains("</") {
                    return false
                }

                
                if trimmed.count > 24 { return false }
                let allowed = CharacterSet.letters.union(.whitespaces)
                return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
            }

            let cleaned = emotions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidEmotionToken($0) }
                .map { $0.lowercased() }

            guard !cleaned.isEmpty else {
                self.visionStatusText = "Vision live • waiting"
                self.visionDataVisible = false
                self.topEmotionDisplay = ""
                self.latestEmotionChips = []
                self.visionPersonCount = 0
                self.people = []
                return
            }

            self.visionStatusText = "Vision live • updates every 15s"
            self.visionDataVisible = true

            // Chips (dedupe, keep order)
            var seen: Set<String> = []
            let uniqueBatch = cleaned.filter { seen.insert($0).inserted }
            self.latestEmotionChips = uniqueBatch.prefix(6).map { $0.capitalized }

            // Rolling history
            for e in cleaned { self.emotionHistory.append(e) }
            if self.emotionHistory.count > self.maxEmotionHistory {
                self.emotionHistory.removeFirst(self.emotionHistory.count - self.maxEmotionHistory)
            }
            self.emotionHistoryCount = self.emotionHistory.count

            // Top emotion by frequency
            let counts = self.emotionCounts(self.emotionHistory)
            if let top = counts.max(by: { $0.value < $1.value })?.key {
                self.topEmotionDisplay = top.capitalized
            } else {
                self.topEmotionDisplay = ""
            }

            // Gentle urgency bump for negative emotions
            let topLower = self.topEmotionDisplay.lowercased()
            if topLower.contains("angry") || topLower.contains("fear") || topLower.contains("sad") {
                if self.urgency == .passive { self.urgency = .attention }
            }

            // Always show 1 person when valid
            self.visionPersonCount = 1
            let label = self.topEmotionDisplay.isEmpty ? "Person" : "Person • \(self.topEmotionDisplay)"
            self.people = [
                LiveAwarenessView.DetectedPerson(
                    rect: CGRect(x: 0.34, y: 0.22, width: 0.32, height: 0.40),
                    label: label
                )
            ]
        }
    }

    private func emotionCounts(_ items: [String]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for e in items { dict[e, default: 0] += 1 }
        return dict
    }


    private func requestMicPermissionIfNeeded() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    AVAudioApplication.requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    session.requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
    }
}


private final class EmotionAPIClient {
    private let baseURL = URL(string: "https://awareness.pythonanywhere.com")!

    enum APIError: Error, LocalizedError {
        case badResponse(Int)
        case notHTTP
        case emptyBody

        var errorDescription: String? {
            switch self {
            case .badResponse(let code): return "HTTP \(code)"
            case .notHTTP: return "Non-HTTP response"
            case .emptyBody: return "Empty response"
            }
        }
    }

    func getEmotionLoop() async throws -> [String] {
        let url = baseURL.appendingPathComponent("getEmotionLoop")
        return try await fetchEmotionArray(url: url)
    }

    private func fetchEmotionArray(url: URL) async throws -> [String] {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else { throw APIError.notHTTP }
        guard (200...299).contains(http.statusCode) else { throw APIError.badResponse(http.statusCode) }
        guard !data.isEmpty else { throw APIError.emptyBody }

        // Try JSON first
        if let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return decoded
        }

        let raw = String(decoding: data, as: UTF8.self)
        let rawLower = raw.lowercased()

        if rawLower.contains("<html") || rawLower.contains("<!doctype") || rawLower.contains("ngrok")
            || rawLower.contains("<head") || rawLower.contains("<body") || rawLower.contains("<link") {
            return []
        }

        // Fallback parse: "['happy', 'neutral']" OR "happy"
        return parsePythonListLikeString(raw)
    }

    private func parsePythonListLikeString(_ s: String) -> [String] {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)

        if (t.hasPrefix("\"") && t.hasSuffix("\"")) || (t.hasPrefix("'") && t.hasSuffix("'")) {
            t.removeFirst(); t.removeLast()
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if t.hasPrefix("[") && t.hasSuffix("]") {
            t.removeFirst()
            t.removeLast()
        }

        let parts = t
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { part -> String in
                var p = part
                if (p.hasPrefix("\"") && p.hasSuffix("\"")) || (p.hasPrefix("'") && p.hasSuffix("'")) {
                    p.removeFirst(); p.removeLast()
                }
                return p
            }
            .filter { !$0.isEmpty }

        if parts.isEmpty {
            let single = t.replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return single.isEmpty ? [] : [single]
        }

        return parts
    }
}

private struct DirectionalAwarenessRing: View {
    var soundAngleDeg: Double
    var soundActive: Bool
    var urgency: LiveAwarenessViewModel.Urgency
    var zones: [ClosedRange<Double>]
    var arrowPulse: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))

                ForEach(0..<24, id: \.self) { i in
                    let a = Double(i) * 15.0
                    Capsule()
                        .fill(Color.white.opacity(i % 6 == 0 ? 0.32 : 0.14))
                        .frame(width: i % 6 == 0 ? 3 : 2, height: i % 6 == 0 ? 14 : 8)
                        .offset(y: -(size * 0.44))
                        .rotationEffect(.degrees(a))
                }

                ForEach(Array(zones.enumerated()), id: \.offset) { _, r in
                    ArcSegment(startDeg: r.lowerBound, endDeg: r.upperBound)
                        .stroke(urgency.color.opacity(0.35),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .padding(22)
                }

                Circle()
                    .stroke(
                        urgency.color.opacity(urgency == .critical ? 0.55 : urgency == .attention ? 0.35 : 0.18),
                        lineWidth: 10
                    )
                    .padding(14)
                    .blur(radius: 0.8)

                if soundActive {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: urgency.color.opacity(0.45), radius: 16)
                        .rotationEffect(.degrees(soundAngleDeg))
                        .scaleEffect(arrowPulse ? 1.00 : 0.92)
                        .opacity(arrowPulse ? 1.0 : 0.85)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                                   value: arrowPulse)
                }

                VStack(spacing: 6) {
                    Text("Live Awareness")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)

                    Text(soundActive ? "\(Int(soundAngleDeg.rounded()))° sound" : "sound paused")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .offset(y: size * 0.12)
            }
        }
    }
}

private struct EmotionCenterBadge: View {
    var topEmotion: String
    var isLive: Bool
    var urgency: LiveAwarenessViewModel.Urgency
    var showEmotion: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            VStack {
                Spacer()
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isLive ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                            .frame(width: 7, height: 7)
                            .shadow(color: urgency.color.opacity(isLive ? 0.35 : 0.0), radius: 10)

                        Text(isLive ? "Vision Live" : "Vision Off")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Text(!showEmotion || topEmotion.isEmpty ? "—" : topEmotion)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
                        .shadow(color: urgency.color.opacity(0.35), radius: 14)

                    Text("Emotion")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
                )
                .padding(.bottom, size * 0.20)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct BoundingBoxesLayer: View {
    var people: [LiveAwarenessView.DetectedPerson]
    var urgency: LiveAwarenessViewModel.Urgency

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ForEach(people) { p in
                let r = CGRect(
                    x: p.rect.origin.x * w,
                    y: p.rect.origin.y * h,
                    width: p.rect.size.width * w,
                    height: p.rect.size.height * h
                )

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(urgency.color.opacity(0.9), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.12))
                        )
                        .shadow(color: urgency.color.opacity(0.25), radius: 18)

                    Text(p.label)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .truncationMode(.tail)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.55))
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .padding(8)
                }
                .frame(width: r.width, height: r.height)
                .position(x: r.midX, y: r.midY)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ArcSegment: Shape {
    var startDeg: Double
    var endDeg: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2

        p.addArc(
            center: c,
            radius: r,
            startAngle: .degrees(startDeg - 90),
            endAngle: .degrees(endDeg - 90),
            clockwise: false
        )
        return p
    }
}


private struct FlowChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            self.generate(in: geo)
        }
        .frame(minHeight: 10)
    }

    private func generate(in geo: GeometryProxy) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading) { d in
                        if (x + d.width) > geo.size.width {
                            x = 0
                            y -= d.height
                        }
                        let result = x
                        x += d.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = y
                        return result
                    }
            }
        }
    }
}
