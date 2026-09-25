import Foundation

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }

    var endOfMonth: Date {
        let start = startOfMonth
        return Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? self
    }

    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

enum MoneyCurrency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case lbp = "LBP"

    var id: String { rawValue }
    var symbol: String { self == .usd ? "$" : "ل.ل" }
    var title: String { self == .usd ? "دولار" : "ليرة لبنانية" }

    func format(_ value: Double) -> String {
        if self == .usd {
            return String(format: "$%.2f", value)
        }
        return "\(Int(value.rounded()).formatted()) ل.ل"
    }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var title: String { self == .expense ? "مصروف" : "دخل" }
    var icon: String { self == .expense ? "arrow.up.right" : "arrow.down.left" }
}

struct FinanceCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var type: TransactionType
    var isCustom: Bool = false

    static let defaults: [FinanceCategory] = [
        .init(name: "طعام", icon: "fork.knife", type: .expense),
        .init(name: "مواصلات", icon: "car.fill", type: .expense),
        .init(name: "تسوق", icon: "bag.fill", type: .expense),
        .init(name: "فواتير", icon: "doc.text.fill", type: .expense),
        .init(name: "منزل", icon: "house.fill", type: .expense),
        .init(name: "صحة", icon: "cross.case.fill", type: .expense),
        .init(name: "ترفيه", icon: "gamecontroller.fill", type: .expense),
        .init(name: "أخرى", icon: "ellipsis.circle.fill", type: .expense),
        .init(name: "راتب", icon: "banknote.fill", type: .income),
        .init(name: "عمل إضافي", icon: "briefcase.fill", type: .income),
        .init(name: "هدية", icon: "gift.fill", type: .income),
        .init(name: "دخل آخر", icon: "plus.circle.fill", type: .income)
    ]
}

struct MoneyTransaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: TransactionType
    var amount: Double
    var currency: MoneyCurrency
    var categoryID: UUID
    var note: String
    var date: Date
    var paymentMethod: String
    var createdAt: Date = Date()
    var recurringSourceID: UUID? = nil
}

struct SavingsGoal: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var targetAmount: Double
    var savedAmount: Double
    var currency: MoneyCurrency
    var deadline: Date?
    var icon: String = "target"

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(savedAmount / targetAmount, 1)
    }
}

struct RecurringItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var currency: MoneyCurrency
    var type: TransactionType
    var dayOfMonth: Int
    var categoryID: UUID
    var isEnabled: Bool = true
}

struct FinanceData: Codable {
    var transactions: [MoneyTransaction] = []
    var categories: [FinanceCategory] = FinanceCategory.defaults
    var goals: [SavingsGoal] = []
    var recurring: [RecurringItem] = []
}
