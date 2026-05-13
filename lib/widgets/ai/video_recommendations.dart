// lib/screens/ai/widgets/video_recommendations.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

class VideoRecommendations extends StatelessWidget {
  final List<Map<String, dynamic>> videos;

  const VideoRecommendations({
    Key? key,
    required this.videos,
  }) : super(key: key);

  Future<void> _openVideo(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint("Failed to open video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Text("No videos available");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minCardWidth = 160;

        final int cardsPerRow =
        (constraints.maxWidth / minCardWidth)
            .floor()
            .clamp(1, 4);

        final double adaptiveWidth =
            (constraints.maxWidth -
                (cardsPerRow - 1) * AppSpacing.sm) /
                cardsPerRow;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: videos.map((video) {
            final String? url = video['url'];

            return SizedBox(
              width: adaptiveWidth,
              child: GestureDetector(
                onTap: () => _openVideo(url),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail placeholder
                        Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Title
                        Text(
                          video['title'] ?? '',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Channel name
                        if (video['channel'] != null)
                          Text(
                            video['channel'],
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),

                        // Click hint
                        const Text(
                          "Tap to watch ▶",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}