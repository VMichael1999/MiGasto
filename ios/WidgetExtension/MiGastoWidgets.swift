import AppIntents
import SwiftUI
import WidgetKit

// Widgets de la pantalla de inicio y de la pantalla bloqueada. Muestran lo que Flutter deja en
// el grupo de la app (`WidgetSnapshot` en lib/shared/widget_snapshot.dart): no calculan nada,
// así las cifras son las mismas que en Inicio.

// MARK: - Enlaces

enum MiGastoLink {
    static let newExpense = URL(string: "migasto://new")!
    static let newIncome = URL(string: "migasto://new?type=ingreso")!
    static let dashboard = URL(string: "migasto://dashboard")!
    static let movements = URL(string: "migasto://movements")!
    static func movement(_ id: String) -> URL {
        let safe = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return URL(string: "migasto://movement/\(safe)") ?? movements
    }
}

// MARK: - Colores de la app (lib/core/theme/mg_colors.dart)

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x8B8898
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

enum Mg {
    static let card = Color(hex: "15151B")
    static let soft = Color(hex: "1F1F27")
    static let line = Color(hex: "26262F")
    static let ink = Color(hex: "F4F3F7")
    static let ink2 = Color(hex: "8B8898")
    static let ink3 = Color(hex: "585666")
    static let acc = Color(hex: "7C5CFF")
    static let acc2 = Color(hex: "9B82FF")
    static let accSoft = Color(hex: "1E1935")
    static let up = Color(hex: "2FD98A")
    static let down = Color(hex: "FF5C6E")
    static let warn = Color(hex: "F5A524")

    /// La tarjeta de balance de Inicio.
    static let balanceCard = LinearGradient(
        stops: [
            .init(color: Color(hex: "8E73FF"), location: 0),
            .init(color: Color(hex: "6A46F5"), location: 0.58),
            .init(color: Color(hex: "5A36E8"), location: 1),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Datos

struct WidgetData: Decodable {
    struct Movement: Decodable, Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let amount: String
        let kind: String
        let color: String
        let pending: Bool
    }

    let monthKey: String
    let month: String
    let balance: String
    let negative: Bool
    let income: String
    let spent: String
    let percent: Int
    let pending: Int
    let recent: [Movement]

    static let groupId = "group.com.migasto.co"
    static let key = "widget_snapshot"

    /// Lo último que guardó la app, o `nil` si todavía no se abrió.
    static func load() -> WidgetData? {
        guard let json = UserDefaults(suiteName: groupId)?.string(forKey: key),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Para la galería de widgets: se ve cómo queda, sin datos tuyos.
    static let sample = WidgetData(
        monthKey: "", month: "Noviembre", balance: "S/ 1,250.00", negative: false,
        income: "S/ 2,000.00", spent: "S/ 750.00", percent: 62, pending: 1,
        recent: [
            Movement(id: "1", title: "Tambo", subtitle: "Compras", amount: "-S/ 12.50", kind: "gasto", color: "#FF5C8A", pending: false),
            Movement(id: "2", title: "Spotify", subtitle: "Entretenimiento", amount: "-S/ 19.90", kind: "gasto", color: "#FF8A3D", pending: true),
            Movement(id: "3", title: "Sueldo", subtitle: "Sueldo", amount: "+S/ 2,000.00", kind: "ingreso", color: "#2FD98A", pending: false),
            Movement(id: "4", title: "Luz del Sur", subtitle: "Servicios", amount: "-S/ 98.40", kind: "gasto", color: "#7C5CFF", pending: false),
            Movement(id: "5", title: "Uber", subtitle: "Transporte", amount: "-S/ 15.00", kind: "gasto", color: "#22D3EE", pending: false),
            Movement(id: "6", title: "Venta", subtitle: "Venta", amount: "+S/ 80.00", kind: "ingreso", color: "#34D399", pending: false),
        ])

    /// Si el resumen es de un mes anterior (no se abrió la app desde entonces).
    var isFromAnotherMonth: Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return !monthKey.isEmpty && monthKey != f.string(from: Date())
    }
}

struct MiGastoEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

struct MiGastoProvider: TimelineProvider {
    func placeholder(in context: Context) -> MiGastoEntry { MiGastoEntry(date: Date(), data: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (MiGastoEntry) -> Void) {
        completion(MiGastoEntry(date: Date(), data: context.isPreview ? (WidgetData.load() ?? .sample) : WidgetData.load()))
    }

    /// La app recarga los widgets cada vez que cambia algo; además se vuelve a mirar al empezar el
    /// mes, para avisar que el resumen quedó viejo.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MiGastoEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let nextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
            .flatMap { calendar.date(byAdding: .month, value: 1, to: $0) } ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: [MiGastoEntry(date: now, data: WidgetData.load())], policy: .after(nextMonth)))
    }
}

