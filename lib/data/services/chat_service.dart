import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/api_profile.dart';
import '../models/character_card.dart';

/// 流式返回的单个增量片段
class StreamChunk {
  const StreamChunk({
    this.content = '',
    this.reasoning = '',
    this.finishReason,
  });

  final String content;
  final String reasoning;
  final String? finishReason;

  bool get isDone => finishReason != null;
}

enum ApiErrorKind {
  invalidConfiguration,
  http,
  connectionTimeout,
  receiveTimeout,
  sendTimeout,
  badCertificate,
  connectionError,
  cancelled,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.kind = ApiErrorKind.unknown,
    this.statusCode,
    this.raw,
  });

  final String message;
  final ApiErrorKind kind;
  final int? statusCode;
  final String? raw;

  /// 将应用自身的网络错误按界面语言显示；服务端原始错误保持原样便于排查。
  String messageFor(bool isZh) {
    switch (kind) {
      case ApiErrorKind.invalidConfiguration:
        return isZh
            ? 'API 配置不完整：请检查 Base URL 与模型名'
            : 'API configuration is incomplete. Check the Base URL and model name.';
      case ApiErrorKind.http:
        final prefix = statusCode == null ? 'HTTP' : 'HTTP $statusCode';
        final detail = message.trim();
        final fallback = isZh ? '请求失败' : 'Request failed';
        return '$prefix${isZh ? '：' : ': '}${detail.isEmpty ? fallback : detail}';
      case ApiErrorKind.connectionTimeout:
        return isZh
            ? '连接超时：请检查网络或 Base URL'
            : 'Connection timed out. Check your network or Base URL.';
      case ApiErrorKind.receiveTimeout:
        return isZh
            ? '接收超时：服务端响应过慢'
            : 'Receive timed out. The server took too long to respond.';
      case ApiErrorKind.sendTimeout:
        return isZh ? '发送超时' : 'Send timed out.';
      case ApiErrorKind.badCertificate:
        return isZh ? 'SSL 证书校验失败' : 'SSL certificate verification failed.';
      case ApiErrorKind.connectionError:
        return isZh
            ? '无法连接到服务器：请检查网络与 Base URL'
            : 'Could not connect to the server. Check your network and Base URL.';
      case ApiErrorKind.cancelled:
        return isZh ? '已取消' : 'Cancelled.';
      case ApiErrorKind.server:
        return message.trim().isEmpty
            ? (isZh ? '服务端返回错误' : 'The server returned an error.')
            : message;
      case ApiErrorKind.unknown:
        return isZh ? '请求失败' : 'Request failed.';
    }
  }

  @override
  String toString() => message;
}

