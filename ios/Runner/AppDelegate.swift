import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Los avisos locales (recordatorio y campana) también se ven con la app abierta.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SandoraCloud") {
      CloudStore.register(messenger: registrar.messenger())
    }
  }
}

/// La partida en el almacén clave-valor de iCloud (`sandora/cloud`): sigue a la
/// cuenta en todos sus aparatos y vuelve al reinstalar. Avisa a Dart cuando
/// otro aparato guardó o cuando iCloud terminó de bajar la copia.
enum CloudStore {
  private static var channel: FlutterMethodChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let store = NSUbiquitousKeyValueStore.default
    let ch = FlutterMethodChannel(name: "sandora/cloud", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      switch call.method {
      case "available":
        result(FileManager.default.ubiquityIdentityToken != nil)
      case "get":
        result(store.string(forKey: call.arguments as? String ?? ""))
      case "set":
        guard let args = call.arguments as? [String: Any], let key = args["key"] as? String,
          let value = args["value"] as? String
        else { return result(false) }
        store.set(value, forKey: key)
        result(store.synchronize())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store, queue: .main
    ) { _ in ch.invokeMethod("changed", arguments: nil) }
    store.synchronize()
    channel = ch
  }
}