// MARK: - Piezas comunes

struct BrandLogo: View {
    var size: CGFloat = 22
    var body: some View {
        Image("Logo").resizable().scaledToFit().frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Aviso cuando todavía no hay datos (la app no se abrió desde que se instaló el widget).
struct OpenAppHint: View {
    let dark: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BrandLogo(size: 30)
            Spacer(minLength: 0)
            Text("Abre MiGasto")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(dark ? Mg.ink : .white)
            Text("para ver tu resumen aquí")
                .font(.system(size: 12))
                .foregroundStyle(dark ? Mg.ink2 : .white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Barra de «Disponible» como la de la tarjeta de Inicio.
struct AvailableBar: View {
    let percent: Int
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.26))
                Capsule().fill(.white)
                    .frame(width: max(geo.size.width * CGFloat(min(max(percent, 0), 100)) / 100, percent > 0 ? 7 : 0))
            }
        }
        .frame(height: 7)
    }
}

// MARK: - 1. Resumen del mes

struct SummaryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MiGastoEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            if let d = entry.data {
                Text("Disponible \(d.balance)")
            } else {
                Text("MiGasto")
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Disponible").font(.caption2).widgetAccentable()
                Text(entry.data?.balance ?? "Abre MiGasto")
                    .font(.headline).minimumScaleFactor(0.6).lineLimit(1)
                if let d = entry.data {
                    Gauge(value: Double(d.percent), in: 0...100) { EmptyView() }
                        .gaugeStyle(.accessoryLinearCapacity)
                }
            }
        case .systemMedium:
            if let d = entry.data { medium(d) } else { OpenAppHint(dark: false) }
        default:
            if let d = entry.data { small(d) } else { OpenAppHint(dark: false) }
        }
    }

    private func header(_ d: WidgetData) -> some View {
        HStack(spacing: 6) {
            Text("Disponible")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
            Spacer(minLength: 0)
            BrandLogo(size: 22)
        }
    }

    private func amount(_ d: WidgetData, size: CGFloat) -> some View {
        Text(d.balance)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
    }

    private func footer(_ d: WidgetData) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            AvailableBar(percent: d.percent)
            Text(d.isFromAnotherMonth ? "\(d.month) · ábrela para actualizar" : "\(d.percent)% · \(d.month)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func small(_ d: WidgetData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            header(d)
            Spacer(minLength: 0)
            amount(d, size: 26)
            Spacer(minLength: 0)
            footer(d)
        }
    }

    private func medium(_ d: WidgetData) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                header(d)
                Spacer(minLength: 0)
                amount(d, size: 28)
                Spacer(minLength: 0)
                footer(d)
            }
            VStack(spacing: 8) {
                flow(icon: "arrow.up.right", label: "Ingresos", value: d.income)
                flow(icon: "arrow.down.left", label: "Gastos", value: d.spent)
            }
            .frame(width: 128)
        }
    }

    /// Como las cajas de Ingresos y Gastos de la tarjeta de Inicio.
    private func flow(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 9, weight: .bold))
                Text(label.uppercased()).font(.system(size: 9.5, weight: .semibold)).tracking(0.6)
            }
            .foregroundStyle(.white.opacity(0.78))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.14)))
    }
}

