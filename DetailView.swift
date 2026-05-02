import SwiftUI
import SwiftData
import AVFoundation // 引入苹果原生的音视频与语音框架

struct DetailView: View {
    @Bindable var node: VocabNode
    var viewMode: ViewMode
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var allNodes: [VocabNode]
    
    // 使用 AppStorage 自动保存用户定义的字号偏好
    @AppStorage("reviewFontSize") private var reviewFontSize: Double = 18.0
    
    // 语音合成器实例，用于发音功能
    @State private var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                
                // MARK: - 标题栏与单词发音
                HStack(alignment: .bottom) {
                    if viewMode == .all {
                        TextField("词汇", text: $node.word)
                            .font(.system(size: reviewFontSize * 2.2, weight: .bold, design: .serif))
                            .textFieldStyle(.plain)
                    } else {
                        Text(node.word)
                            .font(.system(size: reviewFontSize * 2.2, weight: .bold, design: .serif))
                            .textSelection(.enabled)
                    }
                    
                    // 单词朗读按钮
                    Button(action: { speak(text: node.word) }) {
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .font(.system(size: reviewFontSize * 1.5))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    // 使用 padding 将喇叭和基线对齐
                    .padding(.bottom, 6)
                    .padding(.leading, 4)
                    
                    Spacer()
                    
                    Button(action: openDictionary) {
                        Label("剑桥词典", systemImage: "character.book.closed.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // MARK: - 内容显示区
                VStack(alignment: .leading, spacing: 20) {
                    // 释义部分
                    VStack(alignment: .leading, spacing: 8) {
                        Text("释义").font(.headline).foregroundColor(.secondary)
                        if viewMode == .all {
                            TextField("输入释义...", text: $node.meaning, axis: .vertical)
                                .font(.system(size: reviewFontSize, design: .serif))
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                        } else {
                            Text(node.meaning)
                                .font(.system(size: reviewFontSize, design: .serif))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Divider()
                    
                    // 例句部分与例句发音
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Text("例句").font(.headline).foregroundColor(.secondary)
                            
                            // 例句朗读按钮
                            Button(action: { speak(text: node.example) }) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("朗读例句")
                        }
                        
                        if viewMode == .all {
                            TextField("输入例句...", text: $node.example, axis: .vertical)
                                .font(.system(size: reviewFontSize - 2, design: .serif))
                                .italic()
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(8)
                        } else {
                            Text(node.example)
                                .font(.system(size: reviewFontSize - 2, design: .serif))
                                .italic()
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // MARK: - 字号调节器与管理面板
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "textformat.size")
                        Text("阅读字号调节: \(Int(reviewFontSize))pt")
                        Slider(value: $reviewFontSize, in: 14...48, step: 1)
                            .frame(width: 250)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    if viewMode == .all {
                        Divider()
                        HStack(spacing: 20) {
                            DatePicker("加入时间", selection: $node.dateAdded, displayedComponents: .date)
                                .onChange(of: node.dateAdded) { _, newValue in cascadeDateUpdate(newDate: newValue) }
                            
                            TextField("父节点", text: $node.parentWord).textFieldStyle(.roundedBorder).frame(width: 120)
                            
                            Spacer()
                            
                            Button(role: .destructive, action: cascadeDelete) {
                                Image(systemName: "trash")
                            }.buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
            }
            .padding(40)
        }
        // 当切换词汇时，自动停止上一个词的朗读
        .onChange(of: node) { _, _ in
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - 语音发音逻辑
    private func speak(text: String) {
        // 如果正在播放，先打断（防止狂点按钮导致排队播放）
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        // 指定发音语言为美式英语（可改为 "en-GB" 为英式英语）
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // 调节语速，0.5是正常默认速度，0.4左右适合清晰地听例句
        utterance.rate = 0.45
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - 数据管理逻辑
    private func cascadeDateUpdate(newDate: Date) {
        if node.word == node.rootWord {
            allNodes.filter { $0.rootWord == node.rootWord }.forEach { $0.dateAdded = newDate }
        }
    }
    
    private func cascadeDelete() {
        if node.word == node.rootWord {
            allNodes.filter { $0.rootWord == node.rootWord }.forEach { modelContext.delete($0) }
        } else {
            modelContext.delete(node)
        }
    }
    
    private func openDictionary() {
        guard let encoded = node.word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://dictionary.cambridge.org/dictionary/english/\(encoded)") else { return }
        openURL(url)
    }
}
