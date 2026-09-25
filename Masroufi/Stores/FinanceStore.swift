import Foundation
import SwiftUI
import LocalAuthentication

@MainActor
final class FinanceStore: ObservableObject {
    @Published var data = FinanceData() {
        didSet { save() }
    }

    @Published var monthlyBudgetUSD: Double {
        didSet { UserDefaults.standard.set(monthlyBudgetUSD, forKey: "monthlyBudgetUSD") }
    }
    @Published var lbpPerUSD: Double {
        didSet { UserDefaults.standard.set(lbpPerUSD, forKey: "lbpPerUSD") }
    }
    @Published var displayCurrency: MoneyCurrency {
        didSet { UserDefaults.standard.set(displayCurrency.rawValue, forKey: "displayCurrency") }
    }
    @Published var biometricsEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricsEnabled, forKey: "biometricsEnabled") }
    }
    @Published var isUnlocked = true

    init() {
        let defaults = UserDefaults.standard
        let storedBudget = defaults.double(forKey: "monthlyBudgetUSD")
        monthlyBudgetUSD = storedBudget > 0 ? storedBudget : 500

        let storedRate = defaults.double(forKey: "lbpPerUSD")
        lbpPerUSD = storedRate > 0 ? storedRate : 89500

        displayCurrency = MoneyCurrency(rawValue: defaults.string(forKey: "displayCurrency") ?? "USD") ?? .usd
        biometricsEnabled = defaults.bool(forKey: "biometricsEnabled")

        load()
        if data.categories.isEmpty { data.categories = FinanceCategory.defaults }
        processRecurringItems()
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("Masroufi", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("finance-data.json")
    }

    func load() {
        guard let raw = try? Data(contentsOf: fileURL) else { return }
        do {
            data = try JSONDecoder().decode(FinanceData.self, from: raw)
        } catch {
            print("Failed to decode local data: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let raw = try encoder.encode(data)
            try raw.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save local data: \(error)")
        }
    }

    func convert(_ amount: Double, from: MoneyCurrency, to: MoneyCurrency? = nil) -> Double {
        let target = to ?? displayCurrency
        guard from != target else { return amount }
        guard lbpPerUSD > 0 else { return amount }
        if from == .usd && target == .lbp { return amount * lbpPerUSD }
        return amount / lbpPerUSD
    }

    func addTransaction(type: TransactionType, amount: Double, currency: MoneyCurrency, categoryID: UUID, note: String, date: Date, paymentMethod: String) {
        let item = MoneyTransaction(type: type, amount: amount, currency: currency, categoryID: categoryID, note: note, date: date, paymentMethod: paymentMethod)
        data.transactions.insert(item, at: 0)
    }

    func deleteTransaction(_ id: UUID) {
        data.transactions.removeAll { $0.id == id }
    }

    func updateTransaction(_ tx: MoneyTransaction) {
        guard let index = data.transactions.firstIndex(where: { $0.id == tx.id }) else { return }
        data.transactions[index] = tx
    }

    func addCategory(name: String, icon: String, type: TransactionType) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        data.categories.append(.init(name: cleaned, icon: icon, type: type, isCustom: true))
    }

    func deleteCategory(_ id: UUID) {
        guard !data.transactions.contains(where: { $0.categoryID == id }) else { return }
        guard !data.recurring.contains(where: { $0.categoryID == id }) else { return }
        data.categories.removeAll { $0.id == id && $0.isCustom }
    }

    func addGoal(title: String, targetAmount: Double, currency: MoneyCurrency, deadline: Date?) {
        data.goals.append(.init(title: title, targetAmount: targetAmount, savedAmount: 0, currency: currency, deadline: deadline))
    }

    func addToGoal(_ goalID: UUID, amount: Double) {
        guard let i = data.goals.firstIndex(where: { $0.id == goalID }) else { return }
        data.goals[i].savedAmount = min(data.goals[i].targetAmount, data.goals[i].savedAmount + max(0, amount))
    }

    func deleteGoal(_ id: UUID) {
        data.goals.removeAll { $0.id == id }
    }

    func addRecurring(title: String, amount: Double, currency: MoneyCurrency, type: TransactionType, dayOfMonth: Int, categoryID: UUID) {
        let item = RecurringItem(title: title, amount: amount, currency: currency, type: type, dayOfMonth: min(max(dayOfMonth, 1), 28), categoryID: categoryID)
        data.recurring.append(item)
        processRecurringItems()
    }

    func toggleRecurring(_ id: UUID) {
        guard let i = data.recurring.firstIndex(where: { $0.id == id }) else { return }
        data.recurring[i].isEnabled.toggle()
        processRecurringItems()
    }

    func deleteRecurring(_ id: UUID) {
        data.recurring.removeAll { $0.id == id }
    }

    func processRecurringItems(now: Date = Date()) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        guard let year = comps.year, let month = comps.month, let today = comps.day else { return }

        var additions: [MoneyTransaction] = []
        for item in data.recurring where item.isEnabled && today >= item.dayOfMonth {
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = item.dayOfMonth
            guard let occurrence = calendar.date(from: dateComponents) else { continue }

            let alreadyCreated = data.transactions.contains { tx in
                guard tx.recurringSourceID == item.id else { return false }
                let tc = calendar.dateComponents([.year, .month], from: tx.date)
                return tc.year == year && tc.month == month
            }
            if !alreadyCreated {
                additions.append(MoneyTransaction(
                    type: item.type,
                    amount: item.amount,
                    currency: item.currency,
                    categoryID: item.categoryID,
                    note: item.title,
                    date: occurrence,
                    paymentMethod: "متكرر",
                    recurringSourceID: item.id
                ))
            }
        }

        if !additions.isEmpty {
            data.transactions.insert(contentsOf: additions, at: 0)
        }
    }

    func category(for id: UUID) -> FinanceCategory? {
        data.categories.first { $0.id == id }
    }

    func transactions(in month: Date = Date()) -> [MoneyTransaction] {
        let start = month.startOfMonth
        let end = month.endOfMonth
        return data.transactions.filter { $0.date >= start && $0.date <= end }
    }

    func total(type: TransactionType, in month: Date = Date()) -> Double {
        transactions(in: month)
            .filter { $0.type == type }
            .reduce(0) { $0 + convert($1.amount, from: $1.currency) }
    }

    var monthIncome: Double { total(type: .income) }
    var monthExpense: Double { total(type: .expense) }
    var monthBalance: Double { monthIncome - monthExpense }

    var budgetInDisplayCurrency: Double {
        displayCurrency == .usd ? monthlyBudgetUSD : monthlyBudgetUSD * lbpPerUSD
    }

    var budgetProgress: Double {
        guard budgetInDisplayCurrency > 0 else { return 0 }
        return min(monthExpense / budgetInDisplayCurrency, 1)
    }

    func exportJSON() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Masroufi-Backup-\(Date().dayKey).json")
        do {
            let raw = try JSONEncoder().encode(data)
            try raw.write(to: url, options: .atomic)
            return url
        } catch { return nil }
    }

    func requestUnlock() async {
        guard biometricsEnabled else {
            isUnlocked = true
            return
        }

        isUnlocked = false
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "افتح مصروفي للوصول إلى بياناتك المالية")
            isUnlocked = success
        } catch {
            isUnlocked = false
        }
    }
}
