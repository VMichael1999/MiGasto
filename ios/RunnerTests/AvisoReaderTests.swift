import XCTest
@testable import Runner

/// Textos reales de correos, notificaciones y constancias (ver
/// docs/investigacion-notificaciones-pagos.md) leídos como los recibe «Registrar aviso de pago».
final class AvisoReaderTests: XCTestCase {
    private var reader: PaymentReader!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUpWithError() throws {
        reader = try XCTUnwrap(AvisoReader.shared, "reader_rules.json debe estar en la app")
    }

    private func item(_ text: String) -> [String: Any]? { AvisoReader.item(from: text, reader: reader, now: now) }

    func testCorreoDelBcpConsumoConTarjetaSeGuardaComoGasto() throws {
        let i = try XCTUnwrap(item("Realizaste un consumo de S/ 25.78 con tu Tarjeta de Débito BCP en WL *STEAM PURCHASE."))
        XCTAssertEqual(i["amount"] as? Double, 25.78)
        XCTAssertEqual(i["peer"] as? String, "WL *STEAM PURCHASE")
        XCTAssertEqual(i["provider"] as? String, "tarjeta")
        XCTAssertEqual(i["type"] as? String, "gasto")
        XCTAssertEqual(i["confirmed"] as? Bool, true)
        XCTAssertEqual(i["channel"] as? String, "aviso")
        XCTAssertEqual(i["at"] as? Int, 1_800_000_000_000)
    }

    func testConstanciaDeYapeLeidaDeLaPantallaEnVariasLineas() throws {
        let screen = """
        ¡Yapeaste!
        S/ 12
        Juan Pérez
        01 oct. 2026 09:48 a. m.
        DATOS DE LA TRANSACCIÓN
        """
        let i = try XCTUnwrap(item(screen))
        XCTAssertEqual(i["amount"] as? Double, 12)
        XCTAssertEqual(i["peer"] as? String, "Juan Pérez")
        XCTAssertEqual(i["provider"] as? String, "yape")
        XCTAssertEqual(i["type"] as? String, "gasto")
    }

    func testPlinEnviadoDesdeBbva() throws {
        let i = try XCTUnwrap(item("¡Enviaste un Plin!\nPlineaste S/1 a Adrian I Mamani Q ."))
        XCTAssertEqual(i["provider"] as? String, "plin")
        XCTAssertEqual(i["peer"] as? String, "Adrian I Mamani Q")
    }

    func testUnIngresoEsperaConfirmacion() throws {
        let i = try XCTUnwrap(item("Yape! ADRIAN MAMANI te envió un pago por S/ 1"))
        XCTAssertEqual(i["type"] as? String, "ingreso")
        XCTAssertEqual(i["confirmed"] as? Bool, false)
        XCTAssertEqual(AvisoReader.title(for: i), "Ingreso por confirmar")
        XCTAssertEqual(AvisoReader.body(for: i), "S/ 1.00 · ADRIAN MAMANI · Yape")
    }

    func testLoQueNoEsUnPagoNoSeInventa() {
        XCTAssertNil(item("Ingresaste a tu Banca por Internet."))
        XCTAssertNil(item("¡Suerte asegurada! Gana hasta S/3,000 afiliándote a Dinero Más Seguro Yape"))
        XCTAssertNil(item("Se realizó un pago recurrente de $26.19 en HOSTINGER con tu Tarjeta de Débito."))
        XCTAssertNil(item(""))
    }

    func testAvisosConMontoQueNoSonUnPagoHecho() {
        XCTAssertNil(item("Tu compra por S/ 250.00 con tu Tarjeta de Débito BCP en FALABELLA fue rechazada"))
        XCTAssertNil(item("Usa el código 482913 para confirmar tu compra por S/ 250.00 con tu tarjeta en AMAZON"))
        XCTAssertNil(item("Recuerda: tu pago de S/ 120.00 con Yape vence mañana"))
    }
}
