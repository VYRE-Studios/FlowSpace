import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class FileUploadService {
  static Future<Map<String, dynamic>> uploadFile({
    required String workspaceId,
    required File file,
    Function(double)? onProgress,
  }) async {
    final baseUrl = await ApiClient.baseUrl;
    final uri = Uri.parse('$baseUrl/vault/$workspaceId/upload');

    final request = http.MultipartRequest('POST', uri);
    
    // Add authorization header
    final token = ApiClient.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add file
    final fileStream = http.ByteStream(file.openRead());
    final fileLength = await file.length();
    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: file.path.split('/').last,
    );
    request.files.add(multipartFile);

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
}
