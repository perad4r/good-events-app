import Flutter
import UIKit
import AudioToolbox
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
  private let callAudioChannel = "com.sukientot.app/call_audio"
  private var callAudioTimer: Timer?
  private var pushRegistry: PKPushRegistry?
  private var pushKitChannel: FlutterMethodChannel?
  private var callProvider: CXProvider?
  private var incomingCallPayloads: [UUID: [String: Any]] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "CallAudioPlugin") {
      let channel = FlutterMethodChannel(
        name: callAudioChannel,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
        switch call.method {
        case "playIncoming":
          self?.startSystemSound(id: 1005, interval: 2.2)
          result(nil)
        case "playOutgoing":
          self?.startSystemSound(id: 1151, interval: 2.5)
          result(nil)
        case "stop":
          self?.stopCallAudio()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    if let pushKitRegistrar = self.registrar(forPlugin: "PushKitBridge") {
      let localPushKitChannel = FlutterMethodChannel(
        name: "com.sukientot.app/pushkit",
        binaryMessenger: pushKitRegistrar.messenger()
      )
      self.pushKitChannel = localPushKitChannel
      localPushKitChannel.setMethodCallHandler { (call: FlutterMethodCall, result: FlutterResult) in
        switch call.method {
        case "getVoipToken":
          result(UserDefaults.standard.string(forKey: "pushkit_voip_token"))
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    self.pushRegistry = registry
    let providerConfiguration = CXProviderConfiguration(localizedName: "Sự kiện tốt")
    providerConfiguration.supportsVideo = false
    providerConfiguration.maximumCallsPerCallGroup = 1
    providerConfiguration.supportedHandleTypes = [.generic]
    let provider = CXProvider(configuration: providerConfiguration)
    provider.setDelegate(self, queue: .main)
    self.callProvider = provider
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set(token, forKey: "pushkit_voip_token")
    pushKitChannel?.invokeMethod("voipTokenUpdated", arguments: token)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    guard type == .voIP else { return }
    UserDefaults.standard.removeObject(forKey: "pushkit_voip_token")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let data = payload.dictionaryPayload.reduce(into: [String: Any]()) {
      if let key = $1.key as? String { $0[key] = $1.value }
    }
    let callUuid = UUID()
    incomingCallPayloads[callUuid] = data
    let callerName = data["initiator_name"] as? String ?? "Cuộc gọi đến"
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = false
    guard let callProvider = callProvider else {
      incomingCallPayloads.removeValue(forKey: callUuid)
      completion()
      return
    }
    callProvider.reportNewIncomingCall(with: callUuid, update: update) { error in
      if error != nil { self.incomingCallPayloads.removeValue(forKey: callUuid) }
      completion()
    }
  }

  func providerDidReset(_ provider: CXProvider) {
    incomingCallPayloads.removeAll()
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    if let payload = incomingCallPayloads[action.callUUID] {
      pushKitChannel?.invokeMethod("voipCallAnswered", arguments: payload)
    }
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    if let payload = incomingCallPayloads.removeValue(forKey: action.callUUID) {
      pushKitChannel?.invokeMethod("voipCallEnded", arguments: payload)
    }
    action.fulfill()
  }

  private func startSystemSound(id: SystemSoundID, interval: TimeInterval) {
    stopCallAudio()
    AudioServicesPlaySystemSound(id)
    callAudioTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
      AudioServicesPlaySystemSound(id)
    }
  }

  private func stopCallAudio() {
    callAudioTimer?.invalidate()
    callAudioTimer = nil
  }
}
