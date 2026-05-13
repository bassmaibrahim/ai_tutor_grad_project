// // lib/widgets/ai/listen/voice_selector.dart
// import 'package:flutter/material.dart';
// import '../../../constants/app_colors.dart';
// import '../../../constants/app_spacing.dart';
// import '../../../constants/app_typography.dart';
// import '../../../services/tts_service.dart';
//
// class VoiceSelector extends StatelessWidget {
//   final String? selectedDisplayName;
//   final ValueChanged<Map<String, String>> onVoiceChanged;
//
//   const VoiceSelector({
//     Key? key,
//     required this.selectedDisplayName,
//     required this.onVoiceChanged,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final voices = TTSService.preferredVoices;
//     if (voices.isEmpty) return const SizedBox.shrink();
//
//     // Find current display
//     final currentVoice = voices.firstWhere(
//           (v) => v['display'] == selectedDisplayName,
//       orElse: () => voices.first,
//     );
//
//     return GestureDetector(
//       onTap: () => _showPicker(context, voices),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//             horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
//         decoration: BoxDecoration(
//           color: AppColors.primary.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.record_voice_over,
//                 color: AppColors.primary, size: 20),
//             const SizedBox(width: AppSpacing.sm),
//             Text(
//               currentVoice['display'] ?? '',
//               style: AppTextStyles.caption.copyWith(
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(width: AppSpacing.sm),
//             Icon(Icons.arrow_drop_down,
//                 color: AppColors.primary, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showPicker(
//       BuildContext context, List<Map<String, String>> voices) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: AppSpacing.md),
//               Text('Choose a voice',
//                   style: AppTextStyles.heading3
//                       .copyWith(color: AppColors.primary)),
//               const SizedBox(height: AppSpacing.md),
//               ...voices.map((voice) {
//                 final isSelected = voice['display'] == selectedDisplayName;
//                 return ListTile(
//                   leading: Icon(Icons.record_voice_over,
//                       color: isSelected ? AppColors.primary : AppColors.textSecondary),
//                   title: Text(voice['display'] ?? '',
//                       style: AppTextStyles.body.copyWith(
//                         color: isSelected ? AppColors.primary : AppColors.textPrimary,
//                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                       )),
//                   trailing: isSelected
//                       ? const Icon(Icons.check, color: AppColors.primary)
//                       : null,
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     onVoiceChanged(voice);
//                   },
//                 );
//               }),
//               const SizedBox(height: AppSpacing.md),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }