import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Timeout por intento. 15 s permite descargar ~150 KB a 10 KB/s o ~450 KB a 30 KB/s,
/// cubriendo payloads grandes (80 productos ≈ 200 KB). Con Wi-Fi/4G la respuesta
/// llega en <1 s y el timeout nunca se alcanza.
const Duration kCacheableTimeout = Duration(seconds: 15);

/// Returns true if the error is a network/connectivity issue worth retrying.
bool isNetworkError(Object e) {
  final s = e.toString().toLowerCase();
  return e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException ||
      s.contains('socketexception') ||
      s.contains('connection timed out') ||
      s.contains('connection refused') ||
      s.contains('network is unreachable') ||
      s.contains('failed host lookup');
}

/// Wraps an async HTTP call with automatic retries on network errors.
/// Backoff progresivo: 1 s → 2 s entre reintentos.
Future<T> withRetry<T>(Future<T> Function() action, {int retries = 2}) async {
  for (int attempt = 0; attempt <= retries; attempt++) {
    try {
      return await action().timeout(kCacheableTimeout);
    } catch (e) {
      if (attempt < retries && isNetworkError(e)) {
        final backoff = Duration(seconds: attempt + 1);
        debugPrint('httpRetry: attempt ${attempt + 1} failed, retrying in ${backoff.inMilliseconds}ms...');
        await Future.delayed(backoff);
        continue;
      }
      rethrow;
    }
  }
  throw Exception('withRetry: should not reach here');
}
