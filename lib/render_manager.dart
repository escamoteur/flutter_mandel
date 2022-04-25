import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'mandelbrot.dart';

RenderManager renderManager = RenderManager();

class RenderManager {
  late int numberOfTiles;

  ValueNotifier<bool> busy = ValueNotifier(false);

  Future<Image> renderTile({
    required int width,
    required int height,
    required Offset upperLeftCoord,
    required double renderWidth,
  }) async {
    final mandel = Mandelbrot();
    final double aspect = width / height;

    final imageBuffer = Uint32List(width * height);

    mandel.renderData(
        data: imageBuffer,
        xMin: upperLeftCoord.dx,
        xMax: upperLeftCoord.dx + renderWidth,
        yMin: upperLeftCoord.dy,
        yMax: upperLeftCoord.dy + renderWidth / aspect,
        bitmapWidth: width,
        bitMapHeight: height);

    final frame =
        await ImmutableBuffer.fromUint8List(imageBuffer.buffer.asUint8List())
            .then((value) => ImageDescriptor.raw(value,
                    width: width,
                    height: height,
                    pixelFormat: PixelFormat.bgra8888)
                .instantiateCodec()
                .then((codec) => codec.getNextFrame()));

    busy.value = (--numberOfTiles > 0);

    return frame.image;
  }
}
