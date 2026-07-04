import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/location_model.dart';
import 'package:sukientotapp/data/models/partner/service_area_model.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

import 'controller.dart';

class PartnerServiceAreasScreen extends GetView<PartnerServiceAreasController> {
  const PartnerServiceAreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        title: Text('service_areas'.tr),
        prefixes: [FHeaderAction.back(onPress: () => Get.back())],
      ),
      child: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCard(controller: controller),
                          const SizedBox(height: 20),
                          _SectionLabel(label: 'select_service_area'.tr),
                          const SizedBox(height: 10),
                          _FormCard(
                            children: [
                              _LocationSection(controller: controller),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(label: 'selected_service_areas'.tr),
                          const SizedBox(height: 10),
                          _SelectedAreasCard(controller: controller),
                          _LoadMoreServiceAreas(controller: controller),
                        ],
                      ),
                    ),
                  ),
                  _BottomActionBar(controller: controller),
                ],
              ),
      ),
    );
  }
}

class _LoadMoreServiceAreas extends StatelessWidget {
  final PartnerServiceAreasController controller;

  const _LoadMoreServiceAreas({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasMoreServiceAreas.value &&
          !controller.isLoadingMoreServiceAreas.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: controller.isLoadingMoreServiceAreas.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton.icon(
                  onPressed: controller.loadMoreServiceAreas,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  label: Text('load_more_service_areas'.tr),
                ),
        ),
      );
    });
  }
}

class _HeroCard extends StatelessWidget {
  final PartnerServiceAreasController controller;

