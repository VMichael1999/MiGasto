import Foundation

/// Un pago leído de una captura.
struct ParsedPayment {
    let amount: Double
    let peer: String
    /// `yape`, `plin`, `googlePay` o `tarjeta`.
    let provider: String
    let isIncome: Bool
    /// `PEN` (soles) o `USD` (dólares); `amount` está en esta moneda.
    var currency: String = "PEN"
}

/// Un texto leído de la captura y dónde está, en fracciones de la imagen como las da Vision
/// (x desde la izquierda, y desde abajo).
struct TextBox {
    let text: String
    let minX: Double
    let maxX: Double
    let midY: Double
    let height: Double
}

/// Las constancias de los bancos son una tabla de dos columnas: «Contacto» a la izquierda y el
/// nombre a la derecha. Vision entrega cada texto suelto y, en una misma fila, a veces el valor
/// antes que la etiqueta; aquí se rearman las filas.
enum ReceiptLayout {
    /// Filas de arriba hacia abajo y, en cada una, los textos de izquierda a derecha. Dos textos
    /// van en la misma fila si sus centros están a menos de media línea de altura.
    static func rows(_ boxes: [TextBox]) -> [[TextBox]] {
        var rows: [[TextBox]] = []
        for box in boxes.sorted(by: { $0.midY > $1.midY }) {
            if let first = rows.last?.first, abs(first.midY - box.midY) < min(first.height, box.height) / 2 {
                rows[rows.count - 1].append(box)
            } else {
                rows.append([box])
            }
        }
        return rows.map { $0.sorted { $0.minX < $1.minX } }
    }

    static func lines(_ rows: [[TextBox]]) -> [String] {
        rows.map { $0.map(\.text).joined(separator: " ") }
    }

    /// Etiqueta y valor de cada fila de la tabla. El valor sigue en las filas de abajo que solo
    /// tienen texto a la derecha de la etiqueta (un nombre largo partido: «… valdiviezo» y «maza»).
    static func fields(_ rows: [[TextBox]]) -> [(label: String, value: String)] {
        var fields: [(label: String, value: String)] = []
        var labelEdge: Double?
        for row in rows {
            if row.count >= 2 {
                fields.append((row[0].text, row.dropFirst().map(\.text).joined(separator: " ")))
                labelEdge = row[0].maxX
            } else if let edge = labelEdge, let only = row.first, only.minX > edge {
                fields[fields.count - 1].value += " " + only.text
            } else {
                labelEdge = nil
            }
        }
        return fields
    }
}

/// Lector de pagos. Lee las mismas reglas que Dart y Kotlin
/// (`assets/reader_rules.json`) para que reconozcan lo mismo.
final class PaymentReader {
    private let rules: [String: Any]
    private let amountRegex: NSRegularExpression
    /// Monto en dólares: solo si el texto no trae uno en soles.
    private let usdAmountRegex: NSRegularExpression?
    private let incomeRegexes: [NSRegularExpression]
    private let expenseRegexes: [NSRegularExpression]
    /// Avisos con monto que no son un pago hecho: compra rechazada, código para confirmar, recordatorio.
    private let ignoreRegexes: [NSRegularExpression]

    init?(rulesJSON data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let amount = obj["amount"] as? String,
              let amountRe = try? NSRegularExpression(pattern: amount, options: [.caseInsensitive]),
              let income = obj["income"] as? [String],
              let expense = obj["expense"] as? [String] else { return nil }
        rules = obj
        amountRegex = amountRe
        usdAmountRegex = (obj["usdAmount"] as? String).flatMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
        incomeRegexes = income.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
        expenseRegexes = expense.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
        ignoreRegexes = (obj["ignore"] as? [String] ?? [])
            .compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
    }

    // MARK: - Parseo

    /// Lee un texto en una sola línea (notificación).
    func parse(_ text: String) -> ParsedPayment? {
        if ignoreRegexes.contains(where: { $0.firstMatch(in: text, range: fullRange(text)) != nil }) { return nil }
        let solesMatch = amountRegex.firstMatch(in: text, range: fullRange(text))
        let currency = solesMatch == nil ? "USD" : "PEN"
        guard let provider = provider(in: text),
              let match = solesMatch ?? usdAmountRegex?.firstMatch(in: text, range: fullRange(text)),
              let amountRange = Range(match.range(at: 1), in: text),
              let amount = parseAmount(String(text[amountRange])), amount > 0,
              let isIncome = direction(in: text, provider: provider) else { return nil }

        let peer = peer(in: text, match: match, isIncome: isIncome)
        return ParsedPayment(
            amount: amount,
            peer: peer.isEmpty ? (rules["unknownPeer"] as? String ?? "Desconocido") : peer,
            provider: provider, isIncome: isIncome, currency: currency)
    }

