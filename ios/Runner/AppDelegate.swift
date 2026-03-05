import UIKit
import Flutter
import PushKit
import CallKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate,
                         PKPushRegistryDelegate,
                         CXProviderDelegate {

  // MARK: - Properties
  private var flutterChannel: FlutterMethodChannel?
  private var callProvider: CXProvider?
  private var callController: CXCallController?
  private var voipRegistry: PKPushRegistry?
  private var currentCallUUID: UUID?
  private var hasNotifiedFlutter = false
  private var callAcceptedTime: Date? // ⭐ NEW: Track when call was accepted
  private var isCallActive = false    // ⭐ NEW: Track if call is actually active
  private var callTimeoutTimer: Timer?

  // MARK: - App Launch
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("RootViewController is not FlutterViewController")
    }

    flutterChannel = FlutterMethodChannel(
      name: "picturo_call_service",
      binaryMessenger: controller.binaryMessenger
    )

    // 🔴 REQUIRED: Flutter → iOS bridge
    flutterChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "endCall":
        self?.endCurrentCall()
        result(nil)
      case "callConnected": // ⭐ NEW: Flutter notifies when call is connected
        self?.markCallAsActive()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    setupVoIPPush()
    setupCallKit()

    GeneratedPluginRegistrant.register(with: self)
    return result
  }

  // MARK: - PushKit Setup
  private func setupVoIPPush() {
    voipRegistry = PKPushRegistry(queue: .main)
    voipRegistry?.delegate = self
    voipRegistry?.desiredPushTypes = [.voIP]
    print("🚀 PushKit initialized")
  }

  // MARK: - CallKit Setup
  private func setupCallKit() {
    let config = CXProviderConfiguration(localizedName: "Picturo")
    config.supportsVideo = false
    config.maximumCallsPerCallGroup = 1
    config.maximumCallGroups = 1
    config.supportedHandleTypes = [.generic]
    config.includesCallsInRecents = false

    callProvider = CXProvider(configuration: config)
    callProvider?.setDelegate(self, queue: nil)

    callController = CXCallController()
    print("📞 CallKit configured")
  }

  // MARK: - VoIP Token
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let token = pushCredentials.token
      .map { String(format: "%02x", $0) }
      .joined()

    print("📞 VoIP Token received:", token)

    flutterChannel?.invokeMethod(
      "onVoIPToken",
      arguments: ["token": token]
    )
  }

  // MARK: - Receive VoIP Push
  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {

    let data = payload.dictionaryPayload

    let callerId = data["caller_id"] as? String ?? "0"
    let callerName = data["caller_username"] as? String ?? "Unknown"
    let receiverId = data["receiver_id"] as? String ?? "0"

    print("📞 ========================================")
    print("📞 VoIP Push Received")
    print("📞 Caller: \(callerName) (ID: \(callerId))")
    print("📞 Receiver: \(receiverId)")
    print("📞 ========================================")

    // Persist data for accept callback
    UserDefaults.standard.set(callerId, forKey: "caller_id")
    UserDefaults.standard.set(callerName, forKey: "caller_username")
    UserDefaults.standard.set(receiverId, forKey: "receiver_id")
    UserDefaults.standard.synchronize()

    let uuid = UUID()
    currentCallUUID = uuid
    hasNotifiedFlutter = false
    isCallActive = false // ⭐ Reset call active state

    callTimeoutTimer?.invalidate()
  callTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
    guard let self = self else { return }
    
    print("⏰ ========================================")
    print("⏰ CALL TIMEOUT (30s)")
    print("⏰ isCallActive: \(self.isCallActive)")
    print("⏰ hasNotifiedFlutter: \(self.hasNotifiedFlutter)")
    print("⏰ ========================================")
    
    // If call never became active, end it
    if !self.isCallActive {
      print("⏰ Call never connected - ending due to timeout")
      self.endCurrentCall()
    }
  }

    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = false

    callProvider?.reportNewIncomingCall(with: uuid, update: update) { error in
      if let error = error {
        print("❌ Error reporting incoming call: \(error.localizedDescription)")
      } else {
        print("✅ Incoming call reported to CallKit")
      }
      completion()
    }
  }

  // MARK: - Call Accepted (CRITICAL)
  // MARK: - Call Accepted (CRITICAL)
