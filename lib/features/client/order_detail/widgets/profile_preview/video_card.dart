part of '../profile_preview.dart';

class _VideoCard extends StatelessWidget {
  final PublicProfilePayloadModel payload;

  const _VideoCard({required this.payload});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'introduction_video'.tr,
      child: payload.hasVideo
          ? InlineVideoPlayer(
              htmlContent: payload.videoUrl,
              thumbnailUrl: payload.videoThumbnailUrl,
              onTapExternal: () {
                final String url = payload.externalVideoUrl;
                if (url.isEmpty) return;

                Get.toNamed(
                  Routes.webView,
                  arguments: <String, dynamic>{
                    'url': url,
                    'title': 'introduction_video'.tr,
                    'allowReload': true,
                  },
                );
              },
            )
          : _EmptyText(text: 'public_profile_no_video'.tr),
    );
  }
}
