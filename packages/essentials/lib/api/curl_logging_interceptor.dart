import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';

/// Interceptor que loga cada requisição HTTP como um comando cURL formatado
/// e cada resposta com status, headers e body.
///
/// Adicione ao [ChopperClient]:
/// ```dart
/// ChopperClient(
///   interceptors: [const CurlLoggingInterceptor()],
/// );
/// ```
class CurlLoggingInterceptor implements Interceptor {
  const CurlLoggingInterceptor();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;
    _logRequest(request);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await chain.proceed(request);
      stopwatch.stop();
      _logResponse(response, request, stopwatch.elapsedMilliseconds);
      return response;
    } catch (error) {
      stopwatch.stop();
      _logError(request, error, stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  void _logRequest(Request request) {
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('┌─── REQUEST ────────────────────────────────────')
      ..writeln('│ ${request.method} ${request.url}');

    if (request.headers.isNotEmpty) {
      buffer.writeln('│');
      request.headers.forEach((key, value) {
        buffer.writeln('│  📋 $key: $value');
      });
    }

    if (request.body != null) {
      buffer
        ..writeln('│')
        ..writeln('│  📦 Body:')
        ..writeln('│  ${_formatBody(request.body)}');
    }

    buffer
      ..writeln('│')
      ..writeln('│  🔗 cURL:')
      ..writeln('│  ${_toCurl(request)}')
      ..writeln('└────────────────────────────────────────────────');

    // ignore: avoid_print
    print(buffer);
  }

  void _logResponse(
    Response<dynamic> response,
    Request request,
    int durationMs,
  ) {
    final statusEmoji = response.isSuccessful ? '✅' : '❌';
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('┌─── RESPONSE ───────────────────────────────────')
      ..writeln(
        '│ $statusEmoji ${response.statusCode} │ '
        '${request.method} ${request.url} │ ${durationMs}ms',
      );

    if (response.headers.isNotEmpty) {
      buffer.writeln('│');
      response.headers.forEach((key, value) {
        buffer.writeln('│  📋 $key: $value');
      });
    }

    final body = response.bodyString;
    if (body.isNotEmpty) {
      buffer
        ..writeln('│')
        ..writeln('│  📦 Body:');
      if (body.length > 2000) {
        buffer
          ..writeln('│  ${body.substring(0, 2000)}')
          ..writeln('│  ... [truncated, ${body.length - 2000} more chars]');
      } else {
        buffer.writeln('│  $body');
      }
    }

    buffer.writeln('└────────────────────────────────────────────────');

    // ignore: avoid_print
    print(buffer);
  }

  void _logError(Request request, Object error, int durationMs) {
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('┌─── ERROR ──────────────────────────────────────')
      ..writeln('│ ❌ ${request.method} ${request.url} │ ${durationMs}ms')
      ..writeln('│')
      ..writeln('│ $error')
      ..writeln('└────────────────────────────────────────────────');

    // ignore: avoid_print
    print(buffer);
  }

  String _formatBody(dynamic body) {
    if (body == null) return '';
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return body;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  String _toCurl(Request request) {
    final parts = <String>['curl -X ${request.method}'];

    request.headers.forEach((key, value) {
      final escaped = value.replaceAll("'", r"\'");
      parts.add("-H '$key: $escaped'");
    });

    if (request.body != null) {
      final bodyStr = request.body is String
          ? request.body as String
          : jsonEncode(request.body);
      if (bodyStr.isNotEmpty) {
        final escaped = bodyStr.replaceAll("'", r"\'");
        parts.add("-d '$escaped'");
      }
    }

    parts.add("'${request.url}'");

    return parts.join(' \\\n│     ');
  }
}
