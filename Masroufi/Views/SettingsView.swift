import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var store: FinanceStore
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var showCategory = false
    @State private var showRecurring = false

    var body: some View {
        NavigationStack {
            Form {
                Section("العملة") {
                    Picker("عملة العرض", selection: $store.displayCurrency) {
                        ForEach(MoneyCurrency.allCases) { c in
                            Text(c.title).tag(c)
                        }
                    }

                    HStack {
                        Text("سعر الدولار")
                        Spacer()
                        TextField("89500", value: $store.lbpPerUSD, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        Text("ل.ل")
                    }
                }

                Section("الميزانية") {
                    HStack {
                        Text("ميزانية الشهر")
                        Spacer()
                        TextField("500", value: $store.monthlyBudgetUSD, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        Text("USD")
                    }
                }

                Section("الإدارة") {
                    Button { showRecurring = true } label: {
                        Label("العمليات الشهرية المتكررة", systemImage: "repeat")
                    }
                    Button { showCategory = true } label: {
                        Label("التصنيفات المخصصة", systemImage: "square.grid.2x2")
                    }
                }

                Section("الأمان") {
                    Toggle("حماية Face ID / رمز الجهاز", isOn: $store.biometricsEnabled)
                }

                Section("البيانات") {
                    Button {
                        exportURL = store.exportJSON()
                        showShare = exportURL != nil
                    } label: {
                        Label("تصدير نسخة احتياطية", systemImage: "square.and.arrow.up")
                    }
                }

                Section("حول التطبيق") {
                    LabeledContent("التطبيق", value: "مصروفي")
                    LabeledContent("الإصدار", value: "1.0.0")
                    Text("بياناتك محفوظة محلياً على جهازك ولا تحتاج إلى حساب أو اتصال بالإنترنت.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("الإعدادات")
            .sheet(isPresented: $showShare) {
                if let exportURL { ShareSheet(items: [exportURL]) }
            }
            .sheet(isPresented: $showCategory) { CategoryManagerView() }
            .sheet(isPresented: $showRecurring) { RecurringManagerView() }
        }
    }
}

private struct CategoryManagerView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var type: TransactionType = .expense
    @State private var icon = "tag.fill"

    private let icons = ["tag.fill", "cart.fill", "cup.and.saucer.fill", "fuelpump.fill", "heart.fill", "graduationcap.fill", "airplane", "building.2.fill"]

    var body: some View {
        NavigationStack {
            List {
                Section("إضافة تصنيف") {
                    TextField("اسم التصنيف", text: $name)
                    Picker("النوع", selection: $type) {
                        ForEach(TransactionType.allCases) { Text($0.title).tag($0) }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { item in
                                Button { icon = item } label: {
                                    Image(systemName: item)
                                        .frame(width: 40, height: 40)
                                        .background(icon == item ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    Button("إضافة") {
                        store.addCategory(name: name, icon: icon, type: type)
                        name = ""
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("التصنيفات") {
                    ForEach(store.data.categories) { category in
                        HStack {
                            Label(category.name, systemImage: category.icon)
                            Spacer()
                            Text(category.type.title).font(.caption).foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            if category.isCustom {
                                Button(role: .destructive) { store.deleteCategory(category.id) } label: {
                                    Label("حذف", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("التصنيفات")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("تم") { dismiss() } } }
        }
    }
}

private struct RecurringManagerView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                if store.data.recurring.isEmpty {
                    EmptyStateView(icon: "repeat", title: "لا توجد عمليات متكررة", subtitle: "أضف راتباً أو إيجاراً أو اشتراكاً شهرياً")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.data.recurring) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.headline)
                                Text("يوم \(item.dayOfMonth) من كل شهر · \(item.currency.format(item.amount))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { item.isEnabled },
                                set: { _ in store.toggleRecurring(item.id) }
                            ))
                            .labelsHidden()
                        }
                        .swipeActions {
                            Button(role: .destructive) { store.deleteRecurring(item.id) } label: {
                                Label("حذف", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("العمليات المتكررة")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("تم") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button { showAdd = true } label: { Image(systemName: "plus") } }
            }
            .sheet(isPresented: $showAdd) { AddRecurringView() }
        }
    }
}

private struct AddRecurringView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var currency: MoneyCurrency = .usd
    @State private var type: TransactionType = .expense
    @State private var day = 1
    @State private var categoryID: UUID?

    private var categories: [FinanceCategory] { store.data.categories.filter { $0.type == type } }

    var body: some View {
        NavigationStack {
            Form {
                TextField("الاسم، مثل إيجار أو راتب", text: $title)
                TextField("المبلغ", text: $amount).keyboardType(.decimalPad)
                Picker("العملة", selection: $currency) { ForEach(MoneyCurrency.allCases) { Text($0.rawValue).tag($0) } }
                Picker("النوع", selection: $type) { ForEach(TransactionType.allCases) { Text($0.title).tag($0) } }
                Picker("التصنيف", selection: $categoryID) {
                    Text("اختر").tag(UUID?.none)
                    ForEach(categories) { Label($0.name, systemImage: $0.icon).tag(UUID?.some($0.id)) }
                }
                Stepper("يوم الشهر: \(day)", value: $day, in: 1...28)
            }
            .navigationTitle("عملية متكررة")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")), value > 0, let categoryID, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        store.addRecurring(title: title, amount: value, currency: currency, type: type, dayOfMonth: day, categoryID: categoryID)
                        dismiss()
                    }
                }
            }
            .onChange(of: type) { _, _ in categoryID = nil }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