    /// Lee una captura compartida, sabiendo dónde está cada texto. Además de lo que lee
    /// `parse(lines:)`, toma el nombre de la tabla de la constancia («Contacto» → «Ana Pérez») y,
    /// si no reconoce la app pero ve un monto, lo devuelve igual (`provider` «otro») para que el
    /// formulario llegue relleno: el usuario lo revisa antes de guardar.
    func parse(receipt boxes: [TextBox]) -> ParsedPayment? {
        let rows = ReceiptLayout.rows(boxes)
        let lines = ReceiptLayout.lines(rows)
        guard let base = parse(lines: lines) ?? unnamedReceipt(lines.joined(separator: " ")) else { return nil }
        guard let labeled = labeledPeer(ReceiptLayout.fields(rows)) else { return base }
        return ParsedPayment(amount: base.amount, peer: labeled, provider: base.provider,
                             isIncome: base.isIncome, currency: base.currency)
    }

    /// Una constancia que no dice de qué app es: el monto y, si se sabe, si entró o salió.
    /// Al compartir una constancia lo más común es lo que pagaste, así que sin pista es un gasto.
    private func unnamedReceipt(_ text: String) -> ParsedPayment? {
        let range = fullRange(text)
        if ignoreRegexes.contains(where: { $0.firstMatch(in: text, range: range) != nil }) { return nil }
        let solesMatch = amountRegex.firstMatch(in: text, range: range)
        guard let match = solesMatch ?? usdAmountRegex?.firstMatch(in: text, range: range),
              let amountRange = Range(match.range(at: 1), in: text),
              let amount = parseAmount(String(text[amountRange])), amount > 0 else { return nil }
        let isIncome = incomeRegexes.contains(where: { $0.firstMatch(in: text, range: range) != nil })
        return ParsedPayment(amount: amount, peer: rules["unknownPeer"] as? String ?? "Desconocido",
                             provider: "otro", isIncome: isIncome, currency: solesMatch == nil ? "USD" : "PEN")
    }

    /// El valor de «Contacto», «Destinatario»… sin la cola de la cuenta («Ana Pérez • 0277»).
    private func labeledPeer(_ fields: [(label: String, value: String)]) -> String? {
        let labels = Set((rules["receiptPeerLabels"] as? [String] ?? []).map(Self.fold))
        for field in fields where labels.contains(Self.fold(field.label)) {
            var name = field.value.replacingOccurrences(of: "\\s*[•·].*$", with: "", options: .regularExpression)
            name = name.replacingOccurrences(of: "\\s+\\**\\d{3,}$", with: "", options: .regularExpression)
            name = clean(name)
            if isPeerLine(name) { return name }
        }
        return nil
    }

