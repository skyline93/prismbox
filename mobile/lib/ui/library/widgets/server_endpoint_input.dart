import 'package:flutter/material.dart';

class ServerEndpointInput extends StatelessWidget {
  final TextEditingController controller;

  const ServerEndpointInput({super.key, required this.controller});

  String sanitizeUrl(String url) {
    // Add schema if none is set
    final urlWithSchema = url.trimLeft().startsWith(RegExp(r"https?://"))
        ? url
        : "https://$url";

    // Remove trailing slash(es)
    return urlWithSchema.trimRight().replaceFirst(RegExp(r"/+$"), "");
  }

  String? _validateInput(String? url) {
    if (url == null || url.isEmpty) return null;

    final parsedUrl = Uri.tryParse(sanitizeUrl(url));
    if (parsedUrl == null ||
        !parsedUrl.isAbsolute ||
        !parsedUrl.scheme.startsWith("http") ||
        parsedUrl.host.isEmpty) {
      return '无效地址';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.url,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: '服务器地址',
        labelStyle: const TextStyle(color: Colors.black54),
        hintText: "http://localhost:15000",
        hintStyle: const TextStyle(color: Colors.black38),
        // 为所有边框状态设置圆角
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.black38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24, // 调整内边距以适应圆角
          vertical: 18,
        ),
      ),
      validator: _validateInput,
    );
  }
}
