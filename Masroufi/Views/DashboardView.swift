import SwiftUI
import Charts

private struct CategoryExpense: Identifiable {
    let category: FinanceCategory
    let amount: Double
    var id: UUID { category.id }
}

struct DashboardView: View {
    @EnvironmentObject var store: FinanceStore
    @Binding var showAdd: Bool

    private var recent: [MoneyTransaction] {
        Array(store.data.transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    private var categoryExpenses: [CategoryExpense] {
        let month = store.transactions().filter { $0.type == .expense }
        let grouped = Dictionary(grouping: month, by: \.categoryID)
        return grouped.compactMap { id, txs in
            guard let category = store.category(for: id) else { return nil }
            let sum = txs.reduce(0) { $0 + store.convert($1.amount, from: $1.currency) }
            return CategoryExpense(category: category, amount: sum)
        }.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    balanceCard

                    HStack(spacing: 12) {
                        StatCard(title: "الدخل", value: store.displayCurrency.format(store.monthIncome), icon: "arrow.down.left.circle.fill")
                        StatCard(title: "المصروف", value: store.displayCurrency.format(store.monthExpense), icon: "arrow.up.right.circle.fill")
                    }

                    budgetCard

                    if !categoryExpenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("مصروفك حسب التصنيف").font(.headline)
                            Chart(categoryExpenses.prefix(6)) { item in
                                BarMark(
                                    x: .value("القيمة", item.amount),
                                    y: .value("التصنيف", item.category.name)
                                )
                                .cornerRadius(5)
                            }
                            .frame(height: 190)
                        }
                        .padding(16)
                        .background(.background, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("آخر العمليات").font(.headline)
                            Spacer()
                        }
                        if recent.isEmpty {
                            EmptyStateView(icon: "tray", title: "لا توجد عمليات بعد", subtitle: "أضف أول دخل أو مصروف")
                                .frame(height: 160)
                        } else {
                            ForEach(recent) { tx in
                                TransactionRow(transaction: tx)
                                if tx.id != recent.last?.id { Divider() }
                            }
                        }
                    }
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("مصروفي")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("صافي هذا الشهر")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Text(store.displayCurrency.format(store.monthBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
            HStack {
                Text(Date(), format: .dateTime.month(.wide).year())
                Spacer()
                Image(systemName: "wallet.bifold.fill")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26)
        )
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ميزانية الشهر").font(.headline)
                Spacer()
                Text("\(Int(store.budgetProgress * 100))%")
                    .font(.subheadline.bold())
            }
            ProgressView(value: store.budgetProgress)
                .tint(store.budgetProgress >= 0.9 ? .red : .blue)
            HStack {
                Text("صرفت \(store.displayCurrency.format(store.monthExpense))")
                Spacer()
                Text("من \(store.displayCurrency.format(store.budgetInDisplayCurrency))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary))
    }
}
