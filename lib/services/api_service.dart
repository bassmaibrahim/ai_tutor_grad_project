// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://backup-grad-llm-production.up.railway.app';

  /// Process a document (PDF, image, or text) and return AI-generated results.
  static Future<Map<String, dynamic>> processDocument({
    required Uint8List fileBytes,
    required String fileName,
    required bool includeSummary,
    required bool includeQA,
    required bool includeYoutube,
    required bool includeExplanation,
    required int numVideos,
    required int numQuestions,
  }) async {
    final clampedVideos = numVideos.clamp(1, 10);
    final clampedQuestions = numQuestions.clamp(1, 10);

    final uri = Uri.parse(
      '$baseUrl/api/v1/process'
          '?include_summary=$includeSummary'
          '&include_qa=$includeQA'
          '&include_youtube=$includeYoutube'
          '&include_explanation=$includeExplanation'
          '&num_videos=$clampedVideos'
          '&num_questions=$clampedQuestions',
    );

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

        // The API nests explanation & key_points inside "summary"
        final summaryData = decoded['summary'] ?? {};

        return {
          'summary': summaryData,
          'key_points':
          List<String>.from(summaryData['key_points'] ?? []),
          'explanation':
          (summaryData['explanation'] ?? '').toString(),
          'qa': decoded['qa'] ?? {},
          'youtube': decoded['youtube'] ?? {},
          'detected_topic': decoded['detected_topic'] ?? '',
          'word_count': decoded['word_count'] ?? 0,
          'file_name': fileName,
        };
      } else {
        throw Exception(
            'API Failed: ${response.statusCode} $responseBody');
      }
    } catch (e) {
      throw Exception('API Request Failed: $e');
    }
  }

  /// Convenience method – keep backward compatibility
  static Future<Map<String, dynamic>> processPdf({
    required Uint8List fileBytes,
    required String fileName,
    required bool includeSummary,
    required bool includeQA,
    required bool includeYoutube,
    required int numVideos,
    required int numQuestions,
  }) async {
    return processDocument(
      fileBytes: fileBytes,
      fileName: fileName,
      includeSummary: includeSummary,
      includeQA: includeQA,
      includeYoutube: includeYoutube,
      includeExplanation: true,
      numVideos: numVideos,
      numQuestions: numQuestions,
    );
  }
}