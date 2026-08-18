/// 应用外观与行为设置。
class AppSettings {
  AppSettings({
    this.accentColorValue = 0xFF14E2CE, // 青色
    this.themeModeIndex = 2, // 0 light / 1 dark / 2 system
    this.oledBlack = false,
    this.glassEnabled = true,
    this.glassBlur = 24.0,
    this.glassOpacity = 0.14,
    this.wallpaperPath,
    this.wallpaperOpacity = 0.35,
    this.fontScale = 1.0,
    this.bubbleRadius = 22.0,
    this.showTimestamp = true,
    this.enableAnimation = true,
    this.animationSpeed = 1.0,
    this.languageCode = 'system',
    this.contextStrategy = 0,
    this.summaryTriggerCount = 30,
    this.summaryKeepRecent = 8,
    this.activeApiProfileId,
    this.activeCharacterId = 'builtin-iris',
    this.startNewChat = false,
    this.thinkingEnabled = false,
    this.thinkingLevel = 2,
  });

  /// 主色，默认青色 #14E2CE
  int accentColorValue;

  int themeModeIndex;

  /// OLED 纯黑：深色下背景使用 #000000
  bool oledBlack;

  /// 毛玻璃总开关
  bool glassEnabled;

  /// 模糊半径
  double glassBlur;

  /// 玻璃层叠加白/黑的不透明度
  double glassOpacity;

  /// 自定义背景壁纸的本地路径
  String? wallpaperPath;

  /// 壁纸上蒙层的不透明度（越大壁纸越淡）
  double wallpaperOpacity;

  double fontScale;
  double bubbleRadius;
  bool showTimestamp;

  /// 界面动画总开关
  bool enableAnimation;

  /// 动画速度倍率：0.5 = 慢一倍，2.0 = 快一倍
  double animationSpeed;

  /// 界面语言：'system' / 'zh' / 'en'
  String languageCode;

  /// 上下文策略：0 = 仅保留最近若干条，1 = 自动摘要压缩
  int contextStrategy;

  /// 摘要策略：历史超过这个条数时触发压缩
  int summaryTriggerCount;

  /// 摘要策略：压缩时保留最近多少条原文
  int summaryKeepRecent;

  String? activeApiProfileId;
  String activeCharacterId;

  /// 启动时是否新建对话（true=新建，false=继续上一次）
  bool startNewChat;

  /// 思考模式开关
  bool thinkingEnabled;

  /// 思考深度：1=浅、2=中、3=深
  int thinkingLevel;

  /// 动画是否真正生效（关闭或速度过低时视为不生效）
  bool get animationsActive => enableAnimation && animationSpeed > 0.01;