  const _HeroCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.fTheme.colors.primary,
            context.fTheme.colors.primary.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(FIcons.mapPinned, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'service_areas'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    'service_area_count'.trParams({
                      'count': controller.selectedServiceAreaCountLabel,
                    }),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final PartnerServiceAreasController controller;

  const _LocationSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoadingProvinces = controller.provinces.isEmpty;
      final noProvince = controller.selectedProvince.value == null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'province'.tr,
            style: TextStyle(
              fontSize: 13,
              color: context.fTheme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          _DropdownContainer(
            context: context,
            isDisabled: false,
            child: isLoadingProvinces
                ? const _LoadingDropdown()
                : InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showLocationBottomSheet(
                      context,
                      title: 'province'.tr,
                      items: controller.provinces,
                      selectedValue: controller.selectedProvince.value,
                      onSelect: (item) {
                        controller.onProvinceChanged(item);
                        Get.back();
                      },
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              controller.selectedProvince.value?.name ??
                                  'select_province'.tr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: controller.selectedProvince.value != null
                                    ? context.fTheme.colors.foreground
                                    : context.fTheme.colors.mutedForeground,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.fTheme.colors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'ward'.tr,
            style: TextStyle(
              fontSize: 13,
              color: context.fTheme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          _DropdownContainer(
            context: context,
            isDisabled: noProvince,
            child: controller.isLoadingWards.value
                ? const _LoadingDropdown()
                : InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: noProvince
                        ? null
                        : () async {
                            await controller.ensureAllServiceAreasLoaded();
                            if (!context.mounted) return;
                            _showMultiLocationBottomSheet(context);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              noProvince
                                  ? 'select_province_first'.tr
                                  : 'select_service_area_wards'.tr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: noProvince
                                    ? context.fTheme.colors.mutedForeground
                                    : context.fTheme.colors.foreground,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.fTheme.colors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  String _removeDiacritics(String str) {
    const withDiacritics =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    var lowerStr = str.toLowerCase();
    for (int i = 0; i < withDiacritics.length; i++) {
      lowerStr = lowerStr.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return lowerStr;
  }

  void _showLocationBottomSheet(
    BuildContext context, {
    required String title,
    required List<LocationModel> items,
    required LocationModel? selectedValue,
    required void Function(LocationModel) onSelect,
  }) {
    final query = ''.obs;

    Get.bottomSheet(
      Material(
        color: context.fTheme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                title,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final q = _removeDiacritics(query.value);
                  final filtered = items
                      .where((item) => _removeDiacritics(item.name).contains(q))
                      .toList();

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = selectedValue?.id == item.id;

                      return InkWell(
                        onTap: () => onSelect(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  FIcons.check,
                                  color: context.fTheme.colors.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
    );
  }

  void _showMultiLocationBottomSheet(BuildContext context) {
    final query = ''.obs;

    Get.bottomSheet(
      Material(
        color: context.fTheme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                'ward'.tr,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  controller.selectionVersion.value;
                  final allSelected = controller.areAllCurrentWardsSelected;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'service_area_count'.trParams({
                            'count': controller.selectedServiceAreaCountLabel,
                          }),
                          style: TextStyle(
                            color: context.fTheme.colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: allSelected
                            ? controller.clearCurrentProvinceWards
                            : controller.selectAllCurrentWards,
                        icon: Icon(
                          allSelected
                              ? FIcons.circleMinus
                              : FIcons.circleCheck,
                          size: 16,
                        ),
                        label: Text(
                          allSelected
                              ? 'unselect_city_wards'.tr
                              : 'select_all_city_wards'.tr,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  controller.selectionVersion.value;
                  final q = _removeDiacritics(query.value);
                  final filtered = controller.wards
                      .where((item) => _removeDiacritics(item.name).contains(q))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'no_data'.tr,
                        style: TextStyle(
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = controller.selectedLocationIds
                          .contains(item.id);

                      return InkWell(
                        key: ValueKey('ward_${item.id}_$isSelected'),
                        onTap: () => controller.toggleWard(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? FIcons.circleCheck
                                    : FIcons.circle,
                                color: isSelected
                                    ? context.fTheme.colors.primary
                                    : context.fTheme.colors.mutedForeground,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: CustomButtonPlus(
                    onTap: () => Get.back(),
                    width: double.infinity,
                    btnText: 'done'.tr,
                    textSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 44,
                    borderRadius: 12,
                    borderColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
    );
  }
}

class _SelectedAreasCard extends StatelessWidget {
  final PartnerServiceAreasController controller;

  const _SelectedAreasCard({required this.controller});

  String _removeDiacritics(String str) {
    const withDiacritics =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    var lowerStr = str.toLowerCase();
    for (int i = 0; i < withDiacritics.length; i++) {
      lowerStr = lowerStr.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return lowerStr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fTheme.colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fTheme.colors.border),
      ),
      child: Obx(() {
        if (controller.serviceAreas.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(
                  FIcons.map,
                  color: context.fTheme.colors.mutedForeground,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'no_service_areas'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.fTheme.colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final searchQuery = _removeDiacritics(
          controller.selectedAreaSearch.value.trim(),
        );
        final visibleServiceAreas = searchQuery.isEmpty
            ? controller.serviceAreas.toList()
            : controller.serviceAreas
                  .where((area) {
                    final searchable = _removeDiacritics(
                      '${area.name} ${area.provinceName}',
                    );

                    return searchable.contains(searchQuery);
                  })
                  .toList();

        final groupedAreas = <String, List<PartnerServiceAreaModel>>{};
        for (final area in visibleServiceAreas) {
          final provinceName = area.provinceName.isEmpty
              ? 'unknown_province'.tr
              : area.provinceName;
          groupedAreas.putIfAbsent(provinceName, () => []).add(area);
        }
        final provinceNames = groupedAreas.keys.toList()..sort();

        return Column(
          children: [
            _SelectedAreaSearchField(controller: controller),
            if (visibleServiceAreas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'no_matching_service_areas'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.fTheme.colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ),
            ...provinceNames.map((provinceName) {
              final areas = groupedAreas[provinceName]!;
              areas.sort((a, b) => a.name.compareTo(b.name));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.fTheme.colors.muted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.fTheme.colors.border.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: Row(
                          children: [
                            Icon(
                              FIcons.mapPinned,
                              size: 15,
                              color: context.fTheme.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provinceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.fTheme.colors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ward_count'.trParams({
                                  'count': areas.length.toString(),
                                }),
                                style: TextStyle(
                                  color: context.fTheme.colors.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: context.fTheme.colors.border),
                      ...List.generate(areas.length, (index) {
                        final area = areas[index];
                        final isLast = index == areas.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      area.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.fTheme.colors.foreground,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        controller.removeServiceArea(area.id),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        FIcons.x,
                                        size: 15,
                                        color: context
                                            .fTheme
                                            .colors
                                            .mutedForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                                color: context.fTheme.colors.border.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}

class _SelectedAreaSearchField extends StatefulWidget {
  final PartnerServiceAreasController controller;

  const _SelectedAreaSearchField({required this.controller});

  @override
  State<_SelectedAreaSearchField> createState() =>
      _SelectedAreaSearchFieldState();
}

class _SelectedAreaSearchFieldState extends State<_SelectedAreaSearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.selectedAreaSearch.value,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 40,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: _textController,
            onChanged: (value) =>
                widget.controller.selectedAreaSearch.value = value,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'search_service_area_to_remove'.tr,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: context.fTheme.colors.mutedForeground,
              ),
              suffixIcon: Obx(
                () => widget.controller.selectedAreaSearch.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          _textController.clear();
                          widget.controller.selectedAreaSearch.value = '';
                        },
                        icon: Icon(
                          FIcons.x,
                          size: 15,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final PartnerServiceAreasController controller;

  const _BottomActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: context.fTheme.colors.background,
          border: Border(top: BorderSide(color: context.fTheme.colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: context.fTheme.colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => controller.clearAll(),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        'clear_all'.tr,
                        style: TextStyle(
                          color: context.fTheme.colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(
                () => CustomButtonPlus(
                  onTap: controller.isSaving.value
                      ? () {}
                      : controller.saveServiceAreas,
                  isDisabled: controller.isSaving.value,
                  isLoading: controller.isSaving.value,
                  width: double.infinity,
                  btnText: 'save'.tr,
                  textSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 44,
                  borderRadius: 12,
                  borderColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: context.fTheme.colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.fTheme.colors.foreground,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fTheme.colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fTheme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DropdownContainer extends StatelessWidget {
  final BuildContext context;
  final bool isDisabled;
  final Widget child;

  const _DropdownContainer({
    required this.context,
    required this.isDisabled,
    required this.child,
  });

  @override
  Widget build(BuildContext ctx) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? context.fTheme.colors.border.withValues(alpha: 0.4)
                : context.fTheme.colors.border,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isDisabled
              ? context.fTheme.colors.muted.withValues(alpha: 0.15)
              : null,
        ),
        child: child,
      ),
    );
  }
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
