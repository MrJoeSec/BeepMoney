import SwiftUI
import SwiftData

public struct MonthlySummaryView: View {
    @ObservedObject var settings = UserSettings.shared
    
    public let month: Int
    public let year: Int
    public let allTransactions: [TransactionItem]
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Report Card
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FINANCIAL SUMMARY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            Text("\(monthName) \(String(year))")
                                .font(.title)
                                .fontWeight(.heavy)
                        }
                        
                        Spacer()
                        
                        // Share summary text
                        ShareLink(item: formattedReportText) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    Divider()
                    
                    // Core Four Stats
                    VStack(spacing: 12) {
                        SummaryRow(title: "Income", value: settings.formatCurrency(income), color: .green)
                        SummaryRow(title: "Total Spending", value: settings.formatCurrency(expenses), color: .primary)
                        
                        Divider()
                        
                        SummaryRow(
                            title: "Net Cash Flow",
                            value: settings.formatCurrency(netFlow, showSign: true),
                            color: netFlow >= 0 ? .green : .red,
                            isBold: true
                        )
                        
                        SummaryRow(
                            title: "Savings Rate",
                            value: String(format: "%.1f%%", savingsRate),
                            color: savingsRate >= 20 ? .green : (savingsRate >= 0 ? .blue : .red),
                            isBold: true
                        )
                    }
                    
                    Divider()
                    
                    // Top Spending Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Spending Categories")
                            .font(.headline)
                        
                        if topCategories.isEmpty {
                            Text("No expenses recorded for this month.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(Array(topCategories.prefix(3).enumerated()), id: \.offset) { index, cat in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, alignment: .leading)
                                    
                                    Image(systemName: cat.icon)
                                        .foregroundColor(cat.color)
                                        .font(.subheadline)
                                    
                                    Text(cat.category)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text(settings.formatCurrency(cat.amount))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    Text("(\(Int(round(cat.percentage)))%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Compared with Previous Month
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Compared with \(prevMonthName)")
                            .font(.headline)
                        
                        if prevExpenses == 0 && expenses == 0 {
                            Text("No previous month data available.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            let diff = expenses - prevExpenses
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: diff <= 0 ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                                    .foregroundColor(diff <= 0 ? .green : .orange)
                                
                                Text(diff > 0
                                     ? "Total spending increased by \(settings.formatCurrency(diff))."
                                     : "Total spending decreased by \(settings.formatCurrency(abs(diff)))."
                                )
                                .font(.subheadline)
                            }
                            
                            // Category shifts
                            ForEach(categoryDeltas, id: \.category) { delta in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: delta.diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .foregroundColor(delta.diff > 0 ? .orange : .green)
                                    
                                    Text("\(delta.category) \(delta.diff > 0 ? "increased" : "decreased") by \(settings.formatCurrency(abs(delta.diff))).")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Month-End Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var monthName: String {
        DateFormatter().monthSymbols[max(0, min(11, month - 1))]
    }
    
    private var prevMonthName: String {
        var prevM = month - 1
        if prevM < 1 { prevM = 12 }
        return DateFormatter().monthSymbols[prevM - 1]
    }
    
    private var currentItems: [TransactionItem] {
        AnalyticsEngine.filterTransactions(transactions: allTransactions, for: month, year: year)
    }
    
    private var prevItems: [TransactionItem] {
        var prevM = month - 1
        var prevY = year
        if prevM < 1 {
            prevM = 12
            prevY -= 1
        }
        return AnalyticsEngine.filterTransactions(transactions: allTransactions, for: prevM, year: prevY)
    }
    
    private var expenses: Double {
        AnalyticsEngine.totalExpenses(transactions: currentItems)
    }
    
    private var prevExpenses: Double {
        AnalyticsEngine.totalExpenses(transactions: prevItems)
    }
    
    private var income: Double {
        AnalyticsEngine.totalIncome(transactions: currentItems, effectiveMonthlyIncome: settings.effectiveMonthlyIncome)
    }
    
    private var netFlow: Double {
        income - expenses
    }
    
    private var savingsRate: Double {
        AnalyticsEngine.savingsRate(income: income, expenses: expenses)
    }
    
    private var topCategories: [CategorySpendSummary] {
        AnalyticsEngine.categoryBreakdown(transactions: currentItems)
    }
    
    private struct CategoryDelta {
        let category: String
        let diff: Double
    }
    
    private var categoryDeltas: [CategoryDelta] {
        let currentCats = AnalyticsEngine.categoryBreakdown(transactions: currentItems)
        let prevCats = AnalyticsEngine.categoryBreakdown(transactions: prevItems)
        
        var deltas: [CategoryDelta] = []
        for cat in currentCats {
            let prevAmt = prevCats.first(where: { $0.category.lowercased() == cat.category.lowercased() })?.amount ?? 0
            let diff = cat.amount - prevAmt
            if abs(diff) >= 20 {
                deltas.append(CategoryDelta(category: cat.category, diff: diff))
            }
        }
        return deltas
    }
    
    private var formattedReportText: String {
        """
        # \(monthName) \(year) Financial Summary (TheBag)
        
        Income: \(settings.formatCurrency(income))
        Total Spending: \(settings.formatCurrency(expenses))
        Net Cash Flow: \(settings.formatCurrency(netFlow, showSign: true))
        Savings Rate: \(String(format: "%.1f%%", savingsRate))
        
        Top Categories:
        \(topCategories.prefix(3).map { "• \($0.category): \(settings.formatCurrency($0.amount)) (\(Int(round($0.percentage)))%)" }.joined(separator: "\n"))
        """
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String
    let color: Color
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isBold ? .body : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(isBold ? .title3 : .headline)
                .fontWeight(isBold ? .bold : .semibold)
                .foregroundColor(color)
        }
    }
}
