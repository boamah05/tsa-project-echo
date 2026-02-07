import SwiftUI

struct ContentView: View {

    // MARK: - State (sample)
    @State private var soundSenseOn = true
    @State private var visionSenseOn = true

    @State private var batteryPercent: Int = 86
    @State private var isConnected = true
    @State private var systemHealthText = "Good"


    @State private var soundAngleDeg: Double = 0
    @State private var peopleDetected: Int = 2


    @StateObject private var heading = HeadingProvider()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        headerPill
                        topStatusBar
                        centerCard
                        primaryActions

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    
        .onAppear {
            heading.start()
        }
        .onDisappear {
            heading.stop()
        }
        .onReceive(heading.$headingDeg) { newHeading in
            soundAngleDeg = newHeading
        }
    }

    // MARK: - Header
    private var headerPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "dot.radiowaves.left.and.right")
            Text("Awareness Dashboard")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Top Status Bar
    private var topStatusBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                senseToggle(
                    icon: "speaker.wave.2.fill",
                    title: "Audio Sensor",
                    isOn: $soundSenseOn
                )
                .frame(maxWidth: .infinity)

                senseToggle(
                    icon: "eye.fill",
                    title: "Vision Sensor",
                    isOn: $visionSenseOn
                )
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 10) {
                statusChip(icon: "battery.100", text: "\(batteryPercent)%")
                statusChip(icon: isConnected ? "wifi" : "wifi.slash",
                           text: isConnected ? "Connected" : "Offline")
                statusChip(icon: "heart.fill", text: "Health: \(systemHealthText)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func senseToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(isOn.wrappedValue ? "ON" : "OFF")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isOn.wrappedValue ? .green : .red)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.purple)
        }
        .padding(14)
        .background { cardBackground }
    }

    private func statusChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }

    private var centerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your environment is being monitored")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.north.fill")
                        Text("Sound Direction")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))

                    MiniCompass(angleDeg: soundAngleDeg)
                        .frame(height: 140)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background { subCardBackground }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                        Text("Vision")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))

                    Text("\(peopleDetected)")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("\(peopleDetected) \(peopleDetected == 1 ? "person" : "people") detected nearby")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background { subCardBackground }
            }
        }
        .padding(16)
        .background { cardBackground }
    }

    private var primaryActions: some View {
        VStack(spacing: 12) {

            NavigationLink {
                LiveAwarenessView()
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Awareness")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.purple.opacity(0.95))
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                AwarenessHistoryView()
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Awareness History")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    private var subCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

struct MiniCompass: View {
    var angleDeg: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30.0
                    Capsule()
                        .fill(Color.white.opacity(i % 3 == 0 ? 0.40 : 0.18))
                        .frame(width: i % 3 == 0 ? 3 : 2, height: i % 3 == 0 ? 14 : 9)
                        .offset(y: -(size * 0.38))
                        .rotationEffect(.degrees(angle))
                }

                VStack(spacing: 0) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .shadow(radius: 8)
                    Text("\(Int(angleDeg.rounded()))°")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 4)
                }
                .position(center)
                .rotationEffect(.degrees(angleDeg))
            }
        }
    }
}

#Preview {
    ContentView()
}
