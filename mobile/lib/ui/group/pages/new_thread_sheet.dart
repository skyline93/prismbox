// lib/ui/new_thread/new_thread_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:mobile/providers/new_thread_provider.dart';
import 'package:mobile/ui/group/widgets/new_post/image_attachment_area.dart';
import 'package:mobile/ui/group/widgets/new_post/new_thread_app_bar.dart';
import 'package:mobile/ui/group/widgets/new_post/new_thread_bottom_bar.dart';
import 'package:mobile/ui/group/widgets/new_post/reply_permission_sheet.dart';
import 'package:mobile/ui/group/widgets/new_post/text_input_section.dart';
import 'package:mobile/providers/user_profile_provider.dart';

// class _User {
//   final String name;
//   final String avatarUrl;
//   const _User({required this.name, required this.avatarUrl});
// }

// const _mockUser = _User(
//   name: 'Travel Diaries',
//   avatarUrl:
//       'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
// );

class NewThreadSheet extends HookConsumerWidget {
  final String groupId;

  const NewThreadSheet({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProvider = ref.watch(userProfileProvider);
    final avatarUrl = userProvider.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    final state = ref.watch(newThreadProvider(groupId));
    final notifier = ref.read(newThreadProvider(groupId).notifier);
    final textController = useTextEditingController(text: state.text);
    final focusNode = useFocusNode();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.pickAssets(context);
      });

      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NewThreadAppBar(onCancel: () => Navigator.of(context).pop()),
      body: GestureDetector(
        onTap: () => focusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: hasAvatar
                                ? NetworkImage(
                                    avatarUrl,
                                  ) // 使用 ! 是安全的，因为 hasAvatar 已经检查过 null
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              userProvider.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ImageAttachmentArea(
                              assets: state.selectedAssets,
                              onPickAssets: () => notifier.pickAssets(context),
                              onRemoveAsset: notifier.removeAsset,
                            ),
                            const SizedBox(height: 16),
                            TextInputSection(
                              controller: textController,
                              focusNode: focusNode,
                              onTextChanged: notifier.updateText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            NewThreadBottomBar(
              selectedPermission: state.selectedPermission,
              isPostButtonEnabled: state.isPostButtonEnabled,
              onPermissionTap: () => showReplyPermissionSheet(
                context,
                currentPermission: state.selectedPermission,
                onPermissionSelected: notifier.updatePermission,
              ),
              onPostTap: () => notifier.post(context),
            ),
          ],
        ),
      ),
    );
  }
}
