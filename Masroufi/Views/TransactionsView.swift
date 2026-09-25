import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var store: FinanceStore
    @State private var search = ""
    @State private var filter: TransactionType?

    private var filtered: [MoneyTransaction] {
        store.data.transactions
            .filter { tx in
                let category = store.category(for: tx.categoryID)?.name ?? ""
                let matchesSearch = search.isEmpty || tx.note.localizedCaseInsensitiveContains(search) || category.localizedCaseInsensitiveContains(search)
                let matchesType = filter == nil || tx.type == filter
                return matchesSearch && matchesType
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("النوع", selection: $filter) {
                        Text("الكل").tag(TransactionType?.none)
                        Text("المصروف").tag(TransactionType?.some(.expense))
                        Text("الدخل").tag(TransactionType?.some(.income))
                    }
                    .pickerStyle(.segmented)
                }

                if filtered.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle", title: "لا توجد نتائج", subtitle: "غيّر البحث أو أضف عملية جديدة")
                        .listRowBackground(Color.clear)
                } else {
                    Section("العمليات") {
                        ForEach(filtered) { tx in
                            TransactionRow(transaction: tx)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { store.deleteTransaction(tx.id) } label: {
                                        Label("حذف", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "ابحث عن عملية أو تصنيف")
            .navigationTitle("العمليات")
        }
    }
}
