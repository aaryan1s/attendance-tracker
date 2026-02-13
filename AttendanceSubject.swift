import Foundation

enum AttendanceType: String, Codable {
    case present
    case absent
}

struct AttendanceEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var type: AttendanceType
}

struct AttendanceSubject: Identifiable, Codable {
    var id = UUID()
    var name: String
    var attendedClasses: Int
    var totalClasses: Int
    var targetPercentage: Double  // e.g. 75.0
    var history: [AttendanceEvent] = []  // New: History of events

    var currentPercentage: Double {
        guard totalClasses > 0 else { return 0.0 }
        return (Double(attendedClasses) / Double(totalClasses)) * 100.0
    }

    // Calculates how many more classes need to be attended to reach the target
    func classesNeededToReachTarget() -> Int {
        if totalClasses == 0 {
            return targetPercentage > 0 ? 1 : 0
        }
        let current = currentPercentage
        if current >= targetPercentage { return 0 }
        if targetPercentage >= 100.0 {
            if attendedClasses < totalClasses { return -1 }
            return 0
        }
        let numerator =
            (targetPercentage * Double(totalClasses)) - (100.0 * Double(attendedClasses))
        let denominator = 100.0 - targetPercentage
        let x = numerator / denominator
        return Int(ceil(x))
    }

    // Calculates how many classes you can skip
    func classesCanSkip() -> Int {
        let current = currentPercentage
        if current < targetPercentage { return 0 }
        guard targetPercentage > 0 else { return 999 }
        let numerator =
            (100.0 * Double(attendedClasses)) - (targetPercentage * Double(totalClasses))
        let x = numerator / targetPercentage
        return Int(floor(x))
    }
}
