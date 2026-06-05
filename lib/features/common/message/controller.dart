import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

import 'package:sukientotapp/domain/repositories/partner/message_repository.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:sukientotapp/data/models/message_list_model.dart';

import 'detail_screen.dart';

class MessageController extends GetxController {
  final MessageRepository _repository;
  MessageController(this._repository);

  // ─── Thread List State ────────────────────────────────────────────────────────
  final RxList<MessageListModel> filteredMessages = <MessageListModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString searchQuery = ''.obs;
  int _currentPage = 1;

  // ─── Message Detail State ───────────────────────────────────────────────────
  final RxList<MessageModel> messagesDetail = <MessageModel>[].obs;
  final Rx<MessageListModel?> selectedThread = Rx<MessageListModel?>(null);
  final RxBool isLoadingMessages = false.obs;
  final RxBool isLoadingOlderMessages = false.obs;
  int _messagesPage = 1;
  bool _messagesHasMore = true;

  String get selectedThreadId => selectedThread.value?.id ?? '';

  String? _subscribedChannel;
  static const _pusherEventName = 'SendMessage';

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ScrollController listScrollController = ScrollController();

  var selectedFiles = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchThreads();
    listScrollController.addListener(_onListScroll);
    _handlePendingThreadDeepLink();
    scrollController.addListener(_onDetailScroll);
    debounce(
      searchQuery,
      (_) => _resetAndFetch(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _unsubscribeThread();
    messageController.dispose();
    scrollController.dispose();
    listScrollController.dispose();
    super.onClose();
  }

  // ─── Pending Deep Link ──────────────────────────────────────────────────────

  /// Handles a thread deep link saved from a terminated-state notification tap.
  void _handlePendingThreadDeepLink() {
    final threadId = StorageService.readData(
      key: LocalStorageKeys.pendingThreadId,
    ) as String?;
    if (threadId == null || threadId.isEmpty) return;

    StorageService.removeData(key: LocalStorageKeys.pendingThreadId);
    logger.i(
      '[MessageController] [PendingDeepLink] Opening thread=$threadId',
    );

    // Wait until threads are loaded before opening
    ever(isLoading, (bool loading) {
      if (!loading && filteredMessages.isNotEmpty) {
        openThreadById(threadId);
      }
    });
  }

  // ─── Thread List ─────────────────────────────────────────────────────────────

  Future<void> fetchThreads({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final response = await _repository.getThreads(
        page: _currentPage,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      final threads = (response['threads'] as List<dynamic>? ?? [])
          .map((e) => MessageListModel.fromJson(e as Map<String, dynamic>))
          .toList();

      hasMore.value = response['has_more'] as bool? ?? false;
      _currentPage = (response['current_page'] as int? ?? _currentPage);

      if (loadMore) {
        filteredMessages.addAll(threads);
      } else {
        filteredMessages.assignAll(threads);
      }

      logger.i(
        '[MessageController] [fetchThreads] page=$_currentPage, hasMore=${hasMore.value}, count=${threads.length}',
      );
    } catch (e) {
      logger.e('[MessageController] [fetchThreads] Error: $e');
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    _currentPage++;
    await fetchThreads(loadMore: true);
  }

  Future<void> refreshThreads() async {
    _currentPage = 1;
    hasMore.value = true;
    await fetchThreads();
  }

  void searchMessages(String query) {
    searchQuery.value = query;
  }

  void _resetAndFetch() {
    _currentPage = 1;
    hasMore.value = true;
    fetchThreads();
  }

  void _onListScroll() {
    final pos = listScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      loadMore();
    }
  }

  // ─── User Channel event handler (called by BottomNavController) ─────────────
  void onUserChannelEvent(PusherEvent event) {
    if (event.eventName != _pusherEventName) return;
    if (event.data == null) return;

    try {
      final data = jsonDecode(event.data!) as Map<String, dynamic>;
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final incoming = MessageModel.fromApiJson(
        data,
        currentUserId: currentUserId,
      );

      final threadId = incoming.threadId?.toString();
      if (threadId == null) return;
      final idx = filteredMessages.indexWhere((t) => t.id == threadId);
      if (idx != -1) {
        final updated = filteredMessages[idx].copyWith(
          newestMessage: incoming.text,
          newestMessageSender: incoming.sender,
          time: MessageModel.diffForHumans(DateTime.now().toIso8601String()),
          isRead: incoming.isSender,
          unreadMessages: incoming.isSender
              ? 0
              : filteredMessages[idx].unreadMessages + 1,
        );
        filteredMessages.removeAt(idx);
        filteredMessages.insert(0, updated);
      }

      logger.i(
        '[MessageController] [UserChannel] Updated preview for thread=$threadId',
      );
    } catch (e) {
      logger.e('[MessageController] [UserChannel] Error parsing event: $e');
    }
  }

  // ─── Message Detail ──────────────────────────────────────────────────────────

  /// Opens a thread and loads the first page of messages from the API.
  Future<void> openThread(MessageListModel thread) async {
    await _unsubscribeThread();
    selectedThread.value = thread;
    _messagesPage = 1;
    _messagesHasMore = true;
    messagesDetail.clear();
    await loadMessages();
    await _subscribeToThread(thread.id);
  }

  void closeThread() {
    if (selectedThread.value == null || messagesDetail.isEmpty) return;
    final lastMessage = messagesDetail[0];
    final threadId = selectedThreadId;
    final idx = filteredMessages.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      filteredMessages[idx] = filteredMessages[idx].copyWith(
        newestMessage: lastMessage.text,
        newestMessageSender: lastMessage.sender,
        time: lastMessage.time,
        isRead: true,
        unreadMessages: 0,
      );
    }

    _unsubscribeThread();

    logger.i(
      '[MessageController] [closeThread] Updated preview for thread=$threadId',
    );
  }

  /// Opens a thread by its ID — used when tapping a NEW_MESSAGE notification.
  Future<void> openThreadById(String threadId) async {
    MessageListModel? thread = filteredMessages.firstWhereOrNull(
      (t) => t.id == threadId,
    );

    if (thread == null) {
      await refreshThreads();
      thread = filteredMessages.firstWhereOrNull(
        (t) => t.id == threadId,
      );
    }

    if (thread == null) {
      AppSnackbar.showError(message: 'thread_not_found'.tr);
      return;
    }

    await openThread(thread);
    await Get.to<void>(() => const MessageDetailScreen());
    closeThread();
  }

  Future<void> openThreadFromMyShow(int showid) async {
    MessageListModel? thread = filteredMessages.firstWhereOrNull(
      (t) => t.bill.id == showid,
    );

    if (thread == null) {
      await refreshThreads();
      thread = filteredMessages.firstWhereOrNull(
        (t) => t.bill.id == showid,
      );
    }

    if (thread == null) {
      AppSnackbar.showError(message: 'thread_not_found'.tr);
      return;
    }

    await openThread(thread);
    await Get.to<void>(() => const MessageDetailScreen());
    closeThread();
  }

  Future<void> _subscribeToThread(String threadId) async {
    final channelName = 'private-thread.$threadId';
    await PusherService.subscribe(
      channelName: channelName,
      eventName: _pusherEventName,
      onEvent: _onPusherMessage,
    );
    _subscribedChannel = channelName;
    logger.i('[MessageController] [Pusher] Subscribed to $channelName');
  }

  void _onPusherMessage(PusherEvent event) {
    if (event.eventName != _pusherEventName) return;
    if (event.data == null) return;

    try {
      final data = jsonDecode(event.data!) as Map<String, dynamic>;
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final incoming = MessageModel.fromApiJson(
        data,
        currentUserId: currentUserId,
      );

      if (incoming.isSender) return;

      messagesDetail.insert(0, incoming);
      scrollToBottom();

      // Update the thread's newestMessage preview in the list
      final threadId = selectedThreadId;
      final idx = filteredMessages.indexWhere((t) => t.id == threadId);
      if (idx != -1) {
        final updated = filteredMessages[idx].copyWith(
          newestMessage: incoming.text,
          newestMessageSender: incoming.sender,
          time: MessageModel.diffForHumans(DateTime.now().toIso8601String()),
          isRead: true,
          unreadMessages: 0,
        );
        filteredMessages.removeAt(idx);
        filteredMessages.insert(0, updated);
      }

      logger.i(
        '[MessageController] [Pusher] New message in thread=$_subscribedChannel',
      );
    } catch (e) {
      logger.e('[MessageController] [Pusher] Error parsing event: $e');
    }
  }

  Future<void> _unsubscribeThread() async {
    if (_subscribedChannel == null) return;
    await PusherService.unsubscribe(_subscribedChannel!);
    logger.i(
      '[MessageController] [Pusher] Unsubscribed from $_subscribedChannel',
    );
    _subscribedChannel = null;
  }

  Future<void> loadMessages() async {
    if (isLoadingMessages.value) return;
    final threadId = selectedThreadId;
    if (threadId.isEmpty) return;

    isLoadingMessages.value = true;
    try {
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final response = await _repository.getMessages(
        threadId: threadId,
        page: _messagesPage,
      );
      final raw = response['messages'] as List<dynamic>? ?? [];
      final messages = raw
          .map(
            (e) => MessageModel.fromApiJson(
              e as Map<String, dynamic>,
              currentUserId: currentUserId,
            ),
          )
          .toList();

      _messagesHasMore = response['hasMore'] as bool? ?? false;
      messagesDetail.assignAll(messages.reversed.toList());

      logger.i(
        '[MessageController] [loadMessages] threadId=$threadId, count=${messages.length}, hasMore=$_messagesHasMore',
      );
    } catch (e) {
      logger.e('[MessageController] [loadMessages] Error: $e');
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> loadOlderMessages() async {
    if (!_messagesHasMore || isLoadingOlderMessages.value) return;
    final threadId = selectedThreadId;
    if (threadId.isEmpty) return;

    isLoadingOlderMessages.value = true;
    try {
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      _messagesPage++;
      final response = await _repository.getMessages(
        threadId: threadId,
        page: _messagesPage,
      );
      final raw = response['messages'] as List<dynamic>? ?? [];
      final older = raw
          .map(
            (e) => MessageModel.fromApiJson(
              e as Map<String, dynamic>,
              currentUserId: currentUserId,
            ),
          )
          .toList();

      _messagesHasMore = response['hasMore'] as bool? ?? false;
      messagesDetail.addAll(older.reversed.toList());

      logger.i(
        '[MessageController] [loadOlderMessages] page=$_messagesPage, count=${older.length}, hasMore=$_messagesHasMore',
      );
    } catch (e) {
      logger.e('[MessageController] [loadOlderMessages] Error: $e');
      _messagesPage--; // revert on failure
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoadingOlderMessages.value = false;
    }
  }

  // ─── Scroll ───────────────────────────────────────────────────────────────────

  void _onDetailScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      loadOlderMessages();
    }
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ─── Send Message ─────────────────────────────────────────────────────────────

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final threadId = selectedThreadId;
    if (threadId.isEmpty) return;

    final currentUserName =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name')
            as String? ??
        '';

    final optimistic = MessageModel(
      sender: currentUserName,
      text: text,
      isSender: true,
      sended: false,
      time: 'just_now'.tr,
      date: '',
    );

    messagesDetail.insert(0, optimistic);
    messageController.clear();
    scrollToBottom();

    try {
      await _repository.sendMessage(threadId: threadId, body: text);
      final idx = messagesDetail.indexOf(optimistic);
      if (idx != -1) {
        messagesDetail[idx] = MessageModel(
          sender: optimistic.sender,
          text: optimistic.text,
          isSender: optimistic.isSender,
          sended: true,
          time: optimistic.time,
          date: optimistic.date,
        );
      }
      // Move thread to top of list
      final currentUserName =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name')
              as String? ??
          '';
      final threadIdx = filteredMessages.indexWhere((t) => t.id == threadId);
      if (threadIdx != -1) {
        final updated = filteredMessages[threadIdx].copyWith(
          newestMessage: text,
          newestMessageSender: currentUserName,
          time: MessageModel.diffForHumans(DateTime.now().toIso8601String()),
          isRead: true,
          unreadMessages: 0,
        );
        filteredMessages.removeAt(threadIdx);
        filteredMessages.insert(0, updated);
      }
      logger.i('[MessageController] [sendMessage] Sent to thread=$threadId');
    } catch (e) {
      logger.e('[MessageController] [sendMessage] Error: $e');
      messagesDetail.remove(optimistic);
      messageController.text = text; // restore text on failure
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
