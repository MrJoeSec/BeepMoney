import Foundation
import SwiftData

public enum WealthType: String, Codable, CaseIterable {
    case asset = "Asset"
    case liability = "Liability"
}

public enum AssetCategory: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case cash = "Cash"
    case investments = "Investments"
    case retirement = "Retirement"
    case otherAssets = "Other Assets"
    
    public var icon: String {
        switch self {
        case .checking: return "creditcard.fill"
        case .savings: return "building.columns.fill"
        case .cash: return "banknote.fill"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .retirement: return "lock.shield.fill"
        case .otherAssets: return "sparkles"
        }
    }
}

public enum LiabilityCategory: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case studentLoan = "Student Loan"
    case carLoan = "Car Loan"
    case mortgage = "Mortgage"
    case otherDebt = "Other Debt"
    
    public var icon: String {
        switch self {
        case .creditCard: return "creditcard.and.123"
        case .studentLoan: return "graduationcap.fill"
        case .carLoan: return "car.fill"
        case .mortgage: return "house.fill"
        case .otherDebt: return "exclamationmark.triangle.fill"
        }
    }
}

@Model
public final class WealthItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var amount: Double = 0.0
    public var typeRaw: String = WealthType.asset.rawValue
    public var category: String = AssetCategory.checking.rawValue
    public var notes: String = ""
    public var updatedAt: Date = Date()
    
    public var wealthType: WealthType {
        get { WealthType(rawValue: typeRaw) ?? .asset }
        set { typeRaw = newValue.rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        wealthType: WealthType = .asset,
        category: String,
        notes: String = "",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.typeRaw = wealthType.rawValue
        self.category = category
        self.notes = notes
        self.updatedAt = updatedAt
    }
}

@Model
public final class NetWorthSnapshot {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var totalAssets: Double = 0.0
    public var totalLiabilities: Double = 0.0
    public var netWorth: Double = 0.0
    
    public init(id: UUID = UUID(), date: Date = Date(), totalAssets: Double, totalLiabilities: Double) {
        self.id = id
        self.date = date
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.netWorth = totalAssets - totalLiabilities
    }
}
