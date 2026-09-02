import 'package:sukientotapp/core/utils/import/global.dart';

class CachedMessageAvatar extends StatelessWidget {
  const CachedMessageAvatar({
    super.key,
    required this.imageUrl,
    this.size = 32,
    this.borderRadius = 16,
    this.fallbackIcon = Icons.person_rounded,
    this.highlighted = false,
  });

  final String? imageUrl;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = _normalizeUrl(imageUrl);
    final fallback = Container(
      color: highlighted
          ? context.fTheme.colors.primary.withValues(alpha: 0.12)
          : context.fTheme.colors.muted,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: size * 0.46,
        color: highlighted
            ? context.fTheme.colors.primary
            : context.fTheme.colors.mutedForeground,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: normalizedUrl == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: normalizedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }

  String? _normalizeUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return null;

    final markdownLink = RegExp(
      r'^\[(https?://[^\]]+)\]\((https?://[^)]+)\)$',
    ).firstMatch(value);
    final normalized = markdownLink?.group(2) ?? value;
    final uri = Uri.tryParse(normalized);
    final hasSupportedScheme =
        uri?.isScheme('http') == true || uri?.isScheme('https') == true;
    if (uri == null || !uri.hasAuthority || !hasSupportedScheme) return null;
    return normalized;
  }
}
