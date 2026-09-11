import 'package:flutter_html/flutter_html.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/webview_whitelist.dart';
import 'package:sukientotapp/data/models/common/profile_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controller.dart';

import 'package:sukientotapp/features/components/button/plus.dart';

class MyProfileScreen extends GetView<MyProfileController> {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      resizeToAvoidBottomInset: false,
      header: FHeader.nested(
        title: Text('my_profile'.tr),
        prefixes: [FHeaderAction.back(onPress: () => Get.back())],
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.profile.value;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('failed_to_load_profile'.tr),
                const SizedBox(height: 12),
                CustomButtonPlus(
                  onTap: () => controller.fetchProfile(),
                  width: double.infinity,
                  btnText: 'retry'.tr,
                  textSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 44,
                  borderRadius: 12,
                  borderColor: Colors.transparent,
                ),
              ],
            ),
          );
        }

        final joinedDate = profile.createdAt.isNotEmpty
            ? DateFormat(
                'MMMM d, yyyy',
              ).format(DateTime.parse(profile.createdAt))
            : '-';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Card ──────────────────────────────────────────
              _ProfileHeroCard(profile: profile)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.02, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 20),

              // ── Basic Info ─────────────────────────────────────────
              _SectionLabel(label: 'basic_info'.tr)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.02, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 10),
              _InfoCard(
                    children: [
                      _InfoRow(
                        icon: FIcons.phone,
                        label: 'phone_number'.tr,
                        value: profile.phone,
                      ),
                      _InfoRow(
                        icon: FIcons.mail,
                        label: 'email_address'.tr,
                        value: profile.email,
                      ),
                      _InfoRow(
                        icon: FIcons.clock,
                        label: 'joined'.tr,
                        value: joinedDate,
                      ),
                      _InfoRow(
                        icon: FIcons.building,
                        label: 'location'.tr,
                        value: profile.location,
                      ),
                      if (profile.bio.isNotEmpty && profile.bio != '<p></p>')
                        _InfoHtmlRow(
                          icon: FIcons.info,
                          label: 'bio'.tr,
                          html: profile.bio,
                        ),
                    ],
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.02, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 20),

              // ── Introduction Video ────────────────────────────────
              if (profile.videoUrl.isNotEmpty) ...[
                _SectionLabel(label: 'introduction_video'.tr)
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.02, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 10),
                _VideoCard(iframeSrc: profile.videoUrl)
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.02, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 20),
              ],

              // ── Edit Button ────────────────────────────────────────
              CustomButtonPlus(
                    onTap: () => Get.toNamed(
                      Routes.editProfile,
                      arguments: controller.profile.value,
                    ),
                    width: double.infinity,
                    btnText: 'edit_profile'.tr,
                    textSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 44,
                    borderRadius: 12,
                    borderColor: Colors.transparent,
                  )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Profile Hero Card ────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileHeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPartner = profile.partnerName != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.fTheme.colors.primary,
            context.fTheme.colors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          FAvatar(
            image: CachedNetworkImageProvider(profile.avatarUrl),
            size: 80.0,
            semanticsLabel: 'User avatar',
            fallback: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.fTheme.colors.primaryForeground,
              letterSpacing: -0.3,
            ),
          ),
          if (profile.partnerName != null) ...[
            const SizedBox(height: 4),
            Text(
              profile.partnerName!,
              style: TextStyle(
                fontSize: 13,
                color: context.fTheme.colors.primaryForeground.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroBadge(
                text: isPartner ? 'partner'.tr : 'customer'.tr,
                icon: isPartner
                    ? Icons.storefront_outlined
                    : Icons.person_outline_rounded,
              ),
              const SizedBox(width: 8),
              _HeroBadge(
                text: profile.isLegit ? 'verified'.tr : 'unverified'.tr,
                icon: profile.isLegit
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 1,
            color: context.fTheme.colors.primaryForeground.withValues(
              alpha: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                icon: Icons.check_circle_outline_rounded,
                label: 'completed_orders'.tr,
                value: '${profile.stats.completedOrders}',
              ),
              Container(
                width: 1,
                height: 36,
                color: context.fTheme.colors.primaryForeground.withValues(
                  alpha: 0.25,
                ),
              ),
              _HeroStat(
                icon: Icons.cancel_outlined,
                label: 'cancellation_rate'.tr,
                value: '${profile.stats.cancelledOrdersPct}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _HeroBadge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.fTheme.colors.primaryForeground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.fTheme.colors.primaryForeground.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.fTheme.colors.primaryForeground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.fTheme.colors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 14,
            color: context.fTheme.colors.primaryForeground.withValues(
              alpha: 0.75,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.fTheme.colors.primaryForeground,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.fTheme.colors.primaryForeground.withValues(
                alpha: 0.7,
              ),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? sub;

  const _SectionLabel({required this.label}) : sub = null;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        if (sub != null) ...[
          const SizedBox(width: 8),
          Text(
            sub!,
            style: TextStyle(
              fontSize: 11,
              color: context.fTheme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

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
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) ...[
              const SizedBox(height: 4),
              Divider(color: context.fTheme.colors.border, height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.fTheme.colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.fTheme.colors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.fTheme.colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoHtmlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String html;

  const _InfoHtmlRow({
    required this.icon,
    required this.label,
    required this.html,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.fTheme.colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.fTheme.colors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              Html(data: html),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Video Card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatefulWidget {
  final String iframeSrc;

  const _VideoCard({required this.iframeSrc});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  static const _inlineBaseUrl = 'https://sukientot.com';
  late final WebViewController _webViewController;
  bool _isLoading = true;

  String _buildWrappedHtml(String htmlContent) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; background-color: #000; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  $htmlContent
</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.366',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.isMainFrame) {
              if (request.url == _inlineBaseUrl ||
                  request.url == '$_inlineBaseUrl/') {
                return NavigationDecision.navigate;
              }
              if (WebviewWhitelist.isAllowed(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(
        _buildWrappedHtml(widget.iframeSrc),
        baseUrl: _inlineBaseUrl,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.fTheme.colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (_isLoading)
                Container(
                  color: context.fTheme.colors.muted,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}