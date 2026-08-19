import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/core/services/call_ringtone_service.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/services/notification_service.dart';
import 'package:sukientotapp/data/models/common/call_model.dart';
import 'package:sukientotapp/domain/repositories/common/call_repository.dart';

enum LocalCallState {
  idle,
  creating,
  ringing,
  joining,
  connected,
  reconnecting,
  leaving,
  ended,
  failed,
}

/// Owns the single Agora engine and coordinates server call state with RTC state.
/// Widgets should invoke these actions instead of calling HTTP or Agora directly.
class CallCoordinator extends GetxService with WidgetsBindingObserver {
  CallCoordinator(this._repository);

  static const Duration loneParticipantTimeout = Duration(minutes: 2);
  static const Duration declinedCallUiDelay = Duration(seconds: 2);
  static Future<void>? _activeAgoraConnection;
  static String? _activeAgoraCallId;

  final CallRepository _repository;
  final Rx<CallModel?> activeCall = Rx<CallModel?>(null);
  final Rx<LocalCallState> localState = LocalCallState.idle.obs;
  final RxBool isMuted = false.obs;
  final RxBool isSpeakerEnabled = true.obs;
  final RxSet<int> remoteUids = <int>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxString audioDebugState = ''.obs;
  final RxString threadTitle = ''.obs;
  final RxString endedStateMessage = 'Cuộc gọi đã kết thúc'.obs;
  final RxInt callDurationSeconds = 0.obs;
  final RxBool hasPendingCallRecovery = false.obs;
  final RxBool isCallRecoveryInProgress = false.obs;

  RtcEngine? _engine;
  String? _currentThreadId;
  bool _actionInProgress = false;
  bool _isInChannel = false;
  bool _recoveryCheckInProgress = false;
  Timer? _loneParticipantTimer;
  Timer? _callDurationTimer;

