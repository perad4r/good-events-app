import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/phone_number_censor.dart';

import 'package:sukientotapp/domain/repositories/partner/message_repository.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:sukientotapp/data/models/message_list_model.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/data/models/chat_invitation_model.dart';

import 'detail_screen.dart';
import 'widget/invitation_accept_dialog.dart';

class MessageController extends GetxController {
  final MessageRepository _repository;
  final CallCoordinator callCoordinator;
  MessageController(this._repository, this.callCoordinator);

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
  bool get isPartner =>
      (StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'role') ?? '')
          .toString()
          .toLowerCase() ==
      'partner';
  int? get currentUserId {
    final Object? value = StorageService.readMapData(
      key: LocalStorageKeys.user,
      mapKey: 'id',
    );
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
  final RxBool canRequestPriceIncrease = false.obs;

  String? _subscribedChannel;
  static const _pusherEventName = 'SendMessage';

  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final ScrollController listScrollController = ScrollController();

  final RxList<XFile> selectedImages = <XFile>[].obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isResolvingLocation = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  // ─── Member invitation state ───────────────────────────────────────────────
  final RxString memberPhoneQuery = ''.obs;
  final RxList<ChatUserSearchResult> memberSearchResults =
      <ChatUserSearchResult>[].obs;
  final RxBool isSearchingMembers = false.obs;
  final RxString memberSearchError = ''.obs;
  final RxSet<int> invitingUserIds = <int>{}.obs;
  final RxSet<int> pendingInvitationUserIds = <int>{}.obs;
  final RxBool isAcceptingInvitation = false.obs;
  final RxBool isLeavingThread = false.obs;
  int _memberSearchGeneration = 0;
  final Set<String> _invitedMembershipThreadIds = <String>{};

  static const int _maxImageSizeBytes = 20 * 1024 * 1024;
  static const Set<String> _allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  @override
  void onInit() {
    super.onInit();
    _restoreInvitedMemberships();
    fetchThreads();
    listScrollController.addListener(_onListScroll);
    unawaited(_handlePendingThreadDeepLink());
    _handlePendingChatInvitation();
    scrollController.addListener(_onDetailScroll);
    debounce(
      searchQuery,
      (_) => _resetAndFetch(),
      time: const Duration(milliseconds: 500),
    );
    debounce(
      memberPhoneQuery,
      (_) => _searchMembers(),
      time: const Duration(milliseconds: 400),
    );
    ever(selectedThread, (_) => _updateCanRequestPriceIncrease());
  }

  void _handlePendingChatInvitation() {
    final rawInvitation = StorageService.readData(
      key: LocalStorageKeys.pendingChatInvitation,
    );
    if (rawInvitation is! Map) return;

    final invitation = Map<String, dynamic>.from(rawInvitation);
    final threadId = invitation['thread_id']?.toString();
    if (threadId == null || threadId.isEmpty) {
      StorageService.removeData(key: LocalStorageKeys.pendingChatInvitation);
      return;
    }

    StorageService.removeData(key: LocalStorageKeys.pendingChatInvitation);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isClosed) return;
      final accepted = await showChatInvitationDialog(
        threadId: threadId,
        controller: this,
        inviterName: invitation['inviter_name']?.toString(),
      );
      if (accepted && !isClosed) {
        await openThreadById(threadId);
      }
    });
  }

  void _restoreInvitedMemberships() {
    final stored = StorageService.readData(
      key: LocalStorageKeys.invitedChatMemberships,
    );
    if (stored is! Map) return;
    _invitedMembershipThreadIds.addAll(
      stored.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString()),
    );
  }

  void _persistInvitedMemberships() {
    StorageService.writeMapData(
      key: LocalStorageKeys.invitedChatMemberships,
      value: <String, dynamic>{
        for (final threadId in _invitedMembershipThreadIds) threadId: true,
      },
    );
  }

  void resetMemberSearch() {
    _memberSearchGeneration++;
    memberPhoneQuery.value = '';
    memberSearchResults.clear();
    memberSearchError.value = '';
    isSearchingMembers.value = false;
  }

  void searchMembers(String phone) {
    memberPhoneQuery.value = phone.trim();
    if (memberPhoneQuery.value.length < 3) {
      _memberSearchGeneration++;
      memberSearchResults.clear();
      memberSearchError.value = '';
      isSearchingMembers.value = false;
    }
  }

  Future<void> _searchMembers() async {
    final query = memberPhoneQuery.value;
    if (query.length < 3) return;
    final generation = ++_memberSearchGeneration;
    isSearchingMembers.value = true;
    memberSearchError.value = '';
    try {
      final users = await _repository.searchUsersByPhone(query);
      if (generation != _memberSearchGeneration) return;
      memberSearchResults.assignAll(users);
    } catch (error) {
      if (generation != _memberSearchGeneration) return;
      memberSearchResults.clear();
      memberSearchError.value = error.toString();
    } finally {
      if (generation == _memberSearchGeneration) {
        isSearchingMembers.value = false;
      }
    }
  }

  Future<void> inviteUser(ChatUserSearchResult user) async {
    final threadId = selectedThreadId;
    if (threadId.isEmpty || invitingUserIds.contains(user.id)) return;
    invitingUserIds.add(user.id);
    try {
      final response = await _repository.inviteUser(
        threadId: threadId,
        userId: user.id,
      );
      pendingInvitationUserIds.add(user.id);
      AppSnackbar.showSuccess(message: response.message);
    } catch (error) {
      AppSnackbar.showError(message: error.toString());
    } finally {
      invitingUserIds.remove(user.id);
    }
  }

  /// Entry point for the notification/deep-link flow once it supplies threadId.
  Future<bool> acceptInvitation(String threadId) async {
    if (isAcceptingInvitation.value) return false;
    isAcceptingInvitation.value = true;
    try {
      final response = await _repository.acceptInvitation(threadId);
      _invitedMembershipThreadIds.add(threadId);
      _persistInvitedMemberships();
      await refreshThreads();
      AppSnackbar.showSuccess(message: response.message);
      return true;
    } catch (error) {
      AppSnackbar.showError(message: error.toString());
      return false;
    } finally {
      isAcceptingInvitation.value = false;
    }
  }

  Future<bool> leaveSelectedThread() async {
    final threadId = selectedThreadId;
    if (threadId.isEmpty || isLeavingThread.value) return false;
    isLeavingThread.value = true;
    try {
      final message = await _repository.leaveThread(threadId);
      await _unsubscribeThread();
      filteredMessages.removeWhere((thread) => thread.id == threadId);
      _invitedMembershipThreadIds.remove(threadId);
      _persistInvitedMemberships();
      selectedThread.value = null;
      messagesDetail.clear();
      AppSnackbar.showSuccess(message: message);
      return true;
    } catch (error) {
      AppSnackbar.showError(message: error.toString());
      return false;
    } finally {
      isLeavingThread.value = false;
    }
  }

  @override
  void onClose() {
    _unsubscribeThread();
    messageController.dispose();
    messageFocusNode.dispose();
    scrollController.dispose();
    listScrollController.dispose();
    super.onClose();
  }

  // ─── Pending Deep Link ──────────────────────────────────────────────────────

  /// Handles a thread deep link saved from a terminated-state notification tap.
  Future<void> _handlePendingThreadDeepLink() async {
    final String? threadId = await StorageService.consumeStringData(
      key: LocalStorageKeys.pendingThreadId,
    );
    if (threadId == null || threadId.isEmpty) return;

    logger.i('[MessageController] [PendingDeepLink] Opening thread=$threadId');

    if (!isLoading.value) {
      await openThreadById(threadId);
      return;
    }

    // Wait for the initial thread load once, then release the deep-link worker.
    once(isLoading, (bool loading) {
      if (!loading) {
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
      final currrentUIView =
          StorageService.readData(key: LocalStorageKeys.currentUIView)
              as String?;

      logger.i(
        '[MessageController] [fetchThreads] Fetching threads for view=$currrentUIView, page=$_currentPage, search="${searchQuery.value}"',
      );

      final response = await _repository.getThreads(
        page: _currentPage,
        side: currrentUIView,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      final threads = (response['threads'] as List<dynamic>? ?? [])
          .map((e) => MessageListModel.fromJson(e as Map<String, dynamic>))
          .map(
            (thread) => _invitedMembershipThreadIds.contains(thread.id)
                ? thread.copyWith(canLeave: true)
                : thread,
          )
          .toList();
      final serverLeaveableThreadIds = threads
          .where((thread) => thread.canLeave)
          .map((thread) => thread.id);
      final membershipCount = _invitedMembershipThreadIds.length;
      _invitedMembershipThreadIds.addAll(serverLeaveableThreadIds);
      if (_invitedMembershipThreadIds.length != membershipCount) {
        _persistInvitedMemberships();
      }

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
    loggerNoStack.i(
      '[MessageController] [ThreadList] [IncomingEvent]\n'
      'channelName: ${event.channelName}\n'
      'eventName: ${event.eventName}\n'
      'userId: ${event.userId}\n'
      'dataType: ${event.data.runtimeType}\n'
      'data: ${event.data}',
    );

    final eventName = _normalizedPusherEventName(event.eventName);
    if (eventName != _pusherEventName) return;
    if (event.data == null) return;

    try {
      final data = _decodePusherPayload(event.data);
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
          newestMessage: incoming.previewText,
          newestMessageSender: incoming.sender,
          newestMessageSenderAvatar: incoming.senderAvatar,
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
    pendingInvitationUserIds.clear();
    selectedThread.value = thread;
    _updateCanRequestPriceIncrease();
    callCoordinator.setThreadContext(
      threadId: thread.id,
      title: thread.subject,
    );
    _messagesPage = 1;
    _messagesHasMore = true;
    messagesDetail.clear();
    await loadMessages();
    await _subscribeToThread(thread.id);
    await callCoordinator.reconcile(thread.id);
  }

  void closeThread() {
    if (selectedThread.value == null || messagesDetail.isEmpty) return;
    final lastMessage = messagesDetail[0];
    final threadId = selectedThreadId;
    final idx = filteredMessages.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      filteredMessages[idx] = filteredMessages[idx].copyWith(
        newestMessage: lastMessage.previewText,
        newestMessageSender: lastMessage.sender,
        newestMessageSenderAvatar: lastMessage.senderAvatar,
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

  void _updateCanRequestPriceIncrease() {
    final bill = selectedThread.value?.bill;
    final status = bill?.status;
    canRequestPriceIncrease.value =
        isPartner &&
        currentUserId != null &&
        bill?.partnerId == currentUserId &&
        (status == 'confirmed' || status == 'in_job');
  }

  /// Opens a thread by its ID — used when tapping a NEW_MESSAGE notification.
  Future<void> openThreadById(String threadId) async {
    MessageListModel? thread = filteredMessages.firstWhereOrNull(
      (t) => t.id == threadId,
    );

    if (thread == null) {
      await refreshThreads();
      thread = filteredMessages.firstWhereOrNull((t) => t.id == threadId);
    }

    if (thread == null) {
      AppSnackbar.showError(message: 'thread_not_found'.tr);
      return;
    }

    await openThread(thread);
    await Get.to<void>(() => MessageDetailScreen(controller: this));
    closeThread();
  }

  Future<void> openThreadFromMyShow(int showid) async {
    MessageListModel? thread = filteredMessages.firstWhereOrNull(
      (t) => t.bill.id == showid,
    );

    if (thread == null) {
      await refreshThreads();
      thread = filteredMessages.firstWhereOrNull((t) => t.bill.id == showid);
    }

    if (thread == null) {
      AppSnackbar.showError(message: 'thread_not_found'.tr);
      return;
    }

    await openThread(thread);
    await Get.to<void>(() => MessageDetailScreen(controller: this));
    closeThread();
  }

  Future<void> _subscribeToThread(String threadId) async {
    final channelName = 'private-thread.$threadId';
    final subscribed = await PusherService.subscribe(
      channelName: channelName,
      eventName: _pusherEventName,
      onEvent: _onPusherMessage,
    );
    if (!subscribed) return;
    if (isClosed) {
      await PusherService.unsubscribe(channelName);
      return;
    }

    _subscribedChannel = channelName;
    logger.i('[MessageController] [Pusher] Subscribed to $channelName');
  }

  void _onPusherMessage(PusherEvent event) {
    final eventName = _normalizedPusherEventName(event.eventName);
    if (eventName != _pusherEventName && eventName != 'CallUpdated') return;
    if (event.data == null) return;

    try {
      final data = _decodePusherPayload(event.data);
      if (eventName == 'CallUpdated') {
        unawaited(callCoordinator.handleRealtimeCall(data));
        return;
      }
      if (eventName != _pusherEventName) return;
      final currentUserId =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
              as int?;
      final incoming = MessageModel.fromApiJson(
        data,
        currentUserId: currentUserId,
      );

      // Regular outgoing messages already have an optimistic local item.
      // Call summaries are created only by the backend, so the initiator must
      // also accept the realtime event to see the card immediately.
      if (incoming.isSender && incoming.type != 'call') return;
      if (incoming.id != null &&
          messagesDetail.any((message) => message.id == incoming.id)) {
        return;
      }

      _supersedePendingPriceRequests(incoming.priceIncreaseRequest);
      messagesDetail.insert(0, incoming);
      scrollToBottom();

      // Update the thread's newestMessage preview in the list
      final threadId = selectedThreadId;
      final idx = filteredMessages.indexWhere((t) => t.id == threadId);
      if (idx != -1) {
        final updated = filteredMessages[idx].copyWith(
          newestMessage: incoming.previewText,
          newestMessageSender: incoming.sender,
          newestMessageSenderAvatar: incoming.senderAvatar,
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

  String _normalizedPusherEventName(String eventName) =>
      eventName.replaceFirst(RegExp(r'^\.'), '');

  Map<String, dynamic> _decodePusherPayload(dynamic payload) {
    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } else if (payload is Map) {
      // Platform channels can return Map<Object?, Object?>. The JSON round-trip
      // normalizes both top-level and nested keys to String safely.
      final decoded = jsonDecode(jsonEncode(payload));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw const FormatException('Unsupported Pusher payload');
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

  Future<void> pickImagesForMessage() async {
    if (selectedImages.length >= 20) {
      AppSnackbar.showError(message: 'Chỉ có thể chọn tối đa 20 ảnh.');
      return;
    }

    final bool shouldRestoreFocus = messageFocusNode.hasFocus;
    messageFocusNode.unfocus();

    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      final remainingSlots = 20 - selectedImages.length;
      final candidates = picked.take(remainingSlots).toList();
      if (picked.length > remainingSlots) {
        AppSnackbar.showInfo(
          message: 'Chỉ lấy thêm $remainingSlots ảnh để đủ giới hạn 20 ảnh.',
        );
      }

      final validImages = <XFile>[];
      for (final image in candidates) {
        final ext = image.name.split('.').last.toLowerCase();
        if (!_allowedImageExtensions.contains(ext)) {
          AppSnackbar.showError(message: 'Định dạng ảnh không được hỗ trợ.');
          continue;
        }

        final size = await image.length();
        if (size > _maxImageSizeBytes) {
          AppSnackbar.showError(message: 'Mỗi ảnh không được vượt quá 20MB.');
          continue;
        }

        validImages.add(image);
      }

      if (validImages.isNotEmpty) {
        selectedImages.addAll(validImages);
      }
    } finally {
      if (shouldRestoreFocus && !isClosed) {
        await WidgetsBinding.instance.endOfFrame;
        if (!isClosed) {
          messageFocusNode.requestFocus();
        }
      }
    }
  }

  void removeSelectedImage(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    selectedImages.removeAt(index);
  }

  void clearSelectedImages() {
    selectedImages.clear();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final String censoredText = PhoneNumberCensor.censor(text);
    final images = List<XFile>.from(selectedImages);
    if (text.isEmpty && images.isEmpty) return;
    final threadId = selectedThreadId;
    if (threadId.isEmpty) return;
    if (isSendingMessage.value) return;

    final bool isImageMessage = images.isNotEmpty;
    final String previewText = isImageMessage
        ? (censoredText.isEmpty ? '[Ảnh]' : censoredText)
        : censoredText;

    final currentUserName =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name')
            as String? ??
        '';
    final currentUserAvatar = StorageService.readMapData(
      key: LocalStorageKeys.user,
      mapKey: 'avatar_url',
    )?.toString();
    final optimisticAttachments = isImageMessage
        ? images
              .map(
                (image) => MessageAttachmentModel(
                  name: image.name,
                  fileName: image.name,
                  localPath: image.path,
                ),
              )
              .toList()
        : <MessageAttachmentModel>[];

    final optimistic = MessageModel(
      sender: currentUserName,
      senderAvatar: currentUserAvatar,
      text: isImageMessage ? censoredText : previewText,
      type: isImageMessage ? 'image' : 'text',
      previewText: previewText,
      attachments: optimisticAttachments,
      isSender: true,
      sended: false,
      time: 'just_now'.tr,
      date: '',
    );

    messagesDetail.insert(0, optimistic);
    messageController.clear();
    selectedImages.clear();
    scrollToBottom();

    try {
      isSendingMessage.value = true;
      await _repository.sendMessage(
        threadId: threadId,
        type: isImageMessage ? 'image' : 'text',
        body: censoredText.isEmpty ? null : censoredText,
        images: isImageMessage ? images : null,
      );
      _markOptimisticSent(optimistic);
      _updateThreadPreview(threadId: threadId, text: previewText);
      logger.i('[MessageController] [sendMessage] Sent to thread=$threadId');
    } catch (e) {
      logger.e('[MessageController] [sendMessage] Error: $e');
      messagesDetail.remove(optimistic);
      messageController.text = text; // restore text on failure
      selectedImages.assignAll(images);
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<bool> sendPriceIncreaseRequest({
    required int requestedPrice,
    required String reason,
  }) async {
    final thread = selectedThread.value;
    if (thread == null || isSendingMessage.value) return false;
    if (!isPartner ||
        currentUserId == null ||
        thread.bill.partnerId != currentUserId) {
      AppSnackbar.showError(
        message: 'Chỉ đối tác đang phụ trách đơn mới có thể yêu cầu tăng giá.',
      );
      return false;
    }
    if (reason.trim().isEmpty || reason.trim().length > 1000) return false;
    if (thread.bill.total != null && requestedPrice <= thread.bill.total!) {
      AppSnackbar.showError(message: 'Giá đề nghị phải lớn hơn giá hiện tại.');
      return false;
    }

    try {
      isSendingMessage.value = true;
      final userId = StorageService.readMapData(
        key: LocalStorageKeys.user,
        mapKey: 'id',
      );
      final response = await _repository.sendPriceIncreaseRequest(
        threadId: thread.id,
        requestedPrice: requestedPrice,
        reason: reason.trim(),
        clientMessageId: _generateUuidV4(),
      );

      try {
        final MessageModel message = MessageModel.fromApiJson(
          response,
          currentUserId: userId is int ? userId : int.tryParse('$userId'),
        );
        if (message.priceIncreaseRequest != null &&
            !messagesDetail.any((item) => item.id == message.id)) {
          _supersedePendingPriceRequests(message.priceIncreaseRequest);
          messagesDetail.insert(0, message);
        } else {
          await loadMessages();
        }
      } catch (error) {
        logger.w(
          '[MessageController] Could not parse price increase response: $error',
        );
        await loadMessages();
      }

      _updateThreadPreview(
        threadId: thread.id,
        text: '[Yêu cầu tăng giá]',
      );
      scrollToBottom();
      return true;
    } catch (error) {
      AppSnackbar.showError(message: error.toString());
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  String _generateUuidV4() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
      growable: false,
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final String hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  void _supersedePendingPriceRequests(
    PriceIncreaseRequestModel? newestRequest,
  ) {
    if (newestRequest == null || newestRequest.status != 'pending') return;

    for (int index = 0; index < messagesDetail.length; index++) {
      final MessageModel message = messagesDetail[index];
      final PriceIncreaseRequestModel? request = message.priceIncreaseRequest;
      if (request == null ||
          !request.isPending ||
          request.id == newestRequest.id ||
          request.orderId != newestRequest.orderId) {
        continue;
      }
      messagesDetail[index] = message.copyWith(
        priceIncreaseRequest: request.copyWith(status: 'superseded'),
      );
    }
  }

  void handlePriceIncreaseNotification(Map<String, dynamic> data) {
    final int? requestId = int.tryParse(
      data['price_increase_request_id']?.toString() ?? '',
    );
    final String status = data['status']?.toString().toLowerCase() ?? '';
    final String threadId = data['thread_id']?.toString() ?? '';
    final int? requestedTotal = int.tryParse(
      data['requested_total']?.toString() ?? '',
    );

    bool updatedMessage = false;
    if (requestId != null && status.isNotEmpty) {
      for (int index = 0; index < messagesDetail.length; index++) {
        final MessageModel message = messagesDetail[index];
        final PriceIncreaseRequestModel? request =
            message.priceIncreaseRequest;
        if (request?.id != requestId) continue;
        messagesDetail[index] = message.copyWith(
          priceIncreaseRequest: request!.copyWith(status: status),
        );
        updatedMessage = true;
        break;
      }
    }

    if (status == 'accepted' && requestedTotal != null) {
      final int listIndex = filteredMessages.indexWhere(
        (thread) => thread.id == threadId,
      );
      if (listIndex != -1) {
        filteredMessages[listIndex] = filteredMessages[listIndex].copyWith(
          bill: filteredMessages[listIndex].bill.copyWith(
            total: requestedTotal,
          ),
        );
      }
      final MessageListModel? current = selectedThread.value;
      if (current != null && current.id == threadId) {
        selectedThread.value = current.copyWith(
          bill: current.bill.copyWith(total: requestedTotal),
        );
      }
    }

    if (selectedThreadId == threadId && !updatedMessage) {
      unawaited(loadMessages());
    }
  }

  Future<List<PriceIncreaseRequestModel>> getPriceIncreaseRequests({
    required int billId,
    int page = 1,
  }) async {
    final response = await _repository.getPriceIncreaseRequests(
      billId: billId,
      isPartner: isPartner,
      page: page,
    );
    dynamic raw = response['data'] ?? response['price_increase_requests'];
    if (raw is Map) raw = raw['data'];
    if (raw is! List) return <PriceIncreaseRequestModel>[];
    return raw
        .whereType<Map>()
        .map((item) => PriceIncreaseRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<bool> respondToPriceIncreaseRequest({
    required PriceIncreaseRequestModel request,
    required bool accept,
  }) async {
    try {
      await _repository.respondToPriceIncreaseRequest(
        orderId: request.orderId,
        requestId: request.id,
        accept: accept,
      );
      await loadMessages();
      AppSnackbar.showSuccess(
        message: accept ? 'Đã đồng ý mức giá mới.' : 'Đã từ chối yêu cầu.',
      );
      return true;
    } catch (error) {
      AppSnackbar.showError(message: error.toString());
      return false;
    }
  }

  Future<void> sendCurrentLocation() async {
    final threadId = selectedThreadId;
    if (threadId.isEmpty ||
        isResolvingLocation.value ||
        isSendingMessage.value) {
      return;
    }

    MessageModel? optimistic;
    try {
      isResolvingLocation.value = true;
      isSendingMessage.value = true;
      final position = await _getCurrentPosition();
      if (position == null) return;

      final currentUserName =
          StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name')
              as String? ??
          '';
      final currentUserAvatar = StorageService.readMapData(
        key: LocalStorageKeys.user,
        mapKey: 'avatar_url',
      )?.toString();
      const previewText = '[Vị trí]';
      optimistic = MessageModel(
        sender: currentUserName,
        senderAvatar: currentUserAvatar,
        text: previewText,
        type: 'location',
        previewText: previewText,
        location: MessageLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          label: 'Vị trí hiện tại',
        ),
        isSender: true,
        sended: false,
        time: 'just_now'.tr,
        date: '',
      );

      final shouldShowOptimistic = selectedThreadId == threadId;
      if (shouldShowOptimistic) {
        messagesDetail.insert(0, optimistic);
        scrollToBottom();
      }

      await _repository.sendMessage(
        threadId: threadId,
        type: 'location',
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'label': null,
          'address': null,
        },
      );

      if (shouldShowOptimistic) {
        _markOptimisticSent(optimistic);
      }
      _updateThreadPreview(threadId: threadId, text: previewText);
      logger.i(
        '[MessageController] [sendCurrentLocation] Sent to thread=$threadId',
      );
    } catch (e) {
      logger.e('[MessageController] [sendCurrentLocation] Error: $e');
      if (optimistic != null) {
        messagesDetail.remove(optimistic);
      }
      AppSnackbar.showError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isSendingMessage.value = false;
      isResolvingLocation.value = false;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackbar.showInfo(
          message: 'Vui lòng bật dịch vụ vị trí để gửi vị trí hiện tại.',
        );
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          AppSnackbar.showError(
            message: 'Chưa thể lấy vị trí vì dịch vụ vị trí đang tắt.',
          );
          return null;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        AppSnackbar.showError(
          message: 'Bạn cần cấp quyền vị trí để gửi vị trí.',
        );
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        AppSnackbar.showError(
          message:
              'Quyền vị trí đang bị chặn. Vui lòng mở cài đặt để cấp quyền.',
        );
        await Geolocator.openAppSettings();
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      AppSnackbar.showError(
        message:
            'Không lấy được vị trí hiện tại. Vui lòng thử lại ở nơi có tín hiệu GPS tốt hơn.',
      );
      return null;
    } on LocationServiceDisabledException {
      AppSnackbar.showError(
        message: 'Dịch vụ vị trí đang tắt. Vui lòng bật vị trí rồi thử lại.',
      );
      return null;
    } on PermissionDeniedException {
      AppSnackbar.showError(
        message: 'Bạn cần cấp quyền vị trí để gửi vị trí hiện tại.',
      );
      return null;
    } on MissingPluginException {
      AppSnackbar.showError(
        message:
            'Plugin vị trí chưa được đăng ký. Vui lòng tắt hẳn app và build/run lại sau khi thêm geolocator.',
      );
      return null;
    } catch (e) {
      logger.e('[MessageController] [_getCurrentPosition] Error: $e');
      AppSnackbar.showError(
        message:
            'Không thể lấy vị trí hiện tại. Vui lòng kiểm tra quyền vị trí và thử lại.',
      );
      return null;
    }
  }

  void _markOptimisticSent(MessageModel optimistic) {
    final idx = messagesDetail.indexOf(optimistic);
    if (idx == -1) return;

    messagesDetail[idx] = MessageModel(
      sender: optimistic.sender,
      senderAvatar: optimistic.senderAvatar,
      text: optimistic.text,
      type: optimistic.type,
      previewText: optimistic.previewText,
      attachments: optimistic.attachments,
      location: optimistic.location,
      isSender: optimistic.isSender,
      sended: true,
      time: optimistic.time,
      date: optimistic.date,
    );
  }

  void _updateThreadPreview({required String threadId, required String text}) {
    final currentUserName =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name')
            as String? ??
        '';
    final currentUserAvatar = StorageService.readMapData(
      key: LocalStorageKeys.user,
      mapKey: 'avatar_url',
    )?.toString();
    final threadIdx = filteredMessages.indexWhere((t) => t.id == threadId);
    if (threadIdx == -1) return;

    final updated = filteredMessages[threadIdx].copyWith(
      newestMessage: text,
      newestMessageSender: currentUserName,
      newestMessageSenderAvatar: currentUserAvatar,
      time: MessageModel.diffForHumans(DateTime.now().toIso8601String()),
      isRead: true,
      unreadMessages: 0,
    );
    filteredMessages.removeAt(threadIdx);
    filteredMessages.insert(0, updated);
  }
}
