import AppIntents
import SwiftUI
import WidgetKit

// Widgets de la pantalla de inicio y de la pantalla bloqueada. Muestran lo que Flutter deja en
// el grupo de la app (`WidgetSnapshot` en lib/shared/widget_snapshot.dart): no calculan nada,
// así las cifras son las mismas que en Inicio. El diseño sigue las maquetas aprobadas
// («Widgets MiGasto»): sin logo, saldo anclado abajo, anillo del mes e Inter como la app.

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

// MARK: - Colores y letra de la app (lib/core/theme/mg_colors.dart)

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
    static let line = Color(hex: "2A2A34")
    static let ink = Color(hex: "F4F3F7")
    static let ink2 = Color(hex: "8B8898")
    static let acc = Color(hex: "7C5CFF")
    static let accSoft = Color(hex: "1E1935")
    static let accText = Color(hex: "B8A6FF")
    static let up = Color(hex: "34D399")
    static let down = Color(hex: "FF6B7A")
    static let warn = Color(hex: "F5A524")

    /// La tarjeta de balance de Inicio, con el resplandor de su esquina.
    static var balanceCard: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "8E73FF"), location: 0),
                    .init(color: Color(hex: "6A46F5"), location: 0.58),
                    .init(color: Color(hex: "5A36E8"), location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.white.opacity(0.20), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 130)
        }
    }

    static let plusButton = LinearGradient(colors: [Color(hex: "9B82FF"), Color(hex: "6A46F5")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Inter, la letra de la app (va en la extensión: Fonts/ y UIAppFonts).
enum Inter {
    case medium, semibold, bold

    func font(_ size: CGFloat) -> Font {
        let name: String
        switch self {
        case .medium: name = "Inter-Medium"
        case .semibold: name = "Inter-SemiBold"
        case .bold: name = "Inter-Bold"
        }
        return .custom(name, fixedSize: size)
    }
}

// MARK: - Datos

struct WidgetData: Decodable {
    struct Movement: Decodable, Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let amount: String
        let kind: String
        let icon: String
        let color: String
        let pending: Bool
        let day: String
    }

    let monthKey: String
    let month: String
    let monthShort: String
    let balance: String
    let balanceSign: String
    let balanceInt: String
    let balanceDec: String
    let negative: Bool
    let income: String
    let spent: String
    let todaySpent: String
    let percent: Int
    let pending: Int
    let recent: [Movement]
    let days: [String: String]

    static let groupId = "group.com.migasto.co"
    static let key = "widget_snapshot"

    /// Lo último que guardó la app, o `nil` si todavía no se abrió (o es de un formato viejo).
    static func load() -> WidgetData? {
        guard let json = UserDefaults(suiteName: groupId)?.string(forKey: key),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Para la galería de widgets: se ve cómo queda, sin datos tuyos.
    static let sample = WidgetData(
        monthKey: "", month: "Noviembre", monthShort: "NOV", balance: "S/ 1,250.00",
        balanceSign: "", balanceInt: "1,250", balanceDec: ".00", negative: false,
        income: "S/ 2,000.00", spent: "S/ 750.00", todaySpent: "S/ 38.40", percent: 62, pending: 1,
        recent: [
            Movement(id: "1", title: "Tambo", subtitle: "Compras", amount: "−S/ 12.50", kind: "gasto", icon: "compras", color: "#FF5C8A", pending: false, day: "hoy"),
            Movement(id: "2", title: "Spotify", subtitle: "Entretenimiento", amount: "−S/ 19.90", kind: "gasto", icon: "entretenimiento", color: "#FF8A3D", pending: true, day: "hoy"),
            Movement(id: "3", title: "Luz del Sur", subtitle: "Servicios", amount: "−S/ 98.40", kind: "gasto", icon: "servicios", color: "#7C5CFF", pending: false, day: "hoy"),
            Movement(id: "4", title: "Sueldo", subtitle: "Sueldo", amount: "+S/ 2,000.00", kind: "ingreso", icon: "sueldo", color: "#2FD98A", pending: false, day: "ayer"),
            Movement(id: "5", title: "Uber", subtitle: "Transporte", amount: "−S/ 15.00", kind: "gasto", icon: "transporte", color: "#22D3EE", pending: false, day: "ayer"),
            Movement(id: "6", title: "Menú del día", subtitle: "Alimentación", amount: "−S/ 14.00", kind: "gasto", icon: "alimentacion", color: "#F5A524", pending: false, day: "ayer"),
        ],
        days: ["hoy": "−S/ 110.90", "ayer": "+S/ 1,971.00"])

    /// Si el resumen es de un mes anterior (no se abrió la app desde entonces).
    var isFromAnotherMonth: Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return !monthKey.isEmpty && monthKey != f.string(from: Date())
    }

    /// «Hoy», «Ayer» o «dom 22 nov», según la fecha del teléfono (no la del resumen).
    static func dayLabel(_ key: String, now: Date = Date()) -> String {
        if key == "hoy" { return "Hoy" }
        if key == "ayer" { return "Ayer" }
        let parse = DateFormatter()
        parse.dateFormat = "yyyy-MM-dd"
        guard let date = parse.date(from: key) else { return key }
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return "Hoy" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Ayer"
        }
        let show = DateFormatter()
        show.locale = Locale(identifier: "es_PE")
        show.dateFormat = "EEE d MMM"
        return show.string(from: date).replacingOccurrences(of: ".", with: "")
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

    /// La app recarga los widgets cada vez que cambia algo; además se vuelve a mirar a medianoche
    /// («Hoy» pasa a «Ayer») y al empezar el mes, para avisar que el resumen quedó viejo.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MiGastoEntry>) -> Void) {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        completion(Timeline(entries: [MiGastoEntry(date: now, data: WidgetData.load())], policy: .after(midnight)))
    }
}

