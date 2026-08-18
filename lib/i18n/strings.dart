import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 轻量国际化。
///
/// 不引入 intl 代码生成流程（那会带来 arb 文件与 build_runner 负担），
/// 直接用一张词条表 + BuildContext 扩展，保持工程精简。
///
/// 用法：`context.l.settings`
class L {
  const L(this.code);

  /// 'zh' 或 'en'
  final String code;

  bool get isZh => code == 'zh';

  static const supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  static const delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// 设置里的语言码转 Locale，'system' 返回 null 交给系统决定
  static Locale? localeOf(String languageCode) => switch (languageCode) {
        'zh' => const Locale('zh'),
        'en' => const Locale('en'),
        _ => null,
      };

  static L of(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return L(lang == 'en' ? 'en' : 'zh');
  }

  String _t(String zh, String en) => isZh ? zh : en;

  /// 用于页面专有的少量动态文案，避免为每句静态说明重复声明 getter。
  String text(String zh, String en) => _t(zh, en);

  // ---------------------------------------------------------------- 通用
  String get ok => _t('确定', 'OK');
  String get cancel => _t('取消', 'Cancel');
  String get save => _t('保存', 'Save');
  String get delete => _t('删除', 'Delete');
  String get edit => _t('编辑', 'Edit');
  String get copy => _t('复制', 'Copy');
  String get copied => _t('已复制', 'Copied');
  String get close => _t('关闭', 'Close');
  String get done => _t('完成', 'Done');
  String get retry => _t('重试', 'Retry');
  String get restore => _t('恢复', 'Restore');
  String get rename => _t('重命名', 'Rename');
  String get search => _t('搜索', 'Search');
  String get add => _t('添加', 'Add');
  String get none => _t('无', 'None');
  String get defaultLabel => _t('默认', 'Default');
  String get custom => _t('自定义', 'Custom');
  String get reset => _t('重置', 'Reset');
  String get notImplemented => _t('该功能将在后续版本提供', 'Coming in a future version');

  // ---------------------------------------------------------------- 聊天页
  String get appName => _t('虹月 AI Chat', 'IRIS Chat');
  String get newChat => _t('新建对话', 'New chat');
  String get history => _t('历史对话', 'Chat history');
  String get settings => _t('设置', 'Settings');
  String get sendHint => _t('发送消息…', 'Send a message…');
  String get configureApiFirst => _t('请先在设置里配置 API', 'Configure an API in settings first');
  String get send => _t('发送', 'Send');
  String get stopGenerating => _t('停止生成', 'Stop');
  String get generating => _t('生成中…', 'Generating…');
  String get noApiConfigured => _t('未配置 API', 'No API configured');
  String get startNewChat => _t('开始新的对话', 'Start a new conversation');
  String get emptyHint =>
      _t('长按消息可复制、编辑、重新生成', 'Long-press a message to copy, edit or regenerate');
  String get backToBottom => _t('回到底部', 'Back to bottom');
  String get more => _t('更多', 'More');
  String get collapse => _t('收起', 'Collapse');
  String get voiceInput => _t('语音输入', 'Voice input');
  String get gallery => _t('相册', 'Gallery');
  String get camera => _t('拍照', 'Camera');
  String get voice => _t('语音', 'Voice');
  String get paste => _t('粘贴', 'Paste');

  // ---------------------------------------------------------------- 消息操作
  String get regenerate => _t('重新生成', 'Regenerate');
  String get deleteMessage => _t('删除消息', 'Delete message');
  String get deleteMessageWarning => _t(
        '这条消息及其之后的所有内容都会被删除，无法恢复。',
        'This message and everything after it will be deleted permanently.',
      );
  String get prevBranch => _t('上一个版本', 'Previous version');
  String get nextBranch => _t('下一个版本', 'Next version');
  String get reasoning => _t('思考过程', 'Reasoning');
  String get editMessage => _t('编辑消息', 'Edit message');

  // ---------------------------------------------------------------- 历史
  String get searchHistory => _t('搜索对话…', 'Search conversations…');
  String get noHistory => _t('还没有对话记录', 'No conversations yet');
  String get pin => _t('置顶', 'Pin');
  String get unpin => _t('取消置顶', 'Unpin');
  String get pinned => _t('已置顶', 'Pinned');
  String get swipeToDelete => _t('左滑删除', 'Swipe to delete');
  String get movedToTrash => _t('已移入回收站', 'Moved to trash');
  String get undo => _t('撤销', 'Undo');
  String get trash => _t('回收站', 'Trash');
  String get trashEmpty => _t('回收站是空的', 'Trash is empty');
  String get trashHint =>
      _t('删除的对话在这里保留 30 天', 'Deleted conversations are kept for 30 days');
  String get emptyTrash => _t('清空回收站', 'Empty trash');
  String get deleteForever => _t('彻底删除', 'Delete forever');
  String daysLeft(int d) => _t('$d 天后清除', '$d days left');

