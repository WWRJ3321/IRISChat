/// 版本信息与更新日志（应用内「关于 → 更新日志」直接读这里）。
class AppVersion {
  AppVersion._();

  /// 当前版本号，同时用于备份包命名 003AIChat_V<version>.zip
  static const String current = '1.3.4';

  static const List<ReleaseNote> changelog = [
    ReleaseNote(
      version: '1.3.4',
      date: '2026-08-18',
      added: [
        '全新应用图标：月轮 + 暖色月牙高光，支持 Android 自适应图标',
        '关于页顶部改为显示真实应用图标',
      ],
      fixed: [],
      changed: [
        '开关控件换成更饱满的胶囊样式，开启时带主色微光',
        '整体圆角加大，卡片与弹窗观感更柔和圆润',
      ],
      addedEn: [
        'New app icon: moon ring with a warm crescent highlight, with Android adaptive icon support',
        'The About page header now shows the real app icon',
      ],
      fixedEn: [],
      changedEn: [
        'Switches redesigned as fuller pill toggles with an accent glow when on',
        'Larger corner radii across cards and dialogs for a softer look',
      ],
    ),
    ReleaseNote(
      version: '1.3.3',
      date: '2026-08-18',
      added: [
        '输入栏附件面板新增独立相册 / 拍照按钮，功能分开不再混淆',
        '语音输入首次使用时主动请求麦克风权限，失败时引导去系统设置',
        '群聊提示词强化：明确要求每个 AI 保持独立人格，不模仿其他成员，不做主持人',
      ],
      fixed: [
        '附件面板去掉「粘贴」按钮（用户可自行长按粘贴）',
        '图片选择器和相机选择器逻辑分开，不再共用同一回调',
      ],
      changed: [
        '群聊 system prompt 重写：强调个体独立性、简短回复、不抢话',
      ],
      addedEn: [
        'Input bar now has separate gallery and camera buttons',
        'Voice input requests microphone permission upfront and guides to settings on denial',
        'Group chat system prompt strengthened: each AI must maintain independent personality, not imitate others, not act as moderator',
      ],
      fixedEn: [
        'Removed "paste" button from attach panel (users can long-press to paste)',
        'Gallery picker and camera picker now use separate callbacks',
      ],
      changedEn: [
        'Group chat system prompt rewritten to emphasize independence, brevity, and no taking over',
      ],
    ),
    ReleaseNote(
      version: '1.3.0',
      date: '2026-08-18',
      added: [
        '多 AI 群聊：一条消息发出后，群里成员按顺序各自发言，每人只以自己的身份说话',
        '群聊可设置每条消息的发言轮数（1-3 轮），成员之间能真正来回几句',
        '成员被点名时，其他成员可以选择跳过本轮',
      ],
      fixed: [
        '群聊里 AI 会替别的成员发言、自导自演整段对话的问题',
        '群聊回复开头重复出现自己的名字',
        '删除了群聊成员角色卡后仍按旧人数运行导致的界面异常',
        '群聊配置页下拉框在弹窗里样式错乱、模型列表与供应商不同步',
      ],
      changed: [
        '群聊配置页重做：更清晰的发言顺序 / 轮数选择、成员卡片与状态提示',
        '顶部栏群聊人数按实际存在的成员统计',
      ],
      addedEn: [
        'Multi-AI group chat: after one message, members reply in turn, each speaking only as itself',
        'Configurable rounds per message (1-3) so members can talk back and forth',
        'A member can skip its turn when the user addressed someone else',
      ],
      fixedEn: [
        'AI speaking for other members or roleplaying the whole conversation in group chat',
        'Replies repeating the speaker name at the start',
        'UI glitch when a group member\u0027s character card was deleted but old count was still used',
        'Misstyled dropdowns in the group dialog and model lists not following the provider',
      ],
      changedEn: [
        'Rebuilt the group settings page: clearer order/rounds pickers, member cards and status hints',
        'Top bar member count reflects existing characters only',
      ],
    ),
    ReleaseNote(
      version: '1.2.1',
      date: '2026-08-17',
      added: [
        '群聊多轮轮询：用户发消息后每个 AI 依次有机会回复，可选择不回复，直到无人回复或达上限',
        'AI 回复去重：自动去除模型输出中自带的「名字：」前缀，避免 UI 重复显示身份',
        '历史侧边栏：从左侧滑入的全高侧边栏替代底部弹窗，支持搜索、置顶、重命名、删除',
      ],
      fixed: [
        '群聊原逻辑让所有 AI 同时回应用户消息，现改为顺序轮询多轮对话',
        'AI 回复有时自带名字导致界面显示两遍',
      ],
      changed: [
        '历史面板改为左侧滑入式侧边栏，动画更自然',
      ],
      addedEn: [
        'Multi-turn group chat polling: after user message, each AI takes a turn to reply (or skip); continues until no one replies or max rounds reached',
        'Reply de-duplication: automatically strip self-name prefix (e.g. "Name:") from model output to avoid duplicate identity in UI',
        'History sidebar: left-sliding full-height sidebar replaces bottom sheet, with search, pin, rename, delete',
      ],
      fixedEn: [
        'Group chat previously made all AIs reply to user at once; now uses sequential multi-turn polling',
        'AI sometimes prefixed its own name causing duplicate display in UI',
      ],
      changedEn: [
        'History panel changed to left-sliding sidebar with natural animation',
      ],
    ),
    ReleaseNote(
      version: '1.2.0',
      date: '2026-08-17',
      added: [
        '多 AI 群聊：多个角色轮流或随机参与同一会话，每个角色可绑定不同供应商与模型',
        '群聊身份标识：每条 AI 回复标注角色名，模型系统提示注入身份信息',
        '输入栏思考开关与深度档位（1-3 档）',
        '设置新增「启动时新建对话 / 继续上次」开关',
        '所有角色卡均可删除（含内置角色），删除后不会被自动恢复',
        '服务预设扩充至 11 项（含 Claude/Gemini 兼容网关、Qwen、GLM、英伟达、硅基流动等）',
      ],
      fixed: [
        '群聊上下文断裂：改为显式共享全量上下文，每个 AI 都能看到前序完整对话',
        '群聊角色分不清自身身份：系统提示注入角色名、供应商与模型信息',
        '群聊只使用全局 API：每个角色现在可独立绑定供应商',
        '回复方式选框在弹窗中样式异常',
        '角色卡默认参数调整为 topP 0.95 / maxTokens 4096 / contextLimit 25',
      ],
      changed: [
        '群聊顶部状态栏：启用群聊时显示群聊名、成员数与模式，点击进入群聊配置',
        '版本号升为 1.2.0',
      ],
      addedEn: [
        'Multi-AI group chat: multiple characters take turns or reply randomly; each can bind a different API provider and model',
        'Identity tags in group chat: each reply is labeled with the character name; identity info injected into system prompts',
        'Thinking toggle and depth selector (levels 1-3) in the input bar',
        'New setting: start with a new conversation or resume the last one on app launch',
        'All character cards can now be deleted, including built-in ones; deleted builtins are not restored on restart',
        'Provider presets expanded to 11 (including Claude/Gemini compatible gateways, Qwen, GLM, NVIDIA, SiliconFlow, etc.)',
      ],
      fixedEn: [
        'Group chat context loss: now builds and shares full context explicitly; every AI sees the complete prior conversation',
        'Characters could not distinguish their own identity: system prompts now inject name, provider and model info',
        'Group chat only used global API: each character can now bind an independent provider',
        'Reply mode dropdown had rendering issues in the dialog',
        'Default character params adjusted: topP 0.95 / maxTokens 4096 / contextLimit 25',
      ],
      changedEn: [
        'Top bar shows group chat info (name, member count, mode) when enabled; tap to open group settings',
        'Version bumped to 1.2.0',
      ],
    ),
    ReleaseNote(
      version: '1.1.0',
      date: '2026-08-16',
      added: [
        '内置「虹月」角色卡并设为默认，带完整人设提示词',
        '角色卡头像支持上传本地图片（不再局限 emoji）',
        '同一服务商可保存多个模型，点击即可切换',
        '对话历史支持左滑删除',
        '新增回收站，删除的对话保留 30 天可恢复',
        '上下文管理：可选「保留最近若干条」或「自动摘要压缩」省 token',
        '界面语言切换：跟随系统 / 简体中文 / English',
        '动画速度可在 0.25~3 倍之间调节',
        '应用内更新日志页',
      ],
      fixed: [
        '关闭界面动画的开关此前完全无效，现已真正生效（含页面转场与水波纹）',
        '字号缩放此前只影响消息气泡，现已全局生效',
        '底部手势条区域出现黑边、界面无法铺满屏幕',
        '左下角背景光晕会跟随输入框漂移出「黑雾」',
      ],
      changed: [
        '页面转场改用 Material 3 强调曲线，位移收窄，退场加轻微缩放',
        '默认动效时长整体缩短，观感更利落',
      ],
      addedEn: [
        'Built-in “IRIS Selene” character card is now the default, with a full persona prompt',
        'Character avatars can now use local images instead of emoji only',
        'One provider can store multiple models and switch between them',
        'Swipe left in chat history to delete a conversation',
        'Added Trash: deleted conversations can be restored within 30 days',
        'Context management: keep recent messages or auto-summarize to save tokens',
        'Language switching: System / Simplified Chinese / English',
        'Animation speed can be adjusted from 0.25x to 3x',
        'In-app changelog page',
      ],
      fixedEn: [
        'The animation switch now actually disables animations, including transitions and ripples',
        'Font scaling now applies across the app instead of only message bubbles',
        'Fixed a black edge around the bottom gesture area and incomplete edge-to-edge layout',
        'Fixed the lower-left background glow drifting with the input bar',
      ],
      changedEn: [
        'Page transitions now use Material 3 emphasized curves with tighter movement and a subtle exit scale',
        'Default animation durations were shortened for a crisper feel',
      ],
    ),
    ReleaseNote(
      version: '1.0.0',
      date: '2026-08-16',
      added: [
        '三段式聊天界面：顶部状态栏 / 消息流 / 悬浮毛玻璃输入框',
        'Markdown 渲染、代码高亮、代码块一键复制',
        'OpenAI 兼容接口配置与 SSE 流式输出',
        '会话本地存储与上下文管理',
        '角色卡：系统提示词、温度、Top P 等参数',
        '单条消息重新生成 / 编辑，并保留历史分支（1/3 页码切换）',
        '青色主题、OLED 纯黑、毛玻璃与自定义壁纸',
      ],
      fixed: [],
      changed: [],
      addedEn: [
        'Three-part chat layout: status bar, message stream and floating glass input',
        'Markdown rendering, code highlighting and one-tap code copying',
        'OpenAI-compatible API configuration with SSE streaming',
        'Local conversation storage and context management',
        'Character cards with system prompts, temperature, Top P and more',
        'Regenerate or edit individual messages while preserving conversation branches',
        'Cyan theme, OLED black, glass effects and custom wallpaper',
      ],
      fixedEn: [],
      changedEn: [],
    ),
  ];
}

class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.date,
    required this.added,
    required this.fixed,
    required this.changed,
    required this.addedEn,
    required this.fixedEn,
    required this.changedEn,
  });

  final String version;
  final String date;
  final List<String> added;
  final List<String> fixed;
  final List<String> changed;
  final List<String> addedEn;
  final List<String> fixedEn;
  final List<String> changedEn;

  List<String> addedFor(bool isZh) => isZh ? added : addedEn;
  List<String> fixedFor(bool isZh) => isZh ? fixed : fixedEn;
  List<String> changedFor(bool isZh) => isZh ? changed : changedEn;
}