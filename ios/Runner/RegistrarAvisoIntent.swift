import AppIntents
import Foundation
import UserNotifications

/// Acción de Atajos «Registrar aviso de pago».
///
/// iPhone no deja leer las notificaciones de otras apps, así que el texto del pago llega por
/// Atajos desde tres lugares:
/// - la automatización «Correo» (por ejemplo, los avisos del BCP o la constancia de un servicio
///   pagado con Yape),
/// - la automatización «Mensaje» (los SMS del banco),
/// - un atajo con «Tomar captura de pantalla» y «Extraer texto de la imagen», asignado a tocar
///   dos veces la parte de atrás del iPhone sobre la constancia de Yape, Plin o el banco.
///
/// El texto se lee con las mismas reglas que Android (`reader_rules.json`). Como en Android, el
/// pago queda «Por confirmar» en la app, salvo que el usuario active «Guardar gastos solos» o
/// «Guardar ingresos solos» en Ajustes. Un cargo en dólares espera siempre.
@available(iOS 16.0, *)
struct RegistrarAvisoIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar aviso de pago"
    static var description = IntentDescription(
        "Lee el texto de un correo, un SMS o una captura de tu banco o billetera y guarda el pago.",
        categoryName: "Movimientos"
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Texto", description: "El correo, el SMS o el texto extraído de la captura")
    var texto: String

    @Parameter(
        title: "Avisar si no es un pago",
        description: "Útil al leer la pantalla: te avisa si no encontró un monto que entra o sale",
        default: false
    )
    var avisarSiNoEsPago: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar aviso de pago \(\.$texto)") {
            \.$avisarSiNoEsPago
        }
    }

    func perform() async throws -> some IntentResult {
        guard let reader = AvisoReader.shared,
              let item = AvisoReader.item(from: texto, reader: reader, now: Date()) else {
            if avisarSiNoEsPago {
                await AvisoReader.notify(title: "No encontré un pago",
                                         body: "Ábrelo en la constancia, donde se vean el monto y a quién.")
            }
            return .result()
        }
        SharedQueue.enqueue(item)
        await AvisoReader.notify(title: AvisoReader.title(for: item), body: AvisoReader.body(for: item))
        return .result()
    }
}

/// Convierte el texto de un aviso en un pago para la cola que vacía Flutter.
enum AvisoReader {
    static let shared: PaymentReader? = {
        guard let url = Bundle.main.url(forResource: "reader_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return PaymentReader(rulesJSON: data)
    }()

    /// Interruptores de Ajustes «Guardar gastos solos» y «Guardar ingresos solos». Flutter los
    /// guarda en `UserDefaults.standard` con el prefijo `flutter.`; la acción corre en la app.
    static func autoSaveSettings(_ defaults: UserDefaults = .standard) -> (expense: Bool, income: Bool) {
        (defaults.bool(forKey: "flutter.migasto_auto_save_expense"),
         defaults.bool(forKey: "flutter.migasto_auto_save_income"))
    }

    /// `nil` si el texto no es un pago reconocible (no se inventa un gasto).
    static func item(
        from text: String,
        reader: PaymentReader,
        now: Date,
        autoSave: (expense: Bool, income: Bool) = autoSaveSettings()
    ) -> [String: Any]? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let payment = reader.parse(lines: lines) else { return nil }
        let usd = payment.currency == "USD"
        var item: [String: Any] = [
            "amount": payment.amount,
            "peer": payment.peer,
            "provider": payment.provider,
            "type": payment.isIncome ? "ingreso" : "gasto",
            "channel": "aviso",
            "rawText": String(lines.joined(separator: " ").prefix(500)),
            // Queda por confirmar salvo que el usuario pidiera guardarlos solos. En dólares
            // espera siempre: MiGasto lo pasa a soles con el tipo de cambio del día.
            "confirmed": !usd && (payment.isIncome ? autoSave.income : autoSave.expense),
            "at": Int(now.timeIntervalSince1970 * 1000),
        ]
        if usd { item["currency"] = "USD" }
        return item
    }

    static func title(for item: [String: Any]) -> String {
        let income = item["type"] as? String == "ingreso"
        if item["currency"] as? String == "USD" {
            return income ? "Ingreso en dólares por confirmar" : "Gasto en dólares por confirmar"
        }
        let saved = item["confirmed"] as? Bool == true
        switch (income, saved) {
        case (true, true): return "Ingreso guardado"
        case (true, false): return "Ingreso por confirmar"
        case (false, true): return "Gasto guardado"
        case (false, false): return "Gasto por confirmar"
        }
    }

    /// «S/ 25.50 · Tambo · Yape».
    static func body(for item: [String: Any]) -> String {
        let symbol = item["currency"] as? String == "USD" ? "US$" : "S/"
        let amount = String(format: "\(symbol) %.2f", item["amount"] as? Double ?? 0)
        let source: String
        switch item["provider"] as? String {
        case "yape": source = "Yape"
        case "plin": source = "Plin"
        case "googlePay": source = "Google Wallet"
        default: source = "Tarjeta"
        }
        return [amount, item["peer"] as? String ?? "", source].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Solo si el usuario permitió avisos.
    static func notify(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