// MARK: - Piezas comunes

/// El anillo del mes: lo que queda de lo que entró.
struct MonthRing: View {
    let percent: Int
    var size: CGFloat = 46
    var line: CGFloat = 5
    var label: CGFloat = 12
    var dashed = false

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.25),
                            style: StrokeStyle(lineWidth: line, dash: dashed ? [4, 5] : []))
            if !dashed {
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(percent, 0), 100)) / 100)
                    .stroke(.white, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()
                Text("\(percent)%")
                    .font(Inter.bold.font(label))
                    .monospacedDigit()
            }
        }
        .padding(line / 2)
        .frame(width: size, height: size)
    }
}

/// «S/ 16,056.54» con «S/» y los decimales más chicos; si no entra, baja de tamaño en pasos fijos.
struct BalanceText: View {
    let data: WidgetData
    let sizes: [CGFloat]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(sizes, id: \.self) { size in
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(data.balanceSign)S/")
                        .font(Inter.semibold.font(size * 0.52))
                        .opacity(0.8)
                        .padding(.trailing, size * 0.08)
                    Text(data.balanceInt)
                        .font(Inter.bold.font(size))
                        .tracking(-size * 0.02)
                    Text(data.balanceDec)
                        .font(Inter.semibold.font(size * 0.6))
                        .opacity(0.8)
                }
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            }
        }
    }
}

