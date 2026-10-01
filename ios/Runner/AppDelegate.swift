import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // La clave llega desde el .env (ver ios/Flutter/*.xcconfig e Info.plist).
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Mismo canal que usa Android: Flutter vacía la cola de pagos y pide el permiso de avisos.
    let channel = FlutterMethodChannel(
      name: "com.example.mi_gasto/accessibility",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeNativeQueue":
        result(SharedQueue.take())
      case "requestNotificationPermission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
          DispatchQueue.main.async { result(granted) }
        }
      case "debugEnqueue":
        // La usa el probador de pagos de Ajustes (solo visible en desarrollo) para
        // simular lo que deja la acción de Atajos.
        if let item = call.arguments as? [String: Any] {
          SharedQueue.enqueue(item)
          result(true)
        } else {
          result(false)
        }
      case "openShortcuts":
        if let url = URL(string: "shortcuts://") {
          UIApplication.shared.open(url) { opened in result(opened) }
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
