import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sukientotapp/core/routes/pages.dart';
import 'package:sukientotapp/data/models/client/blog_home_model.dart';
import 'package:sukientotapp/features/components/common/blog_card.dart';

class ClientBlogPanel extends StatelessWidget {
  const ClientBlogPanel({super.key, required this.blogs});

  final List<BlogItemModel> blogs;

  static const double panelHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: panelHeight,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: blogs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final blog = blogs[index];
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: BlogCard(
                imageUrl: blog.thumbnail ?? '',
                title: blog.title,
                address: blog.address ?? '',
                capacity: blog.maxPeople,
                category: blog.type,
                tag: blog
                    .type, // `TODO: backend payload has no tag mapped currently, so we will temporary use type as tag`
                date: DateTime.now(), // Use publishedHuman for date later if needed, or parse
                onTap: () {
                  Get.toNamed(
                    Routes.webView,
                    arguments: {
                      'url': blog.blogUrl,
                      'title': blog.title,
                    },
                  );
                },
              ),
            );
          },
        ),
      ).animate(delay: 500.ms).fadeIn(duration: 200.ms),
    );
  }
}
