import Foundation
import SwiftUI

public final class SmartDefaultsService {
    public static let shared = SmartDefaultsService()
    
    private let categoryFreqKey = "thebag_category_frequencies"
    private let subcategoryFreqKey = "thebag_subcategory_frequencies"
    private let lastSubcategoryKey = "thebag_last_subcategories"
    
    // Increment frequency for category & subcategory
    public func recordUsage(category: String, subcategory: String) {
        var catMap = UserDefaults.standard.dictionary(forKey: categoryFreqKey) as? [String: Int] ?? [:]
        catMap[category] = (catMap[category] ?? 0) + 1
        UserDefaults.standard.set(catMap, forKey: categoryFreqKey)
        
        let subKey = "\(category):\(subcategory)"
        var subMap = UserDefaults.standard.dictionary(forKey: subcategoryFreqKey) as? [String: Int] ?? [:]
        subMap[subKey] = (subMap[subKey] ?? 0) + 1
        UserDefaults.standard.set(subMap, forKey: subcategoryFreqKey)
        
        // Remember last subcategory for this category
        var lastMap = UserDefaults.standard.dictionary(forKey: lastSubcategoryKey) as? [String: String] ?? [:]
        lastMap[category] = subcategory
        UserDefaults.standard.set(lastMap, forKey: lastSubcategoryKey)
    }
    
    // Sort categories placing most frequently used first
    public func sortCategories(_ categories: [StandardCategory]) -> [StandardCategory] {
        let catMap = UserDefaults.standard.dictionary(forKey: categoryFreqKey) as? [String: Int] ?? [:]
        guard !catMap.isEmpty else { return categories }
        
        return categories.sorted { a, b in
            let freqA = catMap[a.name] ?? 0
            let freqB = catMap[b.name] ?? 0
            if freqA != freqB {
                return freqA > freqB
            }
            return false
        }
    }
    
    // Sort subcategories placing most frequently used first
    public func sortSubcategories(for category: String, subcategories: [String]) -> [String] {
        let subMap = UserDefaults.standard.dictionary(forKey: subcategoryFreqKey) as? [String: Int] ?? [:]
        guard !subMap.isEmpty else { return subcategories }
        
        return subcategories.sorted { a, b in
            let keyA = "\(category):\(a)"
            let keyB = "\(category):\(b)"
            let freqA = subMap[keyA] ?? 0
            let freqB = subMap[keyB] ?? 0
            if freqA != freqB {
                return freqA > freqB
            }
            return false
        }
    }
    
    public func lastUsedSubcategory(for category: String) -> String? {
        let lastMap = UserDefaults.standard.dictionary(forKey: lastSubcategoryKey) as? [String: String] ?? [:]
        return lastMap[category]
    }
}
