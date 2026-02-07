import SwiftUI
import SwiftData

struct AwarenessHistoryView: View {

    enum SourceFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case soundOnly = "Sound only"
        case visionOnly = "Vision only"
        case criticalOnly = "Critical"
        var id: String { rawValue }
    }

    enum RangeFilter: String, CaseIterable, Identifiable {
        case last24h = "Last 24 hours"
        case last7d  = "7 days"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \AwarenessEvent.timestamp, order: .reverse)
    private var events: [AwarenessEvent]

    @State private var sourceFilter: SourceFilter = .all
    @State private var rangeFilter: RangeFilter = .last24h

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                filterRow

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        let filtered = filteredEvents(events)

                        if filtered.isEmpty {
                            emptyState
                        } else {
                            ForEach(filtered) { e in
                                TimelineCard(event: e)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
            .padding(.top, 14)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .semibold))
            Text("Awareness History")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Spacer()

          
            Button {
                insertDemoEvent()
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
            }
        }
        .padding(.horizontal, 18)
    }

    private var filterRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                filterPill(title: "Source", selection: $sourceFilter)
                filterPill(title: "Range", selection: $rangeFilter)
            }
            .padding(.horizontal, 18)
        }
    }

    private func filterPill<T: CaseIterable & Identifiable & RawRepresentable>(
        title: String,
        selection: Binding<T>
    ) -> some View where T.RawValue == String {
        Menu {
            ForEach(Array(T.allCases)) { item in
                Button(item.rawValue) { selection.wrappedValue = item }
            }
        } label: {
            HStack(spacing: 8) {
                Text("\(title):")
                    .foregroundStyle(.white.opacity(0.65))
                Text(selection.wrappedValue.rawValue)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
            Text("No events yet")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text("Your awareness timeline will appear here as you use Live Awareness.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding(.top, 60)
    }

    private func filteredEvents(_ input: [AwarenessEvent]) -> [AwarenessEvent] {
        let now = Date()
        let cutoff: Date = {
            switch rangeFilter {
            case .last24h:
                return Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
            case .last7d:
                return Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            }
        }()

        return input
            .filter { $0.timestamp >= cutoff }
            .filter { event in
                switch sourceFilter {
                case .all:
                    return true
                case .criticalOnly:
                    return event.urgencyRaw.lowercased() == "critical"
                case .soundOnly:
          
                    return event.visionPersonCount == nil && event.emotion == nil
                case .visionOnly:
                  
                    return event.visionPersonCount != nil || event.emotion != nil
                }
            }
    }


    private func insertDemoEvent() {
        let samples: [AwarenessEvent] = [
            .init(timestamp: Date(), kind: "Vehicle", direction: "LEFT", urgency: "Attention", visionPersonCount: 0),
            .init(timestamp: Date().addingTimeInterval(-3600), kind: "Person", direction: "FRONT", urgency: "Passive", emotion: "Neutral", visionPersonCount: 1),
            .init(timestamp: Date().addingTimeInterval(-7200), kind: "Alarm", direction: "RIGHT", urgency: "Critical")
        ]
        if let pick = samples.randomElement() {
            modelContext.insert(pick)
            try? modelContext.save()
        }
    }
}

private struct TimelineCard: View {
    let event: AwarenessEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 10) {
                Circle()
                    .fill(urgencyColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: urgencyColor.opacity(0.55), radius: 10)

                Text("\(event.kindRaw) — \(event.directionRaw) — \(timeString(event.timestamp))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: iconForKind(event.kindRaw))
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 6) {
                if let count = event.visionPersonCount {
                    Text("Vision: \(count == 0 ? "No person detected" : "\(count) person\(count == 1 ? "" : "s") detected")")
                        .foregroundStyle(.white.opacity(0.78))
                }

                if let emotion = event.emotion, !emotion.isEmpty {
                    Text("Emotion: \(emotion)")
                        .foregroundStyle(.white.opacity(0.78))
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .font(.footnote.weight(.semibold))
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

    private var urgencyColor: Color {
        switch event.urgencyRaw.lowercased() {
        case "critical": return .red
        case "attention": return .yellow
        default: return .green
        }
    }

    private func iconForKind(_ kind: String) -> String {
        switch kind.lowercased() {
        case "vehicle": return "car.fill"
        case "person": return "person.fill"
        case "alarm": return "exclamationmark.triangle.fill"
        default: return "wave.3.right"
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

#Preview {
    AwarenessHistoryView()
        .modelContainer(for: AwarenessEvent.self, inMemory: true)
}
