import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'mandelbrot.dart';

class MandleView extends StatefulWidget {
  final int width;
  final int height;
  final Offset upperLeftCoord;
  final double renderWidth;
  const MandleView({
    required this.width,
    required this.height,
    required this.upperLeftCoord,
    required this.renderWidth,
    Key? key,
  }) : super(key: key);

  @override
  State<MandleView> createState() => _MandleViewState();
}

class _MandleViewState extends State<MandleView> {
  Uint32List? imageBuffer;
  final mandel = Mandelbrot();
  FrameInfo? frameToDisplay;

  @override
  void initState() {
    imageBuffer = Uint32List(widget.width * widget.height);
    renderMandel();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MandleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.width != oldWidget.width || widget.height != oldWidget.height) {
      /// Window size changed so we have to adapt our image buffer size
      imageBuffer = Uint32List(widget.width * widget.height);
    }
    renderMandel();
  }

  void renderMandel() {
    final double aspect = widget.width / widget.height;

    mandel.renderData(
        data: imageBuffer!,
        xMin: widget.upperLeftCoord.dx,
        xMax: widget.upperLeftCoord.dx + widget.renderWidth,
        yMin: widget.upperLeftCoord.dy,
        yMax: widget.upperLeftCoord.dy + widget.renderWidth / aspect,
        bitmapWidth: widget.width,
        bitMapHeight: widget.height);

    Future.delayed(Duration(seconds: 1)).then((value) =>
        ImmutableBuffer.fromUint8List(imageBuffer!.buffer.asUint8List())
            .then((value) => ImageDescriptor.raw(value,
                    width: widget.width,
                    height: widget.height,
                    pixelFormat: PixelFormat.bgra8888)
                .instantiateCodec()
                .then((codec) => codec.getNextFrame()))
            .then((frame) => setState(() => frameToDisplay = frame)));
  }

  @override
  Widget build(BuildContext context) {
    if (frameToDisplay != null) {
      return RawImage(
        image: frameToDisplay!.image,
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