/// OpenAI 兼容格式的对话服务。
///
/// 只依赖 `POST {baseUrl}/chat/completions`，
/// 因此 OpenAI / DeepSeek / Moonshot / 硅基流动 / Ollama 等都能直接用。
class ChatService {
  ChatService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
            ));

  final Dio _dio;
  CancelToken? _cancelToken;

  /// 当前是否有请求在进行
  bool get isBusy => _cancelToken != null && !_cancelToken!.isCancelled;

  /// 中止当前生成
  void cancel() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('user_aborted');
    }
    _cancelToken = null;
  }

  Map<String, String> _headers(ApiProfile profile) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': profile.stream ? 'text/event-stream' : 'application/json',
    };
    if (profile.apiKey.trim().isNotEmpty) {
      h['Authorization'] = 'Bearer ${profile.apiKey.trim()}';
    }
    h.addAll(profile.extraHeaders);
    return h;
  }

  Map<String, dynamic> _buildBody({
    required ApiProfile profile,
    required CharacterCard card,
    required List<Map<String, dynamic>> messages,
    required bool stream,
    String? model,
    bool thinkingEnabled = false,
    int thinkingLevel = 2,
  }) {
    final resolvedModel = (model?.trim().isNotEmpty ?? false)
        ? model!.trim()
        : ((card.modelOverride?.trim().isNotEmpty ?? false)
            ? card.modelOverride!.trim()
            : profile.selectedModel);

    final body = <String, dynamic>{
      'model': resolvedModel,
      'messages': messages,
      'stream': stream,
      'temperature': card.temperature,
      'top_p': card.topP,
    };

    if (card.maxTokens > 0) body['max_tokens'] = card.maxTokens;
    if (card.presencePenalty != 0) {
      body['presence_penalty'] = card.presencePenalty;
    }
    if (card.frequencyPenalty != 0) {
      body['frequency_penalty'] = card.frequencyPenalty;
    }

    // 思考模式：部分模型（DeepSeek R1 / o1 等）支持 reasoning_effort
    if (thinkingEnabled) {
      const efforts = ['low', 'medium', 'high'];
      final idx = (thinkingLevel - 1).clamp(0, 2);
      body['reasoning_effort'] = efforts[idx];
    }

    return body;
  }

  /// 流式对话。逐个 yield [StreamChunk]。
  Stream<StreamChunk> streamChat({
    required ApiProfile profile,
    required CharacterCard card,
    required List<Map<String, dynamic>> messages,
    bool thinkingEnabled = false,
    int thinkingLevel = 2,
  }) async* {
    if (!profile.isUsable) {
      throw const ApiException('', kind: ApiErrorKind.invalidConfiguration);
    }

    _cancelToken = CancelToken();
    final token = _cancelToken!;

    late Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        profile.chatEndpoint,
        data: _buildBody(
          profile: profile,
          card: card,
          messages: messages,
          stream: true,
          thinkingEnabled: thinkingEnabled,
          thinkingLevel: thinkingLevel,
        ),
        options: Options(
          headers: _headers(profile),
          responseType: ResponseType.stream,
          // 自己判断状态码，便于读出错误体
          validateStatus: (_) => true,
        ),
        cancelToken: token,
      );
    } on DioException catch (e) {
      _cancelToken = null;
      if (CancelToken.isCancel(e)) return;
      throw _dioException(e);
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      final errText = await _readAllAsString(response.data!);
      _cancelToken = null;
      throw ApiException(
        _extractErrorMessage(errText),
        kind: ApiErrorKind.http,
        statusCode: status,
        raw: errText,
      );
    }

    // SSE 解析：按行读，处理 `data: {...}` 与 `data: [DONE]`
    final buffer = StringBuffer();
    try {
      await for (final bytes in response.data!.stream) {
        if (token.isCancelled) break;
        buffer.write(utf8.decode(bytes, allowMalformed: true));

        var text = buffer.toString();
        // 以换行切分，最后一段可能不完整，留在 buffer 里
        final lines = text.split('\n');
        buffer
          ..clear()
          ..write(lines.removeLast());

        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty) continue;
          if (!line.startsWith('data:')) continue;

          final payload = line.substring(5).trim();
          if (payload == '[DONE]') {
            yield const StreamChunk(finishReason: 'stop');
            return;
          }

          final chunk = _parseChunk(payload);
          if (chunk != null) yield chunk;
        }
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) {
        throw _dioException(e);
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// 非流式对话（部分接口不支持 SSE 时的回退）
  ///
  /// [model] 可选：显式指定模型，优先于角色卡覆盖与 profile 默认模型。
  Future<String> completeChat({
    required ApiProfile profile,
    required CharacterCard card,
    required List<Map<String, dynamic>> messages,
    String? model,
    bool thinkingEnabled = false,
    int thinkingLevel = 2,
  }) async {
    if (!profile.isUsable) {
      throw const ApiException('', kind: ApiErrorKind.invalidConfiguration);
    }
    _cancelToken = CancelToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        profile.chatEndpoint,
        data: _buildBody(
          profile: profile,
          card: card,
          messages: messages,
          stream: false,
          model: model,
          thinkingEnabled: thinkingEnabled,
          thinkingLevel: thinkingLevel,
        ),
        options: Options(
          headers: _headers(profile),
          validateStatus: (_) => true,
        ),
        cancelToken: _cancelToken,
      );

      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ApiException(
          _extractErrorMessage(jsonEncode(res.data)),
          kind: ApiErrorKind.http,
          statusCode: status,
        );
      }

      final choices = res.data?['choices'] as List?;
      final msg = (choices?.isNotEmpty ?? false)
          ? (choices!.first as Map)['message'] as Map?
          : null;
      return (msg?['content'] as String?) ?? '';
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return '';
      throw _dioException(e);
    } finally {
      _cancelToken = null;
    }
  }

  /// 拉取可用模型列表
  Future<List<String>> fetchModels(ApiProfile profile) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        profile.modelsEndpoint,
        options: Options(
          headers: _headers(profile),
          validateStatus: (_) => true,
        ),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ApiException(
          _extractErrorMessage(jsonEncode(res.data)),
          kind: ApiErrorKind.http,
          statusCode: status,
        );
      }
      final data = res.data?['data'] as List?;
      if (data == null) return const [];
      return data
          .map((e) => (e as Map)['id']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList()
        ..sort();
    } on DioException catch (e) {
      throw _dioException(e);
    }
  }

  // ------------------------------------------------------------------ 内部

  StreamChunk? _parseChunk(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;

      // 有些服务把错误也放在流里
      if (json['error'] != null) {
        final err = json['error'];
        final msg = err is Map ? (err['message']?.toString() ?? '$err') : '$err';
        throw ApiException(msg, kind: ApiErrorKind.server);
      }

      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final first = choices.first as Map;
      final delta = (first['delta'] ?? first['message']) as Map?;
      if (delta == null) {
        final fr = first['finish_reason']?.toString();
        return fr == null ? null : StreamChunk(finishReason: fr);
      }

      return StreamChunk(
        content: delta['content']?.toString() ?? '',
        reasoning: delta['reasoning_content']?.toString() ??
            delta['reasoning']?.toString() ??
            '',
        finishReason: first['finish_reason']?.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      // 单个片段解析失败不应中断整个流
      return null;
    }
  }

  Future<String> _readAllAsString(ResponseBody body) async {
    final chunks = <int>[];
    await for (final b in body.stream) {
      chunks.addAll(b);
    }
    return utf8.decode(chunks, allowMalformed: true);
  }

  String _extractErrorMessage(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map) {
        final err = json['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (json['message'] != null) {
          return json['message'].toString();
        }
      }
    } catch (_) {
      // Not JSON. Fall through to a shortened original response.
    }
    return raw.length > 300 ? '${raw.substring(0, 300)}…' : raw;
  }

  ApiException _dioException(DioException e) {
    final kind = switch (e.type) {
      DioExceptionType.connectionTimeout => ApiErrorKind.connectionTimeout,
      DioExceptionType.receiveTimeout => ApiErrorKind.receiveTimeout,
      DioExceptionType.sendTimeout => ApiErrorKind.sendTimeout,
      DioExceptionType.badCertificate => ApiErrorKind.badCertificate,
      DioExceptionType.connectionError => ApiErrorKind.connectionError,
      DioExceptionType.cancel => ApiErrorKind.cancelled,
      _ => ApiErrorKind.unknown,
    };
    return ApiException(e.message ?? '', kind: kind);
  }
}