/// Aviso cuando la app todavía no dejó datos (recién instalado el widget).
struct OpenAppHint: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonthRing(percent: 0, dashed: true)
            Spacer(minLength: 0)
            Text(text)
                .font(Inter.semibold.font(15))
                .lineSpacing(2)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
                Label("Disponible \(d.balanceSign)S/ \(d.balanceInt)", systemImage: "circle.lefthalf.filled")
            } else {
                Label("MiGasto", systemImage: "circle.lefthalf.filled")
            }
        case .accessoryCircular:
            if let d = entry.data {
                Gauge(value: Double(d.percent), in: 0...100) { Text("Disponible") } currentValueLabel: {
                    Text("\(d.percent)%").monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
            } else {
                ZStack { AccessoryWidgetBackground(); Image(systemName: "circle.dashed") }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.map { "Disponible · \($0.percent)%" } ?? "Disponible")
                    .font(.system(size: 12, weight: .semibold))
                    .widgetAccentable()
                Text(entry.data?.balance ?? "Abre MiGasto")
                    .font(.system(size: 17, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let d = entry.data {
                    Gauge(value: Double(d.percent), in: 0...100) { EmptyView() }
                        .gaugeStyle(.accessoryLinearCapacity)
                }
            }
        case .systemMedium:
            if let d = entry.data { medium(d) } else { OpenAppHint(text: "Abre MiGasto para ver tu saldo aquí") }
        default:
            if let d = entry.data { small(d) } else { OpenAppHint(text: "Abre MiGasto para ver tu saldo aquí") }
        }
    }

    /// «Disponible», «Te pasaste» o, con un mes viejo, «Toca para actualizar».
    @ViewBuilder
    private func caption(_ d: WidgetData) -> some View {
        if d.isFromAnotherMonth {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise").font(.system(size: 10, weight: .bold))
                Text("Toca para actualizar")
            }
            .font(Inter.semibold.font(12))
        } else {
            Text(d.negative ? "Te pasaste" : "Disponible")
                .font(Inter.medium.font(12.5))
                .opacity(0.82)
        }
    }

    private func small(_ d: WidgetData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                MonthRing(percent: d.percent).opacity(d.isFromAnotherMonth ? 0.55 : 1)
                Spacer(minLength: 0)
                Text(d.monthShort)
                    .font(Inter.semibold.font(11))
                    .tracking(0.7)
                    .opacity(0.75)
            }
            Spacer(minLength: 0)
            caption(d)
            BalanceText(data: d, sizes: [27, 24, 21, 18])
                .padding(.top, 2)
                .opacity(d.isFromAnotherMonth ? 0.6 : 1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func medium(_ d: WidgetData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if d.isFromAnotherMonth {
                        caption(d)
                    } else {
                        Text("\(d.negative ? "Te pasaste" : "Disponible") · \(d.month)")
                            .font(Inter.medium.font(12.5))
                            .opacity(0.82)
                    }
                    BalanceText(data: d, sizes: [34, 30, 26, 22])
                        .opacity(d.isFromAnotherMonth ? 0.6 : 1)
                }
                Spacer(minLength: 0)
                MonthRing(percent: d.percent, size: 58, line: 6, label: 14)
                    .opacity(d.isFromAnotherMonth ? 0.55 : 1)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                flow(icon: "arrow.up.right", label: "Ingresos", value: d.income)
                flow(icon: "arrow.down.left", label: "Gastos", value: d.spent)
            }
        }
        .foregroundStyle(.white)
    }

    /// Las cajas de Ingresos y Gastos de la tarjeta de Inicio.
    private func flow(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 9, weight: .bold))
                Text(label).font(Inter.medium.font(11.5))
            }
            .opacity(0.85)
            Text(value)
                .font(Inter.semibold.font(15))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.15)))
    }
}

