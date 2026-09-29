import Foundation
import SwiftUI

public struct CategorySpendSummary: Identifiable, Hashable {
    public var id: String { category }
    public let category: String
    public let amount: Double
    public let percentage: Double
    public let transactionCount: Int
    public let icon: String
    public let color: Color
}

public struct MonthlyTrendPoint: Identifiable {
    public var id: String { monthLabel }
    public let date: Date
    public let monthLabel: String
    public let spent: Double
    public let income: Double
    public let net: Double
}

public struct DynamicInsight: Identifiable {
    public let id = UUID()
    public let icon: String
    public let color: Color
    public let title: String
    public let message: String
}

public final class AnalyticsEngine {
    
    public static func dateRange(for month: Int, year: Int) -> (start: Date, end: Date) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let calendar = Calendar.current
        let start = calendar.date(from: components) ?? Date()
        
        var nextComponents = DateComponents()
        nextComponents.month = 1
        nextComponents.second = -1
        let end = calendar.date(byAdding: nextComponents, to: start) ?? Date()
        
        return (start, end)
    }
    
    public static func filterTransactions(transactions: [TransactionItem], for month: Int, year: Int) -> [TransactionItem] {
        let calendar = Calendar.current
        return transactions.filter { item in
            let comp = calendar.dateComponents([.year, .month], from: item.date)
            return comp.year == year && comp.month == month
        }
    }
    
    public static func totalExpenses(transactions: [TransactionItem]) -> Double {
        transactions
            .filter { $0.transactionType == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    public static func totalIncome(transactions: [TransactionItem], effectiveMonthlyIncome: Double) -> Double {
        let recordedIncome = transactions
            .filter { $0.transactionType == .income }
            .reduce(0) { $0 + $1.amount }
        // If user recorded individual income transactions, use recorded + default baseline if applicable
        return recordedIncome > 0 ? recordedIncome : effectiveMonthlyIncome
    }
    
    public static func recordedIncomeOnly(transactions: [TransactionItem]) -> Double {
        transactions
            .filter { $0.transactionType == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    public static func netCashFlow(income: Double, expenses: Double) -> Double {
        income - expenses
    }
    
    public static func savingsRate(income: Double, expenses: Double) -> Double {
        guard income > 0 else { return 0.0 }
        let rate = ((income - expenses) / income) * 100.0
        return max(-100.0, min(100.0, rate))
    }
    
    public static func categoryBreakdown(transactions: [TransactionItem]) -> [CategorySpendSummary] {
        let expenseItems = transactions.filter { $0.transactionType == .expense }
        let total = expenseItems.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }
        
        var grouped: [String: (amount: Double, count: Int)] = [:]
        for item in expenseItems {
            let cat = item.category
            let current = grouped[cat] ?? (0.0, 0)
            grouped[cat] = (current.amount + item.amount, current.count + 1)
        }
        
        return grouped.map { (cat, data) in
            let percentage = (data.amount / total) * 100.0
            return CategorySpendSummary(
                category: cat,
                amount: data.amount,
                percentage: percentage,
                transactionCount: data.count,
                icon: CategoryCatalog.icon(for: cat),
                color: CategoryCatalog.color(for: cat)
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    public static func subcategoryBreakdown(transactions: [TransactionItem], category: String) -> [(subcategory: String, amount: Double, count: Int)] {
        let items = transactions.filter {
            $0.transactionType == .expense && $0.category.lowercased() == category.lowercased()
        }
        var map: [String: (amount: Double, count: Int)] = [:]
        for item in items {
            let sub = item.subcategory.isEmpty ? item.category : item.subcategory
            let cur = map[sub] ?? (0.0, 0)
            map[sub] = (cur.amount + item.amount, cur.count + 1)
        }
        return map.map { (sub, val) in
            (subcategory: sub, amount: val.amount, count: val.count)
        }.sorted { $0.amount > $1.amount }
    }
    
    public static func dailySpendingAverage(expenses: Double, month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let curComp = calendar.dateComponents([.year, .month, .day], from: now)
        
        let daysToDivide: Int
        if curComp.year == year && curComp.month == month {
            daysToDivide = max(1, curComp.day ?? 1)
        } else {
            // Full month days
            var comp = DateComponents(year: year, month: month)
            comp.day = 1
            if let date = calendar.date(from: comp),
               let range = calendar.range(of: .day, in: .month, for: date) {
                daysToDivide = range.count
            } else {
                daysToDivide = 30
            }
        }
        return expenses / Double(daysToDivide)
    }
    
    public static func projectedMonthlySpend(expenses: Double, month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        var comp = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: comp),
              let totalDays = calendar.range(of: .day, in: .month, for: date)?.count else {
            return expenses
        }
        let daily = dailySpendingAverage(expenses: expenses, month: month, year: year)
        return daily * Double(totalDays)
    }
    
    public static func generateInsights(
        allTransactions: [TransactionItem],
        currentMonth: Int,
        currentYear: Int,
        userSettings: UserSettings
    ) -> [DynamicInsight] {
        var insights: [DynamicInsight] = []
        let calendar = Calendar.current
        
        let currentItems = filterTransactions(transactions: allTransactions, for: currentMonth, year: currentYear)
        let currentExpenses = totalExpenses(transactions: currentItems)
        let currentIncome = totalIncome(transactions: currentItems, effectiveMonthlyIncome: userSettings.effectiveMonthlyIncome)
        
        // Previous month calculation
        var prevMonth = currentMonth - 1
        var prevYear = currentYear
        if prevMonth < 1 {
            prevMonth = 12
            prevYear -= 1
        }
        let prevItems = filterTransactions(transactions: allTransactions, for: prevMonth, year: prevYear)
        let prevExpenses = totalExpenses(transactions: prevItems)
        
        // 1. Remaining budget insight
        let remaining = currentIncome - currentExpenses
        if currentIncome > 0 {
            if remaining >= 0 {
                insights.append(DynamicInsight(
                    icon: "wallet.pass.fill",
                    color: .green,
                    title: "Monthly Buffer",
                    message: "You have \(userSettings.formatWholeCurrency(remaining)) remaining for the month based on your current income and spending."
                ))
            } else {
                insights.append(DynamicInsight(
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    title: "Spending Alert",
                    message: "You are currently \(userSettings.formatWholeCurrency(abs(remaining))) over your monthly income."
                ))
            }
        }
        
        // 2. Daily average burn rate and projection
        let dailyAvg = dailySpendingAverage(expenses: currentExpenses, month: currentMonth, year: currentYear)
        let projected = projectedMonthlySpend(expenses: currentExpenses, month: currentMonth, year: currentYear)
        if currentExpenses > 0 {
            insights.append(DynamicInsight(
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                title: "Daily Spend Rate",
                message: "Your spending is currently averaging \(userSettings.formatWholeCurrency(dailyAvg))/day. At this rate, you may spend approximately \(userSettings.formatWholeCurrency(projected)) this month."
            ))
        }
        
        // 3. Category MoM comparisons (e.g. Travel, Eating Out, Housing)
        let currentCatBreakdown = categoryBreakdown(transactions: currentItems)
        let prevCatBreakdown = categoryBreakdown(transactions: prevItems)
        
        if let topCat = currentCatBreakdown.first, currentExpenses > 0 {
            let pct = Int(round(topCat.percentage))
            insights.append(DynamicInsight(
                icon: topCat.icon,
                color: topCat.color,
                title: "Top Category",
                message: "\(topCat.category) represents \(pct)% of your total spending this month (\(userSettings.formatWholeCurrency(topCat.amount)))."
            ))
        }
        
        // Look for notable category shifts
        for catSummary in currentCatBreakdown.prefix(3) {
            let catName = catSummary.category
            let currentAmt = catSummary.amount
            if let prevCat = prevCatBreakdown.first(where: { $0.category.lowercased() == catName.lowercased() }) {
                let prevAmt = prevCat.amount
                if prevAmt > 0 {
                    let diff = currentAmt - prevAmt
                    let changePct = Int(round((diff / prevAmt) * 100.0))
                    if changePct > 15 {
                        insights.append(DynamicInsight(
                            icon: "arrow.up.right",
                            color: .orange,
                            title: "\(catName) Spending",
                            message: "Your \(catName) spending is \(changePct)% higher than last month (\(userSettings.formatWholeCurrency(currentAmt)) vs \(userSettings.formatWholeCurrency(prevAmt)))."
                        ))
                    } else if changePct < -15 {
                        insights.append(DynamicInsight(
                            icon: "arrow.down.right",
                            color: .green,
                            title: "\(catName) Reduction",
                            message: "You're spending \(abs(changePct))% less on \(catName) than last month."
                        ))
                    }
                }
            }
        }
        
        // 4. Restaurant / Eating out specific count
        let eatingOutCount = currentItems.filter {
            $0.transactionType == .expense &&
            ($0.category.lowercased().contains("eat") ||
             $0.subcategory.lowercased().contains("restaurant") ||
             $0.subcategory.lowercased().contains("dinner") ||
             $0.subcategory.lowercased().contains("fast food") ||
             $0.subcategory.lowercased().contains("lunch"))
        }.count
        if eatingOutCount >= 3 {
            insights.append(DynamicInsight(
                icon: "fork.knife",
                color: .orange,
                title: "Dining Frequency",
                message: "You made \(eatingOutCount) dining/restaurant purchases this month."
            ))
        }
        
        // 5. Largest expense
        if let largest = currentItems.filter({ $0.transactionType == .expense }).max(by: { $0.amount < $1.amount }) {
            let name = largest.merchant.isEmpty ? (largest.subcategory.isEmpty ? largest.category : largest.subcategory) : largest.merchant
            insights.append(DynamicInsight(
                icon: "tag.fill",
                color: .purple,
                title: "Largest Expense",
                message: "Largest single expense was \(userSettings.formatWholeCurrency(largest.amount)) for \(name) on \(largest.date.formatted(date: .abbreviated, time: .omitted))."
            ))
        }
        
        // Fallback default insight if no data yet
        if insights.isEmpty {
            insights.append(DynamicInsight(
                icon: "sparkles",
                color: .blue,
                title: "Ready to Track",
                message: "Log your purchases with Quick Add to unlock personalized spending trends and real-time insights."
            ))
        }
        
        return insights
    }
    
    public static func monthlyTrends(allTransactions: [TransactionItem], monthsBack: Int = 6, userSettings: UserSettings) -> [MonthlyTrendPoint] {
        let calendar = Calendar.current
        var points: [MonthlyTrendPoint] = []
        let now = Date()
        
        for i in (0..<monthsBack).reversed() {
            guard let targetDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let comp = calendar.dateComponents([.year, .month], from: targetDate)
            let month = comp.month ?? 1
            let year = comp.year ?? 2026
            
            let items = filterTransactions(transactions: allTransactions, for: month, year: year)
            let spent = totalExpenses(transactions: items)
            let income = totalIncome(transactions: items, effectiveMonthlyIncome: userSettings.effectiveMonthlyIncome)
            let net = income - spent
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let label = formatter.string(from: targetDate)
            
            points.append(MonthlyTrendPoint(
                date: targetDate,
                monthLabel: label,
                spent: spent,
                income: income,
                net: net
            ))
        }
        return points
    }
}
