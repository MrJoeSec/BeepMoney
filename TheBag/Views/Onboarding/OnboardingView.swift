import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var settings = UserSettings.shared
    public var onComplete: () -> Void
    
    @State private var incomeInput: String = "5000"
    @State private var selectedFrequency: IncomeFrequency = .monthly
    @State private var selectedCurrencyCode: String = "USD"
    @State private var startingBalanceInput: String = ""
    @State private var savingsGoalInput: String = "1000"
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.top, 16)
                        
                        Text("Welcome to TheBag")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("100% private, local wealth and spending tracking. Let's get set up in under 60 seconds.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Question 1: Monthly Income
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What's your income?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text(currentSymbol)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            TextField("5,000", text: $incomeInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        
                        // Frequency Picker
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(IncomeFrequency.allCases) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    // Question 2: Currency Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Currency")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Menu {
                            ForEach(CurrencyOption.popular) { curr in
                                Button(action: {
                                    selectedCurrencyCode = curr.code
                                }) {
                                    HStack {
                                        Text("\(curr.code) (\(curr.symbol)) - \(curr.name)")
                                        if selectedCurrencyCode == curr.code {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("\(selectedCurrencyCode) (\(currentSymbol))")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Question 3: Optional Starting Balance & Savings Goal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Optional Preferences")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Starting Cash / Bank Balance (Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(currentSymbol)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                TextField("e.g. 2500", text: $startingBalanceInput)
                                    .keyboardType(.decimalPad)
                                    .font(.body)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Savings Target (Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(currentSymbol)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                TextField("e.g. 1000", text: $savingsGoalInput)
                                    .keyboardType(.decimalPad)
                                    .font(.body)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Privacy Note
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("All data remains on your iPhone. No cloud accounts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    
                    // Get Started Button
                    Button(action: completeOnboarding) {
                        Text("Start Tracking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.green)
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private var currentSymbol: String {
        CurrencyOption.popular.first(where: { $0.code == selectedCurrencyCode })?.symbol ?? "$"
    }
    
    private func completeOnboarding() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        settings.currencyCode = selectedCurrencyCode
        settings.incomeFrequency = selectedFrequency
        if let inc = Double(incomeInput), inc > 0 {
            settings.monthlyIncome = inc
        }
        if let bal = Double(startingBalanceInput) {
            settings.startingBalance = bal
        }
        if let goal = Double(savingsGoalInput) {
            settings.savingsGoal = goal
        }
        settings.hasCompletedOnboarding = true
        onComplete()
    }
}
