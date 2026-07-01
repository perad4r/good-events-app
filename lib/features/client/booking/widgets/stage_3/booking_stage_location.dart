import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import 'package:sukientotapp/data/models/location_model.dart';
import '../booking_fields.dart';
import '../booking_header.dart';
import '../booking_layout.dart';

class BookingLocationStage extends GetView<ClientBookingController> {
  const BookingLocationStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingHeader(
          icon: FIcons.mapPin,
          title: 'booking_stage_location_title'.tr,
          subtitle: 'booking_stage_location_subtitle'.tr,
        ),
        const SizedBox(height: 24),
        BookingTwoColumnRow(
          left: Obx(
            () => BookingSelectField(
              label: 'booking_location'.tr,
              value: controller.selectedProvinceModel.value?.name ?? '',
              placeholder: 'booking_select_province'.tr,
              errorText: controller.fieldErrors['province'],
              onTap: () => _showOptions<LocationModel>(
                title: 'booking_location'.tr,
                options: controller.provinces,
                selectedValue: controller.selectedProvinceModel.value,
                onSelect: controller.selectProvince,
                labelBuilder: (m) => m.name,
              ),
            ),
          ),
          right: Obx(
            () {
              final hasProvince = controller.selectedProvinceModel.value != null;
              final isLoadingWards = controller.isFetchingWards.value;

              return BookingSelectField(
                label: 'booking_location_ward'.tr,
                value: controller.selectedWardModel.value?.name ?? '',
                placeholder: isLoadingWards
                    ? 'loading_with_dot'.tr
                    : 'booking_select_ward'.tr,
                errorText: controller.fieldErrors['ward'],
                isLoading: isLoadingWards,
                onTap: () {
                  if (!hasProvince) {
                    Get.snackbar('error'.tr, 'select_province_first'.tr);
                    return;
                  }

                  _showOptions<LocationModel>(
                    title: 'booking_location_ward'.tr,
                    options: controller.wards,
                    selectedValue: controller.selectedWardModel.value,
                    onSelect: controller.selectWard,
                    labelBuilder: (m) => m.name,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => BookingTextField(
            label: 'booking_address_detail'.tr,
            hint: 'booking_address_placeholder'.tr,
            controller: controller.addressDetailController,
            errorText: controller.fieldErrors['locationDetail'],
          ),
        ),
      ],
    );
  }

  String _removeDiacritics(String str) {
    const withDiacritics = 'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    var lowerStr = str.toLowerCase();
    for (int i = 0; i < withDiacritics.length; i++) {
      lowerStr = lowerStr.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return lowerStr;
  }

  void _showOptions<T extends LocationModel>({
    required String title,
    required List<T> options,
    required T? selectedValue,
    required ValueChanged<T> onSelect,
    String Function(T value)? labelBuilder,
  }) {
    if (options.isEmpty) return;
    final query = ''.obs;

    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Get.context!.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FTappable(
                      onPress: () => Get.back(),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'search_with_dot'.tr,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) => query.value = val,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Obx(() {
                  final String q = _removeDiacritics(query.value);
                  final filteredItems = options.where((item) {
                    final normalizedName = _removeDiacritics(item.name);
                    return normalizedName.contains(q);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'no_results_found'.tr,
                        style: TextStyle(
                          color: Get.context!.fTheme.colors.mutedForeground,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final option = filteredItems[index];
                      final label = labelBuilder?.call(option) ?? option.name;
                      final bool isSelected = option.id == selectedValue?.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: context.fTheme.colors.primary,
                              )
                            : null,
                        onTap: () {
                          onSelect(option);
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
