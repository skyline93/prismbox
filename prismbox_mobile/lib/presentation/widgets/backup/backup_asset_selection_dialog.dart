// lib/presentation/widgets/backup/backup_asset_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/local_asset.dart';

/// 备份资产选择对话框
/// 显示资产列表供用户选择
class BackupAssetSelectionDialog extends StatefulWidget {
  final List<LocalAsset> assets;
  final List<String>? initialSelectedIds;

  const BackupAssetSelectionDialog({
    super.key,
    required this.assets,
    this.initialSelectedIds,
  });

  @override
  State<BackupAssetSelectionDialog> createState() =>
      _BackupAssetSelectionDialogState();

  /// 显示对话框并返回选中的资产ID列表
  static Future<List<String>?> show(
    BuildContext context, {
    required List<LocalAsset> assets,
    List<String>? initialSelectedIds,
  }) async {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => BackupAssetSelectionDialog(
        assets: assets,
        initialSelectedIds: initialSelectedIds,
      ),
    );
  }
}

class _BackupAssetSelectionDialogState
    extends State<BackupAssetSelectionDialog> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedIds != null) {
      _selectedIds.addAll(widget.initialSelectedIds!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('选择要备份的照片 (${_selectedIds.length}/${widget.assets.length})'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.assets.length,
          itemBuilder: (context, index) {
            final asset = widget.assets[index];
            final isSelected = _selectedIds.contains(asset.id);

            return CheckboxListTile(
              title: Text(asset.id),
              subtitle: Text(
                asset.createdAt.toString(),
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(asset.id);
                  } else {
                    _selectedIds.remove(asset.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectAll,
          child: const Text('全选'),
        ),
        TextButton(
          onPressed: _deselectAll,
          child: const Text('全不选'),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedIds.toList()),
          child: Text('备份 (${_selectedIds.length})'),
        ),
      ],
    );
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(widget.assets.map((a) => a.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }
}

