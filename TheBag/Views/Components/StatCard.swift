import SwiftUI

public struct StatCard: View {
    public let title: String
    public let value: String
    public let icon: String
    public var iconColor: Color = .blue
    public var subtitle: String? = nil
    public var isPositive: Bool? = nil
    
    public init(
        title: String,
        value: String,
        icon: String,
        iconColor: Color = .blue,
        subtitle: String? = nil,
        isPositive: Bool? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.subtitle = subtitle
        self.isPositive = isPositive
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
                    .padding(6)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(subColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }
    
    private var subColor: Color {
        if let isPos = isPositive {
            return isPos ? .green : .red
        }
        return .secondary
    }
}
