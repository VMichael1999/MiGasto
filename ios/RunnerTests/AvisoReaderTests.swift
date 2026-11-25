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

    /// Como recién instalada: «Guardar gastos solos» y «Guardar ingresos solos» apagados.
    private func item(_ text: String, autoSave: (expense: Bool, income: Bool) = (false, false)) -> [String: Any]? {
        AvisoReader.item(from: text, reader: reader, now: now, autoSave: autoSave)
    }

    func testCorreoDelBcpConsumoConTarjetaQuedaPorConfirmar() throws {
        let i = try XCTUnwrap(item("Realizaste un consumo de S/ 25.78 con tu Tarjeta de Débito BCP en WL *STEAM PURCHASE."))
        XCTAssertEqual(i["amount"] as? Double, 25.78)
        XCTAssertEqual(i["peer"] as? String, "WL *STEAM PURCHASE")
        XCTAssertEqual(i["provider"] as? String, "tarjeta")
        XCTAssertEqual(i["type"] as? String, "gasto")
        XCTAssertEqual(i["confirmed"] as? Bool, false)
        XCTAssertEqual(AvisoReader.title(for: i), "Gasto por confirmar")
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

    /// El atajo del disparador «Notificación» (iOS 27) pasa App, Título y Cuerpo.
    func testIngresoDeLemonDesdeElAtajoDeNotificaciones() throws {
        let i = try XCTUnwrap(item("Lemon Cash Recibiste S/ 1.5 🙌 ANA LUCIA PEREZ RIOS te envió dinero. Ya lo puedes encontrar en tu cuenta."))
        XCTAssertEqual(i["amount"] as? Double, 1.5)
        XCTAssertEqual(i["peer"] as? String, "ANA LUCIA PEREZ RIOS")
        XCTAssertEqual(i["provider"] as? String, "lemon")
        XCTAssertEqual(i["type"] as? String, "ingreso")
        XCTAssertEqual(AvisoReader.body(for: i), "S/ 1.50 · ANA LUCIA PEREZ RIOS · Lemon")
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
        XCTAssertNil(item(""))
    }

    func testAvisosConMontoQueNoSonUnPagoHecho() {
        XCTAssertNil(item("Tu compra por S/ 250.00 con tu Tarjeta de Débito BCP en FALABELLA fue rechazada"))
        XCTAssertNil(item("Usa el código 482913 para confirmar tu compra por S/ 250.00 con tu tarjeta en AMAZON"))
        XCTAssertNil(item("Recuerda: tu pago de S/ 120.00 con Yape vence mañana"))
    }

    func testUnConsumoEnDolaresEsperaConfirmacion() throws {
        let i = try XCTUnwrap(item("Realizaste un consumo de US$ 20.00 con tu Tarjeta de Crédito BCP en NETFLIX.COM"))
        XCTAssertEqual(i["amount"] as? Double, 20)
        XCTAssertEqual(i["currency"] as? String, "USD")
        XCTAssertEqual(i["confirmed"] as? Bool, false)
        XCTAssertEqual(AvisoReader.title(for: i), "Gasto en dólares por confirmar")
        XCTAssertEqual(AvisoReader.body(for: i), "US$ 20.00 · NETFLIX.COM · Tarjeta")

        let recurrente = try XCTUnwrap(item("Se realizó un pago recurrente de $26.19 en HOSTINGER con tu Tarjeta de Débito."))
        XCTAssertEqual(recurrente["currency"] as? String, "USD")
        XCTAssertEqual(recurrente["amount"] as? Double, 26.19)
    }

    func testConGuardarGastosSolosElGastoQuedaGuardado() throws {
        let i = try XCTUnwrap(item("Realizaste un consumo de S/ 25.78 con tu Tarjeta de Débito BCP en WL *STEAM PURCHASE.",
                                   autoSave: (true, false)))
        XCTAssertEqual(i["confirmed"] as? Bool, true)
        XCTAssertEqual(AvisoReader.title(for: i), "Gasto guardado")
        // El interruptor de gastos no toca los ingresos.
        let ingreso = try XCTUnwrap(item("Yape! ADRIAN MAMANI te envió un pago por S/ 1", autoSave: (true, false)))
        XCTAssertEqual(ingreso["confirmed"] as? Bool, false)
    }

    func testConGuardarIngresosSolosElIngresoQuedaGuardado() throws {
        let i = try XCTUnwrap(item("Yape! ADRIAN MAMANI te envió un pago por S/ 1", autoSave: (false, true)))
        XCTAssertEqual(i["confirmed"] as? Bool, true)
        XCTAssertEqual(AvisoReader.title(for: i), "Ingreso guardado")
    }

    func testUnCargoEnDolaresEsperaAunqueSeGuardenSolos() throws {
        let i = try XCTUnwrap(item("Realizaste un consumo de US$ 20.00 con tu tarjeta en NETFLIX.COM", autoSave: (true, true)))
        XCTAssertEqual(i["confirmed"] as? Bool, false)
    }

    func testLosInterruptoresSeLeenDeLoQueGuardaFlutter() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "migasto-tests-ajustes"))
        defaults.removePersistentDomain(forName: "migasto-tests-ajustes")
        XCTAssertTrue(AvisoReader.autoSaveSettings(defaults) == (false, false))
        defaults.set(true, forKey: "flutter.migasto_auto_save_expense")
        XCTAssertTrue(AvisoReader.autoSaveSettings(defaults) == (true, false))
        defaults.removePersistentDomain(forName: "migasto-tests-ajustes")
    }
}
