import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';

/// 处理图片选择等功能的服务类。
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final _uuid = const Uuid();
  final _picker = ImagePicker();

  /// 从相册选一张图片。
  Future<Attachment?> pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return null;
    return _importFile(xfile, AttachmentKind.image);
  }

  /// 拍照选一张图片。
  Future<Attachment?> takePhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera);
    if (xfile == null) return null;
    return _importFile(xfile, AttachmentKind.image);
  }

  Future<Attachment?> _importFile(XFile xfile, AttachmentKind kind) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = xfile.path.split('.').last.toLowerCase();
    final fileName = '${kind.name}_${_uuid.v4()}.$ext';
    final dest = '${dir.path}/attachments/$fileName';
    final destFile = File(dest);
    await destFile.parent.create(recursive: true);
    await File(xfile.path).copy(dest);
    return Attachment(
      kind: kind,
      localPath: dest,
      displayName: xfile.name,
      mimeType: xfile.mimeType,
    );
  }
}
