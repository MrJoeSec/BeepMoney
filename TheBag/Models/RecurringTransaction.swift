import Foundation
import SwiftData

public enum RecurringFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case biweekly = "Biweekly"
    case weekly = "Weekly"
    case yearly = "Yearly"
}

@Model
public final class RecurringTransaction {
    public var id: UUID = UUID()
    public var title: String = ""
    public var amount: Double = 0.0
    public var category: String = "Recurring Bills"
    public var subcategory: String = "Subscriptions"
    public var frequencyRaw: String = RecurringFrequency.monthly.rawValue
    public var dueDay: Int = 1 // 1-31
    public var isExpense: Bool = true
    public var reminderEnabled: Bool = true
    public var notes: String = ""
    public var isActive: Bool = true
    public var createdAt: Date = Date()
    
    public var frequency: RecurringFrequency {
        get { RecurringFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String = "Recurring Bills",
        subcategory: String = "Subscriptions",
        frequency: RecurringFrequency = .monthly,
        dueDay: Int = 1,
        isExpense: Bool = true,
        reminderEnabled: Bool = true,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.subcategory = subcategory
        self.frequencyRaw = frequency.rawValue
        self.dueDay = max(1, min(31, dueDay))
        self.isExpense = isExpense
        self.reminderEnabled = reminderEnabled
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
