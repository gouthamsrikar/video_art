import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideScreen extends StatefulWidget {
  VideoPlayerController controller;
  double width;
  VideScreen(this.controller, this.width);

  @override
  State<VideScreen> createState() => _VideScreenState();
}

class _VideScreenState extends State<VideScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.width,
      child: widget.controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayer(widget.controller),
            )
          : Container(),
    );
  }
}
