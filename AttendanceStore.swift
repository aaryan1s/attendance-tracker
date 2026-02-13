import Combine
import Foundation
import SwiftUI

class AttendanceStore: ObservableObject {
    @Published var subjects: [AttendanceSubject] = [] {
        didSet {
            saveSubjects()
        }
    }

    private let saveKey = "saved_subjects"

    init() {
        loadSubjects()
    }

    func addSubject(name: String, target: Double) {
        let newSubject = AttendanceSubject(
            name: name, attendedClasses: 0, totalClasses: 0, targetPercentage: target, history: [])
        subjects.append(newSubject)
    }

    func deleteSubject(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
    }

    func markPresent(for subject: AttendanceSubject) {
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index].attendedClasses += 1
            subjects[index].totalClasses += 1
            subjects[index].history.insert(AttendanceEvent(date: Date(), type: .present), at: 0)
        }
    }

    func markAbsent(for subject: AttendanceSubject) {
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index].totalClasses += 1
            subjects[index].history.insert(AttendanceEvent(date: Date(), type: .absent), at: 0)
        }
    }

    // Undo the last action from history if possible, or just raw decrement
    func undoLastAction(for subject: AttendanceSubject) {
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            guard let lastEvent = subjects[index].history.first else { return }

            // Remove the event
            subjects[index].history.removeFirst()

            // Revert counts with safety checks
            if lastEvent.type == .present {
                subjects[index].attendedClasses = max(0, subjects[index].attendedClasses - 1)
                subjects[index].totalClasses = max(0, subjects[index].totalClasses - 1)
            } else {
                subjects[index].totalClasses = max(0, subjects[index].totalClasses - 1)
            }
        }
    }

    private func saveSubjects() {
        if let encoded = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadSubjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode([AttendanceSubject].self, from: data)
        {
            subjects = decoded
        }
    }
}
