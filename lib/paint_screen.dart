import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:painter/painter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:videowrite/video_screen.dart';

class PaintScreen extends StatefulWidget {
  @override
  _PaintScreenState createState() => new _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  bool _finished = false;
  PainterController _controller = _newController();
  late Uint8List imageFile;

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _videocontroller = VideoPlayerController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
        _videocontroller.play();
      });
  }

  static PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.transparent;
    return controller;
  }

  late VideoPlayerController _videocontroller;

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: 'New Painting',
          onPressed: () => setState(() {
            _finished = false;
            _controller = _newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        new IconButton(
            icon: new Icon(
              Icons.undo,
            ),
            tooltip: 'Undo',
            onPressed: () {
              if (_controller.isEmpty) {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) =>
                        new Text('Nothing to undo'));
              } else {
                _controller.undo();
              }
            }),
        new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: _controller.clear),
        new IconButton(
            icon: new Icon(Icons.check),
            onPressed: () async {
              _videocontroller.pause();
              var pos = await _videocontroller.position;
              final uint8list = await VideoThumbnail.thumbnailData(
                      video:
                          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",

                      //thumbnailPath: (await getTemporaryDirectory()).path,
                      imageFormat: ImageFormat.WEBP,
                      maxHeight: MediaQuery.of(context).size.width.toInt(),
                      maxWidth: MediaQuery.of(context).size.width.toInt(),
                      // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
                      quality: 75,
                      timeMs: pos!.inMilliseconds)
                  .then((value) async {
                final image1 = img.decodeImage(value!);
                var sket = await _controller.finish().toPNG();
                final image2 = await img.decodeImage(sket);
                var mergedImage = await img.Image(image1!.width + image2!.width,
                    max(image1.height, image2.height));
                await img.copyInto(
                  mergedImage,
                  image1,
                );
                await img.copyInto(
                  mergedImage,
                  image2,
                );
                var listtt = await mergedImage.getBytes();

                print(listtt.toString());

               // _show(_controller.finish(), context, listtt);
              });

              // screenshotController.capture().then((image) {
              //   _show(_controller.finish(), context, image!);
              // }).catchError((onError) {
              //   print(onError);
              // });

              // _show(_controller.finish(), context);
            }),
      ];
    }
    return new Scaffold(
      appBar: new AppBar(
          title: const Text('Painter Example'),
          actions: actions,
          bottom: new PreferredSize(
            child: new DrawBar(_controller),
            preferredSize: new Size(MediaQuery.of(context).size.width, 30.0),
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            new Center(
              child: Screenshot(
                controller: screenshotController,
                child: Container(
                  height: MediaQuery.of(context).size.width * (9 / 16),
                  child:
                      //  _videocontroller.value.isInitialized
                      //     ? AspectRatio(
                      //         aspectRatio: 1,
                      //         child: VideoPlayer(_videocontroller),
                      //       )
                      //     : Container()
                      Stack(
                    children: [
                      // Container(
                      //   color: Colors.transparent,
                      //   height: MediaQuery.of(context).size.width * (9 / 16),
                      //   child: _videocontroller.value.isInitialized
                      //       ? AspectRatio(
                      //           aspectRatio: 16 / 9,
                      //           child: VideoPlayer(_videocontroller),
                      //         )
                      //       : Container(),
                      // ),
                      VideScreen(_videocontroller,
                          MediaQuery.of(context).size.width * (9 / 16)),
                      new AspectRatio(
                          aspectRatio: 16 / 9, child: new Painter(_controller)),
                    ],
                  ),
                ),
              ),
            ),
            VideoProgressIndicator(_videocontroller, allowScrubbing: true),
            SizedBox(
              height: 100,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _videocontroller.value.isPlaying
                        ? _videocontroller.pause()
                        : _videocontroller.play();
                  });
                },
                child: Container(
                  color: Colors.blue,
                  height: 60,
                  width: 100,
                  alignment: Alignment.center,
                  child: Text(
                    _videocontroller.value.isPlaying ? "Pause" : "Play",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _show(
      PictureDetails picture, BuildContext context, Uint8List imagedata) {
    setState(() {
      _finished = true;
    });
    Navigator.of(context)
        .push(new MaterialPageRoute(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('View your image'),
        ),
        body: new Container(
            alignment: Alignment.center,
            child: new FutureBuilder<Uint8List>(
              future: picture.toPNG(),
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return new Text('Error: ${snapshot.error}');
                    } else {
                      return Image.memory(imagedata);
                    }
                  default:
                    return new Container(
                        child: new FractionallySizedBox(
                      widthFactor: 0.1,
                      child: new AspectRatio(
                          aspectRatio: 1.0,
                          child: new CircularProgressIndicator()),
                      alignment: Alignment.center,
                    ));
                }
              },
            )),
      );
    }));
  }
}

class DrawBar extends StatelessWidget {
  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(child: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new Container(
              child: new Slider(
            value: _controller.thickness,
            onChanged: (double value) => setState(() {
              _controller.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            activeColor: Colors.white,
          ));
        })),
        new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new RotatedBox(
              quarterTurns: _controller.eraseMode ? 2 : 0,
              child: IconButton(
                  icon: new Icon(Icons.create),
                  tooltip: (_controller.eraseMode ? 'Disable' : 'Enable') +
                      ' eraser',
                  onPressed: () {
                    setState(() {
                      _controller.eraseMode = !_controller.eraseMode;
                    });
                  }));
        }),
        new ColorPickerButton(_controller, false),
        new ColorPickerButton(_controller, true),
      ],
    );
  }
}

class ColorPickerButton extends StatefulWidget {
  final PainterController _controller;
  final bool _background;

  ColorPickerButton(this._controller, this._background);

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return new IconButton(
        icon: new Icon(_iconData, color: _color),
        tooltip: widget._background
            ? 'Change background color'
            : 'Change draw color',
        onPressed: _pickColor);
  }

  void _pickColor() {
    Color pickerColor = _color;
    Navigator.of(context)
        .push(new MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return new Scaffold(
                  appBar: new AppBar(
                    title: const Text('Pick color'),
                  ),
                  body: new Container(
                      alignment: Alignment.center,
                      child: new ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) => pickerColor = c,
                      )));
            }))
        .then((_) {
      setState(() {
        _color = pickerColor;
      });
    });
  }

  Color get _color => widget._background
      ? widget._controller.backgroundColor
      : widget._controller.drawColor;

  IconData get _iconData =>
      widget._background ? Icons.format_color_fill : Icons.brush;

  set _color(Color color) {
    if (widget._background) {
      widget._controller.backgroundColor = color;
    } else {
      widget._controller.drawColor = color;
    }
  }
}
