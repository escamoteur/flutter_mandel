import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_mandel/isolates.dart';

import 'mandelbrot.dart';

/// To keep things simple for this demo we use a simple global variable
/// In a real app you would access such a class via a service loactor
RenderManager renderManager = RenderManager();

class RenderManager {
  final watch = Stopwatch();
  int requestCount = 0;
  late int numberOfTiles;
  final isolateList = <IsolateEntry>[];
  final availableIsolates = <IsolateEntry>[];
  int isolatesInUse = 0;
  final waitingTiles = <TileRequest>[];

  final Map<int, Completer<Image>> _requestedTilesCompleters = {};
  // this port is shared by all isolates
  final tileResultPort = ReceivePort();

  ValueNotifier<bool> busy = ValueNotifier(false);
  ValueNotifier<String> renderTimeAsString = ValueNotifier(' ');

  RenderManager() {
    tileResultPort.listen((message) async {
      final response = message as TileResponse;

      final frame = await ImmutableBuffer.fromUint8List(
              response.data.materialize().asUint8List())
          .then((value) => ImageDescriptor.raw(value,
                  width: response.width,
                  height: response.height,
                  pixelFormat: PixelFormat.bgra8888)
              .instantiateCodec()
              .then((codec) => codec.getNextFrame()));

      /// transfer image to the waiting tile
      _requestedTilesCompleters
          .remove(response.requestId)!
          .complete(frame.image);

      /// when we receive a response at this point it means one of our isolates
      /// just got idle so we can directly use it to render the next waiting tile
      if (waitingTiles.isNotEmpty) {
        isolateList[response.isolateId]
            .toIsolate
            .send(waitingTiles.removeLast());
      } else {
        /// No tiles are currently waiting, so we put the idle isolate back
        ///  in the available list
        availableIsolates.add(isolateList[response.isolateId]);

        if (availableIsolates.length == isolateList.length) // no isolate in use
        {
          busy.value = false;
          renderTimeAsString.value = '${watch.elapsedMilliseconds}ms';
        }
      }
    });
  }

  void emptyQeue() {
    waitingTiles.clear();
  }

  Future<void> increaseIsolateCount() async {
    final newIsolate = await IsolateEntry.create(
      isolateId: isolateList.length,
      resultPort: tileResultPort.sendPort,
    );
    isolateList.add(newIsolate);
    availableIsolates.add(newIsolate);
  }

  void decreaseIsolateCount() {
    if (isolatesInUse == 0) {
      //only if all isolates are idle
      if (isolateList.isNotEmpty) {
        isolateList.removeLast().dispose();
      }
    }
  }

  Future<Image> renderTile({
    required int width,
    required int height,
    required Offset upperLeftCoord,
    required double renderWidth,
  }) {
    if (isolateList.isNotEmpty) {
      /// schedule an isolate
      final tileRequest = TileRequest(
        id: requestCount,
        width: width,
        height: height,
        upperLeftCoord: upperLeftCoord,
        renderWidth: renderWidth,
      );
      if (availableIsolates.isNotEmpty) {
        final nextIsolate = availableIsolates.removeLast();

        nextIsolate.toIsolate.send(tileRequest);
      } else {
        waitingTiles.add(tileRequest);
      }
      final completer = Completer<Image>();
      _requestedTilesCompleters[requestCount++] = completer;
      return completer.future;
    } else {
      /// No rendereing isolate
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

      return ImmutableBuffer.fromUint8List(imageBuffer.buffer.asUint8List())
          .then(
        (value) => ImageDescriptor.raw(value,
                width: width, height: height, pixelFormat: PixelFormat.bgra8888)
            .instantiateCodec()
            .then(
              (codec) => codec.getNextFrame().then((frame) {
                if (--numberOfTiles == 0) {
                  busy.value = false;
                  renderTimeAsString.value = '${watch.elapsedMilliseconds}ms';
                }
                return frame.image;
              }),
            ),
      );
    }
  }
}
