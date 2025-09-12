// lib/ui/new_thread/widgets/reply_permission_sheet.dart
import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/reply_permission.dart';

class ReplyPermissionSheet extends StatelessWidget {
  final ReplyPermission currentPermission;
  final ValueChanged<ReplyPermission> onPermissionSelected;

  const ReplyPermissionSheet({
    super.key,
    required this.currentPermission,
    required this.onPermissionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '谁可以回复',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ...ReplyPermission.values.map((permission) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                leading: Icon(permission.icon, color: Colors.black87),
                title: Text(
                  permission.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: currentPermission == permission
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  onPermissionSelected(permission);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

void showReplyPermissionSheet(
  BuildContext context, {
  required ReplyPermission currentPermission,
  required ValueChanged<ReplyPermission> onPermissionSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ReplyPermissionSheet(
      currentPermission: currentPermission,
      onPermissionSelected: onPermissionSelected,
    ),
  );
}
