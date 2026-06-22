import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Custom cache manager that:
/// 1. Sends `Accept: image/jpeg,image/png,image/*` headers.
/// 2. After download, re-encodes every image as PNG through Flutter's own
///    Dart/Skia codec. This completely sidesteps Android's native
///    `ImageDecoder.decodeBitmap`, which throws `'unimplemented'` for WebP
///    profiles and AVIF on API < 31 emulators/devices.
class AppCacheManager {
  static const _key = 'appImageCache_v2';

  static final instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      fileService: _SafeImageFileService(),
    ),
  );
}

/// Downloads an image with standard Accept headers, then re-encodes the
/// bytes as PNG so the resulting cached file is always a format that any
/// Android version can decode without the native `ImageDecoder`.
class _SafeImageFileService extends FileService {
  final _client = http.Client();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll({
      'Accept': 'image/jpeg,image/png,image/webp;q=0.8,image/*;q=0.5',
      ...?headers,
    });

    final streamed = await _client.send(request);

    // Re-encode through Flutter's Dart-side codec (Skia / Impeller).
    // This converts WebP / AVIF / unknown formats → PNG bytes so the
    // Android native ImageDecoder never sees the original format.
    final bytes = await streamed.stream.toBytes();
    final pngBytes = await _toPng(bytes);

    // Wrap the PNG bytes in a StreamedResponse so CacheManager stores them.
    final fakeResponse = http.StreamedResponse(
      Stream.value(pngBytes),
      streamed.statusCode,
      contentLength: pngBytes.length,
      headers: {
        ...streamed.headers,
        HttpHeaders.contentTypeHeader: 'image/png',
      },
      reasonPhrase: streamed.reasonPhrase,
    );

    return HttpGetResponse(fakeResponse);
  }

  /// Decode [bytes] with Flutter's codec, then re-encode as PNG.
  /// Falls back to the original bytes on any error.
  static Future<List<int>> _toPng(List<int> bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(bytes),
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (byteData != null) return byteData.buffer.asUint8List();
    } catch (_) {
      // If re-encoding fails (e.g. truly corrupt file), return original bytes
      // so CacheManager can store something and show the error widget.
    }
    return bytes;
  }
}

