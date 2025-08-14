import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaVideoViewer extends StatefulWidget {
  final File videoFile;

  const MediaVideoViewer({super.key, required this.videoFile});

  @override
  State<MediaVideoViewer> createState() => _MediaVideoViewerState();
}

class _MediaVideoViewerState extends State<MediaVideoViewer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..setLooping(true)
      ..addListener(() {
        final currentlyPlaying = _controller.value.isPlaying;
        if (currentlyPlaying != _isPlaying) {
          setState(() {
            _isPlaying = currentlyPlaying;
          });
        }
      });
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void didUpdateWidget(covariant MediaVideoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile.path != widget.videoFile.path) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: GestureDetector(
                onTap: () => _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    if (!_isPlaying)
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('视频播放失败', style: TextStyle(color: Colors.red)),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}
