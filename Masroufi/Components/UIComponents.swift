import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary))
    }
}

struct TransactionRow: View {
    @EnvironmentObject var store: FinanceStore
    let transaction: MoneyTransaction

    var body: some View {
        HStack(spacing: 12) {
            let category = store.category(for: transaction.categoryID)
            Image(systemName: category?.icon ?? "circle.fill")
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "بدون تصنيف").font(.headline)
                Text(transaction.note.isEmpty ? transaction.paymentMethod : transaction.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text((transaction.type == .expense ? "-" : "+") + transaction.currency.format(transaction.amount))
                    .font(.subheadline.bold())
                Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(subtitle))
    }
}
