import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss

    @State private var type: TransactionType = .expense
    @State private var amount = ""
    @State private var currency: MoneyCurrency = .usd
    @State private var categoryID: UUID?
    @State private var note = ""
    @State private var date = Date()
    @State private var paymentMethod = "نقدي"

    private var availableCategories: [FinanceCategory] {
        store.data.categories.filter { $0.type == type }
    }

    private var validAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("نوع العملية", selection: $type) {
                        ForEach(TransactionType.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("المبلغ") {
                    HStack {
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                        Picker("العملة", selection: $currency) {
                            ForEach(MoneyCurrency.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Section("التفاصيل") {
                    Picker("التصنيف", selection: $categoryID) {
                        Text("اختر").tag(UUID?.none)
                        ForEach(availableCategories) { category in
                            Label(category.name, systemImage: category.icon).tag(UUID?.some(category.id))
                        }
                    }
                    DatePicker("التاريخ", selection: $date, displayedComponents: .date)
                    Picker("طريقة الدفع", selection: $paymentMethod) {
                        ForEach(["نقدي", "بطاقة", "تحويل", "أخرى"], id: \.self) { Text($0) }
                    }
                    TextField("ملاحظة اختيارية", text: $note)
                }
            }
            .navigationTitle(type == .expense ? "إضافة مصروف" : "إضافة دخل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        guard let value = validAmount, value > 0, let categoryID else { return }
                        store.addTransaction(type: type, amount: value, currency: currency, categoryID: categoryID, note: note, date: date, paymentMethod: paymentMethod)
                        dismiss()
                    }
                    .disabled(validAmount == nil || validAmount! <= 0 || categoryID == nil)
                }
            }
            .onChange(of: type) { _, _ in categoryID = nil }
        }
        .presentationDetents([.large])
    }
}
