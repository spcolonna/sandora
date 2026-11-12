import Flutter
import GameKit
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SandoraGames") {
      GameCenter.register(messenger: registrar.messenger())
    }
  }
}

/// Game Center (`sandora/games`): entra en silencio al abrir y guarda la
/// pantalla de inicio de sesión de Apple para cuando se toque "Game Center".
enum GameCenter {
  private static var channel: FlutterMethodChannel?
  private static var login: UIViewController?

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "sandora/games", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      switch call.method {
      case "auth":
        authenticate()
        result(nil)
      case "report":
        guard let args = call.arguments as? [String: Double] else { return result(false) }
        let list = args.map { id, percent -> GKAchievement in
          let a = GKAchievement(identifier: id)
          a.percentComplete = percent
          // El aviso grande es el del jardín.
          a.showsCompletionBanner = false
          return a
        }
        GKAchievement.report(list) { error in DispatchQueue.main.async { result(error == nil) } }
      case "show":
        result(show())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  private static func authenticate() {
    GKLocalPlayer.local.authenticateHandler = { vc, _ in
      login = vc
      // GameKit puede llamar desde otro hilo: Flutter solo se habla desde el principal.
      DispatchQueue.main.async { channel?.invokeMethod("auth", arguments: GKLocalPlayer.local.isAuthenticated) }
    }
  }

  private static func show() -> Bool {
    guard let top = topController() else { return false }
    if GKLocalPlayer.local.isAuthenticated {
      let gc: GKGameCenterViewController
      if #available(iOS 14.0, *) {
        gc = GKGameCenterViewController(state: .achievements)
      } else {
        gc = GKGameCenterViewController()
        gc.viewState = .achievements
      }
      gc.gameCenterDelegate = Dismisser.shared
      top.present(gc, animated: true)
      return true
    }
    guard let vc = login else { return false }
    login = nil
    top.present(vc, animated: true)
    return true
  }

  private static func topController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }

  private final class Dismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = Dismisser()
    func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) {
      vc.dismiss(animated: true)
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
