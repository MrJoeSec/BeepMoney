import SwiftUI
import Charts
import SwiftData

public struct SpendingTrendsView: View {
    @ObservedObject var settings = UserSettings.shared
    @Query private var allTransactions: [TransactionItem]
    
    @State private var selectedTimeframe: Int = 6 // months
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timeframe Picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    Text("3 Months").tag(3)
                    Text("6 Months").tag(6)
                    Text("12 Months").tag(12)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Monthly Spend Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Spending Trend")
                        .font(.headline)
                    
                    if trendPoints.isEmpty || trendPoints.allSatisfy({ $0.spent == 0 }) {
                        Text("No spending recorded in this period yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        Chart {
                            ForEach(trendPoints) { point in
                                BarMark(
                                    x: .value("Month", point.monthLabel),
                                    y: .value("Spending", point.spent)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(6)
                                
                                LineMark(
                                    x: .value("Month", point.monthLabel),
                                    y: .value("Spending", point.spent)
                                )
                                .foregroundStyle(Color.indigo)
                                .symbol(Circle())
                            }
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
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
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // Income vs Expenses Comparison Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Income vs. Expenses")
                        .font(.headline)
                    
                    Chart {
                        ForEach(trendPoints) { point in
                            BarMark(
                                x: .value("Month", point.monthLabel),
                                y: .value("Income", point.income)
                            )
                            .foregroundStyle(Color.green.opacity(0.85))
                            .position(by: .value("Type", "Income"))
                            .cornerRadius(4)
                            
                            BarMark(
                                x: .value("Month", point.monthLabel),
                                y: .value("Spent", point.spent)
                            )
                            .foregroundStyle(Color.red.opacity(0.85))
                            .position(by: .value("Type", "Spent"))
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 180)
                    .chartLegend(position: .top, alignment: .trailing)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // Key Statistical Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Financial Metrics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Spent This Month",
                            value: settings.formatWholeCurrency(spentThisMonth),
                            icon: "creditcard.fill",
                            iconColor: .blue
                        )
                        
                        StatCard(
                            title: "Spent Last Month",
                            value: settings.formatWholeCurrency(spentLastMonth),
                            icon: "clock.arrow.circlepath",
                            iconColor: .indigo
                        )
                        
                        StatCard(
                            title: "Spent This Year",
                            value: settings.formatWholeCurrency(spentThisYear),
                            icon: "calendar",
                            iconColor: .purple
                        )
                        
                        StatCard(
                            title: "Avg Monthly Spend",
                            value: settings.formatWholeCurrency(averageMonthlySpend),
                            icon: "chart.bar.xaxis",
                            iconColor: .teal
                        )
                        
                        StatCard(
                            title: "Avg Daily Spend",
                            value: settings.formatWholeCurrency(dailyAverage),
                            icon: "sun.max.fill",
                            iconColor: .orange
                        )
                        
                        StatCard(
                            title: "Total Transactions",
                            value: "\(allTransactions.count)",
                            icon: "number.circle.fill",
                            iconColor: .mint
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Notable Records
                VStack(alignment: .leading, spacing: 12) {
                    Text("Records & Highlights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        if let largest = largestExpense {
                            HStack {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Largest Expense")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(largest.merchant.isEmpty ? largest.subcategory : largest.merchant)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                Text(settings.formatCurrency(largest.amount))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 14)
                        }
                        
                        if let topCategory = topSpendingCategory {
                            HStack {
                                Image(systemName: CategoryCatalog.icon(for: topCategory.category))
                                    .foregroundColor(CategoryCatalog.color(for: topCategory.category))
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Highest Spending Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(topCategory.category)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                Text(settings.formatCurrency(topCategory.amount))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 14)
                        }
                        
                        if let mostFreq = mostFrequentCategory {
                            HStack {
                                Image(systemName: "repeat.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Most Frequent Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(mostFreq.category)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                Text("\(mostFreq.transactionCount) times")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Spending Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var trendPoints: [MonthlyTrendPoint] {
        AnalyticsEngine.monthlyTrends(allTransactions: allTransactions, monthsBack: selectedTimeframe, userSettings: settings)
    }
    
    private var now: (month: Int, year: Int) {
        let comp = Calendar.current.dateComponents([.year, .month], from: Date())
        return (comp.month ?? 9, comp.year ?? 2026)
    }
    
    private var spentThisMonth: Double {
        let items = AnalyticsEngine.filterTransactions(transactions: allTransactions, for: now.month, year: now.year)
        return AnalyticsEngine.totalExpenses(transactions: items)
    }
    
    private var spentLastMonth: Double {
        var prevM = now.month - 1
        var prevY = now.year
        if prevM < 1 {
            prevM = 12
            prevY -= 1
        }
        let items = AnalyticsEngine.filterTransactions(transactions: allTransactions, for: prevM, year: prevY)
        return AnalyticsEngine.totalExpenses(transactions: items)
    }
    
    private var spentThisYear: Double {
        allTransactions
            .filter {
                $0.transactionType == .expense &&
                Calendar.current.component(.year, from: $0.date) == now.year
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var averageMonthlySpend: Double {
        let nonZeroMonths = trendPoints.filter { $0.spent > 0 }
        guard !nonZeroMonths.isEmpty else { return 0.0 }
        let sum = nonZeroMonths.reduce(0.0) { $0 + $1.spent }
        return sum / Double(nonZeroMonths.count)
    }
    
    private var dailyAverage: Double {
        AnalyticsEngine.dailySpendingAverage(expenses: spentThisMonth, month: now.month, year: now.year)
    }
    
    private var largestExpense: TransactionItem? {
        allTransactions.filter { $0.transactionType == .expense }.max(by: { $0.amount < $1.amount })
    }
    
    private var categoryBreakdownAll: [CategorySpendSummary] {
        AnalyticsEngine.categoryBreakdown(transactions: allTransactions)
    }
    
    private var topSpendingCategory: CategorySpendSummary? {
        categoryBreakdownAll.first
    }
    
    private var mostFrequentCategory: CategorySpendSummary? {
        categoryBreakdownAll.max(by: { $0.transactionCount < $1.transactionCount })
    }
}
