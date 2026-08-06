import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/common/call_model.dart';

class AudioCallScreen extends GetView<CallCoordinator> {
  const AudioCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: SafeArea(
          child: Obx(() {
            final call = controller.activeCall.value;
            final state = controller.localState.value;
            if (call == null && state == LocalCallState.ended) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.currentRoute.isNotEmpty) Get.back<void>();
              });
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    controller.threadTitle.value.isNotEmpty
                        ? controller.threadTitle.value
                        : 'Cuộc gọi âm thanh',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _stateLabel(
                      state,
                      call,
                      controller.endedStateMessage.value,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _ParticipantsPanel(
                      call: call,
                      controller: controller,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state == LocalCallState.failed) ...[
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFCA5A5)),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _CallControls(controller: controller),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  String _stateLabel(
    LocalCallState state,
    CallModel? call,
    String endedStateMessage,
  ) => switch (state) {
    LocalCallState.creating => 'Đang tạo cuộc gọi…',
    LocalCallState.ringing => 'Đang đổ chuông…',
    LocalCallState.joining => 'Đang kết nối…',
    LocalCallState.connected => 'Đã kết nối',
    LocalCallState.reconnecting => 'Đang kết nối lại…',
    LocalCallState.leaving => 'Đang rời cuộc gọi…',
    LocalCallState.ended => endedStateMessage,
    LocalCallState.failed => 'Không thể kết nối',
    LocalCallState.idle =>
      call == null ? 'Cuộc gọi đã kết thúc' : 'Sẵn sàng tham gia',
  };
}

class _ParticipantsPanel extends StatelessWidget {
  const _ParticipantsPanel({required this.call, required this.controller});

  final CallModel? call;
  final CallCoordinator controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final participants = call?.participants ?? const <CallParticipant>[];
      // Materialize the reactive set inside this observer so RTC join/offline
      // events always rebuild the status indicator, independently from API
      // participant updates.
      final onlineUids = controller.remoteUids.toSet();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Người tham gia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${participants.length}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: participants.isEmpty
                ? const Center(
                    child: Text(
                      'Đang chờ người khác tham gia…',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: participants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      final isCurrentUser =
                          participant.id ==
                          StorageService.readMapData(
                            key: LocalStorageKeys.user,
                            mapKey: 'id',
                          );
                      final isRtcOnline =
                          isCurrentUser || onlineUids.contains(participant.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isCurrentUser
                                    ? '${participant.name} (Bạn)'
                                    : participant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRtcOnline
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({required this.controller});
  final CallCoordinator controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final call = controller.activeCall.value;
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final isInitiator = call?.initiator?.id == currentUserId;
      final connected =
          controller.localState.value == LocalCallState.connected ||
          controller.localState.value == LocalCallState.reconnecting;
      final isMuted = controller.isMuted.value;
      final isSpeakerEnabled = controller.isSpeakerEnabled.value;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundControl(
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: isMuted ? 'Bật mic' : 'Tắt mic',
                selected: isMuted,
                onTap: connected ? () => controller.setMuted(!isMuted) : null,
              ),
              const SizedBox(width: 26),
              _RoundControl(
                icon: isSpeakerEnabled
                    ? Icons.volume_up_rounded
                    : Icons.hearing_rounded,
                label: isSpeakerEnabled ? 'Tắt loa' : 'Bật loa',
                selected: isSpeakerEnabled,
                onTap: connected
                    ? () => controller.setSpeakerEnabled(!isSpeakerEnabled)
                    : null,
              ),
              const SizedBox(width: 26),
              _RoundControl(
                icon: Icons.call_end_rounded,
                label: 'Rời cuộc gọi',
                destructive: true,
                onTap: () async {
                  await controller.leave();
                  if (controller.localState.value != LocalCallState.ended) {
                    Get.back<void>();
                  }
                },
              ),
            ],
          ),
          if (isInitiator) ...[
            const SizedBox(height: 28),
            TextButton(
              onPressed: () async {
                await controller.end();
              },
              child: const Text(
                'Kết thúc cuộc gọi cho tất cả',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFDC2626)
        : selected
        ? Colors.white
        : const Color(0xFF374151);
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(
                icon,
                color: selected && !destructive ? Colors.black : Colors.white,
                size: 27,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
