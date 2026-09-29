import Foundation
import SwiftData

public enum TransactionType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
}

@Model
public final class TransactionItem {
    public var id: UUID = UUID()
    public var amount: Double = 0.0
    public var typeRaw: String = TransactionType.expense.rawValue
    public var category: String = "Groceries"
    public var subcategory: String = "Supermarket"
    public var date: Date = Date()
    public var merchant: String = ""
    public var notes: String = ""
    public var isRecurring: Bool = false
    public var createdAt: Date = Date()
    
    public var transactionType: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        amount: Double,
        transactionType: TransactionType = .expense,
        category: String,
        subcategory: String = "",
        date: Date = Date(),
        merchant: String = "",
        notes: String = "",
        isRecurring: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.typeRaw = transactionType.rawValue
        self.category = category
        self.subcategory = subcategory.isEmpty ? category : subcategory
        self.date = date
        self.merchant = merchant
        self.notes = notes
        self.isRecurring = isRecurring
        self.createdAt = createdAt
    }
}
