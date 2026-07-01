import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/client/home/controller.dart';
import 'package:sukientotapp/data/providers/client/booking_provider.dart';
import 'package:sukientotapp/domain/repositories/location_repository.dart';
import 'package:sukientotapp/data/models/location_model.dart';
import 'package:sukientotapp/data/models/client/event_order_model.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/booking_loading_dialog.dart';

class ClientBookingController extends GetxController {
  final BookingProvider _bookingProvider;
  final LocationRepository _locationRepository;

  static const String customEventTypeKey = 'event_type_custom';
  static const int totalStages = 3;
  static const int minEventDurationMinutes = 5;
  static const int maxBookingPhotos = 5;
  static const int maxBookingPhotoBytes = 20 * 1024 * 1024;
  static const Set<String> allowedBookingPhotoExtensions = {
    'jpeg',
    'jpg',
    'png',
    'webp',
  };

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxInt currentStage = 0.obs;

  final RxList<String> eventTypes = <String>[].obs;
  //location models
  final provinces = <LocationModel>[].obs;
  final wards = <LocationModel>[].obs;

  final isFetchingProvinces = false.obs;
  final isFetchingWards = false.obs;

  // ID mappings for events
  final List<Map<String, dynamic>> _apiEvents = [];
  int? categoryId;

  final RxString selectedStartTime = ''.obs;
  final RxString selectedEndTime = ''.obs;
  final RxString selectedEventDate = ''.obs;
  final RxString selectedEventType = ''.obs;

  final RxString selectedProvince = ''.obs;
  final RxList<XFile> bookingPhotos = <XFile>[].obs;

  final selectedProvinceModel = Rx<LocationModel?>(null);
  final selectedWardModel = Rx<LocationModel?>(null);

