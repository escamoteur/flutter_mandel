import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_mandel/mandelbrot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mandel Demo'),
        ),
        body: AspectRatio(
          aspectRatio: 4 / 3,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return MandleView(
                  width: constraints.maxWidth.toInt(),
                  height: constraints.maxHeight.toInt());
            },
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MandleView extends StatefulWidget {
  final int width;
  final int height;
  const MandleView({
    required this.width,
    required this.height,
    Key? key,
  }) : super(key: key);

  @override
  State<MandleView> createState() => _MandleViewState();
}

class _MandleViewState extends State<MandleView> {
  late final imageBuffer = Uint32List(widget.width * widget.height);

  @override
  void initState() {
    imageBuffer.fillRange(0, imageBuffer.length, 0xff00ff00);

    final mandel = Mandelbrot();

    mandel.renderData(
        data: imageBuffer,
        xMin: -2.4,
        xMax: 0.5,
        yMin: -1.1,
        yMax: 1.1,
        bitmapWidth: widget.width,
        bitMapHeight: widget.height);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.FrameInfo>(
        future:
            ui.ImmutableBuffer.fromUint8List(imageBuffer.buffer.asUint8List())
                .then((value) => ui.ImageDescriptor.raw(value,
                        width: widget.width,
                        height: widget.height,
                        pixelFormat: ui.PixelFormat.bgra8888)
                    .instantiateCodec()
                    .then((codec) => codec.getNextFrame())),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              color: Colors.amber,
              child: RawImage(
                image: snapshot.data!.image,
                fit: BoxFit.cover,
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
