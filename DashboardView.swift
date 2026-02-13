import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: AttendanceStore
    @State private var showingAddSubject = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.primary.opacity(0.05).edgesIgnoringSafeArea(.all)

                if store.subjects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No subjects yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Button("Add Subject") {
                            showingAddSubject = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(store.subjects) { subject in
                                NavigationLink(
                                    destination: AttendanceSubjectDetailView(
                                        store: store, subject: subject)
                                ) {
                                    AttendanceSubjectCard(subject: subject)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Attendance")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSubject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView(store: store)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showingSettings = false }
                            }
                        }
                }
            }
        }
    }
}

struct AttendanceSubjectCard: View {
    let subject: AttendanceSubject

    var statusColor: Color {
        subject.currentPercentage >= subject.targetPercentage ? .green : .orange
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(subject.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "percent")
                        .font(.caption2)
                    Text("\(String(format: "%.1f", subject.currentPercentage))%")
                        .font(.subheadline)
                        .bold()
                }
                .foregroundColor(statusColor)

                if subject.currentPercentage >= subject.targetPercentage {
                    let skippable = subject.classesCanSkip()
                    Text(skippable > 0 ? "Can bunk: \(skippable)" : "Don't bunk!")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.top, 2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("Target: \(Int(subject.targetPercentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(subject.attendedClasses) / \(subject.totalClasses)")
                    .font(.caption)
                    .padding(5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(5)
            }

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.leading, 5)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}
