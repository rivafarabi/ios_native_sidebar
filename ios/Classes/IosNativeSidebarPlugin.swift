import Flutter
import UIKit

public class IosNativeSidebarPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var sidebarContainer: SidebarContainerViewController?
    private var originalRootViewController: UIViewController?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = IosNativeSidebarPlugin()

        let method = FlutterMethodChannel(
            name: "ios_native_sidebar",
            binaryMessenger: registrar.messenger()
        )
        method.setMethodCallHandler(instance.handle)
        instance.methodChannel = method

        let event = FlutterEventChannel(
            name: "ios_native_sidebar/events",
            binaryMessenger: registrar.messenger()
        )
        event.setStreamHandler(instance)
        instance.eventChannel = event
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - Method Dispatch

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":    handleInitialize(call, result: result)
        case "updateItems":   handleUpdateItems(call, result: result)
        case "selectItem":    handleSelectItem(call, result: result)
        case "setSidebarVisible": handleSetSidebarVisible(call, result: result)
        case "teardown":      handleTeardown(result: result)
        default:              result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Handlers

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let styleStr = args["style"] as? String,
              let itemsData = args["items"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS",
                                message: "initialize requires {style, items}",
                                details: nil))
            return
        }

        let style: SidebarStyle = styleStr == "splitView" ? .splitView : .sidebarAdaptable
        let title = args["title"] as? String
        let largeTitleDisplayMode = args["largeTitleDisplayMode"] as? Bool ?? true
        let items = itemsData.compactMap { SidebarItemModel(dict: $0) }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let window = self.keyWindow else {
                result(FlutterError(code: "NO_WINDOW", message: "No key window found", details: nil))
                return
            }

            // Store original root VC so we can restore on teardown
            self.originalRootViewController = window.rootViewController

            let container = SidebarContainerViewController(
                style: style,
                title: title,
                largeTitleDisplayMode: largeTitleDisplayMode,
                items: items,
                contentViewController: window.rootViewController!,
                onEvent: { [weak self] event in
                    self?.eventSink?(event)
                }
            )
            self.sidebarContainer = container

            // Swap the root VC directly — no animation, no pre-load.
            // UIKit loads and lays out the container synchronously within the
            // current run-loop cycle before the next frame is composited, so
            // Flutter content appears immediately with no blank-frame gap.
            // Pre-loading container.view before this swap would detach the
            // Flutter view from the live window hierarchy and cause a crash.
            window.rootViewController = container

            self.eventSink?(["type": "initialized"])
            result(nil)
        }
    }

    private func handleUpdateItems(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let itemsData = args["items"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "updateItems requires {items}", details: nil))
            return
        }
        let items = itemsData.compactMap { SidebarItemModel(dict: $0) }
        DispatchQueue.main.async { [weak self] in
            self?.sidebarContainer?.updateItems(items)
            result(nil)
        }
    }

    private func handleSelectItem(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let itemId = args["itemId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "selectItem requires {itemId}", details: nil))
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.sidebarContainer?.selectItem(id: itemId)
            result(nil)
        }
    }

    private func handleSetSidebarVisible(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let visible = args["visible"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "setSidebarVisible requires {visible}", details: nil))
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.sidebarContainer?.setSidebarVisible(visible)
            result(nil)
        }
    }

    private func handleTeardown(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.keyWindow,
                  let original = self.originalRootViewController else {
                result(nil)
                return
            }
            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: { window.rootViewController = original }
            )
            self.sidebarContainer = nil
            self.originalRootViewController = nil
            result(nil)
        }
    }

    // MARK: - Helpers

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
