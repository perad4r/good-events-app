import Flutter
import UIKit
import AudioToolbox
import AVFAudio
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
  private let callAudioChannel = "com.sukientot.app/call_audio"
  private let pushKitChannelName = "com.sukientot.app/pushkit"
  private var callAudioTimer: Timer?
  private var pushRegistry: PKPushRegistry?
  private var pushKitChannel: FlutterMethodChannel?
  private var callProvider: CXProvider?
  private var incomingCallPayloads: [UUID: [String: Any]] = [:]
  private var callUuidById: [String: UUID] = [:]
  private var acceptedCallUuid: UUID?
  private var isFlutterReadyForVoipEvents = false
  private var pendingVoipEvents: [[String: Any]] = []

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
        name: pushKitChannelName,
        binaryMessenger: pushKitRegistrar.messenger()
      )
      self.pushKitChannel = localPushKitChannel
      localPushKitChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
        switch call.method {
        case "getVoipToken":
          result(UserDefaults.standard.string(forKey: "pushkit_voip_token"))
        case "consumePendingVoipEvents":
          guard let self = self else {
            result([])
            return
          }
          self.isFlutterReadyForVoipEvents = true
          let events = self.pendingVoipEvents
          self.pendingVoipEvents.removeAll()
          result(events)
        case "endVoipCall":
          let callId = (call.arguments as? [String: Any])?["call_id"] as? String
          if let callId = callId {
            self.endCall(callId: callId, reason: .remoteEnded)
          }
          result(nil)
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
    emitVoipEvent(method: "voipTokenUpdated", payload: ["token": token])
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
    let eventType = data["type"] as? String
    let callId = stringValue(data["call_id"])

    if eventType == "call_ended" {
      emitVoipEvent(method: "voipCallEnded", payload: data)
      if let callId = callId {
        endCall(callId: callId, reason: .remoteEnded)
      }
      completion()
      return
    }

    // When Flutter is visible, use the app's incoming-call screen rather than
    // duplicating it with a CallKit alert. Background calls still use CallKit,
    // which is required for reliable VoIP delivery on iOS.
    if UIApplication.shared.applicationState == .active {
      emitVoipEvent(method: "voipIncomingCall", payload: data)
      completion()
      return
    }

    if let callId = callId, callUuidById[callId] != nil {
      completion()
      return
    }
    let callUuid = UUID()
    incomingCallPayloads[callUuid] = data
    if let callId = callId {
      callUuidById[callId] = callUuid
    }
    let callerName = data["initiator_name"] as? String ?? "Cuộc gọi đến"
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = false
    guard let callProvider = callProvider else {
      removeCall(callUuid: callUuid)
      completion()
      return
    }
    callProvider.reportNewIncomingCall(with: callUuid, update: update) { error in
      if error != nil { self.removeCall(callUuid: callUuid) }
      completion()
    }
  }

  func providerDidReset(_ provider: CXProvider) {
    incomingCallPayloads.removeAll()
    callUuidById.removeAll()
    acceptedCallUuid = nil
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    if let payload = incomingCallPayloads[action.callUUID] {
      acceptedCallUuid = action.callUUID
      emitVoipEvent(method: "voipCallAnswered", payload: payload)
    }
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    if let payload = incomingCallPayloads[action.callUUID] {
      emitVoipEvent(method: "voipCallEnded", payload: payload)
    }
    removeCall(callUuid: action.callUUID)
    action.fulfill()
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    guard let callUuid = acceptedCallUuid,
          let payload = incomingCallPayloads[callUuid] else { return }
    emitVoipEvent(method: "voipAudioSessionActivated", payload: payload)
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    guard let callUuid = acceptedCallUuid,
          let payload = incomingCallPayloads[callUuid] else { return }
    emitVoipEvent(method: "voipAudioSessionDeactivated", payload: payload)
  }

  private func emitVoipEvent(method: String, payload: [String: Any]) {
    guard isFlutterReadyForVoipEvents else {
      pendingVoipEvents.append(["method": method, "payload": payload])
      return
    }
    pushKitChannel?.invokeMethod(method, arguments: payload)
  }

  private func endCall(callId: String, reason: CXCallEndedReason) {
    guard let callUuid = callUuidById[callId] else { return }
    callProvider?.reportCall(with: callUuid, endedAt: Date(), reason: reason)
    removeCall(callUuid: callUuid)
  }

  private func removeCall(callUuid: UUID) {
    if let callId = stringValue(incomingCallPayloads[callUuid]?["call_id"]) {
      callUuidById.removeValue(forKey: callId)
    }
    incomingCallPayloads.removeValue(forKey: callUuid)
    if acceptedCallUuid == callUuid {
      acceptedCallUuid = nil
    }
  }

  private func stringValue(_ value: Any?) -> String? {
    guard let value = value else { return nil }
    return String(describing: value)
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
