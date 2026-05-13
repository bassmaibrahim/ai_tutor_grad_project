// lib/widgets/recent_studies/study_detail/youtube_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import 'section_title.dart';

class YouTubeSection extends StatelessWidget {
  final Map<String, dynamic>? youtubeData;

  const YouTubeSection({Key? key, required this.youtubeData}) : super(key: key);

  List<Map<String, dynamic>> _extractVideos() {
    if (youtubeData == null) return [];
    final videosRaw = youtubeData!['videos'];
    if (videosRaw is List) {
      return videosRaw
          .whereType<Map<String, dynamic>>()
          .where((v) =>
      (v['url']?.toString() ?? '').isNotEmpty ||
          (v['title']?.toString() ?? '').isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final videos = _extractVideos();
    if (videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Recommended Videos'),
        const SizedBox(height: AppSpacing.sm),
        ...videos.map((video) => _YouTubeCard(video: video)),
      ],
    );
  }
}

class _YouTubeCard extends StatelessWidget {
  final Map<String, dynamic> video;

  const _YouTubeCard({required this.video});

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Failed to open URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? 'Untitled Video';
    final channel = video['channel'] ?? '';
    final url = video['url'] ?? '';
    final thumbnail = video['thumbnail'] ?? '';
    final description = video['description'] ?? '';

    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnail.isNotEmpty
                  ? Image.network(
                thumbnail,
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackThumbnail(),
              )
                  : _fallbackThumbnail(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      channel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: IconButton(
                  icon: const Icon(Icons.open_in_new,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => _openUrl(url),
                  tooltip: 'Watch on YouTube',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumbnail() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.red, size: 28),
      ),
    );
  }
}