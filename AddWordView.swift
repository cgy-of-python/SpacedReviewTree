import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var jsonText: String = ""
    @State private var dateAdded: Date = Date()
    @State private var errorMsg: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("批量录入词族").font(.headline)
            
            DatePicker("设定加入日期", selection: $dateAdded, displayedComponents: .date)
            
            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
                .frame(width: 500, height: 350)
            
            if let error = errorMsg {
                Text(error).foregroundColor(.red).font(.caption)
            }
            
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("执行添加") {
                    do {
                        // 🚨 修复点：调用已更名为 importJSONText 的方法 🚨
                        try DataTransferManager.importJSONText(modelContext: modelContext, jsonString: jsonText, dateAdded: dateAdded)
                        dismiss()
                    } catch {
                        errorMsg = "解析错误: \(error.localizedDescription)"
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
