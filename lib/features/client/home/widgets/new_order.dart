import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/client/home/controller.dart';

class NewOrderPanel extends StatefulWidget {
  const NewOrderPanel({super.key, required this.controller});

  final ClientHomeController controller;

  @override
  State<NewOrderPanel> createState() => _NewOrderPanelState();
}

class _NewOrderPanelState extends State<NewOrderPanel> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller?.forward().then((_) => _controller?.reverse());
        Get.find<ClientBottomNavigationController>().setIndex(1);
      },
      child:
          Container(
                padding: const EdgeInsets.fromLTRB(12, 15, 12, 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Obx(() {
                  final summary = widget.controller.summary.value;
                  final count = summary?.pendingPartners ?? 0;
                  final countStr = count > 9 ? '9+' : count.toString();

                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          FIcons.star,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'new_applicant'.trParams({'count': countStr}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'waiting_for_response'.tr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      // if (controller.reviewers.isNotEmpty) ...[
                      const Spacer(),
                      // width is calculated to fit 5 items (4 overlaps + base avatar)
                      SizedBox(
                        width: 38 + (22 * 4),
                        height: 38,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: _buildAvatarList(),
                        ),
                      ),
                      // ] else ...[
                      //`TODO: handle empty state when have data`
                      //   const Spacer(),
                      //   const _AvatarWidget(isLast: true),
                      // ],
                    ],
                  );
                }),
              )
              .animate(
                autoPlay: false,
                onInit: (controller) => _controller = controller,
              )
              .scaleXY(end: 0.95, duration: 100.ms, curve: Curves.easeInOut),
    ).animate(delay: 350.ms).fadeIn(duration: 200.ms);
  }
  List<Widget> _buildAvatarList() {
    final summary = widget.controller.summary.value;
    List<String> reviewers = summary?.pendingPartnerAvatars ?? [];

    // If we have real data but no avatars, or if summary is null (e.g. initial load), show fallback
    if (summary == null || (summary.pendingPartners > 0 && reviewers.isEmpty)) {
      reviewers = [
        'https://i.pravatar.cc/150?img=12',
        'https://i.pravatar.cc/150?img=5',
        'https://i.pravatar.cc/150?img=8',
        'https://i.pravatar.cc/150?img=20',
      ];
    }

    List<Widget> avatars = [];
    final totalCount = summary?.pendingPartners ?? reviewers.length;
    const maxDisplayCount = 4;

    for (var i = 0; i < maxDisplayCount; i++) {
      if (i == maxDisplayCount - 1 && totalCount > maxDisplayCount) {
        // Only show "remaining" if there are more than we can display in the available slots
        final remaining = totalCount - (maxDisplayCount - 1);
        avatars.add(
          Positioned(
            left: i * 22.0,
            child: _AvatarWidget(isLast: true, remaining: remaining),
          ),
        );
      } else if (i < reviewers.length) {
        final reviewerAvatar = reviewers[i];
        avatars.add(
          Positioned(
            left: i * 22.0,
            child: _AvatarWidget(imagePath: reviewerAvatar),
          ),
        );
      } else {
        break;
      }
    }

    avatars.add(
      Positioned(
        left: maxDisplayCount * 22.0,
        child: const _MoreAvatarButton(),
      ),
    );

    return avatars;
  }
}

class _AvatarWidget extends StatelessWidget {
  final String imagePath;
  final bool isLast;
  final int remaining;

  const _AvatarWidget({
    this.imagePath = '',
    this.isLast = false,
    this.remaining = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.lightMuted,
        child: _buildAvatarContent(context),
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    if (isLast) {
      final displayText = remaining > 0 ? '+$remaining' : '';
      return Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (imagePath.isEmpty) {
      return const Icon(
        Icons.person,
        size: 20,
        color: AppColors.lightMutedForeground,
      );
    }

    return ClipOval(
      child: Image.network(
        imagePath,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 20,
            color: AppColors.lightMutedForeground,
          );
        },
      ),
    );
  }
}

class _MoreAvatarButton extends StatelessWidget {
  const _MoreAvatarButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.red600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Center(
        child: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
      ),
    );
  }
}
