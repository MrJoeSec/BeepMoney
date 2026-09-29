import SwiftUI
import SwiftData

public struct QuickAddView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var settings = UserSettings.shared
    @Query private var customCategories: [CustomCategoryItem]
    
    // Core transaction state
    @State private var transactionType: TransactionType = .expense
    @State private var amountString: String = "0"
    @State private var selectedCategory: String = "Groceries"
    @State private var selectedSubcategory: String = "Supermarket"
    
    // Optional details
    @State private var merchant: String = ""
    @State private var notes: String = ""
    @State private var transactionDate: Date = Date()
    @State private var isRecurring: Bool = false
    @State private var showingMoreDetails: Bool = false
    
    // Success feedback
    @State private var showConfirmation: Bool = false
    @State private var lastAddedDescription: String = ""
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 12) {
                    // Top Bar: Date & Type Switcher
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(transactionDate.formatted(date: .complete, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Quick Add")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // Expense / Income Picker
                        Picker("Type", selection: $transactionType) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                        .onChange(of: transactionType) { _, newType in
                            onTypeChanged(newType)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Amount Display Area
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(settings.currencySymbol)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text(amountString)
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(transactionType == .expense ? .primary : .green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        Button(action: {
                            showingMoreDetails = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.subheadline)
                                Text("Details")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    
                    // Category Selection Grid / Scroll
                    VStack(alignment: .leading, spacing: 6) {
                        Text(transactionType == .expense ? "What did you spend on?" : "Income Source")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(currentCategories, id: \.name) { cat in
                                    CategoryPill(
                                        name: cat.name,
                                        icon: cat.icon,
                                        color: cat.color,
                                        isSelected: selectedCategory.lowercased() == cat.name.lowercased()
                                    ) {
                                        selectCategory(cat.name)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Subcategories Chips
                    if !currentSubcategories.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(currentSubcategories, id: \.self) { sub in
                                        Button(action: {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                            selectedSubcategory = sub
                                        }) {
                                            Text(sub)
                                                .font(.system(size: 13, weight: selectedSubcategory.lowercased() == sub.lowercased() ? .semibold : .regular))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(
                                                    selectedSubcategory.lowercased() == sub.lowercased()
                                                    ? Color.accentColor.opacity(0.18)
                                                    : Color(.secondarySystemFill)
                                                )
                                                .foregroundColor(
                                                    selectedSubcategory.lowercased() == sub.lowercased()
                                                    ? .accentColor
                                                    : .primary
                                                )
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedSubcategory.lowercased() == sub.lowercased() ? Color.accentColor : Color.clear, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Calculator Keypad
                    CalculatorKeypadView(amountString: $amountString)
                        .padding(.horizontal)
                    
                    // Instant ADD Button
                    Button(action: commitTransaction) {
                        HStack(spacing: 8) {
                            Image(systemName: transactionType == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.title3)
                            Text(transactionType == .expense ? "ADD EXPENSE" : "ADD INCOME")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            canSubmit
                            ? (transactionType == .expense ? Color.blue : Color.green)
                            : Color.gray.opacity(0.4)
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: canSubmit
                            ? (transactionType == .expense ? Color.blue.opacity(0.3) : Color.green.opacity(0.3))
                            : Color.clear,
                            radius: 6,
                            y: 2
                        )
                    }
                    .disabled(!canSubmit)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Top Confirmation Toast
                if showConfirmation {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text(lastAddedDescription)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMoreDetails) {
                MoreDetailsSheet(
                    merchant: $merchant,
                    notes: $notes,
                    date: $transactionDate,
                    isRecurring: $isRecurring
                )
            }
            .onAppear {
                setupInitialCategory()
            }
        }
    }
    
    private var canSubmit: Bool {
        guard let val = Double(amountString), val > 0 else { return false }
        return !selectedCategory.isEmpty
    }
    
    private var currentCategories: [StandardCategory] {
        if transactionType == .income {
            return CategoryCatalog.standardIncomeCategories
        }
        
        let standard = CategoryCatalog.standardExpenseCategories
        let custom = customCategories.filter { $0.isExpense }.map {
            StandardCategory(
                name: $0.name,
                icon: $0.icon,
                colorName: $0.colorName,
                subcategories: $0.subcategories
            )
        }
        let all = standard + custom
        return SmartDefaultsService.shared.sortCategories(all)
    }
    
    private var currentSubcategories: [String] {
        var subs: [String] = []
        if let found = currentCategories.first(where: { $0.name.lowercased() == selectedCategory.lowercased() }) {
            subs = found.subcategories
        } else {
            subs = CategoryCatalog.defaultSubcategories(for: selectedCategory)
        }
        return SmartDefaultsService.shared.sortSubcategories(for: selectedCategory, subcategories: subs)
    }
    
    private func setupInitialCategory() {
        if let first = currentCategories.first {
            selectedCategory = first.name
            if let lastSub = SmartDefaultsService.shared.lastUsedSubcategory(for: first.name) {
                selectedSubcategory = lastSub
            } else {
                selectedSubcategory = first.subcategories.first ?? first.name
            }
        }
    }
    
    private func onTypeChanged(_ newType: TransactionType) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        if newType == .income {
            selectedCategory = "Income"
            selectedSubcategory = "Salary"
        } else {
            setupInitialCategory()
        }
    }
    
    private func selectCategory(_ name: String) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        selectedCategory = name
        
        if let lastSub = SmartDefaultsService.shared.lastUsedSubcategory(for: name) {
            selectedSubcategory = lastSub
        } else if let cat = currentCategories.first(where: { $0.name.lowercased() == name.lowercased() }),
                  let firstSub = cat.subcategories.first {
            selectedSubcategory = firstSub
        } else {
            selectedSubcategory = name
        }
    }
    
    private func commitTransaction() {
        guard let amount = Double(amountString), amount > 0 else { return }
        
        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // Create model
        let item = TransactionItem(
            amount: amount,
            transactionType: transactionType,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            date: transactionDate,
            merchant: merchant,
            notes: notes,
            isRecurring: isRecurring
        )
        
        modelContext.insert(item)
        
        // Record frequency for smart sorting
        SmartDefaultsService.shared.recordUsage(category: selectedCategory, subcategory: selectedSubcategory)
        
        // Show brief confirmation
        let formattedAmt = settings.formatCurrency(amount)
        lastAddedDescription = "\(selectedSubcategory) \(formattedAmt) Added ✓"
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showConfirmation = true
        }
        
        // Reset inputs immediately for the next rapid entry
        amountString = "0"
        merchant = ""
        notes = ""
        transactionDate = Date()
        isRecurring = false
        
        // Dismiss confirmation after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showConfirmation = false
            }
        }
    }
}

private struct CategoryPill: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.04), radius: 4, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