    /// Minúsculas, sin tildes ni dos puntos: «Contacto:» y «contacto» son la misma etiqueta.
    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
            .trimmingCharacters(in: CharacterSet(charactersIn: ": ").union(.whitespaces))
    }

    /// Lee el texto de una captura, línea por línea. En la constancia de Yape o Plin el
    /// comercio suele ir en la línea que sigue al monto.
    func parse(lines: [String]) -> ParsedPayment? {
        let joined = lines.joined(separator: " ")
        guard let base = parse(joined) else { return nil }
        if base.peer != (rules["unknownPeer"] as? String ?? "Desconocido") { return base }

        // Sin preposición: se toma la línea siguiente a la del monto.
        for (i, line) in lines.enumerated()
        where amountRegex.firstMatch(in: line, range: fullRange(line)) != nil {
            let candidates = lines.dropFirst(i + 1)
            if let next = candidates.first(where: { isPeerLine($0) }) {
                return ParsedPayment(amount: base.amount, peer: next.trimmingCharacters(in: .whitespaces),
                                     provider: base.provider, isIncome: base.isIncome, currency: base.currency)
            }
        }
        return base
    }

    /// Una línea que parece un nombre: sin monto, sin fecha ni códigos.
    private func isPeerLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.count >= 2, t.count <= 40 else { return false }
        if amountRegex.firstMatch(in: t, range: fullRange(t)) != nil { return false }
        let lower = t.lowercased()
        let noise = ["código", "codigo", "operación", "operacion", "fecha", "hora", "destino", "número", "numero", "yape", "plin", "compartir", "constancia"]
        if noise.contains(where: { lower.contains($0) }) { return false }
        let digits = t.filter { $0.isNumber }.count
        return digits * 2 < t.count
    }

    // MARK: - Piezas

    private func provider(in text: String) -> String? {
        let lower = text.lowercased()
        guard let providers = rules["providers"] as? [[String: Any]] else { return nil }
        for p in providers {
            guard let id = p["id"] as? String, let keywords = p["keywords"] as? [String] else { continue }
            let boundary = (p["wordBoundary"] as? Bool) ?? false
            for k in keywords {
                if boundary {
                    let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: k) + "(?![\\p{L}\\p{N}])"
                    if lower.range(of: pattern, options: .regularExpression) != nil { return id }
                } else if lower.contains(k) {
                    return id
                }
            }
        }
        return nil
    }

    /// true ingreso, false gasto, nil si no se puede saber.
    private func direction(in text: String, provider: String) -> Bool? {
        let range = fullRange(text)
        if incomeRegexes.contains(where: { $0.firstMatch(in: text, range: range) != nil }) { return true }
        if expenseRegexes.contains(where: { $0.firstMatch(in: text, range: range) != nil }) { return false }
        let defaults = rules["defaultTypeByProvider"] as? [String: String] ?? [:]
        switch defaults[provider] {
        case "gasto": return false
        case "ingreso": return true
        default: return nil
        }
    }

    /// "1,200.50" -> 1200.5; "12,50" -> 12.5.
    private func parseAmount(_ raw: String) -> Double? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        let thousands = try? NSRegularExpression(pattern: "^\\d{1,3}(,\\d{3})+(\\.\\d+)?$")
        if thousands?.firstMatch(in: s, range: fullRange(s)) != nil {
            s = s.replacingOccurrences(of: ",", with: "")
        } else {
            s = s.replacingOccurrences(of: ",", with: ".")
        }
        return Double(s)
    }

    private func peer(in text: String, match: NSTextCheckingResult, isIncome: Bool) -> String {
        let ns = text as NSString
        let after = ns.substring(from: match.range.location + match.range.length).trimmingCharacters(in: .whitespacesAndNewlines)
        let before = withoutTitlePrefix(ns.substring(to: match.range.location).trimmingCharacters(in: .whitespacesAndNewlines))
        let preps = (rules["peerPrepositions"] as? [String] ?? []).joined(separator: "|")

        func fromAfter() -> String {
            guard let re = try? NSRegularExpression(pattern: "^(\(preps))\\b(.*)", options: [.caseInsensitive, .dotMatchesLineSeparators]),
                  let m = re.firstMatch(in: after, range: fullRange(after)),
                  let prep = Range(m.range(at: 1), in: after),
                  let r = Range(m.range(at: 2), in: after) else { return "" }
            let rest = String(after[r])
            // Lo que sigue a «con» es la tarjeta, no el comercio: «PEN35.00 con Visa Clasica …»
            // (Google Wallet). Si después viene «en», ahí está el comercio (correo del BCP).
            if after[prep].lowercased() == "con" {
                guard let place = try? NSRegularExpression(pattern: "\\sen\\s+(.+)$", options: [.caseInsensitive, .dotMatchesLineSeparators]),
                      let pm = place.firstMatch(in: rest, range: fullRange(rest)),
                      let pr = Range(pm.range(at: 1), in: rest) else { return "" }
                return clean(String(rest[pr]))
            }
            return clean(rest)
        }

        // En ingresos el nombre suele ir antes; en gastos, después.
        let first = isIncome ? clean(before) : fromAfter()
        if !first.isEmpty { return first }
        let second = isIncome ? fromAfter() : clean(before)
        if !second.isEmpty || isIncome { return second }
        return fromAfterWithoutPreposition(after)
    }

    /// Quita el título que es solo el nombre del banco («Interbank Ana te ha plineado»).
    private func withoutTitlePrefix(_ before: String) -> String {
        let names = rules["titlePrefixes"] as? [String] ?? []
        guard !names.isEmpty else { return before }
        let pattern = "^(?:" + names.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")(?![\\p{L}\\p{N}])"
        return before.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Constancia de Yape al enviar: el nombre va justo después del monto, sin «a» ni «de».
    /// Se toma hasta la primera cifra (la fecha) y se descarta si queda demasiado largo.
    private func fromAfterWithoutPreposition(_ after: String) -> String {
        let cut = after.firstIndex(where: { $0.isNumber }) ?? after.endIndex
        let name = clean(String(after[..<cut]))
        return (2...60).contains(name.count) ? name : ""
    }

    private func clean(_ input: String) -> String {
        var t = input
        for stop in rules["peerStopWords"] as? [String] ?? [] {
            if let r = t.lowercased().range(of: stop), r.lowerBound > t.lowercased().startIndex {
                t = String(t[..<t.index(t.startIndex, offsetBy: t.lowercased().distance(from: t.lowercased().startIndex, to: r.lowerBound))])
            }
        }
        let phrases = (rules["cleanPhrases"] as? [String] ?? []).sorted { $0.count > $1.count }
        for phrase in phrases {
            let pattern = "(^|[^\\p{L}])" + NSRegularExpression.escapedPattern(for: phrase) + "(?![\\p{L}])"
            t = t.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        let preps = (rules["peerPrepositions"] as? [String] ?? []).joined(separator: "|")
        t = t.replacingOccurrences(of: "^\\s*(\(preps))\\b", with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: "\\b(\(preps))\\s*$", with: "", options: [.regularExpression, .caseInsensitive])
        // Emojis de los títulos («¡Recibiste un Plin! 💸»).
        t = t.replacingOccurrences(of: "\\p{So}", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.replacingOccurrences(of: "^[\\s:,\\-¡!.*_]+|[\\s:,\\-¡!.*_]+$", with: "", options: .regularExpression)
    }

    private func fullRange(_ s: String) -> NSRange { NSRange(s.startIndex..., in: s) }
}
