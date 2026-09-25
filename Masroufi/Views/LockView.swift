import SwiftUI

struct LockView: View {
    @EnvironmentObject var store: FinanceStore

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
            Text("مصروفي مقفل")
                .font(.title2.bold())
            Text("استخدم Face ID أو رمز الجهاز للوصول إلى بياناتك")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("فتح التطبيق") {
                Task { await store.requestUnlock() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .task { await store.requestUnlock() }
    }
}
