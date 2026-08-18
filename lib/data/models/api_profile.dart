import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 一个 OpenAI 兼容格式的 API 服务商配置。
///
/// 只要接口遵循 `POST {baseUrl}/chat/completions` 且支持 SSE 流式，
/// 就能直接接入（OpenAI / DeepSeek / Moonshot / 硅基流动 / 本地 Ollama 等）。
class ApiProfile {
  ApiProfile({
    String? id,
    this.name = '新配置',
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.models = const <String>[],
    this.selectedModel = '',
    this.extraHeaders = const <String, String>{},
    this.stream = true,
  }) : id = id ?? _uuid.v4();

  final String id;
  String name;

  /// 形如 https://api.openai.com/v1 （不含 /chat/completions）
  String baseUrl;
  String apiKey;

  /// 可用模型列表（手动填写或通过 /models 拉取）
  List<String> models;
  String selectedModel;

  Map<String, String> extraHeaders;
  bool stream;

  String get chatEndpoint {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return '$base/chat/completions';
  }

  String get modelsEndpoint {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return '$base/models';
  }

  bool get isUsable =>
      baseUrl.trim().isNotEmpty && selectedModel.trim().isNotEmpty;

  ApiProfile copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    List<String>? models,
    String? selectedModel,
    Map<String, String>? extraHeaders,
    bool? stream,
  }) {
    return ApiProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? List<String>.from(this.models),
      selectedModel: selectedModel ?? this.selectedModel,
      extraHeaders:
          extraHeaders ?? Map<String, String>.from(this.extraHeaders),
      stream: stream ?? this.stream,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'models': models,
        'selectedModel': selectedModel,
        'extraHeaders': extraHeaders,
        'stream': stream,
      };

  factory ApiProfile.fromJson(Map<String, dynamic> json) => ApiProfile(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '新配置',
        baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
        apiKey: json['apiKey'] as String? ?? '',
        models:
            (json['models'] as List?)?.map((e) => e as String).toList() ?? [],
        selectedModel: json['selectedModel'] as String? ?? '',
        extraHeaders: ((json['extraHeaders'] as Map?) ?? {})
            .map((k, v) => MapEntry(k as String, v.toString())),
        stream: json['stream'] as bool? ?? true,
      );

  /// 常用服务商预设，方便用户一键填充
  static const presets = <String, String>{
    'OpenAI': 'https://api.openai.com/v1',
    'Claude (兼容网关)': 'https://api.anthropic.com/v1',
    'Gemini (兼容网关)': 'https://generativelanguage.googleapis.com/v1beta/openai',
    'DeepSeek': 'https://api.deepseek.com/v1',
    'Moonshot': 'https://api.moonshot.cn/v1',
    'Qwen (DashScope)': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    '智谱 GLM': 'https://open.bigmodel.cn/api/paas/v4',
    '英伟达 NIM': 'https://integrate.api.nvidia.com/v1',
    '硅基流动': 'https://api.siliconflow.cn/v1',
    'Ollama 云端': 'https://ollama.com/v1',
    'Ollama 本地': 'http://127.0.0.1:11434/v1',
  };
}