import XCTest
@testable import Runner

/// Pagos con Apple Pay que llegan por la automatización de Wallet («Registrar pago de Wallet» y
/// «Registrar movimiento»).
final class WalletPaymentTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func item(_ text: String, autoSaveExpense: Bool) -> [String: Any] {
        let parsed = WalletTextParser.parse(text)
        return WalletPayment.item(amount: parsed.amount, merchant: parsed.merchant, card: parsed.card,
                                  rawText: "Apple Pay: \(text)", now: now, autoSaveExpense: autoSaveExpense)
    }

    func testRecienInstaladaElPagoQuedaPorConfirmar() {
        let i = item("Comercio: Tambo\nMonto: S/ 25.50\nTarjeta: Visa BBVA ···4821", autoSaveExpense: false)
        XCTAssertEqual(i["amount"] as? Double, 25.5)
        XCTAssertEqual(i["peer"] as? String, "Tambo")
        XCTAssertEqual(i["card"] as? String, "Visa BBVA ···4821")
        XCTAssertEqual(i["provider"] as? String, "tarjeta")
        XCTAssertEqual(i["type"] as? String, "gasto")
        XCTAssertEqual(i["channel"] as? String, "wallet")
        XCTAssertEqual(i["confirmed"] as? Bool, false)
        XCTAssertEqual(i["at"] as? Int, 1_800_000_000_000)
        XCTAssertEqual(WalletPayment.title(for: i), "Gasto por confirmar")
        XCTAssertEqual(WalletPayment.body(for: i), "S/ 25.50 · Tambo · Visa BBVA ···4821")
    }

    func testConGuardarGastosSolosQuedaGuardado() {
        let i = item("Comercio: Tambo\nMonto: S/ 25.50", autoSaveExpense: true)
        XCTAssertEqual(i["confirmed"] as? Bool, true)
        XCTAssertEqual(WalletPayment.title(for: i), "Gasto guardado")
        XCTAssertNil(i["card"])
        XCTAssertEqual(WalletPayment.body(for: i), "S/ 25.50 · Tambo")
    }

    func testSinMontoEsperaAunqueSeGuardenSolos() {
        let i = item("Tambo", autoSaveExpense: true)
        XCTAssertEqual(i["amount"] as? Double, 0)
        XCTAssertEqual(i["confirmed"] as? Bool, false)
        XCTAssertEqual(i["rawText"] as? String, "Apple Pay: Tambo")
        XCTAssertEqual(WalletPayment.title(for: i), "Pago con Apple Pay por completar")
    }

    func testSinComercioUsaUnNombreGenerico() {
        let i = WalletPayment.item(amount: 10, merchant: "  ", card: " ", rawText: "", now: now, autoSaveExpense: false)
        XCTAssertEqual(i["peer"] as? String, "Pago con Apple Pay")
        XCTAssertNil(i["card"])
    }
}
