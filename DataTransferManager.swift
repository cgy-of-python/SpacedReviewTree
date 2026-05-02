import SwiftUI
import SwiftData
import AppKit

class DataTransferManager {
    
    // 文本粘贴导入
    static func importJSONText(modelContext: ModelContext, jsonString: String, dateAdded: Date) throws {
        guard let data = jsonString.data(using: .utf8) else { return }
        try decodeAndInsert(data: data, modelContext: modelContext, dateAdded: dateAdded)
    }
    
    // 备份文件导入
    static func importFromFile(modelContext: ModelContext) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                // 默认使用今天作为导入时间，也可以根据需求改成读取文件内的原时间
                try decodeAndInsert(data: data, modelContext: modelContext, dateAdded: Date())
            } catch {
                print("导入失败: \(error)")
            }
        }
    }
    
    private static func decodeAndInsert(data: Data, modelContext: ModelContext, dateAdded: Date) throws {
        let decoder = JSONDecoder()
        let jsonNodes = try decoder.decode([VocabJSONNode].self, from: data)
        for jsonNode in jsonNodes {
            // 顶层节点的 rootWord 和 parentWord 都是它自己
            flattenAndInsert(jsonNode: jsonNode, parentWord: jsonNode.root, rootWord: jsonNode.root, context: modelContext, dateAdded: dateAdded)
        }
        try modelContext.save()
    }
    
    private static func flattenAndInsert(jsonNode: VocabJSONNode, parentWord: String, rootWord: String, context: ModelContext, dateAdded: Date) {
        let newNode = VocabNode(word: jsonNode.root, meaning: jsonNode.meaning, example: jsonNode.sentence, dateAdded: dateAdded, parentWord: parentWord, rootWord: rootWord)
        context.insert(newNode)
        
        if let children = jsonNode.sons {
            for child in children {
                // 子节点的直系父节点是当前的 jsonNode.root，但绝对 root 保持不变
                flattenAndInsert(jsonNode: child, parentWord: jsonNode.root, rootWord: rootWord, context: context, dateAdded: dateAdded)
            }
        }
    }

    // 导出功能
    static func exportData(allNodes: [VocabNode]) {
        // 重建多级树（这里为了简便，依然采用你的格式结构，但深度保留）
        func buildNode(for word: String) -> VocabJSONNode? {
            guard let node = allNodes.first(where: { $0.word == word }) else { return nil }
            let directSons = allNodes.filter { $0.parentWord == word && $0.word != word }
            let sonsJSON = directSons.compactMap { buildNode(for: $0.word) }
            return VocabJSONNode(root: node.word, meaning: node.meaning, sentence: node.example, sons: sonsJSON.isEmpty ? nil : sonsJSON)
        }
        
        let rootWords = Array(Set(allNodes.filter { $0.word == $0.rootWord }.map { $0.word }))
        let exportData: [VocabJSONNode] = rootWords.compactMap { buildNode(for: $0) }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(exportData)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "SpacedReview_Backup.json"
            if panel.runModal() == .OK, let url = panel.url { try data.write(to: url) }
        } catch {
            print("导出失败: \(error)")
        }
    }
}
