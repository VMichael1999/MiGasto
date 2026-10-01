import AppIntents
import SwiftUI
import WidgetKit

/// Abre MiGasto en la pantalla de registro (`migasto://new`).
private let newMovementURL = URL(string: "migasto://new")!

// MARK: - Widget de pantalla de inicio y de pantalla bloqueada

struct QuickAddEntry: TimelineEntry {
    let date: Date
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry { QuickAddEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(QuickAddEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        completion(Timeline(entries: [QuickAddEntry(date: Date())], policy: .never))
    }
}

struct QuickAddView: View {
    @Environment(\.widgetFamily) private var family

    private let brand = Color(red: 0.55, green: 0.91, blue: 0.52)
    private let ink = Color(red: 0.06, green: 0.055, blue: 0.075)

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
        default:
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(ink)
                    Image(systemName: "plus").font(.title2.weight(.bold)).foregroundStyle(brand)
                }
                .frame(width: 44, height: 44)
                Spacer()
                Text("Registrar").font(.headline).foregroundStyle(ink)
                Text("Gasto o ingreso").font(.caption).foregroundStyle(ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct QuickAddWidget: Widget {
    let kind = "MiGastoQuickAdd"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { _ in
            QuickAddView()
                .widgetURL(newMovementURL)
                .containerBackground(Color(red: 0.55, green: 0.91, blue: 0.52), for: .widget)
        }
        .configurationDisplayName("Registrar movimiento")
        .description("Abre MiGasto para registrar un gasto o un ingreso en segundos.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Control del Centro de control (iOS 18)

@available(iOS 18.0, *)
struct OpenNewMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar movimiento"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(newMovementURL))
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
        QuickAddWidget()
        if #available(iOS 18.0, *) {
            QuickAddControl()
        }
    }
}
