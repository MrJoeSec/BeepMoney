import SwiftUI

public struct BudgetProgressBar: View {
    public let spent: Double
    public let limit: Double
    public let currencySymbol: String
    
    public init(spent: Double, limit: Double, currencySymbol: String = "$") {
        self.spent = spent
        self.limit = limit
        self.currencySymbol = currencySymbol
    }
    
    private var progress: Double {
        guard limit > 0 else { return 0.0 }
        return spent / limit
    }
    
    private var statusColor: Color {
        if progress > 1.0 {
            return .red
        } else if progress >= 0.75 {
            return .yellow
        } else {
            return .green
        }
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(statusColor)
                        .frame(width: min(geo.size.width, max(4, geo.size.width * CGFloat(min(1.0, progress)))), height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(currencySymbol)\(String(format: "%.0f", spent)) spent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if spent > limit {
                    Text("Over by \(currencySymbol)\(String(format: "%.0f", spent - limit))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                } else {
                    Text("\(currencySymbol)\(String(format: "%.0f", limit - spent)) left")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
