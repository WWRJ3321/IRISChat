import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AttachmentKind { image, audio, file }

/// 消息附件：图片、文件或音频，统一管理路径和元数据。
class Attachment {
  Attachment({
    String? id,
    required this.kind,
    required this.localPath,
    this.displayName,
    this.mimeType,
  }) : id = id ?? _uuid.v4();

  final String id;
  final AttachmentKind kind;

  /// 应用私有目录内的本地路径，绝对路径。
  final String localPath;

  /// 原始文件名，用于显示
  String? displayName;

  /// mime 类型，例如 image/png、image/jpeg
  String? mimeType;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'localPath': localPath,
        'displayName': displayName,
        'mimeType': mimeType,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String?,
        kind: AttachmentKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => AttachmentKind.file,
        ),
        localPath: json['localPath'] as String? ?? '',
        displayName: json['displayName'] as String?,
        mimeType: json['mimeType'] as String?,
      );
}