func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
  print("📞 ========================================")
  print("📞 CALL ACCEPTED VIA CALLKIT")
  print("📞 UUID: \(action.callUUID.uuidString)")
  print("📞 Timestamp: \(Date())")
  print("📞 ========================================")
  
  // Fulfill immediately - this activates the audio session
  action.fulfill()
  
  // Prevent duplicate notifications
  guard !hasNotifiedFlutter else {
    print("⚠️ Flutter already notified, skipping duplicate")
    return
  }
  
  hasNotifiedFlutter = true
  callAcceptedTime = Date() // ⭐ Track when call was accepted
  
  // ⭐ CRITICAL: Notify Flutter IMMEDIATELY (no delay)
  print("✅ Notifying Flutter NOW (no delay)")
  
  self.flutterChannel?.invokeMethod(
    "onCallAccepted",
    arguments: [
      "caller_id": UserDefaults.standard.string(forKey: "caller_id") ?? "",
      "caller_username": UserDefaults.standard.string(forKey: "caller_username") ?? "",
      "receiver_id": UserDefaults.standard.string(forKey: "receiver_id") ?? ""
    ]
  )
  
  print("✅ Flutter notified of call acceptance")
}

  // ⭐ NEW: Mark call as active (called from Flutter)
  // ⭐ NEW: Mark call as active (called from Flutter)
private func markCallAsActive() {
  print("📞 ========================================")
  print("📞 MARK CALL AS ACTIVE CALLED")
  print("📞 Current state:")
  print("📞   - isCallActive: \(isCallActive)")
  print("📞   - hasNotifiedFlutter: \(hasNotifiedFlutter)")
  print("📞   - currentCallUUID: \(currentCallUUID?.uuidString ?? "nil")")
  
  if let acceptTime = callAcceptedTime {
    let elapsed = Date().timeIntervalSince(acceptTime)
    print("📞   - Time since accept: \(String(format: "%.2f", elapsed))s")
  } else {
    print("📞   - No accept time recorded")
  }
  
  print("📞 ========================================")
  
  // Make idempotent
  if isCallActive {
    print("⚠️ Call already marked as active")
    return
  }
  
  isCallActive = true

  callTimeoutTimer?.invalidate()
  callTimeoutTimer = nil
  print("✅ Timeout timer cancelled (call is active)")
  
  // ⭐ If no accept time yet, set it now
  // This can happen if markCallAsActive is called before CXAnswerCallAction completes
  if callAcceptedTime == nil {
    callAcceptedTime = Date()
    print("⚠️ Setting accept time now (was nil)")
  }
  
  print("✅ ========================================")
  print("✅ CALL NOW MARKED AS ACTIVE")
  print("✅ Time: \(Date())")
  print("✅ ========================================")
}

  // MARK: - Call Declined / Ended (FIXED)
  // MARK: - Call Declined / Ended (FIXED)
