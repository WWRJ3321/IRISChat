import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// 轻量语音转文字服务。按一次开始录音，再按一次停止并返回识别文本。
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();
  final _stt = SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  String _lastRecognized = '';
  bool get isListening => _listening;

  /// 请求麦克风权限。首次调用会弹出系统权限对话框。
  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      // 权限被永久拒绝，引导用户去设置
      openAppSettings();
    }
    return false;
  }

  Future<bool> init() async {
    if (_initialized) return true;
    // 先检查权限
    final hasPerm = await _ensurePermission();
    if (!hasPerm) return false;
    final ok = await _stt.initialize(
      onError: (e) {},
      onStatus: (s) {
        _listening = s == 'listening';
      },
    );
    _initialized = ok;
    return ok;
  }

  /// 开始录音。返回是否成功开始。
  Future<bool> start() async {
    final ok = await init();
    if (!ok) return false;
    if (_listening) return true;
    _lastRecognized = '';
    await _stt.listen(
      localeId: 'zh_CN',
      listenMode: ListenMode.dictation,
      onResult: (r) {
        _lastRecognized = r.recognizedWords;
      },
    );
    _listening = true;
    return true;
  }

  /// 停止录音，返回识别到的文本。
  Future<String> stop() async {
    await _stt.stop();
    _listening = false;
    return _lastRecognized;
  }

  /// 取消录音，不返回结果。
  Future<void> cancel() async {
    await _stt.cancel();
    _listening = false;
  }
}