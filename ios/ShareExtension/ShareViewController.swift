import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Extensión "Compartir": recibe la captura de la constancia de Yape o Plin, lee
/// el texto en el teléfono y deja el pago en la cola para que MiGasto lo guarde.
final class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        spinner.startAnimating()
        Task { await process() }
    }

    private func process() async {
        let image = await loadImage()
        let lines = image == nil ? [] : await OCR.lines(in: image!)
        let reader = loadReader()
        let parsed = reader?.parse(lines: lines)
        let categories = CategoryRules.load()
        await MainActor.run { show(parsed: parsed, lines: lines, categories: categories) }
    }

    private func loadImage() async -> UIImage? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }
        for item in items {
            for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let image = await load(provider) { return image }
            }
        }
        return nil
    }

    private func load(_ provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: UIImage(data: data))
                } else if let image = item as? UIImage {
                    continuation.resume(returning: image)
                } else if let data = item as? Data {
                    continuation.resume(returning: UIImage(data: data))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadReader() -> PaymentReader? {
        guard let url = Bundle.main.url(forResource: "reader_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return PaymentReader(rulesJSON: data)
    }

    private func show(parsed: ParsedPayment?, lines: [String], categories: CategoryRules?) {
        spinner.stopAnimating()
        let text = lines.joined(separator: " ")
        let view = ShareView(
            parsed: parsed,
            rawText: text,
            categoryFor: { categories?.suggest(text: text, peer: $0.peer, isIncome: $0.isIncome) ?? ($0.isIncome ? "transferenciaRecibida" : "otros") },
            onSave: { [weak self] item in
                SharedQueue.enqueue(item)
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: NSError(domain: "MiGasto", code: 0))
            }
        )
        let host = UIHostingController(rootView: view)
        addChild(host)
        host.view.frame = self.view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(host.view)
        host.didMove(toParent: self)
    }
}

/// Categoría sugerida con las mismas palabras clave que Flutter y Android
/// (`assets/category_rules.json`).
struct CategoryRules {
    private let gasto: [(String, [NSRegularExpression])]
    private let ingreso: [(String, [NSRegularExpression])]
    private let gastoDefault: String
    private let ingresoDefault: String

    static func load() -> CategoryRules? {
        guard let url = Bundle.main.url(forResource: "category_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        func groups(_ key: String) -> [(String, [NSRegularExpression])] {
            (obj[key] as? [[String: Any]] ?? []).compactMap { g in
                guard let name = g["category"] as? String, let words = g["keywords"] as? [String] else { return nil }
                let res = words.compactMap {
                    try? NSRegularExpression(
                        pattern: "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: $0) + "(?![\\p{L}\\p{N}])",
                        options: [.caseInsensitive])
                }
                return (name, res)
            }
        }
        return CategoryRules(
            gasto: groups("gasto"), ingreso: groups("ingreso"),
            gastoDefault: obj["gastoDefault"] as? String ?? "otros",
            ingresoDefault: obj["ingresoDefault"] as? String ?? "transferenciaRecibida")
    }

    func suggest(text: String, peer: String, isIncome: Bool) -> String {
        let combined = "\(text) \(peer)"
        let range = NSRange(combined.startIndex..., in: combined)
        for (name, res) in (isIncome ? ingreso : gasto)
        where res.contains(where: { $0.firstMatch(in: combined, range: range) != nil }) {
            return name
        }
        return isIncome ? ingresoDefault : gastoDefault
    }
}
