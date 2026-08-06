import 'dart:async';

import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/common/call_model.dart';
import 'package:sukientotapp/data/models/message_list_model.dart';
import 'package:sukientotapp/features/common/call/screen.dart';

const int _adminUserId = 2;
bool _isAudioCallScreenOpen = false;

Future<void> openAudioCallScreen() async {
  if (_isAudioCallScreenOpen) return;
  _isAudioCallScreenOpen = true;
  try {
    await Get.to<void>(
      () => const AudioCallScreen(),
      transition: Transition.downToUp,
    );
  } finally {
    _isAudioCallScreenOpen = false;
  }
}

/// Reopens the in-call UI when iOS brings the app to the foreground after the
/// user taps the system CallKit status indicator.
class CallResumeNavigator extends StatefulWidget {
  const CallResumeNavigator({required this.child, super.key});

  final Widget child;

  @override
  State<CallResumeNavigator> createState() => _CallResumeNavigatorState();
}

class _CallResumeNavigatorState extends State<CallResumeNavigator>
    with WidgetsBindingObserver {
  late final CallCoordinator _coordinator;
  late final Worker _callStateWorker;
  Timer? _navigationRetryTimer;
  bool _isAppResumed = false;

  @override
  void initState() {
    super.initState();
    _coordinator = Get.find<CallCoordinator>();
    _isAppResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _callStateWorker = ever<LocalCallState>(
      _coordinator.localState,
      (_) => _openCallUiIfNeeded(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCallUiIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCallUiIfNeeded();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CallResumeNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCallUiIfNeeded();
    });
  }

  void _openCallUiIfNeeded() {
    if (!mounted || !_isAppResumed || _isAudioCallScreenOpen) return;
    // During a cold start, SplashController replaces the whole navigation
    // stack with the home route. Opening the call screen before that would
    // make it part of the discarded stack while the Agora session stays live.
    if (Get.currentRoute == Routes.splashScreen) {
      _scheduleNavigationRetry();
      return;
    }
    _navigationRetryTimer?.cancel();
    _navigationRetryTimer = null;
    if (_coordinator.activeCall.value == null) return;
    final state = _coordinator.localState.value;
    final isOngoing = state == LocalCallState.joining ||
        state == LocalCallState.connected ||
        state == LocalCallState.reconnecting;
    if (isOngoing) unawaited(openAudioCallScreen());
  }

  void _scheduleNavigationRetry() {
    if (_navigationRetryTimer?.isActive == true) return;
    _navigationRetryTimer = Timer(
      const Duration(milliseconds: 250),
      _openCallUiIfNeeded,
    );
  }

  @override
  void dispose() {
    _navigationRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _callStateWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> showStartCallSheet({
  required BuildContext context,
  required MessageListModel thread,
  required CallCoordinator coordinator,
}) async {
  final currentUserId =
      StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
          as int?;
  final candidates = thread.participants
      .where(
        (participant) =>
            participant.id > 0 &&
            participant.id != currentUserId &&
            participant.id != _adminUserId &&
            participant.role != 'admin' &&
            participant.name.trim().toLowerCase() != 'admin',
      )
      .toList(growable: false);

  logger.d(
    'showStartCallSheet: candidates=${thread.toJson()}',
  );

  if (candidates.isEmpty) {
    AppSnackbar.showError(
      message: 'Chưa tìm thấy thành viên hợp lệ để mời vào cuộc gọi.',
    );
    return;
  }

  final selectedIds = <int>{};
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        decoration: BoxDecoration(
          color: context.fTheme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.fTheme.colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bắt đầu cuộc gọi âm thanh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn người sẽ nhận thông báo. Thành viên khác vẫn có thể tham gia sau.',
                style: TextStyle(
                  color: context.fTheme.colors.mutedForeground,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final participant = candidates[index];
                    final selected = selectedIds.contains(participant.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => setState(() {
                        selected
                            ? selectedIds.remove(participant.id)
                            : selectedIds.add(participant.id);
                      }),
                      title: Text(participant.name),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              FButton(
                onPress: selectedIds.isEmpty
                    ? null
                    : () async {
                        Navigator.of(sheetContext).pop();
                        final session = await coordinator.createAudioCall(
                          threadId: thread.id,
                          invitedUserIds: selectedIds.toList(growable: false),
                        );
                        if (session != null) {
                          await openAudioCallScreen();
                        } else if (coordinator.errorMessage.value.isNotEmpty) {
                          AppSnackbar.showError(
                            message: coordinator.errorMessage.value,
                          );
                        }
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Bắt đầu gọi'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ActiveCallBanner extends StatelessWidget {
  const ActiveCallBanner({
    super.key,
    required this.coordinator,
    required this.threadId,
  });
  final CallCoordinator coordinator;
  final String threadId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final call = coordinator.activeCall.value;
      if (call == null ||
          call.threadId.toString() != threadId ||
          call.status == CallStatus.ended) {
        return const SizedBox.shrink();
      }
      final connected =
          coordinator.localState.value == LocalCallState.connected ||
          coordinator.localState.value == LocalCallState.reconnecting;
      return Material(
        color: const Color(0xFFECFDF5),
        child: InkWell(
          onTap: () async {
            if (!connected) {
              final session = await coordinator.joinActiveCall();
              if (session == null) return;
            }
            await openAudioCallScreen();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                const Icon(
                  Icons.call_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đang có cuộc gọi âm thanh',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  connected ? 'Mở' : 'Tham gia',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class GlobalIncomingCallOverlay extends StatelessWidget {
  const GlobalIncomingCallOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CallCoordinator>()) return child;
    final coordinator = Get.find<CallCoordinator>();
    return Stack(
      children: [
        child,
        Obx(() {
          final call = coordinator.activeCall.value;
          final currentUserId =
              StorageService.readMapData(
                    key: LocalStorageKeys.user,
                    mapKey: 'id',
                  )
                  as int?;
          final isPendingInvite =
              call?.invitedUsers.any(
                (user) =>
                    user.id == currentUserId &&
                    user.status == CallInviteStatus.pending,
              ) ??
              false;
          final shouldShow =
              call != null &&
              isPendingInvite &&
              coordinator.localState.value == LocalCallState.ringing;
          if (!shouldShow) return const SizedBox.shrink();
          return Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 14,
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.initiator?.name ?? 'Cuộc gọi đến',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Cuộc gọi âm thanh đến',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: coordinator.decline,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                      icon: const Icon(Icons.call_end_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () async {
                        final session = await coordinator.joinActiveCall();
                        if (session != null) await openAudioCallScreen();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      icon: const Icon(Icons.call_rounded),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
