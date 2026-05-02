import SwiftUI
import SwiftData

enum ViewMode { case review, all }

struct TreeItem: Identifiable, Hashable {
    let id: String
    let title: String
    let node: VocabNode?
    let count: Int // 该节点下包含的词汇总数
    var children: [TreeItem]?
    
    static func == (lhs: TreeItem, rhs: TreeItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timeMachine: TimeMachine
    @Query(sort: \VocabNode.dateAdded, order: .reverse) private var allNodes: [VocabNode]
    
    @State private var selectedNode: VocabNode?
    @State private var showingAddSheet = false
    @State private var viewMode: ViewMode = .review
    
    // MARK: - 树状构建逻辑
    
    private func buildReviewTree() -> [TreeItem] {
        let dueNodes = allNodes.filter { $0.isDueForReview(on: timeMachine.targetDate) }
        let nodesByParent = Dictionary(grouping: dueNodes) { $0.parentWord }
        
        func buildChildren(for parentWord: String) -> [TreeItem]? {
            guard let children = nodesByParent[parentWord]?.filter({ $0.word != parentWord }) else { return nil }
            let result = children.map { node in
                TreeItem(id: node.id.uuidString, title: node.word, node: node, count: 1, children: buildChildren(for: node.word))
            }
            return result.isEmpty ? nil : result.sorted { $0.title < $1.title }
        }
        
        let rootNodes = dueNodes.filter { $0.word == $0.parentWord }
        return rootNodes.map { node in
            let children = buildChildren(for: node.word)
            let totalCount = 1 + (children?.count ?? 0)
            return TreeItem(id: node.id.uuidString, title: node.word, node: node, count: totalCount, children: children)
        }.sorted { $0.node!.dateAdded > $1.node!.dateAdded }
    }
    
    private func buildAllDateTree() -> [TreeItem] {
        let calendar = Calendar.current
        let rootNodes = allNodes.filter { $0.word == $0.rootWord }
        
        let byYear = Dictionary(grouping: rootNodes) { calendar.component(.year, from: $0.dateAdded) }
        return byYear.keys.sorted(by: >).map { year in
            let yearNodes = byYear[year]!
            let byMonth = Dictionary(grouping: yearNodes) { calendar.component(.month, from: $0.dateAdded) }
            
            let monthItems = byMonth.keys.sorted(by: >).map { month in
                let monthNodes = byMonth[month]!
                let byDay = Dictionary(grouping: monthNodes) { calendar.component(.day, from: $0.dateAdded) }
                
                let dayItems = byDay.keys.sorted(by: >).map { day in
                    let dayNodes = byDay[day]!.sorted { $0.dateAdded > $1.dateAdded }
                    let vocabItems = dayNodes.map { buildSingleVocabTree(for: $0) }
                    
                    // 计算这一天总共有多少词汇
                    let dayTotal = vocabItems.reduce(0) { $0 + $1.count }
                    return TreeItem(id: "\(year)-\(month)-\(day)", title: "\(day)日", node: nil, count: dayTotal, children: vocabItems)
                }
                
                let monthTotal = dayItems.reduce(0) { $0 + $1.count }
                return TreeItem(id: "\(year)-\(month)", title: "\(month)月", node: nil, count: monthTotal, children: dayItems)
            }
            
            let yearTotal = monthItems.reduce(0) { $0 + $1.count }
            return TreeItem(id: "\(year)", title: "\(year)年", node: nil, count: yearTotal, children: monthItems)
        }
    }
    
    private func buildSingleVocabTree(for rootNode: VocabNode) -> TreeItem {
        let nodesByParent = Dictionary(grouping: allNodes) { $0.parentWord }
        
        func buildChildren(for parentWord: String) -> [TreeItem]? {
            guard let children = nodesByParent[parentWord]?.filter({ $0.word != parentWord }) else { return nil }
            return children.map { node in
                TreeItem(id: node.id.uuidString, title: node.word, node: node, count: 1, children: buildChildren(for: node.word))
            }.sorted { $0.title < $1.title }
        }
        
        let children = buildChildren(for: rootNode.word)
        let totalInFamily = 1 + (allNodes.filter { $0.rootWord == rootNode.word && $0.word != rootNode.word }.count)
        return TreeItem(id: rootNode.id.uuidString, title: rootNode.word, node: rootNode, count: totalInFamily, children: children)
    }
    
    var displayTree: [TreeItem] {
        viewMode == .review ? buildReviewTree() : buildAllDateTree()
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWordView()
        }
    }
    
    @ViewBuilder
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider()
            treeList
        }
        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        .toolbar {
            sidebarToolbar
        }
    }
    
    @ViewBuilder
    private var sidebarHeader: some View {
        VStack(spacing: 12) {
            Picker("模式", selection: $viewMode) {
                Text("今日复习").tag(ViewMode.review)
                Text("全部词库 (\(allNodes.count))").tag(ViewMode.all)
            }
            .pickerStyle(.segmented)
            
            if viewMode == .review {
                DatePicker("复习日期", selection: $timeMachine.targetDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
        .padding(14)
        .background(Color(NSColor.windowBackgroundColor))
        
        if viewMode == .review && timeMachine.isNotToday {
            timeMachineWarning
        }
    }
    
    @ViewBuilder
    private var timeMachineWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                Text("非今日复习日程").font(.headline)
            }
            Button(action: { withAnimation { timeMachine.resetToToday() } }) {
                Text("退出并返回今天").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .padding([.horizontal, .bottom], 14)
    }
    
    @ViewBuilder
    private var treeList: some View {
        List(selection: $selectedNode) {
            if displayTree.isEmpty {
                Text("暂无内容").foregroundColor(.secondary).padding()
            } else {
                OutlineGroup(displayTree, children: \.children) { item in
                    if let node = item.node {
                        // 词汇节点：允许被选中 (添加 tag)
                        HStack {
                            Text(item.title)
                                .font(.system(.body, design: .serif))
                            Spacer()
                        }
                        // 🚨 修复点：maxWidth 必须写在 minHeight 前面
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .tag(node)
                    } else {
                        // 日期文件夹节点：不允许选中 (没有 tag)，但显示数量
                        HStack {
                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(6)
                        }
                        .frame(maxWidth: .infinity,minHeight: 28, alignment: .leading)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .animation(.default, value: displayTree)
        .id(viewMode)
    }
    
    @ToolbarContentBuilder
    private var sidebarToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus.viewfinder")
            }
        }
        ToolbarItem(placement: .automatic) {
            Menu {
                Button("导入 JSON", systemImage: "square.and.arrow.down") {
                    DataTransferManager.importFromFile(modelContext: modelContext)
                }
                Button("导出全部", systemImage: "square.and.arrow.up") {
                    DataTransferManager.exportData(allNodes: allNodes)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if let node = selectedNode {
            DetailView(node: node, viewMode: viewMode)
        } else {
            ContentUnavailableView("请选择词汇", systemImage: "book.pages")
        }
    }
}
