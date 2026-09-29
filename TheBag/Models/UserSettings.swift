import Foundation
import SwiftUI
import Combine

public enum IncomeFrequency: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case biweekly = "Biweekly"
    case weekly = "Weekly"
    case other = "Other"
    
    public var id: String { rawValue }
    
    /// Multiplier to convert to effective monthly income
    public var monthlyMultiplier: Double {
        switch self {
        case .monthly: return 1.0
        case .biweekly: return 26.0 / 12.0 // ~2.1667
        case .weekly: return 52.0 / 12.0   // ~4.3333
        case .other: return 1.0
        }
    }
}

public struct CurrencyOption: Identifiable, Hashable {
    public let code: String
    public let symbol: String
    public let name: String
    
    public var id: String { code }
    
    public static let popular: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "CAD", symbol: "CA$", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyOption(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyOption(code: "CHF", symbol: "CHF", name: "Swiss Franc"),
        CurrencyOption(code: "AED", symbol: "AED", name: "UAE Dirham"),
        CurrencyOption(code: "SAR", symbol: "SAR", name: "Saudi Riyal"),
        CurrencyOption(code: "INR", symbol: "₹", name: "Indian Rupee")
    ]
}

public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()
    
    @AppStorage("hasCompletedOnboarding") public var hasCompletedOnboarding: Bool = false
    @AppStorage("monthlyIncome") public var monthlyIncome: Double = 5000.0
    @AppStorage("incomeFrequencyRaw") public var incomeFrequencyRaw: String = IncomeFrequency.monthly.rawValue
    @AppStorage("currencyCode") public var currencyCode: String = "USD"
    @AppStorage("startingBalance") public var startingBalance: Double = 0.0
    @AppStorage("savingsGoal") public var savingsGoal: Double = 1000.0
    @AppStorage("isBiometricLockEnabled") public var isBiometricLockEnabled: Bool = false
    
    public var incomeFrequency: IncomeFrequency {
        get { IncomeFrequency(rawValue: incomeFrequencyRaw) ?? .monthly }
        set { incomeFrequencyRaw = newValue.rawValue }
    }
    
    public var effectiveMonthlyIncome: Double {
        return monthlyIncome * incomeFrequency.monthlyMultiplier
    }
    
    public var currencySymbol: String {
        CurrencyOption.popular.first(where: { $0.code == currencyCode })?.symbol ?? "$"
    }
    
    public func formatCurrency(_ amount: Double, showSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? String(format: "\(currencySymbol)%.2f", abs(amount))
        if showSign {
            if amount > 0 {
                return "+\(formatted)"
            } else if amount < 0 {
                return "-\(formatted)"
            }
        }
        return amount < 0 ? "-\(formatted)" : formatted
    }
    
    public func formatWholeCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "\(currencySymbol)%.0f", amount)
    }
}