struct SummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MiGastoSummary", provider: MiGastoProvider()) { entry in
            SummaryView(entry: entry)
                .widgetURL(MiGastoLink.dashboard)
                .containerBackground(for: .widget) { Mg.balanceCard }
        }
        .configurationDisplayName("Resumen del mes")
        .description("Tu saldo disponible, con lo que entró y salió este mes.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - 2. Últimos movimientos

/// Ícono de cada categoría, el equivalente del que muestra la app.
enum CategorySymbol {
    static func name(_ icon: String) -> String {
        switch icon {
        case "alimentacion": return "fork.knife"
        case "transporte": return "bus"
        case "servicios": return "bolt"
        case "compras": return "bag"
        case "entretenimiento": return "tv"
        case "otros": return "ellipsis"
        case "sueldo": return "wallet.bifold"
        case "transferenciaRecibida", "propia": return "arrow.left.arrow.right"
        case "venta": return "storefront"
        case "otrosIngresos": return "banknote"
        default: return "square.grid.2x2"
        }
    }
}

struct RecentView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MiGastoEntry

    private var large: Bool { family == .systemLarge }

    /// Lo que entra en el widget: 3 filas en el mediano; en el grande, las filas con el título de
    /// su día mientras quepan en el alto (fila 42 pt, título de día 24 pt, con su espacio).
    private func lines(_ d: WidgetData) -> [(header: String?, movement: WidgetData.Movement)] {
        var out: [(header: String?, movement: WidgetData.Movement)] = []
        var lastDay: String?
        var used: CGFloat = 0
        let budget: CGFloat = large ? 296 : 3
        for m in d.recent {
            let newDay = large && m.day != lastDay
            let cost: CGFloat = large ? 42 + (newDay ? 24 : 0) : 1
            if used + cost > budget { break }
            out.append((newDay ? m.day : nil, m))
            used += cost
            lastDay = m.day
        }
        return out
    }

    var body: some View {
        if let d = entry.data {
            VStack(alignment: .leading, spacing: large ? 6 : 5) {
                header(d)
                if d.recent.isEmpty {
                    empty
                } else {
                    ForEach(lines(d), id: \.movement.id) { line in
                        if let day = line.header { dayHeader(day, total: d.days[day]) }
                        Link(destination: MiGastoLink.movement(line.movement.id)) { row(line.movement) }
                    }
                    Spacer(minLength: 0)
                    if large {
                        Link(destination: MiGastoLink.movements) {
                            Text("Ver todos")
                                .font(Inter.semibold.font(13))
                                .foregroundStyle(Mg.accText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mg.accSoft))
                        }
                    }
                }
            }
            .foregroundStyle(Mg.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Movimientos").font(Inter.semibold.font(14)).foregroundStyle(Mg.ink)
                Spacer(minLength: 0)
                Text("Abre MiGasto para ver tus movimientos aquí")
                    .font(Inter.medium.font(13))
                    .foregroundStyle(Mg.ink2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func header(_ d: WidgetData) -> some View {
        HStack {
            Text("Movimientos").font(Inter.semibold.font(large ? 15 : 14))
            Spacer(minLength: 0)
            if d.pending > 0 {
                Text(d.pending == 1 ? "1 por confirmar" : "\(d.pending) por confirmar")
                    .font(Inter.semibold.font(11))
                    .foregroundStyle(Mg.warn)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Mg.warn.opacity(0.14)))
            }
        }
        .frame(height: 20)
        .padding(.bottom, large ? 2 : 1)
    }

    private func dayHeader(_ day: String, total: String?) -> some View {
        HStack {
            Text(WidgetData.dayLabel(day).uppercased())
            Spacer(minLength: 0)
            Text(total ?? "")
        }
        .font(Inter.semibold.font(11.5))
        .tracking(0.2)
        .monospacedDigit()
        .foregroundStyle(Mg.ink2)
        .padding(.top, 2)
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            Text("Aún no hay movimientos este mes")
                .font(Inter.medium.font(13))
                .foregroundStyle(Mg.ink2)
            Link(destination: MiGastoLink.newExpense) {
                Text("Registrar el primero")
                    .font(Inter.semibold.font(13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Mg.acc))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ m: WidgetData.Movement) -> some View {
        let tint = m.icon == "propia" ? Color(hex: "94A3B8") : Color(hex: m.color)
        let tile: CGFloat = large ? 32 : 30
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: large ? 10 : 9, style: .continuous).fill(tint.opacity(0.16))
                Image(systemName: CategorySymbol.name(m.icon))
                    .font(.system(size: large ? 15 : 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: tile, height: tile)
            VStack(alignment: .leading, spacing: 1) {
                Text(m.title)
                    .font(Inter.semibold.font(13.5))
                    .lineLimit(1)
                Text(m.pending ? "Por confirmar" : m.subtitle)
                    .font(Inter.medium.font(11.5))
                    .foregroundStyle(m.pending ? Mg.warn : Mg.ink2)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(m.amount)
                .font(Inter.semibold.font(13.5))
                .monospacedDigit()
                .foregroundStyle(amountColor(m))
                .lineLimit(1)
                .fixedSize()
        }
        .frame(height: large ? 36 : 33)
    }

    /// Ingresos en verde, gastos en rojo; entre tus cuentas y lo que espera confirmación, en gris.
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

// MARK: - 3. Registrar

struct QuickAddView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MiGastoEntry

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
                    Text("Registrar").font(.headline)
                    Text("gasto o ingreso").font(.caption)
                }
            }
        case .systemMedium:
            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.data == nil ? "Registrar" : "Hoy gastaste")
                        .font(Inter.medium.font(12.5))
                        .foregroundStyle(Mg.ink2)
                    Spacer(minLength: 0)
                    if let today = entry.data?.todaySpent {
                        Text(today)
                            .font(Inter.semibold.font(13.5))
                            .monospacedDigit()
                            .foregroundStyle(Mg.ink)
                    }
                }
                .padding(.horizontal, 2)
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
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(Mg.plusButton)
                    Image(systemName: "plus").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                VStack(spacing: 2) {
                    Text("Registrar").font(Inter.semibold.font(15)).foregroundStyle(Mg.ink)
                    Text("gasto o ingreso").font(Inter.medium.font(12)).foregroundStyle(Mg.ink2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func button(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.16))
                Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)
            Text(title).font(Inter.semibold.font(15)).foregroundStyle(Mg.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Mg.soft))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Mg.line, lineWidth: 1))
    }
}

struct QuickAddWidget: Widget {
    // Mismo `kind` que el widget anterior: los que ya lo tenían puesto no lo pierden.
    let kind = "MiGastoQuickAdd"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MiGastoProvider()) { entry in
            QuickAddView(entry: entry)
                .widgetURL(MiGastoLink.newExpense)
                .containerBackground(Mg.card, for: .widget)
        }
        .configurationDisplayName("Registrar")
        .description("Registra un gasto o un ingreso en segundos, y mira cuánto gastaste hoy.")
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
