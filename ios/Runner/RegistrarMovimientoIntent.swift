import AppIntents
import Foundation
import UserNotifications

/// Acción de Atajos "Registrar movimiento".
///
/// Se usa desde la automatización "Transacción" de Wallet: cada vez que pagas con
/// Apple Pay en un POS, Atajos pasa el monto, el comercio y la tarjeta, y esta
/// acción los deja en la cola para que Flutter los guarde.
@available(iOS 16.0, *)
struct RegistrarMovimientoIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar movimiento"
    static var description = IntentDescription(
        "Guarda un gasto en MiGasto con el monto, el comercio y la tarjeta que le pases.",
        categoryName: "Movimientos"
    )

    /// Se registra aunque la app esté cerrada: no abre MiGasto.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Monto", description: "Por ejemplo 25.50 o S/ 25.50")
    var monto: String

    @Parameter(title: "Comercio")
    var comercio: String

    @Parameter(title: "Tarjeta", description: "Nombre de la tarjeta de Wallet")
    var tarjeta: String?

    @Parameter(title: "Latitud", description: "Opcional, de la acción Obtener ubicación actual")
    var latitud: Double?

    @Parameter(title: "Longitud", description: "Opcional, de la acción Obtener ubicación actual")
    var longitud: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar \(\.$monto) en \(\.$comercio) con \(\.$tarjeta)") {
            \.$latitud
            \.$longitud
        }
    }

    func perform() async throws -> some IntentResult {
        guard let amount = AmountParser.parse(monto), amount > 0 else {
            throw RegistroError.montoInvalido
        }
        let place = comercio.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = place.isEmpty ? "Desconocido" : place
        let card = tarjeta?.trimmingCharacters(in: .whitespacesAndNewlines)

        var item: [String: Any] = [
            "amount": amount,
            "peer": name,
            "provider": "tarjeta",
            "type": "gasto",
            "channel": "wallet",
            "rawText": "Apple Pay: S/ \(String(format: "%.2f", amount)) en \(name)",
            // El gasto se guarda solo; se puede quitar o editar desde la app.
            "confirmed": true,
            "at": Int(Date().timeIntervalSince1970 * 1000),
        ]
        if let card = card, !card.isEmpty { item["card"] = card }
        if let lat = latitud, let lng = longitud {
            item["latitude"] = lat
            item["longitude"] = lng
        }
        SharedQueue.enqueue(item)

        await notify(amount: amount, place: name, card: card)
        return .result()
    }

    /// "S/ 25.50 en Tambo, con Visa BBVA ···4821". Solo si el usuario permitió avisos.
    private func notify(amount: Double, place: String, card: String?) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "MiGasto"
        var body = "S/ \(String(format: "%.2f", amount)) en \(place)"
        if let card = card, !card.isEmpty { body += ", con \(card)" }
        content.body = body
        content.subtitle = "Registrado. Ábrelo para cambiar la categoría."
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}

@available(iOS 16.0, *)
enum RegistroError: Error, CustomLocalizedStringResourceConvertible {
    case montoInvalido

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .montoInvalido: return "No pudimos leer el monto. Pásalo como 25.50."
        }
    }
}

/// Lee montos como "25.50", "S/ 25,50" o "1,200.50".
enum AmountParser {
    static func parse(_ raw: String) -> Double? {
        var s = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !s.isEmpty else { return nil }
        let thousands = try? NSRegularExpression(pattern: "^\\d{1,3}(,\\d{3})+(\\.\\d+)?$")
        let range = NSRange(s.startIndex..., in: s)
        if thousands?.firstMatch(in: s, range: range) != nil {
            s = s.replacingOccurrences(of: ",", with: "")
        } else {
            s = s.replacingOccurrences(of: ",", with: ".")
        }
        return Double(s)
    }
}

/// Hace que la acción aparezca en Atajos y en Spotlight.
@available(iOS 16.4, *)
struct MiGastoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RegistrarMovimientoIntent(),
            phrases: ["Registrar un movimiento en \(.applicationName)"],
            shortTitle: "Registrar movimiento",
            systemImageName: "plus.circle"
        )
    }
}