  AppSettings copyWith({
    int? accentColorValue,
    int? themeModeIndex,
    bool? oledBlack,
    bool? glassEnabled,
    double? glassBlur,
    double? glassOpacity,
    String? wallpaperPath,
    bool clearWallpaper = false,
    double? wallpaperOpacity,
    double? fontScale,
    double? bubbleRadius,
    bool? showTimestamp,
    bool? enableAnimation,
    double? animationSpeed,
    String? languageCode,
    int? contextStrategy,
    int? summaryTriggerCount,
    int? summaryKeepRecent,
    String? activeApiProfileId,
    String? activeCharacterId,
    bool? startNewChat,
    bool? thinkingEnabled,
    int? thinkingLevel,
  }) {
    return AppSettings(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      oledBlack: oledBlack ?? this.oledBlack,
      glassEnabled: glassEnabled ?? this.glassEnabled,
      glassBlur: glassBlur ?? this.glassBlur,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      wallpaperPath:
          clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
      wallpaperOpacity: wallpaperOpacity ?? this.wallpaperOpacity,
      fontScale: fontScale ?? this.fontScale,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      languageCode: languageCode ?? this.languageCode,
      contextStrategy: contextStrategy ?? this.contextStrategy,
      summaryTriggerCount: summaryTriggerCount ?? this.summaryTriggerCount,
      summaryKeepRecent: summaryKeepRecent ?? this.summaryKeepRecent,
      activeApiProfileId: activeApiProfileId ?? this.activeApiProfileId,
      activeCharacterId: activeCharacterId ?? this.activeCharacterId,
      startNewChat: startNewChat ?? this.startNewChat,
      thinkingEnabled: thinkingEnabled ?? this.thinkingEnabled,
      thinkingLevel: thinkingLevel ?? this.thinkingLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'accentColorValue': accentColorValue,
        'themeModeIndex': themeModeIndex,
        'oledBlack': oledBlack,
        'glassEnabled': glassEnabled,
        'glassBlur': glassBlur,
        'glassOpacity': glassOpacity,
        'wallpaperPath': wallpaperPath,
        'wallpaperOpacity': wallpaperOpacity,
        'fontScale': fontScale,
        'bubbleRadius': bubbleRadius,
        'showTimestamp': showTimestamp,
        'enableAnimation': enableAnimation,
        'animationSpeed': animationSpeed,
        'languageCode': languageCode,
        'contextStrategy': contextStrategy,
        'summaryTriggerCount': summaryTriggerCount,
        'summaryKeepRecent': summaryKeepRecent,
        'activeApiProfileId': activeApiProfileId,
        'activeCharacterId': activeCharacterId,
        'startNewChat': startNewChat,
        'thinkingEnabled': thinkingEnabled,
        'thinkingLevel': thinkingLevel,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        accentColorValue:
            (json['accentColorValue'] as num?)?.toInt() ?? 0xFF14E2CE,
        themeModeIndex: (json['themeModeIndex'] as num?)?.toInt() ?? 2,
        oledBlack: json['oledBlack'] as bool? ?? false,
        glassEnabled: json['glassEnabled'] as bool? ?? true,
        glassBlur: (json['glassBlur'] as num?)?.toDouble() ?? 24.0,
        glassOpacity: (json['glassOpacity'] as num?)?.toDouble() ?? 0.14,
        wallpaperPath: json['wallpaperPath'] as String?,
        wallpaperOpacity:
            (json['wallpaperOpacity'] as num?)?.toDouble() ?? 0.35,
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        bubbleRadius: (json['bubbleRadius'] as num?)?.toDouble() ?? 22.0,
        showTimestamp: json['showTimestamp'] as bool? ?? true,
        enableAnimation: json['enableAnimation'] as bool? ?? true,
        animationSpeed: (json['animationSpeed'] as num?)?.toDouble() ?? 1.0,
        languageCode: json['languageCode'] as String? ?? 'system',
        contextStrategy: (json['contextStrategy'] as num?)?.toInt() ?? 0,
        summaryTriggerCount:
            (json['summaryTriggerCount'] as num?)?.toInt() ?? 30,
        summaryKeepRecent: (json['summaryKeepRecent'] as num?)?.toInt() ?? 8,
        activeApiProfileId: json['activeApiProfileId'] as String?,
        activeCharacterId:
            json['activeCharacterId'] as String? ?? 'builtin-iris',
        startNewChat: json['startNewChat'] as bool? ?? false,
        thinkingEnabled: json['thinkingEnabled'] as bool? ?? false,
        thinkingLevel: (json['thinkingLevel'] as num?)?.toInt() ?? 2,
      );

  /// 预设配色方案
  static const presetAccents = <String, int>{
    '青色': 0xFF14E2CE,
    '深海蓝': 0xFF3B82F6,
    '暮光紫': 0xFF8B5CF6,
    '樱粉': 0xFFEC4899,
    '琥珀橙': 0xFFF59E0B,
    '青柠绿': 0xFF10B981,
    '赤焰红': 0xFFEF4444,
    '石墨灰': 0xFF64748B,
  };
}