import SwiftUI

struct AttendanceSubjectDetailView: View {
    @ObservedObject var store: AttendanceStore
    var subject: AttendanceSubject

    // Live subject binding logic
    var liveSubject: AttendanceSubject {
        store.subjects.first(where: { $0.id == subject.id }) ?? subject
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // --- Top Card: Stats ---
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 20.0)
                            .opacity(0.2)
                            .foregroundColor(Color.gray.opacity(0.2))

                        Circle()
                            .trim(
                                from: 0.0,
                                to: CGFloat(min(liveSubject.currentPercentage / 100.0, 1.0))
                            )
                            .stroke(
                                style: StrokeStyle(
                                    lineWidth: 20.0, lineCap: .round, lineJoin: .round)
                            )
                            .foregroundColor(
                                liveSubject.currentPercentage >= liveSubject.targetPercentage
                                    ? Color.green : Color.orange
                            )
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: liveSubject.currentPercentage)

                        VStack {
                            Text(String(format: "%.1f%%", liveSubject.currentPercentage))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                            Text("Target: \(Int(liveSubject.targetPercentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top)

                    // --- Controls ---
                    HStack(spacing: 40) {
                        AttendanceButton(
                            icon: "checkmark.circle.fill", color: .green, label: "Present"
                        ) {
                            store.markPresent(for: liveSubject)
                        }

                        AttendanceButton(icon: "xmark.circle.fill", color: .red, label: "Absent") {
                            store.markAbsent(for: liveSubject)
                        }
                    }
                    .padding(.bottom)
                }
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                // --- Calculations Card ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("Analysis")
                        .font(.headline)

                    if liveSubject.currentPercentage >= liveSubject.targetPercentage {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("On Track")
                                .bold()
                        }
                        let skippable = liveSubject.classesCanSkip()
                        VStack(alignment: .leading, spacing: 5) {
                            Text(
                                skippable > 0
                                    ? "You can bunk the next \(skippable) classes safely."
                                    : "Don't miss the next class!"
                            )
                            .font(.headline)
                            .foregroundColor(skippable > 0 ? .green : .orange)

                            if skippable > 0 {
                                Text(
                                    "This will keep your attendance above \(Int(liveSubject.targetPercentage))%."
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(
                                .orange)
                            Text("Attention Needed")
                                .bold()
                        }
                        let needed = liveSubject.classesNeededToReachTarget()
                        Text(
                            needed == -1
                                ? "Target unreachable based on total classes (if 100%)."
                                : "Attend next \(needed) classes to reach target."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)

                // --- History ---
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("History")
                            .font(.headline)
                        Spacer()
                        Button("Undo Last") {
                            store.undoLastAction(for: liveSubject)
                        }
                        .font(.caption)
                        .disabled(liveSubject.history.isEmpty)
                    }

                    if liveSubject.history.isEmpty {
                        Text("No history yet.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(liveSubject.history.prefix(10)) { event in
                            HStack {
                                Circle()
                                    .fill(event.type == .present ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(event.type.rawValue.capitalized)
                                    .font(.subheadline)
                                Spacer()
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color.primary.opacity(0.05))
        .navigationTitle(liveSubject.name)
    }
}

struct AttendanceButton: View {
    let icon: String
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.primary)
            }
        }
    }
}
