import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_mandel/isolates.dart';

RenderManager renderManager = RenderManager();

class RenderManager {
  late IsolateEntry renderIsolate;
  int requestCount = 0;
  late int numberOfTiles;

  final Map<int, Completer<Image>> _requestedTilesCompleters = {};
  // this port is shared by all isolates
  final tileResultPort = ReceivePort();

  ValueNotifier<bool> busy = ValueNotifier(false);

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

      busy.value = (--numberOfTiles > 0);

      _requestedTilesCompleters
          .remove(response.requestId)
          ?.complete(frame.image);
    });
  }

  Future<void> initIsolates() async {
    renderIsolate = await IsolateEntry.create(
        IsolateInitData(isolateId: 1, resultPort: tileResultPort.sendPort));
  }

  Future<Image> renderTile({
    required int width,
    required int height,
    required Offset upperLeftCoord,
    required double renderWidth,
  }) async {
    /// schedule an isolate
    renderIsolate.toIsolate.send(TileRequest(
      id: requestCount,
      width: width,
      height: height,
      upperLeftCoord: upperLeftCoord,
      renderWidth: renderWidth,
    ));

    final completer = Completer<Image>();
    _requestedTilesCompleters[requestCount++] = completer;
    return completer.future;
  }
}
