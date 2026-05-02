import SwiftUI
import SwiftData

@main
struct SpacedReviewTreeApp: App {
    @StateObject private var timeMachine = TimeMachine()
    
    // 显式创建 Container，用于捕获底层的 Schema 不匹配错误
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([VocabNode.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果由于旧版缓存未清理干净导致加载失败，这里会直接拦截并报错！
            fatalError("数据库加载失败，请确保旧版沙盒缓存已清理干净: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timeMachine)
        }
        .modelContainer(sharedModelContainer)
    }
}