func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
  print("📞 ========================================")
  print("📞 CXEndCallAction TRIGGERED")
  print("📞 Timestamp: \(Date())")
  print("📞 State:")
  print("📞   - isCallActive: \(isCallActive)")
  print("📞   - hasNotifiedFlutter: \(hasNotifiedFlutter)")
  print("📞   - UUID: \(action.callUUID.uuidString)")
  
  if let acceptTime = callAcceptedTime {
    let duration = Date().timeIntervalSince(acceptTime)
    print("📞   - Duration: \(String(format: "%.2f", duration))s")
  } else {
    print("📞   - No accept time (never accepted)")
  }
  
  print("📞 Call stack (first 5 frames):")
  Thread.callStackSymbols.prefix(5).forEach { print("  \($0)") }
  print("📞 ========================================")
  
  // Capture state before clearing
  let wasActive = isCallActive
  let timeSinceAccept = callAcceptedTime != nil ? Date().timeIntervalSince(callAcceptedTime!) : 0
  
  // Clean up state FIRST
  hasNotifiedFlutter = false
  isCallActive = false
  callAcceptedTime = nil
  currentCallUUID = nil
  callTimeoutTimer?.invalidate()
  callTimeoutTimer = nil
  
  // Fulfill the action
  action.fulfill()
  
  // Decision tree
  if wasActive {
    // Call was active - normal end, Flutter already knows
    print("✅ Normal call end (was active for \(String(format: "%.1f", timeSinceAccept))s)")
    return
  }
  
  if timeSinceAccept > 0 && timeSinceAccept < 5 {
    // Suspicious timing - likely race condition
    print("⚠️ Race condition detected (ended \(String(format: "%.2f", timeSinceAccept))s after accept)")
    print("⚠️ Not sending decline - letting Flutter handle it")
    return
  }
  
  if timeSinceAccept == 0 {
    // User declined before answering
    print("❌ User declined incoming call")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      self.flutterChannel?.invokeMethod(
        "onCallDeclined",
        arguments: [
          "caller_id": UserDefaults.standard.string(forKey: "caller_id") ?? "",
          "receiver_id": UserDefaults.standard.string(forKey: "receiver_id") ?? ""
        ]
      )
    }
    return
  }
  
  // Call failed to connect after 5+ seconds
  print("❌ Call connection failed (\(String(format: "%.1f", timeSinceAccept))s)")
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    self.flutterChannel?.invokeMethod(
      "onCallEnded",
      arguments: [
        "caller_id": UserDefaults.standard.string(forKey: "caller_id") ?? "",
        "duration": 0,
        "error": "Connection failed"
      ]
    )
  }
}

  // MARK: - Audio Session Callbacks
  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    print("🔊 Audio session activated by CallKit")
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    print("🔇 Audio session deactivated by CallKit")
  }

  // MARK: - End Call from Flutter
  private func endCurrentCall() {
  print("📞 ========================================")
  print("📞 END CURRENT CALL REQUESTED")
  print("📞 currentCallUUID: \(currentCallUUID?.uuidString ?? "nil")")
  print("📞 isCallActive: \(isCallActive)")
  print("📞 ========================================")
  
  guard let uuid = currentCallUUID else {
    print("⚠️ No call to end (UUID is nil)")
    return
  }
  
  // ⭐ FIX: Don't try to end if already ended
  // Check if this UUID is still in CallKit's active calls
  let activeCallUUIDs = callController?.callObserver.calls.map { $0.uuid } ?? []
  
  if !activeCallUUIDs.contains(uuid) {
    print("⚠️ Call UUID not found in active calls - already ended")
    print("⚠️ Active calls: \(activeCallUUIDs.map { $0.uuidString })")
    
    // Clean up state
    currentCallUUID = nil
    hasNotifiedFlutter = false
    isCallActive = false
    callAcceptedTime = nil
    callTimeoutTimer?.invalidate()
    callTimeoutTimer = nil
    
    return
  }
  
  print("📞 Requesting CXEndCallAction")
  
  let endAction = CXEndCallAction(call: uuid)
  let transaction = CXTransaction(action: endAction)
  
  callController?.request(transaction) { error in
    if let error = error {
      print("❌ End call error: \(error.localizedDescription)")
    } else {
      print("✅ Call ended successfully via transaction")
    }
  }
  
  // Clean up immediately (don't wait for callback)
  currentCallUUID = nil
  hasNotifiedFlutter = false
  isCallActive = false
  callAcceptedTime = nil
  callTimeoutTimer?.invalidate()
  callTimeoutTimer = nil
}

  // MARK: - Provider Reset
  func providerDidReset(_ provider: CXProvider) {
    print("🔄 CallKit provider reset")
    
    currentCallUUID = nil
    hasNotifiedFlutter = false
    isCallActive = false
    callAcceptedTime = nil

    UserDefaults.standard.removeObject(forKey: "caller_id")
    UserDefaults.standard.removeObject(forKey: "caller_username")
    UserDefaults.standard.removeObject(forKey: "receiver_id")
  }
}