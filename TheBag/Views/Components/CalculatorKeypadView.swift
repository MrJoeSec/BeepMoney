import SwiftUI

public struct CalculatorKeypadView: View {
    @Binding public var amountString: String
    public var onCommit: (() -> Void)? = nil
    
    private let keypadRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    public init(amountString: Binding<String>, onCommit: (() -> Void)? = nil) {
        self._amountString = amountString
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Quick-add pill buttons for fast amounts
            HStack(spacing: 8) {
                QuickAmountButton(label: "+$5") { addQuickAmount(5) }
                QuickAmountButton(label: "+$10") { addQuickAmount(10) }
                QuickAmountButton(label: "+$20") { addQuickAmount(20) }
                QuickAmountButton(label: "+$50") { addQuickAmount(50) }
                QuickAmountButton(label: "C") {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    amountString = "0"
                }
            }
            .padding(.horizontal, 4)
            
            // 4x3 Grid of calculator keys
            ForEach(keypadRows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button(action: {
                            handleKeyPress(key)
                        }) {
                            Text(key)
                                .font(.system(size: key == "⌫" ? 22 : 24, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(key == "⌫" ? Color(.secondarySystemFill) : Color(.systemBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(14)
                                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private func handleKeyPress(_ key: String) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if key == "⌫" {
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
            return
        }
        
        if key == "." {
            if !amountString.contains(".") {
                amountString.append(".")
            }
            return
        }
        
        // Handle numbers
        if amountString == "0" {
            amountString = key
        } else {
            // Prevent more than 2 decimal places
            if let dotIndex = amountString.firstIndex(of: ".") {
                let decimals = amountString.distance(from: dotIndex, to: amountString.endIndex) - 1
                if decimals >= 2 { return }
            }
            // Prevent unrealistically huge numbers
            if amountString.count < 10 {
                amountString.append(key)
            }
        }
    }
    
    private func addQuickAmount(_ val: Double) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        let current = Double(amountString) ?? 0.0
        let newTotal = current + val
        if newTotal.truncatingRemainder(dividingBy: 1) == 0 {
            amountString = String(format: "%.0f", newTotal)
        } else {
            amountString = String(format: "%.2f", newTotal)
        }
    }
}

private struct QuickAmountButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color(.secondarySystemFill))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