struct SummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MiGastoSummary", provider: MiGastoProvider()) { entry in
            SummaryView(entry: entry)
                .widgetURL(MiGastoLink.dashboard)
                .containerBackground(for: .widget) {
                    ZStack(alignment: .topTrailing) {
                        Mg.balanceCard
                        // Resplandor de la esquina, como en la tarjeta de Inicio.
                        RadialGradient(colors: [.white.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: 90)
                            .frame(width: 180, height: 180)
                            .offset(x: 60, y: -70)
                    }
                }
        }
        .configurationDisplayName("Resumen del mes")
        .description("Tu saldo disponible, con lo que entró y salió este mes.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - 2. Últimos movimientos

struct RecentView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MiGastoEntry

    private var rows: Int { family == .systemLarge ? 6 : 3 }

    var body: some View {
        if let d = entry.data {
            VStack(alignment: .leading, spacing: 0) {
                header(d)
                if d.recent.isEmpty {
                    Spacer()
                    Text("Aún no hay movimientos")
                        .font(.system(size: 13)).foregroundStyle(Mg.ink2)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    Spacer(minLength: 6)
                    VStack(spacing: family == .systemLarge ? 10 : 7) {
                        ForEach(d.recent.prefix(rows)) { m in
                            Link(destination: MiGastoLink.movement(m.id)) { row(m) }
                        }
                    }
                    Spacer(minLength: 0)
                    if family == .systemLarge {
                        Link(destination: MiGastoLink.movements) {
                            Text("Ver todos")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Mg.acc2)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        } else {
            OpenAppHint(dark: true)
        }
    }

    private func header(_ d: WidgetData) -> some View {
        HStack(spacing: 6) {
            BrandLogo(size: 20)
            Text("Movimientos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Mg.ink)
            Spacer(minLength: 0)
            if d.pending > 0 {
                Text(d.pending == 1 ? "1 por confirmar" : "\(d.pending) por confirmar")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Mg.acc2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Mg.accSoft))
            }
        }
    }

    private func row(_ m: WidgetData.Movement) -> some View {
        let tint = Color(hex: m.color)
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.16))
                Text(String(m.title.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(m.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Mg.ink)
                        .lineLimit(1)
                    if m.pending {
                        Circle().fill(Mg.warn).frame(width: 6, height: 6)
                    }
                }
                Text(m.pending ? "Por confirmar" : m.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(m.pending ? Mg.warn : Mg.ink2)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(m.amount)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(amountColor(m))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// Ingresos en verde, gastos en rojo, entre tus cuentas y por confirmar en gris.
    private func amountColor(_ m: WidgetData.Movement) -> Color {
        if m.pending { return Mg.ink2 }
        switch m.kind {
        case "ingreso": return Mg.up
        case "gasto": return Mg.down
        default: return Mg.ink2
        }
    }
}

struct RecentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MiGastoRecent", provider: MiGastoProvider()) { entry in
            RecentView(entry: entry)
                .widgetURL(MiGastoLink.movements)
                .containerBackground(Mg.card, for: .widget)
        }
        .configurationDisplayName("Últimos movimientos")
        .description("Tus últimos gastos e ingresos, y cuántos esperan que los confirmes.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 3. Registrar rápido

struct QuickAddView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "plus").font(.title2.weight(.semibold))
            }
            .accessibilityLabel("Registrar movimiento")
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill").font(.title2)
                VStack(alignment: .leading) {
                    Text("MiGasto").font(.headline)
                    Text("Registrar movimiento").font(.caption)
                }
            }
        case .systemMedium:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    BrandLogo(size: 22)
                    Text("Registrar").font(.system(size: 14, weight: .semibold)).foregroundStyle(Mg.ink)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 10) {
                    Link(destination: MiGastoLink.newExpense) {
                        button(icon: "arrow.down.left", title: "Gasto", tint: Mg.down)
                    }
                    Link(destination: MiGastoLink.newIncome) {
                        button(icon: "arrow.up.right", title: "Ingreso", tint: Mg.up)
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Mg.acc)
                    Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 46, height: 46)
                Spacer(minLength: 0)
                Text("Registrar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Mg.ink)
                Text("Gasto o ingreso")
                    .font(.system(size: 12))
                    .foregroundStyle(Mg.ink2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) { BrandLogo(size: 22) }
        }
    }

    private func button(icon: String, title: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)
            Spacer(minLength: 0)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Mg.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Mg.soft))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Mg.line, lineWidth: 1))
    }
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> MiGastoEntry { MiGastoEntry(date: Date(), data: nil) }
    func getSnapshot(in context: Context, completion: @escaping (MiGastoEntry) -> Void) {
        completion(MiGastoEntry(date: Date(), data: nil))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MiGastoEntry>) -> Void) {
        completion(Timeline(entries: [MiGastoEntry(date: Date(), data: nil)], policy: .never))
    }
}

struct QuickAddWidget: Widget {
    // Mismo `kind` que el widget anterior: los que ya lo tenían puesto no lo pierden.
    let kind = "MiGastoQuickAdd"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { _ in
            QuickAddView()
                .widgetURL(MiGastoLink.newExpense)
                .containerBackground(Mg.card, for: .widget)
        }
        .configurationDisplayName("Registrar")
        .description("Abre MiGasto para registrar un gasto o un ingreso en segundos.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Control del Centro de control (iOS 18)

@available(iOS 18.0, *)
struct OpenNewMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar movimiento"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(MiGastoLink.newExpense))
    }
}

@available(iOS 18.0, *)
struct QuickAddControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "MiGastoQuickAddControl") {
            ControlWidgetButton(action: OpenNewMovementIntent()) {
                Label("Registrar", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Registrar movimiento")
        .description("Abre MiGasto en la pantalla de registro.")
    }
}

@main
struct MiGastoWidgets: WidgetBundle {
    var body: some Widget {
        SummaryWidget()
        RecentWidget()
        QuickAddWidget()
        if #available(iOS 18.0, *) {
            QuickAddControl()
        }
    }
}
