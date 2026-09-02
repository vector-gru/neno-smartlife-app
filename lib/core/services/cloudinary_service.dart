import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// CloudinaryService
//
// Handles unsigned direct uploads to Cloudinary.
// No SDK needed — just a multipart POST to the upload API.
//
// Config:
//   cloudName  : d8syztlv
//   uploadPreset: neno_products   (unsigned, folder: neno-smartlife/products)
// ─────────────────────────────────────────────────────────────────────────────

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  static const _cloudName = 'd8syztlv';
  static const _uploadPreset = 'neno_products';
  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads a single local file to Cloudinary.
  /// Returns the secure HTTPS URL of the uploaded image.
  /// Throws on network error or non-200 response.
  Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    // Cloudinary auto-generates a public_id; the folder is set in the preset.

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw CloudinaryException(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw const CloudinaryException('No secure_url in Cloudinary response');
    }

    return secureUrl;
  }

  /// Uploads multiple local images concurrently.
  /// Already-uploaded URLs (starting with 'http') are passed through unchanged.
  /// Returns the list of Cloudinary URLs in the same order as input.
  Future<List<String>> uploadImages(List<String> paths) async {
    final futures = paths.map((path) async {
      if (path.startsWith('http')) return path; // already a remote URL
      return uploadImage(File(path));
    });
    return Future.wait(futures);
  }
}

class CloudinaryException implements Exception {
  final String message;
  const CloudinaryException(this.message);

  @override
  String toString() => 'CloudinaryException: $message';
}
