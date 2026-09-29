import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

public struct BackupDataPayload: Codable {
    public struct ExportedTransaction: Codable {
        public let id: String
        public let amount: Double
        public let type: String
        public let category: String
        public let subcategory: String
        public let date: String
        public let merchant: String
        public let notes: String
        public let isRecurring: Bool
    }
    
    public struct ExportedWealth: Codable {
        public let id: String
        public let name: String
        public let amount: Double
        public let type: String
        public let category: String
        public let notes: String
    }
    
    public struct ExportedBudget: Codable {
        public let categoryName: String
        public let monthlyLimit: Double
    }
    
    public struct ExportedRecurring: Codable {
        public let title: String
        public let amount: Double
        public let category: String
        public let subcategory: String
        public let frequency: String
        public let dueDay: Int
        public let isExpense: Bool
    }
    
    public let appVersion: String
    public let exportedAt: String
    public let transactions: [ExportedTransaction]
    public let wealthItems: [ExportedWealth]
    public let budgets: [ExportedBudget]
    public let recurringItems: [ExportedRecurring]
}

public struct FinancialDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json, .commaSeparatedText, .plainText] }
    
    public var text: String
    public var contentType: UTType
    
    public init(text: String, contentType: UTType = .json) {
        self.text = text
        self.contentType = contentType
    }
    
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            self.text = string
            self.contentType = configuration.contentType
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

public final class ExportImportService {
    public static let shared = ExportImportService()
    
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    public func exportToJSON(
        transactions: [TransactionItem],
        wealth: [WealthItem],
        budgets: [CategoryBudget],
        recurring: [RecurringTransaction]
    ) -> String {
        let exportedTransactions = transactions.map {
            BackupDataPayload.ExportedTransaction(
                id: $0.id.uuidString,
                amount: $0.amount,
                type: $0.typeRaw,
                category: $0.category,
                subcategory: $0.subcategory,
                date: Self.isoFormatter.string(from: $0.date),
                merchant: $0.merchant,
                notes: $0.notes,
                isRecurring: $0.isRecurring
            )
        }
        
        let exportedWealth = wealth.map {
            BackupDataPayload.ExportedWealth(
                id: $0.id.uuidString,
                name: $0.name,
                amount: $0.amount,
                type: $0.typeRaw,
                category: $0.category,
                notes: $0.notes
            )
        }
        
        let exportedBudgets = budgets.map {
            BackupDataPayload.ExportedBudget(
                categoryName: $0.categoryName,
                monthlyLimit: $0.monthlyLimit
            )
        }
        
        let exportedRecurring = recurring.map {
            BackupDataPayload.ExportedRecurring(
                title: $0.title,
                amount: $0.amount,
                category: $0.category,
                subcategory: $0.subcategory,
                frequency: $0.frequencyRaw,
                dueDay: $0.dueDay,
                isExpense: $0.isExpense
            )
        }
        
        let payload = BackupDataPayload(
            appVersion: "1.0.0",
            exportedAt: Self.isoFormatter.string(from: Date()),
            transactions: exportedTransactions,
            wealthItems: exportedWealth,
            budgets: exportedBudgets,
            recurringItems: exportedRecurring
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(payload), let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    public func exportToCSV(transactions: [TransactionItem]) -> String {
        var csv = "Date,Type,Category,Subcategory,Amount,Merchant,Notes,IsRecurring\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for item in transactions.sorted(by: { $0.date > $1.date }) {
            let dateStr = dateFormatter.string(from: item.date)
            let type = item.typeRaw
            let category = escapeCSV(item.category)
            let subcategory = escapeCSV(item.subcategory)
            let amount = String(format: "%.2f", item.amount)
            let merchant = escapeCSV(item.merchant)
            let notes = escapeCSV(item.notes)
            let recurring = item.isRecurring ? "true" : "false"
            
            csv.append("\(dateStr),\(type),\(category),\(subcategory),\(amount),\(merchant),\(notes),\(recurring)\n")
        }
        return csv
    }
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return text
    }
    
    public func importFromJSON(jsonString: String, context: ModelContext) throws -> Int {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "ExportImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"])
        }
        let decoder = JSONDecoder()
        let payload = try decoder.decode(BackupDataPayload.self, from: data)
        
        var count = 0
        for item in payload.transactions {
            let date = Self.isoFormatter.date(from: item.date) ?? Date()
            let tx = TransactionItem(
                id: UUID(uuidString: item.id) ?? UUID(),
                amount: item.amount,
                transactionType: TransactionType(rawValue: item.type) ?? .expense,
                category: item.category,
                subcategory: item.subcategory,
                date: date,
                merchant: item.merchant,
                notes: item.notes,
                isRecurring: item.isRecurring
            )
            context.insert(tx)
            count += 1
        }
        
        for w in payload.wealthItems {
            let item = WealthItem(
                id: UUID(uuidString: w.id) ?? UUID(),
                name: w.name,
                amount: w.amount,
                wealthType: WealthType(rawValue: w.type) ?? .asset,
                category: w.category,
                notes: w.notes
            )
            context.insert(item)
        }
        
        for b in payload.budgets {
            let item = CategoryBudget(categoryName: b.categoryName, monthlyLimit: b.monthlyLimit)
            context.insert(item)
        }
        
        for r in payload.recurringItems {
            let item = RecurringTransaction(
                title: r.title,
                amount: r.amount,
                category: r.category,
                subcategory: r.subcategory,
                frequency: RecurringFrequency(rawValue: r.frequency) ?? .monthly,
                dueDay: r.dueDay,
                isExpense: r.isExpense
            )
            context.insert(item)
        }
        
        try context.save()
        return count
    }
    
    public func importFromCSV(csvString: String, context: ModelContext) throws -> Int {
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return 0 }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var count = 0
        for line in lines.dropFirst() {
            let parts = parseCSVLine(line)
            guard parts.count >= 5 else { continue }
            
            let dateStr = parts[0]
            let typeStr = parts[1]
            let catStr = parts[2]
            let subcatStr = parts[3]
            let amountStr = parts[4]
            let merchantStr = parts.count > 5 ? parts[5] : ""
            let notesStr = parts.count > 6 ? parts[6] : ""
            let recurringStr = parts.count > 7 ? parts[7] : "false"
            
            let date = dateFormatter.date(from: dateStr) ?? Self.isoFormatter.date(from: dateStr) ?? Date()
            let amount = Double(amountStr) ?? 0.0
            let type = TransactionType(rawValue: typeStr) ?? .expense
            let isRecurring = recurringStr.lowercased() == "true"
            
            let tx = TransactionItem(
                amount: amount,
                transactionType: type,
                category: catStr,
                subcategory: subcatStr,
                date: date,
                merchant: merchantStr,
                notes: notesStr,
                isRecurring: isRecurring
            )
            context.insert(tx)
            count += 1
        }
        
        try context.save()
        return count
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var cur = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(cur.trimmingCharacters(in: .whitespaces))
                cur = ""
            } else {
                cur.append(char)
            }
        }
        result.append(cur.trimmingCharacters(in: .whitespaces))
        return result
    }
}
