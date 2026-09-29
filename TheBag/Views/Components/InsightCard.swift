import SwiftUI

public struct InsightCard: View {
    public let insight: DynamicInsight
    
    public init(insight: DynamicInsight) {
        self.insight = insight
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(insight.color)
                .frame(width: 34, height: 34)
                .background(insight.color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
