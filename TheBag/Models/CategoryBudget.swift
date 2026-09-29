import Foundation
import SwiftData

@Model
public final class CategoryBudget {
    public var id: UUID = UUID()
    public var categoryName: String = ""
    public var monthlyLimit: Double = 0.0
    public var updatedAt: Date = Date()
    
    public init(id: UUID = UUID(), categoryName: String, monthlyLimit: Double, updatedAt: Date = Date()) {
        self.id = id
        self.categoryName = categoryName
        self.monthlyLimit = monthlyLimit
        self.updatedAt = updatedAt
    }
}
