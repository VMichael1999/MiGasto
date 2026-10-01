import SwiftUI

/// Categorías, con el mismo nombre que usa Flutter.
struct CategoryOption: Identifiable, Hashable {
    let id: String
    let label: String

    static let gastos: [CategoryOption] = [
        .init(id: "alimentacion", label: "Alimentación"),
        .init(id: "transporte", label: "Transporte"),
        .init(id: "compras", label: "Compras"),
        .init(id: "servicios", label: "Servicios"),
        .init(id: "entretenimiento", label: "Entretenimiento"),
        .init(id: "otros", label: "Otros"),
    ]
    static let ingresos: [CategoryOption] = [
        .init(id: "sueldo", label: "Sueldo"),
        .init(id: "transferenciaRecibida", label: "Transferencia recibida"),
        .init(id: "venta", label: "Venta"),
        .init(id: "otrosIngresos", label: "Otros"),
    ]
}

/// "Guardar en MiGasto": confirma lo que se leyó de la captura de Yape o Plin.
struct ShareView: View {
    let provider: String
    let rawText: String
    let readOK: Bool
    let onSave: ([String: Any]) -> Void
    let onCancel: () -> Void

    @State private var isIncome: Bool
    @State private var amountText: String
    @State private var peer: String
    @State private var category: String

    private let brand = Color(red: 0.55, green: 0.91, blue: 0.52)
    private let income = Color(red: 0.14, green: 0.35, blue: 0.78)

    init(parsed: ParsedPayment?, rawText: String, categoryFor: (ParsedPayment) -> String,
         onSave: @escaping ([String: Any]) -> Void, onCancel: @escaping () -> Void) {
        self.provider = parsed?.provider ?? "yape"
        self.rawText = rawText
        self.readOK = parsed != nil
        self.onSave = onSave
        self.onCancel = onCancel
        _isIncome = State(initialValue: parsed?.isIncome ?? false)
        _amountText = State(initialValue: parsed.map { String(format: "%.2f", $0.amount) } ?? "")
        _peer = State(initialValue: parsed?.peer ?? "")
        _category = State(initialValue: parsed.map(categoryFor) ?? "otros")
    }

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }
    private var canSave: Bool { (amount ?? 0) > 0 && !peer.trimmingCharacters(in: .whitespaces).isEmpty }
    private var options: [CategoryOption] { isIncome ? CategoryOption.ingresos : CategoryOption.gastos }
    private var providerName: String {
        switch provider { case "plin": return "Plin"; case "googlePay": return "Google Wallet"; default: return "Yape" }
    }
    private var providerColor: Color {
        switch provider {
        case "plin": return Color(red: 0.06, green: 0.75, blue: 0.69)
        case "googlePay": return Color(red: 0.35, green: 0.61, blue: 0.97)
        default: return Color(red: 0.61, green: 0.31, blue: 0.84)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $isIncome) {
                        Text("Gasto").tag(false)
                        Text("Ingreso").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, nowIncome in
                        category = nowIncome ? "transferenciaRecibida" : "otros"
                    }
                }

                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(isIncome ? "+ S/" : "S/").font(.title3.weight(.semibold))
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(isIncome ? income : Color.primary)
                            .accessibilityLabel("Monto en soles")
                    }
                    TextField(isIncome ? "De quién" : "Comercio", text: $peer)
                        .accessibilityLabel(isIncome ? "De quién" : "Comercio")
                }

                Section {
                    HStack {
                        Text("App")
                        Spacer()
                        Circle().fill(providerColor).frame(width: 8, height: 8)
                        Text(providerName).fontWeight(.semibold)
                    }
                    Picker("Categoría", selection: $category) {
                        ForEach(options) { Text($0.label).tag($0.id) }
                    }
                }

                Section {
                    if !readOK {
                        Text("No pudimos leer este pago. Completa el monto y el comercio.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("La captura no se guarda; solo el texto que leímos.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Guardar en MiGasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        var item: [String: Any] = [
            "amount": amount,
            "peer": peer.trimmingCharacters(in: .whitespaces),
            "provider": provider,
            "type": isIncome ? "ingreso" : "gasto",
            "channel": "captura",
            "category": category,
            "rawText": String(rawText.prefix(400)),
            // Un ingreso nunca se guarda solo como confirmado salvo que el usuario lo toque aquí.
            "confirmed": true,
            "at": Int(Date().timeIntervalSince1970 * 1000),
        ]
        if rawText.isEmpty { item["rawText"] = "Captura de \(providerName)" }
        onSave(item)
    }
}
