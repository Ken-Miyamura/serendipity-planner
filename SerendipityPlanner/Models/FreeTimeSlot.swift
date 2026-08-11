import Foundation

struct FreeTimeSlot: Identifiable, Equatable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var dayText: String {
        // ja: 8/11(火) / en: Tue, 8/11
        DateFormatter.localized(template: "MdE").string(from: startDate)
    }

    init(id: UUID = UUID(), startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }
}
