import SwiftUI
import SwiftData

public struct TransactionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = UserSettings.shared
    
    @Bindable public var transaction: TransactionItem
    
    @State private var amountString: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: String = ""
    @State private var selectedSubcategory: String = ""
    @State private var date: Date = Date()
    @State private var merchant: String = ""
    @State private var notes: String = ""
    @State private var isRecurring: Bool = false
    @State private var showingDeleteAlert: Bool = false
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type & Amount")) {
                    Picker("Type", selection: $selectedType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text(settings.currencySymbol)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        if selectedType == .expense {
                            ForEach(CategoryCatalog.standardExpenseCategories, id: \.name) { cat in
                                Text(cat.name).tag(cat.name)
                            }
                        } else {
                            ForEach(CategoryCatalog.standardIncomeCategories, id: \.name) { cat in
                                Text(cat.name).tag(cat.name)
                            }
                        }
                    }
                    .onChange(of: selectedCategory) { _, newCat in
                        let subs = CategoryCatalog.defaultSubcategories(for: newCat)
                        if !subs.contains(selectedSubcategory) {
                            selectedSubcategory = subs.first ?? newCat
                        }
                    }
                    
                    Picker("Subcategory", selection: $selectedSubcategory) {
                        let subs = CategoryCatalog.defaultSubcategories(for: selectedCategory)
                        ForEach(subs, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Merchant", text: $merchant)
                    TextField("Notes", text: $notes)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Recurring", isOn: $isRecurring)
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Delete Transaction")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(transaction)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to permanently delete this transaction?")
            }
            .onAppear {
                loadInitialValues()
            }
        }
    }
    
    private func loadInitialValues() {
        amountString = String(format: "%.2f", transaction.amount)
        selectedType = transaction.transactionType
        selectedCategory = transaction.category
        selectedSubcategory = transaction.subcategory
        date = transaction.date
        merchant = transaction.merchant
        notes = transaction.notes
        isRecurring = transaction.isRecurring
    }
    
    private func saveChanges() {
        if let val = Double(amountString), val > 0 {
            transaction.amount = val
        }
        transaction.transactionType = selectedType
        transaction.category = selectedCategory
        transaction.subcategory = selectedSubcategory
        transaction.date = date
        transaction.merchant = merchant
        transaction.notes = notes
        transaction.isRecurring = isRecurring
        
        dismiss()
    }
}
