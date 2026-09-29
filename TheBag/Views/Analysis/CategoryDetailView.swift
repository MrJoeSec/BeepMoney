import SwiftUI
import Charts
import SwiftData

public struct CategoryDetailView: View {
    @ObservedObject var settings = UserSettings.shared
    
    public let categoryName: String
    public let month: Int
    public let year: Int
    public let allTransactions: [TransactionItem]
    
    @State private var editingTransaction: TransactionItem? = nil
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Category Card
                VStack(spacing: 12) {
                    Image(systemName: CategoryCatalog.icon(for: categoryName))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(CategoryCatalog.color(for: categoryName))
                        .padding(16)
                        .background(CategoryCatalog.color(for: categoryName).opacity(0.12))
                        .clipShape(Circle())
                    
                    Text(categoryName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(settings.formatCurrency(totalSpent))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(monthName) \(String(year)) Spending")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // Key Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "Share of Total",
                        value: String(format: "%.1f%%", percentageOfTotal),
                        icon: "chart.pie.fill",
                        iconColor: CategoryCatalog.color(for: categoryName)
                    )
                    
                    StatCard(
                        title: "Avg Purchase",
                        value: settings.formatWholeCurrency(averagePurchase),
                        icon: "divide.circle.fill",
                        iconColor: .orange
                    )
                    
                    StatCard(
                        title: "Purchases",
                        value: "\(categoryTransactions.count)",
                        icon: "number.circle.fill",
                        iconColor: .indigo
                    )
                    
                    StatCard(
                        title: "vs Last Month",
                        value: momChangeFormatted,
                        icon: momIsIncrease ? "arrow.up.right" : "arrow.down.right",
                        iconColor: momIsIncrease ? .orange : .green,
                        isPositive: !momIsIncrease
                    )
                }
                .padding(.horizontal)
                
                // Subcategory Breakdown
                if !subcategoriesBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subcategory Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(subcategoriesBreakdown, id: \.subcategory) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.subcategory)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(item.count) transactions")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(settings.formatCurrency(item.amount))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        
                                        if totalSpent > 0 {
                                            Text(String(format: "%.0f%%", (item.amount / totalSpent) * 100))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                
                                if item.subcategory != subcategoriesBreakdown.last?.subcategory {
                                    Divider()
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Transactions List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transactions (\(categoryTransactions.count))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if categoryTransactions.isEmpty {
                        Text("No transactions logged in this category for \(monthName).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(categoryTransactions) { item in
                                TransactionRowView(item: item, currencySymbol: settings.currencySymbol)
                                    .padding(.horizontal, 14)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingTransaction = item
                                    }
                                
                                if item.id != categoryTransactions.last?.id {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTransaction) { item in
            TransactionEditView(transaction: item)
        }
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[max(0, min(11, month - 1))]
    }
    
    private var monthItems: [TransactionItem] {
        AnalyticsEngine.filterTransactions(transactions: allTransactions, for: month, year: year)
    }
    
    private var categoryTransactions: [TransactionItem] {
        monthItems
            .filter { $0.transactionType == .expense && $0.category.lowercased() == categoryName.lowercased() }
            .sorted(by: { $0.date > $1.date })
    }
    
    private var totalSpent: Double {
        categoryTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var percentageOfTotal: Double {
        let totalMonth = AnalyticsEngine.totalExpenses(transactions: monthItems)
        guard totalMonth > 0 else { return 0.0 }
        return (totalSpent / totalMonth) * 100.0
    }
    
    private var averagePurchase: Double {
        guard !categoryTransactions.isEmpty else { return 0.0 }
        return totalSpent / Double(categoryTransactions.count)
    }
    
    private var subcategoriesBreakdown: [(subcategory: String, amount: Double, count: Int)] {
        AnalyticsEngine.subcategoryBreakdown(transactions: monthItems, category: categoryName)
    }
    
    private var prevMonthSpent: Double {
        var prevM = month - 1
        var prevY = year
        if prevM < 1 {
            prevM = 12
            prevY -= 1
        }
        let prevItems = AnalyticsEngine.filterTransactions(transactions: allTransactions, for: prevM, year: prevY)
        return prevItems
            .filter { $0.transactionType == .expense && $0.category.lowercased() == categoryName.lowercased() }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var momIsIncrease: Bool {
        totalSpent >= prevMonthSpent
    }
    
    private var momChangeFormatted: String {
        guard prevMonthSpent > 0 else {
            return totalSpent > 0 ? "New" : "0%"
        }
        let diff = totalSpent - prevMonthSpent
        let pct = (diff / prevMonthSpent) * 100.0
        let sign = pct > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f%%", pct))"
    }
}
