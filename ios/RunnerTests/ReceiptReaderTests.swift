import XCTest
@testable import Runner

/// Capturas compartidas a MiGasto («Guardar en MiGasto»): el texto llega con su lugar en la
/// pantalla, como lo da Vision. Las posiciones copian las de una constancia real del BBVA; los
/// nombres y números son inventados.
final class ReceiptReaderTests: XCTestCase {
    private var reader: PaymentReader!

    override func setUpWithError() throws {
        reader = try XCTUnwrap(AvisoReader.shared, "reader_rules.json debe estar en la app")
    }

    private func box(_ text: String, x: Double, to maxX: Double, y: Double, h: Double = 0.02) -> TextBox {
        TextBox(text: text, minX: x, maxX: maxX, midY: y, height: h)
    }

    /// «Envío a contactos» del BBVA (Plin) a una billetera, en el orden en que Vision lo entrega:
    /// en algunas filas el valor llega antes que la etiqueta.
    private var bbva: [TextBox] {
        [
            box("Envíoa contactos", x: 0.33, to: 0.67, y: 0.965, h: 0.015),
            box("Operación", x: 0.25, to: 0.81, y: 0.752, h: 0.042),
            box("exitosa", x: 0.34, to: 0.72, y: 0.706, h: 0.034),
            box("24 noviembre 2026,21:56", x: 0.23, to: 0.77, y: 0.653, h: 0.023),
            box("Importe enviado", x: 0.34, to: 0.66, y: 0.611, h: 0.019),
            box("S/ 1.00", x: 0.31, to: 0.69, y: 0.566, h: 0.041),
            box("Dale", x: 0.82, to: 0.92, y: 0.457),
            box("Entidad de destino", x: 0.07, to: 0.45, y: 0.456),
            box("S/ 0.00", x: 0.76, to: 0.91, y: 0.408),
            box("Comisión", x: 0.07, to: 0.28, y: 0.406),
            box("0000012300000", x: 0.56, to: 0.91, y: 0.358),
            box("Número de operación", x: 0.08, to: 0.51, y: 0.356),
            box("0000", x: 0.79, to: 0.91, y: 0.336),
            box("Envío a contactos", x: 0.57, to: 0.91, y: 0.289),
            box("Tipo de operación", x: 0.08, to: 0.44, y: 0.286),
            box("Ana lucía pérez", x: 0.52, to: 0.91, y: 0.238),
            box("Contacto", x: 0.09, to: 0.27, y: 0.238),
            box("ríos • 0123", x: 0.68, to: 0.92, y: 0.218),
            box("Cuenta ganadora", x: 0.58, to: 0.91, y: 0.170),
            box("Cuenta de origen", x: 0.09, to: 0.42, y: 0.169),
            box("001100000000000000", x: 0.46, to: 0.91, y: 0.150),
            box("43", x: 0.85, to: 0.91, y: 0.128),
        ]
    }

    func testLasFilasDeLaTablaSeRearmanDeIzquierdaADerecha() {
        let lines = ReceiptLayout.lines(ReceiptLayout.rows(bbva))
        XCTAssertTrue(lines.contains("Entidad de destino Dale"))
        XCTAssertTrue(lines.contains("Contacto Ana lucía pérez"))
        XCTAssertEqual(lines.first, "Envíoa contactos")
    }

    func testElValorPartidoEnDosFilasSeJunta() {
        let fields = ReceiptLayout.fields(ReceiptLayout.rows(bbva))
        XCTAssertEqual(fields.first { $0.label == "Contacto" }?.value, "Ana lucía pérez ríos • 0123")
        XCTAssertEqual(fields.first { $0.label == "Cuenta de origen" }?.value, "Cuenta ganadora 001100000000000000 43")
    }

    func testEnvioAContactosDelBbvaEsUnPlinEnviado() throws {
        let p = try XCTUnwrap(reader.parse(receipt: bbva))
        XCTAssertEqual(p.amount, 1)
        XCTAssertEqual(p.provider, "plin")
        XCTAssertFalse(p.isIncome)
        XCTAssertEqual(p.currency, "PEN")
        // El nombre sale de «Contacto», sin los últimos dígitos de la cuenta; «Dale» es la
        // billetera de destino, no la persona.
        XCTAssertEqual(p.peer, "Ana lucía pérez ríos")
    }

    func testUnaConstanciaQueNoDiceLaAppIgualTraeElMonto() throws {
        let p = try XCTUnwrap(reader.parse(receipt: [
            box("Transferencia exitosa", x: 0.2, to: 0.8, y: 0.8),
            box("S/ 25.50", x: 0.3, to: 0.7, y: 0.7, h: 0.04),
            box("Destinatario:", x: 0.08, to: 0.35, y: 0.5),
            box("Juan Torres", x: 0.6, to: 0.92, y: 0.5),
        ]))
        XCTAssertEqual(p.amount, 25.5)
        XCTAssertEqual(p.provider, "otro")
        XCTAssertFalse(p.isIncome)
        XCTAssertEqual(p.peer, "Juan Torres")
    }

    func testUnaConstanciaDeIngresoSinAppEsIngreso() throws {
        let p = try XCTUnwrap(reader.parse(receipt: [
            box("Recibiste S/ 40.00", x: 0.2, to: 0.8, y: 0.8),
            box("Remitente", x: 0.08, to: 0.3, y: 0.5),
            box("Rosa Díaz", x: 0.6, to: 0.92, y: 0.5),
        ]))
        XCTAssertEqual(p.provider, "otro")
        XCTAssertTrue(p.isIncome)
        XCTAssertEqual(p.peer, "Rosa Díaz")
    }

    func testLaConstanciaDeYapeSeLeeComoAntes() throws {
        let p = try XCTUnwrap(reader.parse(receipt: [
            box("¡Yapeaste!", x: 0.3, to: 0.7, y: 0.85),
            box("S/ 12", x: 0.35, to: 0.65, y: 0.75, h: 0.05),
            box("Juan Pérez", x: 0.3, to: 0.7, y: 0.68),
            box("01 oct. 2026 09:48 a. m.", x: 0.25, to: 0.75, y: 0.64),
            box("DATOS DE LA TRANSACCIÓN", x: 0.1, to: 0.6, y: 0.5),
        ]))
        XCTAssertEqual(p.provider, "yape")
        XCTAssertEqual(p.peer, "Juan Pérez")
        XCTAssertEqual(p.amount, 12)
    }

    func testSinMontoOConUnaCompraRechazadaNoHayPago() {
        XCTAssertNil(reader.parse(receipt: [box("Operación exitosa", x: 0.2, to: 0.8, y: 0.8)]))
        XCTAssertNil(reader.parse(receipt: [box("Compra rechazada por S/ 30.00", x: 0.1, to: 0.9, y: 0.8)]))
        XCTAssertNil(reader.parse(receipt: []))
    }
}
