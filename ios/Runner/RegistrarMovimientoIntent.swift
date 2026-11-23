import AppIntents
import CoreLocation
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

/// Acción de Atajos "Registrar pago de Wallet": un solo campo, la «Entrada de atajo» de la
/// automatización de Wallet. Sirve cuando Atajos no deja elegir monto y comercio por separado:
/// MiGasto interpreta el texto y, si no logra leerlo, guarda el pago como pendiente con el texto
/// original para que se complete a mano.
@available(iOS 16.0, *)
struct RegistrarPagoWalletIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar pago de Wallet"
    static var description = IntentDescription(
        "Guarda el pago que te pasa la automatización de Wallet. Solo pon la «Entrada de atajo».",
        categoryName: "Movimientos"
    )

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Pago", description: "La «Entrada de atajo» de la automatización de Wallet")
    var pago: String

    @Parameter(title: "Ubicación", description: "Opcional: la acción «Obtener ubicación actual», para ver dónde pagaste en el mapa")
    var ubicacion: CLPlacemark?

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar pago de Wallet \(\.$pago)") {
            \.$ubicacion
        }
    }

    func perform() async throws -> some IntentResult {
        let parsed = WalletTextParser.parse(pago)
        let known = parsed.amount != nil && (parsed.amount ?? 0) > 0
        let amount = parsed.amount ?? 0
        let name = parsed.merchant ?? "Pago con Apple Pay"
        let original = String(pago.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))

        var item: [String: Any] = [
            "amount": amount,
            "peer": name,
            "provider": "tarjeta",
            "type": "gasto",
            "channel": "wallet",
            "rawText": "Apple Pay: \(original)",
            // Si no se pudo leer el monto queda pendiente, para que no se pierda.
            "confirmed": known,
            "at": Int(Date().timeIntervalSince1970 * 1000),
        ]
        if let card = parsed.card, !card.isEmpty { item["card"] = card }
        if let coordinate = ubicacion?.location?.coordinate, CLLocationCoordinate2DIsValid(coordinate) {
            item["latitude"] = coordinate.latitude
            item["longitude"] = coordinate.longitude
            if let accuracy = ubicacion?.location?.horizontalAccuracy, accuracy >= 0 { item["accuracy"] = accuracy }
            // Dirección legible, la que Atajos ya resolvió (calle y zona).
            let street = [ubicacion?.thoroughfare, ubicacion?.subThoroughfare]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            let zone = ubicacion?.subLocality ?? ubicacion?.locality
            let place = [street, zone ?? ""].filter { !$0.isEmpty }.joined(separator: ", ")
            if !place.isEmpty { item["place"] = place }
        }
        SharedQueue.enqueue(item)
        return .result()
    }
}

/// Interpreta el texto que entrega Wallet cuando Atajos no separa los datos.
enum WalletTextParser {
    struct Result {
        var amount: Double?
        var merchant: String?
        var card: String?
    }

    static func parse(_ raw: String) -> Result {
        var result = Result()
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return result }

        // Campos con etiqueta: «Comercio: Tambo», «Merchant: Tambo», «Tarjeta: Visa ···4821».
        func labeled(_ names: [String]) -> String? {
            for name in names {
                let pattern = "(?im)^\\s*\(name)\\s*[:=]\\s*(.+)$"
                if let re = try? NSRegularExpression(pattern: pattern),
                   let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                   let r = Range(m.range(at: 1), in: text) {
                    let value = String(text[r]).trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty { return value }
                }
            }
            return nil
        }

        result.merchant = labeled(["Comercio", "Merchant", "Nombre", "Name"])
        result.card = labeled(["Tarjeta o pase", "Tarjeta", "Card or Pass", "Card"])
        if let a = labeled(["Monto", "Cantidad", "Importe", "Amount"]) {
            result.amount = AmountParser.parse(a)
        }

        // Monto suelto: junto a una moneda («S/ 25.50», «PEN 25.50», «$25.50») o el primer número con decimales.
        if result.amount == nil {
            let patterns = [
                "(?:S/\\.?|PEN|USD|US\\$|\\$)\\s*([0-9][0-9.,]*)",
                "([0-9][0-9.,]*)\\s*(?:soles|PEN|USD)",
                "([0-9]+[.,][0-9]{2})(?![0-9])",
            ]
            for pattern in patterns {
                if let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                   let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                   let r = Range(m.range(at: 1), in: text),
                   let value = AmountParser.parse(String(text[r])) {
                    result.amount = value
                    break
                }
            }
        }

        // Sin etiqueta: la primera línea que no es un monto ni una tarjeta es el comercio.
        if result.merchant == nil {
            let lines = text.components(separatedBy: CharacterSet(charactersIn: "\n·|"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            result.merchant = lines.first { line in
                let digits = line.filter { $0.isNumber }.count
                return digits * 2 < line.count && !line.contains("···") && !line.lowercased().contains("visa")
                    && !line.lowercased().contains("mastercard")
            }
        }
        return result
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
        AppShortcut(
            intent: RegistrarPagoWalletIntent(),
            phrases: ["Registrar un pago de Wallet en \(.applicationName)"],
            shortTitle: "Registrar pago de Wallet",
            systemImageName: "creditcard"
        )
        AppShortcut(
            intent: RegistrarAvisoIntent(),
            phrases: ["Registrar un aviso de pago en \(.applicationName)"],
            shortTitle: "Registrar aviso de pago",
            systemImageName: "text.viewfinder"
        )
    }
}
