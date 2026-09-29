import SwiftUI
import SwiftData

public struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = UserSettings.shared
    @Query(sort: \TransactionItem.date, order: .reverse) private var transactions: [TransactionItem]
    
    @State private var searchText: String = ""
    @State private var filterType: String = "All" // "All", "Expenses", "Income"
    @State private var editingTransaction: TransactionItem? = nil
    @State private var transactionToDelete: TransactionItem? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Segment
                Picker("Filter", selection: $filterType) {
                    Text("All").tag("All")
                    Text("Expenses").tag("Expenses")
                    Text("Income").tag("Income")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Transactions List
                if filteredTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text(searchText.isEmpty ? "No transactions recorded yet" : "No results for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Tap Quick Add to log your first expense or income." : "Try searching by category, subcategory, merchant, or notes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(groupedTransactions, id: \.dateGroup) { group in
                            Section(header: Text(group.dateGroup).font(.footnote).fontWeight(.bold)) {
                                ForEach(group.items) { item in
                                    TransactionRowView(item: item, currencySymbol: settings.currencySymbol)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editingTransaction = item
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                transactionToDelete = item
                                                showDeleteConfirmation = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                editingTransaction = item
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search category, merchant, note, amount...")
            .sheet(item: $editingTransaction) { item in
                TransactionEditView(transaction: item)
            }
            .alert("Delete Transaction", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let item = transactionToDelete {
                        modelContext.delete(item)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to permanently delete this transaction?")
            }
        }
    }
    
    private var filteredTransactions: [TransactionItem] {
        transactions.filter { item in
            // Filter by type
            if filterType == "Expenses" && item.transactionType != .expense {
                return false
            }
            if filterType == "Income" && item.transactionType != .income {
                return false
            }
            
            // Search query filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesCategory = item.category.lowercased().contains(query)
                let matchesSub = item.subcategory.lowercased().contains(query)
                let matchesMerchant = item.merchant.lowercased().contains(query)
                let matchesNotes = item.notes.lowercased().contains(query)
                let matchesAmount = String(format: "%.2f", item.amount).contains(query)
                let dateStr = item.date.formatted(date: .abbreviated, time: .omitted).lowercased()
                let matchesDate = dateStr.contains(query)
                
                return matchesCategory || matchesSub || matchesMerchant || matchesNotes || matchesAmount || matchesDate
            }
            
            return true
        }
    }
    
    private struct DateGroupedTransactions {
        let dateGroup: String
        let items: [TransactionItem]
    }
    
    private var groupedTransactions: [DateGroupedTransactions] {
        let calendar = Calendar.current
        var dict: [String: [TransactionItem]] = [:]
        var order: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        
        for item in filteredTransactions {
            let key: String
            if calendar.isDateInToday(item.date) {
                key = "Today"
            } else if calendar.isDateInYesterday(item.date) {
                key = "Yesterday"
            } else {
                key = dateFormatter.string(from: item.date)
            }
            
            if dict[key] == nil {
                dict[key] = []
                order.append(key)
            }
            dict[key]?.append(item)
        }
        
        return order.map { key in
            DateGroupedTransactions(dateGroup: key, items: dict[key] ?? [])
        }
    }
}

public struct TransactionRowView: View {
    public let item: TransactionItem
    public let currencySymbol: String
    
    public var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: CategoryCatalog.icon(for: item.category))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(CategoryCatalog.color(for: item.category))
                .frame(width: 38, height: 38)
                .background(CategoryCatalog.color(for: item.category).opacity(0.12))
                .clipShape(Circle())
            
            // Name / Subcategory & Merchant
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.merchant.isEmpty ? item.subcategory : item.merchant)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if item.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !item.notes.isEmpty {
                        Text("• \(item.notes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                let sign = item.transactionType == .expense ? "-" : "+"
                Text("\(sign)\(currencySymbol)\(String(format: "%.2f", item.amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(item.transactionType == .expense ? .primary : .green)
                
                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
