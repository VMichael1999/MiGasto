import Foundation

/// Cola de pagos que el código nativo de iPhone deja en un App Group.
///
/// Flutter es el único que escribe en la base de datos: la vacía con
/// `takeNativeQueue` al abrir la app y al volver a ella (igual que en Android),
/// porque Isar no se puede escribir desde Swift.
enum SharedQueue {
    static let groupId = "group.com.example.miGasto"
    private static let key = "migasto_native_queue"
    private static let lock = NSLock()

    private static var defaults: UserDefaults? { UserDefaults(suiteName: groupId) }

    /// Agrega un pago a la cola.
    static func enqueue(_ item: [String: Any]) {
        lock.lock()
        defer { lock.unlock() }
        guard let defaults = defaults else { return }
        var items = (defaults.array(forKey: key) as? [[String: Any]]) ?? []
        items.append(item)
        defaults.set(items, forKey: key)
    }

    /// Devuelve la cola como JSON y la vacía.
    static func take() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard let defaults = defaults else { return "[]" }
        let items = (defaults.array(forKey: key) as? [[String: Any]]) ?? []
        defaults.removeObject(forKey: key)
        guard JSONSerialization.isValidJSONObject(items),
              let data = try? JSONSerialization.data(withJSONObject: items),
              let text = String(data: data, encoding: .utf8) else { return "[]" }
        return text
    }
}
