import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: FinanceStore
    @State private var showAddGoal = false
    @State private var selectedGoal: SavingsGoal?

    var body: some View {
        NavigationStack {
            Group {
                if store.data.goals.isEmpty {
                    EmptyStateView(icon: "target", title: "لا توجد أهداف توفير", subtitle: "أنشئ هدفاً وابدأ بتتبع تقدمك")
                } else {
                    List {
                        ForEach(store.data.goals) { goal in
                            Button { selectedGoal = goal } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Label(goal.title, systemImage: goal.icon).font(.headline)
                                        Spacer()
                                        Text("\(Int(goal.progress * 100))%")
                                            .font(.subheadline.bold())
                                    }
                                    ProgressView(value: goal.progress)
                                    HStack {
                                        Text(goal.currency.format(goal.savedAmount))
                                        Spacer()
                                        Text("الهدف \(goal.currency.format(goal.targetAmount))")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { store.deleteGoal(goal.id) } label: {
                                    Label("حذف", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("أهداف التوفير")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAddGoal = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddGoal) { AddGoalView() }
            .sheet(item: $selectedGoal) { goal in AddGoalAmountView(goal: goal) }
        }
    }
}

private struct AddGoalView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var target = ""
    @State private var currency: MoneyCurrency = .usd
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("اسم الهدف", text: $title)
                TextField("المبلغ المستهدف", text: $target).keyboardType(.decimalPad)
                Picker("العملة", selection: $currency) {
                    ForEach(MoneyCurrency.allCases) { Text($0.title).tag($0) }
                }
                Toggle("تاريخ مستهدف", isOn: $hasDeadline)
                if hasDeadline { DatePicker("التاريخ", selection: $deadline, displayedComponents: .date) }
            }
            .navigationTitle("هدف جديد")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        guard let amount = Double(target.replacingOccurrences(of: ",", with: ".")), amount > 0, !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        store.addGoal(title: title, targetAmount: amount, currency: currency, deadline: hasDeadline ? deadline : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AddGoalAmountView: View {
    @EnvironmentObject var store: FinanceStore
    @Environment(\.dismiss) var dismiss
    let goal: SavingsGoal
    @State private var amount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("\(goal.title) — \(Int(goal.progress * 100))%") {
                    TextField("المبلغ المضاف", text: $amount).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("إضافة للهدف")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("إضافة") {
                        guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")), value > 0 else { return }
                        store.addToGoal(goal.id, amount: value)
                        dismiss()
                    }
                }
            }
        }
    }
}