  final TextEditingController customEventController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController addressDetailController = TextEditingController();

  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  ClientBookingController(this._bookingProvider, this._locationRepository);

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      categoryId = args['category_id'] as int?;
    }

    // Clear errors when user types
    customEventController.addListener(() {
      if (customEventController.text.isNotEmpty) {
        fieldErrors.remove('customEvent');
      }
    });

    addressDetailController.addListener(() {
      if (addressDetailController.text.isNotEmpty) {
        fieldErrors.remove('locationDetail');
      }
    });

    loadInitialData();
  }

  bool get shouldShowCustomEvent =>
      selectedEventType.value == customEventTypeKey;
  bool get isFirstStage => currentStage.value == 0;
  bool get isLastStage => currentStage.value == totalStages - 1;

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      final fetchedTypes = await _bookingProvider.getEventTypes();
      _apiEvents.assignAll(fetchedTypes);

      final typeNames = fetchedTypes
          .map((e) => (e['name'] as String).trim())
          .toList();
      eventTypes.assignAll([...typeNames, customEventTypeKey]);
    } catch (e) {
      logger.e('Failed to load event types: $e');
      eventTypes.assignAll([customEventTypeKey]);
    }

    selectedStartTime.value = '';
    selectedEndTime.value = '';
    selectedEventType.value = '';

    await fetchProvinces();

    isLoading.value = false;
  }

  void nextStage() {
    if (!_validateCurrentStage()) return;

    if (currentStage.value < totalStages - 1) {
      currentStage.value += 1;
    }
  }

  void previousStage() {
    if (currentStage.value > 0) {
      currentStage.value -= 1;
    }
  }

  void startOver() {
    currentStage.value = 0;
  }

  void selectStartTime(String value) {
    selectedStartTime.value = value;
    fieldErrors.remove('startTime');
  }

  void selectEndTime(String value) {
    selectedEndTime.value = value;
    fieldErrors.remove('endTime');
  }

  void selectEventDate(DateTime date) {
    selectedEventDate.value = DateFormat('dd/MM/yyyy').format(date);
    fieldErrors.remove('eventDate');
  }

  void selectEventType(String value) {
    selectedEventType.value = value;
    fieldErrors.remove('eventType');
    if (value != customEventTypeKey) {
      customEventController.clear();
      fieldErrors.remove('customEvent');
    }
  }

  Future<void> fetchProvinces() async {
    try {
      isFetchingProvinces.value = true;
      final data = await _locationRepository.getProvinces();
      provinces.assignAll(data);
    } catch (e) {
      logger.e('[ClientBookingController] Error fetching provinces: $e');
      Get.snackbar('error'.tr, 'failed_to_load_provinces'.tr);
    } finally {
      isFetchingProvinces.value = false;
    }
  }

  Future<void> fetchWards(int provinceId) async {
    try {
      isFetchingWards.value = true;
      wards.clear();
      final data = await _locationRepository.getWards(provinceId);
      wards.assignAll(data);
    } catch (e) {
      logger.e('[ClientBookingController] Error fetching wards: $e');
      Get.snackbar('error'.tr, 'failed_to_load_wards'.tr);
    } finally {
      isFetchingWards.value = false;
    }
  }

  void selectProvince(LocationModel province) {
    if (selectedProvinceModel.value?.id != province.id) {
      selectedProvinceModel.value = province;
      selectedWardModel.value = null;
      fieldErrors.remove('province');
      fieldErrors.remove('ward');
      fetchWards(province.id);
    }
  }

  void selectWard(LocationModel ward) {
    selectedWardModel.value = ward;
    fieldErrors.remove('ward');
  }

  Future<void> addBookingPhotos(List<XFile> photos) async {
    if (photos.isEmpty) return;

    final int remainingSlots = maxBookingPhotos - bookingPhotos.length;
    if (remainingSlots <= 0) {
      final String message = 'booking_stage_photo_max_error'.tr;
      fieldErrors['bookingPhoto'] = message;
      Get.snackbar('error'.tr, message);
      return;
    }

    final List<XFile> acceptedPhotos = [];
    for (final photo in photos.take(remainingSlots)) {
      final String? errorMessage = await _validateBookingPhoto(photo);
      if (errorMessage != null) {
        fieldErrors['bookingPhoto'] = errorMessage;
        Get.snackbar('error'.tr, errorMessage);
        return;
      }

      acceptedPhotos.add(photo);
    }

    bookingPhotos.addAll(acceptedPhotos);
    fieldErrors.remove('bookingPhoto');

    if (photos.length > remainingSlots) {
      Get.snackbar('notification'.tr, 'booking_stage_photo_max_notice'.tr);
    }
  }

  Future<void> addBookingPhoto(XFile photo) async {
    await addBookingPhotos([photo]);
  }

  void removeBookingPhotoAt(int index) {
    if (index < 0 || index >= bookingPhotos.length) {
      return;
    }

    bookingPhotos.removeAt(index);
    fieldErrors.remove('bookingPhoto');
  }

  void clearBookingPhotos() {
    bookingPhotos.clear();
    fieldErrors.remove('bookingPhoto');
  }

  int? _getEventId(String name) {
    return _apiEvents.firstWhereOrNull(
      (e) => (e['name'] as String).trim() == name,
    )?['id'];
  }

  bool _validateCurrentStage() {
    bool isValid = true;
    fieldErrors.clear();

    if (currentStage.value == 0) {
      if (selectedEventDate.value.isEmpty) {
        fieldErrors['eventDate'] = 'Vui lòng chọn ngày đặt lịch.';
        isValid = false;
      }
      if (selectedStartTime.value.isEmpty) {
        fieldErrors['startTime'] = 'Vui lòng chọn giờ bắt đầu.';
        isValid = false;
      }
      if (selectedEndTime.value.isEmpty) {
        fieldErrors['endTime'] = 'Vui lòng chọn giờ kết thúc.';
        isValid = false;
      }

      if (isValid) {
        try {
          final dateParsed = DateFormat(
            'dd/MM/yyyy',
          ).parse(selectedEventDate.value);
          final startParsed = DateFormat(
            'HH:mm',
          ).parse(selectedStartTime.value);
          final endParsed = DateFormat('HH:mm').parse(selectedEndTime.value);

          final startDateTime = DateTime(
            dateParsed.year,
            dateParsed.month,
            dateParsed.day,
            startParsed.hour,
            startParsed.minute,
          );
          final endDateTime = DateTime(
            dateParsed.year,
            dateParsed.month,
            dateParsed.day,
            endParsed.hour,
            endParsed.minute,
          );
          final now = DateTime.now();

          if (startDateTime.isBefore(now)) {
            fieldErrors['eventDate'] =
                'Thời gian tổ chức sự kiện phải là thời gian tới.';
            fieldErrors['startTime'] =
                'Thời gian tổ chức sự kiện phải là thời gian tới.';
            isValid = false;
          } else {
            final nowPlusLead = now.add(const Duration(minutes: 15));
            if (startDateTime.isBefore(nowPlusLead)) {
              fieldErrors['startTime'] =
                  'Bạn phải đặt lịch trước ít nhất 15 phút.';
              isValid = false;
            }
          }

          if (startDateTime.isAfter(endDateTime) ||
              startDateTime.isAtSameMomentAs(endDateTime)) {
            fieldErrors['startTime'] = 'Giờ bắt đầu phải nhỏ hơn giờ kết thúc.';
            isValid = false;
          }

          final duration = endDateTime.difference(startDateTime).inMinutes;
          if (duration < minEventDurationMinutes) {
            fieldErrors['endTime'] =
                'Thời gian tổ chức sự kiện phải ít nhất $minEventDurationMinutes phút.';
            isValid = false;
          }
        } catch (e) {
          fieldErrors['startTime'] = 'Không thể xác định ngày/giờ.';
          isValid = false;
        }
      }
      return isValid;
    }

    if (currentStage.value == 1) {
      if (shouldShowCustomEvent) {
        if (customEventController.text.trim().isEmpty) {
          fieldErrors['customEvent'] = 'Vui lòng nhập sự kiện.';
          isValid = false;
        } else if (customEventController.text.trim().length < 5) {
          fieldErrors['customEvent'] =
              'Chi tiết sự kiện phải có ít nhất 5 ký tự.';
          isValid = false;
        }
      } else {
        if (selectedEventType.value.isEmpty ||
            _getEventId(selectedEventType.value) == null) {
          fieldErrors['eventType'] = 'Vui lòng chọn sự kiện.';
          isValid = false;
        }
      }
      return isValid;
    }

    if (currentStage.value == 2) {
      if (selectedProvinceModel.value == null) {
        fieldErrors['province'] = 'Vui lòng chọn tỉnh/thành phố.';
        isValid = false;
      }
      if (selectedWardModel.value == null) {
        fieldErrors['ward'] = 'Vui lòng chọn phường/xã.';
        isValid = false;
      }
      if (addressDetailController.text.trim().isEmpty) {
        fieldErrors['locationDetail'] = 'Vui lòng nhập địa chỉ chi tiết.';
        isValid = false;
      } else if (addressDetailController.text.trim().length < 5) {
        fieldErrors['locationDetail'] =
            'Địa chỉ chi tiết phải có ít nhất 5 ký tự.';
        isValid = false;
      }
      return isValid;
    }

    return true;
  }

  Future<String?> _validateBookingPhoto(XFile photo) async {
    final String extension = photo.name.split('.').last.toLowerCase();
    if (!allowedBookingPhotoExtensions.contains(extension)) {
      return 'Ảnh chỉ hỗ trợ định dạng JPEG, PNG, JPG hoặc WEBP.';
    }

    final int fileSize = await photo.length();
    if (fileSize > maxBookingPhotoBytes) {
      return 'Ảnh yêu cầu không được vượt quá 20MB.';
    }

    return null;
  }

  Future<void> submitBooking() async {
    if (isSubmitting.value) return;

    // Validate the last stage before proceeding to actual submit
    if (!_validateCurrentStage()) return;

    if (categoryId == null) {
      Get.snackbar('error'.tr, 'Vui lòng thử lại sau.');
      return;
    }

    if (selectedProvinceModel.value == null ||
        selectedWardModel.value == null) {
      Get.snackbar('error'.tr, 'missing_location'.tr);
      return;
    }

    isSubmitting.value = true;
    Get.dialog(const BookingLoadingDialog(), barrierDismissible: false);

    // Parse date from dd/MM/yyyy to yyyy-MM-dd
    String isoDate = '';
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(selectedEventDate.value);
      isoDate = DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;
      Get.snackbar('error'.tr, 'invalid_date_format'.tr);
      return;
    }

    final Map<String, dynamic> payload = {
      'order_date': isoDate,
      'start_time': selectedStartTime.value,
      'end_time': selectedEndTime.value.isEmpty ? null : selectedEndTime.value,
      'province_id': selectedProvinceModel.value!.id,
      'ward_id': selectedWardModel.value!.id,
      'location_detail': addressDetailController.text.trim(),
      'note': noteController.text.trim(),
      'category_id': categoryId,
    };

    if (shouldShowCustomEvent) {
      payload['custom_event'] = customEventController.text.trim();
      payload['event_id'] = null;
    } else {
      payload['event_id'] = _getEventId(selectedEventType.value);
      payload['custom_event'] = null;
    }

    logger.d('Submitting payload: $payload');

    final result = await _bookingProvider.saveBookingInfo(
      payload,
      bookingPhotos: bookingPhotos.toList(),
    );

    if (Get.isDialogOpen ?? false) {
      Get.back(); // Close loading dialog
    }

    if (result['success'] == true) {
      Get.snackbar('success'.tr, 'booking_success'.tr);

      final order = EventOrderModel.fromJson(result['bill']);

      if (Get.isRegistered<ClientHomeController>()) {
        Get.find<ClientHomeController>().incrementPendingOrders();
      }

      // Pop all screens (including booking flow and partner details)
      // until we are back at the Main Bottom Navigation screen (ClientHome)
      Get.until(
        (route) => route.settings.name == Routes.clientHome || route.isFirst,
      );

      try {
        Get.find<ClientBottomNavigationController>().setIndex(1);
      } catch (e) {
        logger.e('Navigation controller not found: $e');
      }

      // Then push order details on top of the Orders tab
      Get.toNamed(
        Routes.clientOrderDetail,
        arguments: {'order': order, 'isHistory': false},
      );

      // Trigger a refresh of the current orders tab if the controller is alive
      try {
        Get.find<ClientOrderController>().fetchEventOrders();
      } catch (e) {
        logger.e('Order controller not found, skipping refresh: $e');
      }
    } else {
      Get.snackbar('error'.tr, result['message'] ?? 'booking_failed'.tr);
      Get.back(); // Fallback back to partner screen
    }

    isSubmitting.value = false;
  }
}
