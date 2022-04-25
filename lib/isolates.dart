import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'mandelbrot.dart';

class TileRequest {
  final int id;
  final int width;
  final int height;
  final Offset upperLeftCoord;
  final double renderWidth;
  TileRequest({
    required this.id,
    required this.width,
    required this.height,
    required this.upperLeftCoord,
    required this.renderWidth,
  });
}

class TileResponse {
  final int requestId;
  final int isolateId;
  final TransferableTypedData data;
  final int width;
  final int height;

  TileResponse({
    required this.requestId,
    required this.isolateId,
    required this.data,
    required this.height,
    required this.width,
  });
}

class IsolateInitData {
  final SendPort resultPort;
  final int isolateId;

  IsolateInitData({
    required this.isolateId,
    required this.resultPort,
  });
}

class IsolateEntry {
  /// this fields are only accessed from main isolate
  final Isolate isolate;
  final SendPort toIsolate;

  IsolateEntry({
    required this.isolate,
    required this.toIsolate,
  });

  static Future<IsolateEntry> create(IsolateInitData initData) async {
    ReceivePort initPort = ReceivePort();

    final spawnedIsolate =
        await Isolate.spawn(isolateHandler, initPort.sendPort);
    final sendPort = await initPort.first as SendPort;
    sendPort.send(initData);
    return IsolateEntry(isolate: spawnedIsolate, toIsolate: sendPort);
  }

  void dispose() {
    isolate.kill();
  }

  static void isolateHandler(sendPort) {
    /// this here is the code that runs inside the isolate
    final SendPort initSendPort = sendPort;
    final ReceivePort fromMainIsolate = ReceivePort();
    late final SendPort resultPort;
    late final int isolateId;

    initSendPort.send(fromMainIsolate.sendPort);

    fromMainIsolate.listen((message) {
      if (message is IsolateInitData) {
        resultPort = message.resultPort;
        isolateId = message.isolateId;
      } else {
        final request = message as TileRequest;
        final mandel = Mandelbrot();

        final double aspect = request.width / request.height;

        final imageBuffer = Uint32List(request.width * request.height);

        mandel.renderData(
            data: imageBuffer,
            xMin: request.upperLeftCoord.dx,
            xMax: request.upperLeftCoord.dx + request.renderWidth,
            yMin: request.upperLeftCoord.dy,
            yMax: request.upperLeftCoord.dy + request.renderWidth / aspect,
            bitmapWidth: request.width,
            bitMapHeight: request.height);

        resultPort.send(
          TileResponse(
            isolateId: isolateId,
            requestId: request.id,
            width: request.width,
            height: request.height,
            data: TransferableTypedData.fromList([imageBuffer]),
          ),
        );
      }
    });
  }
}
