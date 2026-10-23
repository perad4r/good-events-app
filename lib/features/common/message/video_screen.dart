import 'dart:async';

import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/services/chat_media_service.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:video_player/video_player.dart';

class ChatVideoScreen extends StatefulWidget {
  const ChatVideoScreen({
    super.key,
    required this.attachment,
    required this.mediaService,
  });
  final MessageAttachmentModel attachment;
  final ChatMediaService mediaService;

  @override
  State<ChatVideoScreen> createState() => _ChatVideoScreenState();
}

class _ChatVideoScreenState extends State<ChatVideoScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  bool _ready = false;
  bool _failed = false;
  bool _opening = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final Uri? uri = Uri.tryParse(widget.attachment.url);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw const ChatMediaException('chat_attachment_unavailable');
      }
      final VideoPlayerController player = VideoPlayerController.networkUrl(
        uri,
      );
      _player = player;
      player.addListener(_onPlayerChanged);
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onPlayerChanged() {
    if (mounted && _player?.value.hasError == true && !_failed) {
      setState(() => _failed = true);
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _player?.seekTo(position);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _togglePlayback() async {
    final VideoPlayerController? player = _player;
    if (player == null) return;
    try {
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        if (player.value.position >= player.value.duration) {
          await player.seekTo(Duration.zero);
        }
        await player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_player?.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.removeListener(_onPlayerChanged);
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _openExternally() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.mediaService.openAttachment(
        widget.attachment,
        onProgress: (int received, int total) {
          if (mounted) {
            setState(
              () => _downloadProgress = total > 0
                  ? (received / total).clamp(0.0, 1.0)
                  : null,
            );
          }
        },
      );
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(
          message: error is ChatMediaException
              ? error.key.tr
              : 'chat_open_failed'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _downloadProgress = null;
        });
      }
    }
  }

  String _time(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => FScaffold(
    header: FHeader.nested(
      title: Text(
        widget.attachment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      prefixes: <Widget>[
        FButton.icon(onPress: Get.back, child: const Icon(FIcons.arrowLeft)),
      ],
    ),
    child: Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: _failed
                ? Text(
                    'chat_video_playback_failed'.tr,
                    textAlign: TextAlign.center,
                  )
                : !_ready
                ? const FCircularProgress()
                : AspectRatio(
                    aspectRatio: _player!.value.aspectRatio,
                    child: VideoPlayer(_player!),
                  ),
          ),
        ),
        if (_ready && !_failed)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _player!,
            builder:
                (BuildContext context, VideoPlayerValue value, Widget? child) {
                  final int duration = value.duration.inMilliseconds;
                  return Column(
                    children: <Widget>[
                      FSlider(
                        enabled: duration > 0,
                        control: FSliderControl.liftedContinuous(
                          value: FSliderValue(
                            max: duration <= 0
                                ? 0
                                : (value.position.inMilliseconds / duration)
                                      .clamp(0.0, 1.0),
                          ),
                          onChange: (FSliderValue next) => _seek(
                            Duration(
                              milliseconds: (duration * next.max).round(),
                            ),
                          ),
                        ),
                        semanticValueFormatterCallback: (double progress) =>
                            _time(
                              Duration(
                                milliseconds: (duration * progress).round(),
                              ),
                            ),
                      ),
                      Text(
                        '${_time(value.position)} / ${_time(value.duration)}',
                      ),
                      const SizedBox(height: 8),
                      FButton(
                        onPress: _togglePlayback,
                        child: Text(
                          (value.isPlaying ? 'chat_pause' : 'chat_play').tr,
                        ),
                      ),
                    ],
                  );
                },
          ),
        const SizedBox(height: 12),
        if (_opening) ...<Widget>[
          if (_downloadProgress == null)
            const FProgress()
          else
            FDeterminateProgress(value: _downloadProgress!),
          const SizedBox(height: 8),
        ],
        FButton(
          onPress: _opening ? null : _openExternally,
          child: Text(
            (_opening ? 'chat_downloading' : 'chat_open_external').tr,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}