  // ---------------------------------------------------------------- API 配置
  String get apiConfig => _t('API 配置', 'API configuration');
  String get apiProfiles => _t('服务商配置', 'Providers');
  String get addProfile => _t('新增配置', 'Add provider');
  String get profileName => _t('配置名称', 'Name');
  String get baseUrl => _t('接口地址', 'Base URL');
  String get apiKey => _t('密钥', 'API key');
  String get models => _t('模型', 'Models');
  String get modelList => _t('模型列表', 'Model list');
  String get fetchModels => _t('拉取模型', 'Fetch models');
  String get addModelManually => _t('手动添加模型', 'Add model manually');
  String get selectedModel => _t('当前模型', 'Active model');
  String get streamOutput => _t('流式输出', 'Streaming');
  String get testConnection => _t('测试连接', 'Test connection');
  String get connectionOk => _t('连接正常', 'Connection OK');
  String get presets => _t('常用服务商', 'Presets');
  String get modelHint =>
      _t('可添加多个模型，点击切换当前使用', 'Add multiple models and tap to switch');

  // ---------------------------------------------------------------- 角色卡
  String get characters => _t('角色卡', 'Characters');
  String get characterName => _t('名称', 'Name');
  String get avatar => _t('头像', 'Avatar');
  String get pickImage => _t('选择图片', 'Pick image');
  String get useEmoji => _t('使用 Emoji', 'Use emoji');
  String get removeImage => _t('移除图片', 'Remove image');
  String get systemPrompt => _t('系统提示词', 'System prompt');
  String get greeting => _t('开场白', 'Greeting');
  String get temperature => _t('温度', 'Temperature');
  String get topP => _t('Top P', 'Top P');
  String get maxTokens => _t('最大回复长度', 'Max tokens');
  String get presencePenalty => _t('存在惩罚', 'Presence penalty');
  String get frequencyPenalty => _t('频率惩罚', 'Frequency penalty');
  String get contextLimit => _t('上下文条数', 'Context messages');
  String get modelOverride => _t('指定模型', 'Model override');
  String get builtIn => _t('内置', 'Built-in');
  String get newCharacter => _t('新建角色卡', 'New character');
  String get duplicate => _t('复制一份', 'Duplicate');

  // ---------------------------------------------------------------- 外观
  String get appearance => _t('主题与外观', 'Theme & appearance');
  String get accentColor => _t('主色', 'Accent color');
  String get themeMode => _t('主题模式', 'Theme mode');
  String get light => _t('浅色', 'Light');
  String get dark => _t('深色', 'Dark');
  String get followSystem => _t('自动', 'Auto');
  String get oledBlack => _t('OLED 纯黑', 'OLED black');
  String get oledBlackHint => _t('深色模式下背景使用纯黑', 'Use pure black in dark mode');
  String get glass => _t('毛玻璃', 'Glassmorphism');
  String get glassHint => _t('关闭可提升低端设备流畅度', 'Disable to improve performance');
  String get blurRadius => _t('模糊强度', 'Blur strength');
  String get glassOpacity => _t('玻璃通透度', 'Glass opacity');
  String get wallpaper => _t('背景壁纸', 'Wallpaper');
  String get pickWallpaper => _t('选择壁纸', 'Pick wallpaper');
  String get removeWallpaper => _t('移除壁纸', 'Remove wallpaper');
  String get wallpaperDim => _t('壁纸蒙层', 'Wallpaper dim');
  String get fontScale => _t('字号缩放', 'Font scale');
  String get bubbleRadius => _t('气泡圆角', 'Bubble radius');
  String get showTimestamp => _t('显示时间', 'Show timestamps');
  String get animation => _t('界面动画', 'Animations');
  String get animationSpeed => _t('动画速度', 'Animation speed');
  String get slowSpeed => _t('慢', 'Slow');
  String get fastSpeed => _t('快', 'Fast');
  String get language => _t('语言', 'Language');
  String get languageSystem => _t('跟随系统', 'System');
  String get languageZh => _t('简体中文', '简体中文');
  String get languageEn => _t('English', 'English');

  // ---------------------------------------------------------------- 上下文
  String get contextManagement => _t('上下文管理', 'Context management');
  String get contextStrategy => _t('策略', 'Strategy');
  String get strategyTruncate => _t('只保留最近若干条', 'Keep recent messages only');
  String get strategyTruncateHint =>
      _t('不额外消耗 token，但会丢失早期细节', 'No extra tokens, but older details are lost');
  String get strategySummary => _t('自动摘要压缩', 'Auto-summarize');
  String get strategySummaryHint => _t(
        '把早期对话交给 AI 压缩成摘要，保留脉络但每次压缩会多一次请求',
        'Compresses older messages into a summary; costs one extra request',
      );
  String get summaryTrigger => _t('触发条数', 'Trigger after');
  String get summaryKeepRecent => _t('保留原文条数', 'Keep verbatim');
  String get summarizing => _t('正在压缩上下文…', 'Compressing context…');
  String get contextSummary => _t('对话摘要', 'Conversation summary');

  // ---------------------------------------------------------------- 设置页
  String get dataAndBackup => _t('数据与备份', 'Data & backup');
  String get exportData => _t('导出备份', 'Export backup');
  String get importData => _t('导入备份', 'Import backup');
  String get clearAllChats => _t('清空所有对话', 'Delete all conversations');
  String get about => _t('关于', 'About');
  String get version => _t('版本', 'Version');
  String get changelog => _t('更新日志', 'Changelog');
  String get coreFeatures => _t('核心功能', 'Features');
  String get tips => _t('使用提示', 'Tips');

  // ---------------------------------------------------------------- 错误
  String get errorNoProfile => _t('请先配置 API', 'Configure an API first');
  String get errorNetwork => _t('网络请求失败', 'Network request failed');
  String get errorEmptyReply => _t('模型没有返回内容', 'The model returned nothing');
}

extension LocalizationExt on BuildContext {
  L get l => L.of(this);
}