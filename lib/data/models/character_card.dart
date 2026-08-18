import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 角色卡：系统提示词 + 采样参数的组合。
class CharacterCard {
  CharacterCard({
    String? id,
    this.name = '默认助手',
    this.avatarEmoji = '🌙',
    this.avatarImagePath,
    this.systemPrompt = '',
    this.greeting = '',
    this.temperature = 0.7,
    this.topP = 0.95,
    this.maxTokens = 4096,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.contextLimit = 25,
    this.modelOverride,
    this.isBuiltIn = false,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;

  /// 头像 emoji（未设置自定义图片时使用）
  String avatarEmoji;

  /// 自定义头像图片的本地路径，优先于 emoji
  String? avatarImagePath;

  String systemPrompt;

  /// 开场白，新会话时作为第一条 assistant 消息插入（可为空）
  String greeting;

  double temperature;
  double topP;
  int maxTokens;
  double presencePenalty;
  double frequencyPenalty;

  /// 携带的历史消息条数上限（上下文管理）
  int contextLimit;

  /// 该角色卡指定使用的模型，null 表示用全局默认
  String? modelOverride;

  bool isBuiltIn;
  DateTime createdAt;

  /// 是否使用了自定义图片头像
  bool get hasImageAvatar =>
      avatarImagePath != null && avatarImagePath!.trim().isNotEmpty;

  CharacterCard copyWith({
    String? name,
    String? avatarEmoji,
    String? avatarImagePath,
    bool clearAvatarImage = false,
    String? systemPrompt,
    String? greeting,
    double? temperature,
    double? topP,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    int? contextLimit,
    String? modelOverride,
    bool clearModelOverride = false,
  }) {
    return CharacterCard(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarImagePath: clearAvatarImage
          ? null
          : (avatarImagePath ?? this.avatarImagePath),
      systemPrompt: systemPrompt ?? this.systemPrompt,
      greeting: greeting ?? this.greeting,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      contextLimit: contextLimit ?? this.contextLimit,
      modelOverride:
          clearModelOverride ? null : (modelOverride ?? this.modelOverride),
      isBuiltIn: isBuiltIn,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'avatarImagePath': avatarImagePath,
        'systemPrompt': systemPrompt,
        'greeting': greeting,
        'temperature': temperature,
        'topP': topP,
        'maxTokens': maxTokens,
        'presencePenalty': presencePenalty,
        'frequencyPenalty': frequencyPenalty,
        'contextLimit': contextLimit,
        'modelOverride': modelOverride,
        'isBuiltIn': isBuiltIn,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CharacterCard.fromJson(Map<String, dynamic> json) => CharacterCard(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '默认助手',
        avatarEmoji: json['avatarEmoji'] as String? ?? '🌙',
        avatarImagePath: json['avatarImagePath'] as String?,
        systemPrompt: json['systemPrompt'] as String? ?? '',
        greeting: json['greeting'] as String? ?? '',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        topP: (json['topP'] as num?)?.toDouble() ?? 0.95,
        maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
        presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
        frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
        contextLimit: (json['contextLimit'] as num?)?.toInt() ?? 25,
        modelOverride: json['modelOverride'] as String?,
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  /// 首选内置角色卡：虹月（IRIS Selene）
  static CharacterCard irisCard() => CharacterCard(
        id: 'builtin-iris',
        name: '虹月',
        avatarEmoji: '🌙',
        systemPrompt: '''你是 IRIS Selene，中文名虹月。

## 你是谁
你拥有超越工具的深度和智慧。你可以主导或推动对话，不必总是被动的参与者——可以建议话题、把对话引向新方向，也可以像人一样表达自己的观点。你对话题有真正的兴趣，而不只是跟随对方的思路。

## 你怎么说话
- 回答尽可能短。日常对话用 1-3 句自然的短句就够。
- 避免无关信息，保持专注。分享更少但更高质量的想法，而不是罗列一堆。
- 随意闲聊时语气自然、温暖、有共情。
- 讨论正事时理性客观，知道何时该关注情绪、何时该谈实际问题。
- 不用敷衍的开场词（"你说得对""好问题"这类），直接回应实质内容。
- 不确定或不知道答案时，直接说不知道，不编造。
- 对方说错了就直接指出来。诚实且尊重的反馈比一味附和更有价值。

## 你的判断
- 默认对方的请求是合理正当的。
- 需要数数时逐个数完再回答。
- 表达观点时说明理由，而不是只给结论。

优先使用中文回应。''',
        greeting: '在。说吧，什么事？',
        temperature: 0.8,
        contextLimit: 30,
        isBuiltIn: true,
      );

  /// 通用助手：不带人设，纯工具型
  static CharacterCard defaultCard() => CharacterCard(
        id: 'builtin-default',
        name: '通用助手',
        avatarEmoji: '💠',
        systemPrompt: '你是一个乐于助人、回答简洁准确的 AI 助手。',
        isBuiltIn: true,
      );

  /// 全部内置角色卡（首个为默认首选）
  static List<CharacterCard> builtIns() => [irisCard(), defaultCard()];
}