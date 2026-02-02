import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/res/endpoints.dart';

final storageRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return StorageRepository(api: api);
});

class StorageRepository {
  final API _api;

  StorageRepository({required API api}) : _api = api;

  /// Gets a signed upload URL from the backend.
  /// [extension] is the file extension (e.g., 'jpg', 'pdf').
  /// [type] must be one of [Services, Food, Avatar, etc] as per backend.
  FutureEither<Map<String, dynamic>> getUploadUrl({
    required String extension,
    required String type,
  }) async {
    final response = await _api.postRequest(
      url: Endpoints.storage,
      body: {'extension': extension, 'type': type},
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(data);
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to get upload URL'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse storage response'));
      }
    });
  }

  /// Uploads raw bytes to a signed URL using a PUT request.
  FutureEither<void> uploadFile({
    required String uploadUrl,
    required List<int> fileBytes,
    String contentType = "application/octet-stream",
  }) async {
    final response = await _api.putRawRequest(
      url: uploadUrl,
      bytes: fileBytes,
      contentType: contentType,
    );

    return response.fold((l) => Left(l), (r) {
      if (r.statusCode == 200 || r.statusCode == 201) {
        return const Right(null);
      } else {
        return Left(Failure(message: 'Failed to upload file to storage'));
      }
    });
  }
}
