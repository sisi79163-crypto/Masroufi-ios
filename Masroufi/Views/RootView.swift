import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject var store: FinanceStore
    @State private var showAdd = false

    var body: some View {
        Group {
            if store.isUnlocked || !store.biometricsEnabled {
                TabView {
                    DashboardView(showAdd: $showAdd)
                        .tabItem { Label("الرئيسية", systemImage: "house.fill") }

                    TransactionsView()
                        .tabItem { Label("العمليات", systemImage: "list.bullet.rectangle") }

                    GoalsView()
                        .tabItem { Label("التوفير", systemImage: "target") }

                    SettingsView()
                        .tabItem { Label("الإعدادات", systemImage: "gearshape.fill") }
                }
                .sheet(isPresented: $showAdd) {
                    AddTransactionView()
                }
            } else {
                LockView()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            if store.biometricsEnabled { store.isUnlocked = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.processRecurringItems()
        }
    }
}
