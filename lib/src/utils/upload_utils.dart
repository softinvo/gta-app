import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/commons/repository/storage_repository.dart';

final uploadUtilsProvider = Provider((ref) {
  final storageRepo = ref.watch(storageRepositoryProvider);
  return FileUploadUtils(storageRepo: storageRepo);
});

class FileUploadUtils {
  final StorageRepository _storageRepo;

  FileUploadUtils({required StorageRepository storageRepo})
    : _storageRepo = storageRepo;

  /// Coordinates the full upload flow:
  /// 1. Requests a signed upload URL from the backend.
  /// 2. Performs a PUT request to upload the file bytes.
  /// 3. Returns a complete [Attachment] object on success.
  ///
  /// [file] is the local file to upload.
  /// [type] is the category/folder for storage (e.g., 'Avatar', 'Food', 'Services').
  FutureEither<Attachment> uploadFile(File file, String type) async {
    try {
      final String extension = file.path.split('.').last.toLowerCase();
      final List<int> bytes = await file.readAsBytes();

      // Step 1: Request signed URL and metadata from backend
      final urlResult = await _storageRepo.getUploadUrl(
        extension: extension,
        type: type,
      );

      return await urlResult.fold((failure) => Left(failure), (data) async {
        final String uploadUrl = data['uploadUrl'];
        final String downloadUrl = data['downloadUrl'];
        final String fileName = data['fileName'] ?? '';

        // Step 2: Upload raw file bytes to the signed URL
        final uploadResult = await _storageRepo.uploadFile(
          uploadUrl: uploadUrl,
          fileBytes: bytes,
        );

        return uploadResult.fold(
          (failure) => Left(failure),
          (_) => Right(
            Attachment(
              fileUrl: downloadUrl,
              fileName: fileName,
              fileType: type,
              fileExtension: '.$extension',
              uploadedAt: DateTime.now(),
            ),
          ),
        );
      });
    } catch (e, stktrc) {
      return Left(
        Failure(
          message: 'Local file processing failed: ${e.toString()}',
          stackTrace: stktrc,
        ),
      );
    }
  }

  /// Uploads every variant image that still points at a local file (picked
  /// in the variant sheet) and returns the variants with remote URLs.
  /// Already-uploaded (http) attachments are kept as-is, and a file shared by
  /// several variants is uploaded only once.
  FutureEither<List<Variant>> uploadVariantImages(
    List<Variant> variants,
    String type,
  ) async {
    final uploaded = <String, Attachment>{};

    Future<Either<Failure, Attachment>> resolve(Attachment a) async {
      if (a.fileUrl.startsWith('http')) return Right(a);
      final cached = uploaded[a.fileUrl];
      if (cached != null) return Right(cached);
      final result = await uploadFile(File(a.fileUrl), type);
      return result.map((remote) => uploaded[a.fileUrl] = remote);
    }

    final out = <Variant>[];
    for (final v in variants) {
      Attachment? thumbnail;
      if (v.thumbnail != null) {
        final result = await resolve(v.thumbnail!);
        if (result.isLeft()) return Left(result.getLeft().toNullable()!);
        thumbnail = result.getRight().toNullable();
      }

      List<Attachment>? previews;
      if (v.previewImages != null) {
        previews = [];
        for (final p in v.previewImages!) {
          final result = await resolve(p);
          if (result.isLeft()) return Left(result.getLeft().toNullable()!);
          previews.add(result.getRight().toNullable()!);
        }
      }

      out.add(v.copyWith(thumbnail: thumbnail, previewImages: previews));
    }
    return Right(out);
  }
}
