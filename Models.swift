import Foundation
import SwiftData

struct VocabJSONNode: Codable {
    var root: String
    var meaning: String
    var sentence: String
    var sons: [VocabJSONNode]?
}
@Model
final class VocabNode {
    var id: UUID = UUID()
    var word: String = ""         // 加上默认值
    var meaning: String = ""      // 加上默认值
    var example: String = ""      // 加上默认值
    var dateAdded: Date = Date()
    var parentWord: String = ""   // 加上默认值
    var rootWord: String = ""     // 加上默认值
    
    
    init(word: String, meaning: String, example: String, dateAdded: Date = Date(), parentWord: String, rootWord: String) {
        self.word = word
        self.meaning = meaning
        self.example = example
        self.dateAdded = dateAdded
        self.parentWord = parentWord
        self.rootWord = rootWord
    }
    
    func isDueForReview(on targetDate: Date) -> Bool {
        let calendar = Calendar.current
        let startOfAdded = calendar.startOfDay(for: dateAdded)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        
        let components = calendar.dateComponents([.day], from: startOfAdded, to: startOfTarget)
        guard let dayDiff = components.day, dayDiff > 0 else { return false }
        
        let reviewIntervals = [1, 3, 7, 15, 30]
        return reviewIntervals.contains(dayDiff)
    }
}

class TimeMachine: ObservableObject {
    @Published var targetDate: Date = Date()
    var isNotToday: Bool { !Calendar.current.isDate(targetDate, inSameDayAs: Date()) }
    func resetToToday() { targetDate = Date() }
}

// 专门用于 UI 递归渲染的树状包装类
struct TreeNode: Identifiable, Hashable {
    var id: UUID { node.id }
    var node: VocabNode
    var children: [TreeNode]? // 如果为空必须是 nil，OutlineGroup 才能不显示展开箭头
}
