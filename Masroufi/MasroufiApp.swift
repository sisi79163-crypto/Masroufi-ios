import SwiftUI

@main
struct MasroufiApp: App {
    @StateObject private var store = FinanceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(nil)
        }
    }
}