  void setThreadContext({required String threadId, required String title}) {
    if (_currentThreadId != null && _currentThreadId != threadId) {
      threadTitle.value = '';
    }
    _currentThreadId = threadId;
    threadTitle.value = title.trim();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(disposeCall(notifyServer: false));
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_isInChannel && _hasPersistedCall) {
      unawaited(preparePersistedCallRecovery());
    } else if (_currentThreadId != null) {
      unawaited(reconcile(_currentThreadId!));
    }
  }

  bool get _hasPersistedCall => StorageService.checkData(
    key: LocalStorageKeys.activeCallRecovery,
  );

  Future<void> preparePersistedCallRecovery() async {
    if (_recoveryCheckInProgress || _isInChannel) return;
    final recovery = StorageService.readMapData(
      key: LocalStorageKeys.activeCallRecovery,
    );
    final callId = recovery is Map<String, dynamic>
        ? recovery['call_id']?.toString()
        : null;
    final threadId = recovery is Map<String, dynamic>
        ? recovery['thread_id']?.toString()
        : null;
    final savedUserId = recovery is Map<String, dynamic>
        ? int.tryParse(recovery['user_id']?.toString() ?? '')
        : null;
    final currentUserId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    if (callId == null ||
        callId.isEmpty ||
        threadId == null ||
        threadId.isEmpty ||
        savedUserId == null ||
        savedUserId != currentUserId) {
      _clearPersistedCall();
      return;
    }

    // Keep the banner hidden until the backend confirms that this exact call
    // is still active. A local marker can outlive a call when the app was
    // terminated before receiving the call-ended event.
    hasPendingCallRecovery.value = false;
    _recoveryCheckInProgress = true;
    try {
      final call = await _repository.active(threadId);
      if (call == null ||
          call.id != callId ||
          call.status == CallStatus.ended) {
        _clearPersistedCall(callId);
        return;
      }
      hasPendingCallRecovery.value = true;
    } on CallApiException catch (error) {
      if (error.statusCode == 403 ||
          error.statusCode == 404 ||
          error.statusCode == 409) {
        _clearPersistedCall(callId);
      } else {
        logger.w(
          '[CallCoordinator] Unable to validate call recovery yet: '
          '${error.message}',
        );
      }
    } catch (error, stackTrace) {
      logger.e(
        '[CallCoordinator] Failed to validate persisted call recovery',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _recoveryCheckInProgress = false;
    }
  }

  /// Restores a call after process termination using fresh server state and
  /// fresh Agora credentials. Tokens are deliberately never stored locally.
  Future<bool> restorePersistedCall() async {
    if (_actionInProgress || _isInChannel) return false;
    final recovery = StorageService.readMapData(
      key: LocalStorageKeys.activeCallRecovery,
    );
    if (recovery is! Map<String, dynamic>) return false;

    final callId = recovery['call_id']?.toString();
    final threadId = recovery['thread_id']?.toString();
    final savedUserId = int.tryParse(recovery['user_id']?.toString() ?? '');
    final currentUserId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    if (callId == null ||
        callId.isEmpty ||
        threadId == null ||
        threadId.isEmpty ||
        savedUserId == null ||
        savedUserId != currentUserId) {
      _clearPersistedCall();
      return false;
    }

    _actionInProgress = true;
    isCallRecoveryInProgress.value = true;
    _currentThreadId = threadId;
    errorMessage.value = '';
    try {
      final call = await _repository.active(threadId);
      if (call == null ||
          call.id != callId ||
          call.status == CallStatus.ended) {
        _clearPersistedCall(callId);
        activeCall.value = null;
        localState.value = LocalCallState.ended;
        return false;
      }

      activeCall.value = call;
      final session = await _repository.join(callId);
      activeCall.value = session.call;
      await _connect(session);
      hasPendingCallRecovery.value = false;
      unawaited(NotificationService.markIncomingCallConnected(callId));
      logger.i('[CallCoordinator] Restored active call $callId.');
      return true;
    } on CallApiException catch (error) {
      if (error.statusCode == 403 ||
          error.statusCode == 404 ||
          error.statusCode == 409) {
        _clearPersistedCall(callId);
        activeCall.value = null;
        localState.value = LocalCallState.ended;
      } else {
        errorMessage.value = error.message;
        activeCall.value = null;
        localState.value = LocalCallState.idle;
        logger.w(
          '[CallCoordinator] Call recovery deferred: ${error.message}',
        );
      }
      return false;
    } catch (error, stackTrace) {
      await disposeCall(notifyServer: false);
      activeCall.value = null;
      localState.value = LocalCallState.idle;
      errorMessage.value = 'Không thể kết nối lại cuộc gọi.';
      logger.e(
        '[CallCoordinator] Failed to restore active call',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _actionInProgress = false;
      isCallRecoveryInProgress.value = false;
    }
  }

  Future<bool> leavePersistedCall() async {
    if (_actionInProgress || _isInChannel) return false;
    final recovery = StorageService.readMapData(
      key: LocalStorageKeys.activeCallRecovery,
    );
    if (recovery is! Map<String, dynamic>) {
      _clearPersistedCall();
      return true;
    }
    final callId = recovery['call_id']?.toString();
    final threadId = recovery['thread_id']?.toString();
    if (callId == null || threadId == null) {
      _clearPersistedCall();
      return true;
    }

    _actionInProgress = true;
    isCallRecoveryInProgress.value = true;
    try {
      final call = await _repository.active(threadId);
      if (call != null && call.id == callId) {
        final currentUserId =
            StorageService.readMapData(
                  key: LocalStorageKeys.user,
                  mapKey: 'id',
                )
                as int?;
        final shouldEnd =
            call.initiator?.id == currentUserId &&
            call.participants.length <= 1;
        if (shouldEnd) {
          await _repository.end(callId);
        } else {
          await _repository.leave(callId);
        }
      }
      _clearPersistedCall(callId);
      activeCall.value = null;
      localState.value = LocalCallState.idle;
      return true;
    } on CallApiException catch (error) {
      if (error.statusCode == 403 ||
          error.statusCode == 404 ||
          error.statusCode == 409) {
        _clearPersistedCall(callId);
        return true;
      }
      errorMessage.value = error.message;
      return false;
    } finally {
      _actionInProgress = false;
      isCallRecoveryInProgress.value = false;
    }
  }

  Future<CallSession?> createAudioCall({
    required String threadId,
    required List<int> invitedUserIds,
  }) async {
    if (_actionInProgress || invitedUserIds.isEmpty) return null;
    _actionInProgress = true;
    _currentThreadId = threadId;
    endedStateMessage.value = 'Cuộc gọi đã kết thúc';
    localState.value = LocalCallState.creating;
    errorMessage.value = '';
    try {
      final session = await _repository.create(
        threadId: threadId,
        type: CallType.audio,
        invitedUserIds: invitedUserIds,
      );
      activeCall.value = session.call;
      await CallRingtoneService.playOutgoing();
      await _connect(session);
      unawaited(NotificationService.markIncomingCallConnected(session.call.id));
      return session;
    } on CallApiException catch (error) {
      await CallRingtoneService.stop();
      if (error.statusCode == 409) {
        await reconcile(threadId);
      } else {
        _fail(error.message);
      }
      return null;
    } catch (error, stackTrace) {
      await CallRingtoneService.stop();
      logger.e(
        '[CallCoordinator] Failed to initialize outgoing call',
        error: error,
        stackTrace: stackTrace,
      );
      _fail('Không thể khởi tạo âm thanh cuộc gọi.');
      return null;
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> reconcile(String threadId) async {
    if (_currentThreadId != null && _currentThreadId != threadId) {
      threadTitle.value = '';
    }
    _currentThreadId = threadId;
    try {
      final call = await _repository.active(threadId);
      if (call == null || call.status == CallStatus.ended) {
        _clearPersistedCallForThread(threadId);
        activeCall.value = null;
        if (_isInChannel) await disposeCall(notifyServer: false);
        return;
      }
      activeCall.value = call;
      if (!_isInChannel) {
        localState.value = LocalCallState.ringing;
        final currentUserId =
            StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
                as int?;
        final hasPendingInvite = call.invitedUsers.any(
          (user) =>
              user.id == currentUserId &&
              user.status == CallInviteStatus.pending,
        );
        if (hasPendingInvite) await CallRingtoneService.playIncoming();
      }
    } on CallApiException catch (error) {
      if (error.statusCode == 404) activeCall.value = null;
      logger.w(
        '[CallCoordinator] Active call reconcile failed: ${error.message}',
      );
    }
  }

  Future<CallSession?> joinActiveCall() async {
    final call = activeCall.value;
    if (call == null || _actionInProgress || _isInChannel) return null;
    _actionInProgress = true;
    errorMessage.value = '';
    try {
      await NotificationService.cancelIncomingCall(call.id, accepted: true);
      await CallRingtoneService.stop();
      final session = await _repository.join(call.id);
      activeCall.value = session.call;
      await _connect(session);
      // Repeat cleanup after connecting. A delayed FCM/CallKit event may have
      // recreated the incoming alert while the join request was in flight.
      await NotificationService.cancelIncomingCall(call.id, accepted: true);
      await CallRingtoneService.stop();
      unawaited(NotificationService.markIncomingCallConnected(call.id));
      return session;
    } on CallApiException catch (error) {
      if (error.statusCode == 403 ||
          error.statusCode == 404 ||
          error.statusCode == 409) {
        _clearPersistedCall(call.id);
        await NotificationService.cancelIncomingCall(call.id);
        await CallRingtoneService.stop();
        activeCall.value = null;
        localState.value = LocalCallState.ended;
      } else {
        _handleApiFailure(error);
      }
      return null;
    } catch (error, stackTrace) {
      await CallRingtoneService.stop();
      logger.e(
        '[CallCoordinator] Failed to join Agora call',
        error: error,
        stackTrace: stackTrace,
      );
      _fail('Không thể kết nối âm thanh cuộc gọi.');
      return null;
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> leave() async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    localState.value = LocalCallState.leaving;
    final callId = activeCall.value?.id;
    final threadId = _currentThreadId;
    final currentUserId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    final isInitiator = activeCall.value?.initiator?.id == currentUserId;
    bool endedCall = false;
    try {
      if (callId != null && isInitiator && remoteUids.isEmpty) {
        await _repository.end(callId);
        endedCall = true;
      } else if (callId != null) {
        await _repository.leave(callId);
      }
    } on CallApiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      await disposeCall(notifyServer: false);
      _clearPersistedCall(callId);
      activeCall.value = null;
      _actionInProgress = false;
      if (endedCall) {
        localState.value = LocalCallState.ended;
      } else if (threadId != null) {
        await reconcile(threadId);
      }
    }
  }

  Future<void> decline() async {
    final call = activeCall.value;
    if (call == null || _actionInProgress) return;
    _actionInProgress = true;
    try {
      await NotificationService.cancelIncomingCall(call.id);
      await CallRingtoneService.stop();
      await _repository.decline(call.id);
      _clearPersistedCall(call.id);
      activeCall.value = null;
      localState.value = LocalCallState.idle;
    } on CallApiException catch (error) {
      if (error.statusCode == 409) {
        _clearPersistedCall(call.id);
        activeCall.value = null;
        localState.value = LocalCallState.idle;
        await reconcile(call.threadId.toString());
      } else {
        _handleApiFailure(error);
      }
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> end() async {
    final call = activeCall.value;
    if (call == null || _actionInProgress) return;
    _actionInProgress = true;
    try {
      await CallRingtoneService.stop();
      await _repository.end(call.id);
      await disposeCall(notifyServer: false);
      _clearPersistedCall(call.id);
      activeCall.value = null;
      localState.value = LocalCallState.ended;
    } on CallApiException catch (error) {
      _handleApiFailure(error);
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> setMuted(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
    isMuted.value = muted;
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    await _applySpeakerRoute(enabled);
  }

  Future<void> handleRealtimeCall(Map<String, dynamic> payload) async {
    final raw = payload['call'];
    if (raw is! Map<String, dynamic>) return;
    final incoming = CallModel.fromJson(raw);
    final current = activeCall.value;
    if (current != null && current.id != incoming.id) return;
    if (incoming.status == CallStatus.ended) {
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final wasDeclinedByAllInvitees =
          incoming.initiator?.id == currentUserId &&
          incoming.invitedUsers.isNotEmpty &&
          incoming.invitedUsers.every(
            (user) => user.status == CallInviteStatus.declined,
          ) &&
          !incoming.participants.any((user) => user.id != currentUserId);

      endedStateMessage.value = wasDeclinedByAllInvitees
          ? 'Cuộc gọi đã bị từ chối'
          : 'Cuộc gọi đã kết thúc';
      activeCall.value = incoming;
      await disposeCall(notifyServer: false);
      _clearPersistedCall(incoming.id);
      localState.value = LocalCallState.ended;
      if (wasDeclinedByAllInvitees) {
        await Future<void>.delayed(declinedCallUiDelay);
      }
      if (activeCall.value?.id == incoming.id) activeCall.value = null;
      return;
    }
    await reconcile(incoming.threadId.toString());
  }

  /// FCM is only a ringing signal. Credentials are fetched only after accept.
  Future<void> handleIncomingNotification(Map<String, dynamic> data) async {
    if (data['type']?.toString() != 'incoming_call') return;
    final callId = data['call_id']?.toString();
    final threadId = int.tryParse(data['thread_id']?.toString() ?? '');
    if (threadId == null) return;
    await reconcile(threadId.toString());
    if (activeCall.value?.id != callId && callId != null) {
      await NotificationService.cancelIncomingCall(callId);
      await CallRingtoneService.stop();
      localState.value = LocalCallState.ended;
    }
  }

  Future<void> handleCallEndedSignal(String callId) async {
    _clearPersistedCall(callId);
    if (activeCall.value?.id == callId) {
      await disposeCall(notifyServer: false);
      activeCall.value = null;
      localState.value = LocalCallState.ended;
    } else {
      await CallRingtoneService.stop();
    }
  }

  Future<void> _connect(CallSession session) async {
    final activeConnection = _activeAgoraConnection;
    if (activeConnection != null && _activeAgoraCallId == session.call.id) {
      logger.w(
        '[CallCoordinator] Duplicate Agora connect ignored for ${session.call.id}',
      );
      await activeConnection;
      return;
    }

    final connection = _connectOnce(session);
    _activeAgoraCallId = session.call.id;
    _activeAgoraConnection = connection;
    try {
      await connection;
    } finally {
      if (identical(_activeAgoraConnection, connection)) {
        _activeAgoraConnection = null;
        _activeAgoraCallId = null;
      }
    }
  }

  Future<void> _connectOnce(CallSession session) async {
    if (session.call.type != CallType.audio) {
      throw const CallApiException(
        message: 'Ứng dụng hiện chỉ hỗ trợ cuộc gọi âm thanh.',
      );
    }
    localState.value = LocalCallState.joining;
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const CallApiException(
        message: 'Bạn cần cấp quyền microphone để gọi.',
      );
    }

    await _releaseEngine();
    remoteUids.clear();
    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(RtcEngineContext(appId: session.credentials.appId));
    final joinedChannel = Completer<void>();
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _isInChannel = true;
          localState.value = LocalCallState.connected;
          if (!joinedChannel.isCompleted) joinedChannel.complete();
          unawaited(_applySpeakerRoute(isSpeakerEnabled.value));
          logger.i(
            '[CallCoordinator] Joined Agora channel uid=${connection.localUid}',
          );
          _startCallDurationTimer(session.call.startedAt);
          _startLoneParticipantTimer(session.call.id);
          if (session.call.initiator?.id != session.credentials.uid) {
            unawaited(CallRingtoneService.stop());
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _cancelLoneParticipantTimer();
          remoteUids.add(remoteUid);
          logger.i('[CallCoordinator] Remote user joined uid=$remoteUid');
          unawaited(CallRingtoneService.stop());
        },
        onUserOffline: (connection, remoteUid, reason) {
          remoteUids.remove(remoteUid);
          logger.i(
            '[CallCoordinator] Remote user offline uid=$remoteUid reason=$reason',
          );
          if (remoteUids.isEmpty) {
            _startLoneParticipantTimer(session.call.id);
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          if (state == ConnectionStateType.connectionStateReconnecting) {
            localState.value = LocalCallState.reconnecting;
          } else if (state == ConnectionStateType.connectionStateConnected &&
              _isInChannel) {
            localState.value = LocalCallState.connected;
          }
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          unawaited(_renewToken(session.call.id));
        },
        onLocalAudioStateChanged: (connection, state, reason) {
          audioDebugState.value = 'local:$state/$reason';
          logger.i('[CallCoordinator] Local audio state=$state reason=$reason');
        },
        onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
          audioDebugState.value = 'remote:$remoteUid/$state/$reason';
          logger.i(
            '[CallCoordinator] Remote audio uid=$remoteUid state=$state reason=$reason',
          );
        },
        onFirstLocalAudioFramePublished: (connection, elapsed) {
          logger.i('[CallCoordinator] Local microphone audio is publishing');
        },
        onFirstRemoteAudioDecoded: (connection, remoteUid, elapsed) {
          logger.i('[CallCoordinator] Remote audio decoded uid=$remoteUid');
        },
        onError: (errorCode, message) {
          audioDebugState.value = 'error:$errorCode';
          logger.e('[CallCoordinator] Agora error=$errorCode message=$message');
        },
      ),
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.muteAllRemoteAudioStreams(false);
    await engine.adjustRecordingSignalVolume(100);
    await engine.adjustPlaybackSignalVolume(100);
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioMeeting,
    );
    await engine.setDefaultAudioRouteToSpeakerphone(true);
    await engine.joinChannel(
      token: session.credentials.token,
      channelId: session.credentials.channel,
      uid: session.credentials.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
    await joinedChannel.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw const CallApiException(
        message: 'Quá thời gian kết nối tới kênh âm thanh.',
      ),
    );
    _persistActiveCall(session.call);
  }

  Future<void> _applySpeakerRoute(bool enabled) async {
    final engine = _engine;
    if (engine == null || !_isInChannel) return;
    try {
      await engine.setEnableSpeakerphone(enabled);
      isSpeakerEnabled.value = enabled;
    } on AgoraRtcException catch (error) {
      // Audio routing availability varies by device/headset. It must not make
      // an otherwise successful Agora channel join fail.
      logger.w(
        '[CallCoordinator] Unable to change speaker route: ${error.code}',
      );
    }
  }

  Future<void> _renewToken(String callId) async {
    try {
      final session = await _repository.join(callId);
      activeCall.value = session.call;
      await _engine?.renewToken(session.credentials.token);
    } on CallApiException catch (error) {
      logger.w(
        '[CallCoordinator] Agora token renewal failed: ${error.message}',
      );
    }
  }

  Future<void> disposeCall({required bool notifyServer}) async {
    _cancelLoneParticipantTimer();
    _stopCallDurationTimer();
    final callId = activeCall.value?.id;
    if (callId != null) {
      await NotificationService.cancelIncomingCall(callId);
    }
    await CallRingtoneService.stop();
    if (notifyServer && activeCall.value != null) {
      try {
        await _repository.leave(activeCall.value!.id);
      } on CallApiException catch (_) {}
    }
    await _releaseEngine();
    remoteUids.clear();
    isMuted.value = false;
    isSpeakerEnabled.value = true;
    audioDebugState.value = '';
    if (localState.value != LocalCallState.ended) {
      localState.value = LocalCallState.idle;
    }
  }

  Future<void> _releaseEngine() async {
    final engine = _engine;
    _engine = null;
    _isInChannel = false;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    await engine.release();
  }

  void _handleApiFailure(CallApiException error) {
    if (error.statusCode == 403 || error.statusCode == 404) {
      activeCall.value = null;
    }
    _fail(error.message);
  }

  void _fail(String message) {
    errorMessage.value = message;
    localState.value = LocalCallState.failed;
  }

  void _startLoneParticipantTimer(String callId) {
    _cancelLoneParticipantTimer();
    if (!_isInChannel ||
        activeCall.value?.id != callId ||
        remoteUids.isNotEmpty) {
      return;
    }
    _loneParticipantTimer = Timer(loneParticipantTimeout, () async {
      await _handleLoneParticipantTimeout(callId);
    });
    logger.i(
      '[CallCoordinator] Lone participant timer started for '
      '${loneParticipantTimeout.inMinutes} minutes.',
    );
  }

  void _cancelLoneParticipantTimer() {
    _loneParticipantTimer?.cancel();
    _loneParticipantTimer = null;
  }

  void _startCallDurationTimer(DateTime? startedAt) {
    _callDurationTimer?.cancel();
    final effectiveStartedAt = startedAt?.toLocal() ?? DateTime.now();

    void updateElapsedTime() {
      final elapsed = DateTime.now().difference(effectiveStartedAt).inSeconds;
      callDurationSeconds.value = elapsed < 0 ? 0 : elapsed;
    }

    updateElapsedTime();
    _callDurationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateElapsedTime(),
    );
  }

  void _stopCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    callDurationSeconds.value = 0;
  }

  void _persistActiveCall(CallModel call) {
    final currentUserId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    if (currentUserId == null) return;
    StorageService.writeMapData(
      key: LocalStorageKeys.activeCallRecovery,
      value: <String, dynamic>{
        'call_id': call.id,
        'thread_id': call.threadId.toString(),
        'user_id': currentUserId,
      },
    );
    hasPendingCallRecovery.value = false;
  }

  void _clearPersistedCall([String? callId]) {
    if (callId != null) {
      final recovery = StorageService.readMapData(
        key: LocalStorageKeys.activeCallRecovery,
      );
      if (recovery is Map<String, dynamic> &&
          recovery['call_id']?.toString() != callId) {
        return;
      }
    }
    StorageService.removeData(key: LocalStorageKeys.activeCallRecovery);
    hasPendingCallRecovery.value = false;
  }

  void _clearPersistedCallForThread(String threadId) {
    final recovery = StorageService.readMapData(
      key: LocalStorageKeys.activeCallRecovery,
    );
    if (recovery is Map<String, dynamic> &&
        recovery['thread_id']?.toString() == threadId) {
      StorageService.removeData(key: LocalStorageKeys.activeCallRecovery);
      hasPendingCallRecovery.value = false;
    }
  }

  Future<void> _handleLoneParticipantTimeout(String callId) async {
    final call = activeCall.value;
    final currentUserId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    if (call?.id != callId ||
        !_isInChannel ||
        remoteUids.isNotEmpty ||
        _actionInProgress) {
      return;
    }

    logger.i(
      '[CallCoordinator] Lone participant timeout reached; closing call.',
    );
    if (call?.initiator?.id == currentUserId) {
      await end();
    } else {
      await leave();
    }
  }
}
