import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:mobile/utils/i18n_zh.dart';

class PhotoEditorPage extends StatefulWidget {
  final AssetEntity assetEntity;

  const PhotoEditorPage({super.key, required this.assetEntity});

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final _log = Logger('PhotoEditorPage');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startEditing();
    });
  }

  Future<void> _startEditing() async {
    final File? imageFile = await widget.assetEntity.originFile;

    if (!mounted) return;

    if (imageFile == null) {
      _log.severe('无法获取原始图片文件。');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法获取原始图片文件')));
      Navigator.of(context).pop();
      return;
    }

    // 启动 ProImageEditor 编辑器页面
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProImageEditor.file(
          imageFile,
          configs: const ProImageEditorConfigs(i18n: chineseI18n),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: _onImageEditingComplete,
            onCloseEditor: (_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _onImageEditingComplete(Uint8List bytes) async {
    _log.info('开始进行高质量图像编码...');
    final img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      _log.severe('图像解码失败，无法保存。');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('图像处理失败，无法保存。')));
      Navigator.of(context).pop();
      return;
    }

    final Uint8List highQualityBytes = Uint8List.fromList(
      img.encodeJpg(image, quality: 100),
    );
    _log.info('高质量JPEG编码完成, 文件大小: ${highQualityBytes.lengthInBytes / 1024} KB');

    final String filename =
        'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // 使用 PhotoManager 将处理后的图片字节保存到系统相册
    final AssetEntity newEntity = await PhotoManager.editor.saveImage(
      highQualityBytes,
      filename: filename,
    );

    if (!mounted) return;

    _log.info('新图片已成功保存到相册！');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('编辑成功！新图片已保存到相册。')));
    // 成功保存后，关闭编辑器页面，并将新创建的 AssetEntity 作为结果返回
    Navigator.of(context).pop(newEntity);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
