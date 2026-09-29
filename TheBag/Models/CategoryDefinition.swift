import Foundation
import SwiftUI
import SwiftData

public struct StandardCategory: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let icon: String
    public let colorName: String
    public let subcategories: [String]
    
    public var color: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

public struct CategoryCatalog {
    public static let standardExpenseCategories: [StandardCategory] = [
        StandardCategory(
            name: "Travel",
            icon: "airplane",
            colorName: "blue",
            subcategories: [
                "Uber", "Lyft", "Taxi", "Train", "Subway", "Bus",
                "Airplane", "Rental Car", "Parking", "Gas", "Hotel", "Other Travel"
            ]
        ),
        StandardCategory(
            name: "Groceries",
            icon: "cart.fill",
            colorName: "green",
            subcategories: [
                "Supermarket", "Costco", "Walmart", "Target",
                "Online Grocery", "Household Groceries", "Other"
            ]
        ),
        StandardCategory(
            name: "Eating & Going Out",
            icon: "fork.knife",
            colorName: "orange",
            subcategories: [
                "Restaurant", "Dinner", "Lunch", "Breakfast", "Date", "Coffee",
                "Fast Food", "Activities", "Entertainment", "Movies", "Events", "Other"
            ]
        ),
        StandardCategory(
            name: "Shopping",
            icon: "bag.fill",
            colorName: "pink",
            subcategories: [
                "Clothes", "Shoes", "Electronics", "Accessories",
                "Beauty", "Personal Care", "Gifts", "Other Shopping"
            ]
        ),
        StandardCategory(
            name: "Housing",
            icon: "house.fill",
            colorName: "indigo",
            subcategories: [
                "Rent", "Mortgage", "Furniture", "Kitchenware",
                "Home Improvement", "Decorations", "Other Housing"
            ]
        ),
        StandardCategory(
            name: "Recurring Bills",
            icon: "clock.arrow.circlepath",
            colorName: "red",
            subcategories: [
                "Electricity", "Water", "Internet", "Phone", "Insurance",
                "Subscriptions", "Quran Class", "Gym", "Streaming", "Software", "Other Bills"
            ]
        ),
        StandardCategory(
            name: "Education",
            icon: "book.fill",
            colorName: "teal",
            subcategories: [
                "Tuition", "Books", "Courses", "School Supplies",
                "Certifications", "Tutoring", "Other Education"
            ]
        ),
        StandardCategory(
            name: "Health",
            icon: "cross.fill",
            colorName: "mint",
            subcategories: [
                "Doctor", "Dentist", "Pharmacy", "Medication",
                "Fitness", "Other Health"
            ]
        ),
        StandardCategory(
            name: "Personal",
            icon: "person.fill",
            colorName: "purple",
            subcategories: [
                "Haircut", "Clothing", "Personal Care", "Gifts", "Miscellaneous"
            ]
        ),
        StandardCategory(
            name: "Financial",
            icon: "banknote.fill",
            colorName: "cyan",
            subcategories: [
                "Savings", "Investment", "Debt Payment",
                "Credit Card Payment", "Bank Fees", "Other Financial"
            ]
        ),
        StandardCategory(
            name: "Other",
            icon: "ellipsis.circle.fill",
            colorName: "gray",
            subcategories: [
                "Miscellaneous"
            ]
        )
    ]
    
    public static let standardIncomeCategories: [StandardCategory] = [
        StandardCategory(
            name: "Income",
            icon: "arrow.down.left.circle.fill",
            colorName: "green",
            subcategories: [
                "Salary", "Freelance", "Business", "Side Job",
                "Investment", "Gift", "Refund", "Other Income"
            ]
        )
    ]
    
    public static func defaultSubcategories(for categoryName: String) -> [String] {
        if let found = standardExpenseCategories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) {
            return found.subcategories
        }
        if categoryName.lowercased() == "income" {
            return standardIncomeCategories.first?.subcategories ?? []
        }
        return ["General"]
    }
    
    public static func icon(for categoryName: String) -> String {
        if let found = standardExpenseCategories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) {
            return found.icon
        }
        if categoryName.lowercased() == "income" {
            return "arrow.down.left.circle.fill"
        }
        return "tag.fill"
    }
    
    public static func color(for categoryName: String) -> Color {
        if let found = standardExpenseCategories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) {
            return found.color
        }
        if categoryName.lowercased() == "income" {
            return .green
        }
        return .gray
    }
}

@Model
public final class CustomCategoryItem {
    public var id: UUID = UUID()
    public var name: String = ""
    public var icon: String = "tag.fill"
    public var colorName: String = "blue"
    public var subcategoriesRaw: String = ""
    public var isExpense: Bool = true
    
    public var subcategories: [String] {
        get {
            subcategoriesRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set {
            subcategoriesRaw = newValue.joined(separator: ", ")
        }
    }
    
    public init(name: String, icon: String = "tag.fill", colorName: String = "blue", subcategories: [String] = [], isExpense: Bool = true) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.subcategoriesRaw = subcategories.joined(separator: ", ")
        self.isExpense = isExpense
    }
}
