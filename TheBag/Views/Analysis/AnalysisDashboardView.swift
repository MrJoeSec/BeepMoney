import SwiftUI
import Charts
import SwiftData

public struct AnalysisDashboardView: View {
    @ObservedObject var settings = UserSettings.shared
    @Query private var allTransactions: [TransactionItem]
    
    @State private var selectedMonth: Int = 9
    @State private var selectedYear: Int = 2026
    @State private var chartType: String = "Donut" // "Donut" or "Bar"
    
    public init() {
        let comp = Calendar.current.dateComponents([.year, .month], from: Date())
        _selectedMonth = State(initialValue: comp.month ?? 9)
        _selectedYear = State(initialValue: comp.year ?? 2026)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month / Year Picker Strip
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.secondarySystemFill))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach(1...12, id: \.self) { m in
                                Button(monthName(m)) {
                                    selectedMonth = m
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(monthName(selectedMonth)) \(String(selectedYear))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.secondarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Top 4 Metrics Cards (Income, Spent, Remaining, Savings Rate)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Income",
                            value: settings.formatWholeCurrency(monthIncome),
                            icon: "arrow.down.left.circle.fill",
                            iconColor: .green
                        )
                        
                        StatCard(
                            title: "Spent",
                            value: settings.formatWholeCurrency(monthExpenses),
                            icon: "arrow.up.right.circle.fill",
                            iconColor: .primary
                        )
                        
                        StatCard(
                            title: "Remaining",
                            value: settings.formatWholeCurrency(remainingCash),
                            icon: remainingCash >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                            iconColor: remainingCash >= 0 ? .green : .red,
                            subtitle: remainingCash >= 0 ? "Under Income" : "Over Income",
                            isPositive: remainingCash >= 0
                        )
                        
                        StatCard(
                            title: "Savings Rate",
                            value: String(format: "%.0f%%", savingsRate),
                            icon: "percent",
                            iconColor: savingsRate >= 20 ? .green : (savingsRate >= 0 ? .blue : .red),
                            subtitle: savingsRate >= 20 ? "On Track" : "Caution",
                            isPositive: savingsRate >= 0
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Navigation to Trends & Monthly Summary
                    HStack(spacing: 12) {
                        NavigationLink(destination: SpendingTrendsView()) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.blue)
                                Text("Trends")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        
                        NavigationLink(destination: MonthlySummaryView(month: selectedMonth, year: selectedYear, allTransactions: allTransactions)) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.indigo)
                                Text("Summary")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Dynamic Financial Analysis Insights
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dynamic Financial Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(dynamicInsights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Spending by Category Visual Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Spending by Category")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Chart Type", selection: $chartType) {
                                Text("Donut").tag("Donut")
                                Text("Bar").tag("Bar")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 130)
                        }
                        
                        if categoryBreakdown.isEmpty {
                            Text("No expenses logged for this month.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            if chartType == "Donut" {
                                Chart(categoryBreakdown) { cat in
                                    SectorMark(
                                        angle: .value("Amount", cat.amount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(4)
                                    .foregroundStyle(cat.color)
                                }
                                .frame(height: 220)
                            } else {
                                Chart(categoryBreakdown) { cat in
                                    BarMark(
                                        x: .value("Amount", cat.amount),
                                        y: .value("Category", cat.category)
                                    )
                                    .foregroundStyle(cat.color)
                                    .cornerRadius(4)
                                }
                                .frame(height: max(160, CGFloat(categoryBreakdown.count * 36)))
                                .chartXAxis {
                                    AxisMarks(position: .bottom) { value in
                                        AxisValueLabel {
                                            if let doubleVal = value.as(Double.self) {
                                                Text("\(settings.currencySymbol)\(Int(doubleVal))")
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(18)
                    .padding(.horizontal)
                    
                    // Detailed Category List with Navigation to CategoryDetailView
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if categoryBreakdown.isEmpty {
                            Text("No category expenses to display.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(categoryBreakdown) { cat in
                                    NavigationLink(destination: CategoryDetailView(
                                        categoryName: cat.category,
                                        month: selectedMonth,
                                        year: selectedYear,
                                        allTransactions: allTransactions
                                    )) {
                                        HStack(spacing: 12) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(cat.color)
                                                .frame(width: 36, height: 36)
                                                .background(cat.color.opacity(0.12))
                                                .clipShape(Circle())
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(cat.category)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.primary)
                                                
                                                Text("\(cat.transactionCount) transactions")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(settings.formatCurrency(cat.amount))
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                                
                                                Text(String(format: "%.1f%%", cat.percentage))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                    }
                                    
                                    if cat.id != categoryBreakdown.last?.id {
                                        Divider()
                                            .padding(.leading, 62)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(18)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Analysis")
        }
    }
    
    private func previousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
    }
    
    private func nextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
    }
    
    private func monthName(_ m: Int) -> String {
        DateFormatter().monthSymbols[max(0, min(11, m - 1))]
    }
    
    private var monthItems: [TransactionItem] {
        AnalyticsEngine.filterTransactions(transactions: allTransactions, for: selectedMonth, year: selectedYear)
    }
    
    private var monthExpenses: Double {
        AnalyticsEngine.totalExpenses(transactions: monthItems)
    }
    
    private var monthIncome: Double {
        AnalyticsEngine.totalIncome(transactions: monthItems, effectiveMonthlyIncome: settings.effectiveMonthlyIncome)
    }
    
    private var remainingCash: Double {
        monthIncome - monthExpenses
    }
    
    private var savingsRate: Double {
        AnalyticsEngine.savingsRate(income: monthIncome, expenses: monthExpenses)
    }
    
    private var categoryBreakdown: [CategorySpendSummary] {
        AnalyticsEngine.categoryBreakdown(transactions: monthItems)
    }
    
    private var dynamicInsights: [DynamicInsight] {
        AnalyticsEngine.generateInsights(
            allTransactions: allTransactions,
            currentMonth: selectedMonth,
            currentYear: selectedYear,
            userSettings: settings
        )
    }
}
