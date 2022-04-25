import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mandel/render_manager.dart';

import 'mandel_view.dart';

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
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Mandel Demo'),
          ),
          body: const MandelExplorer(),
        )
        //   onPressed: _incrementCounter,
        //   tooltip: 'Increment',
        //   child: const Icon(Icons.add),
        // ), // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}

class MandelExplorer extends StatefulWidget {
  const MandelExplorer({
    Key? key,
  }) : super(key: key);

  @override
  State<MandelExplorer> createState() => _MandelExplorerState();
}

class _MandelExplorerState extends State<MandelExplorer> {
  Offset upperLeft = const Offset(-2.05, -1.1);
  double renderWidth = 3.0;

  final int tileSize = 256;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final tilesX = (constraints.maxWidth / tileSize).ceil();
        final tilesY = (constraints.maxHeight / tileSize).ceil();
        final double renderTileSize = renderWidth / tilesX;

        renderManager.numberOfTiles = tilesX * tilesY;

        return Stack(
          children: [
            for (int xTiles = 0; xTiles < tilesX; xTiles++)
              for (int yTiles = 0; yTiles < tilesY; yTiles++)
                Positioned(
                  left: (xTiles * tileSize).toDouble(),
                  top: (yTiles * tileSize).toDouble(),
                  child: MandleView(
                    width: tileSize,
                    height: tileSize,
                    upperLeftCoord: upperLeft.translate(
                        xTiles * renderTileSize, yTiles * renderTileSize),
                    renderWidth: renderTileSize,
                  ),
                ),
            ValueListenableBuilder<bool>(
                valueListenable: renderManager.busy,
                builder: (context, busy, widget) {
                  if (busy) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    return const Center(child: SizedBox());
                  }
                }),
            Positioned(
                right: 60,
                bottom: 100,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      upperLeft = upperLeft.translate(0, -(renderWidth / 30));
                    });
                  }),
                  child: const Icon(Icons.arrow_drop_up),
                )),
            Positioned(
                right: 20,
                bottom: 60,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      upperLeft = upperLeft.translate((renderWidth / 30), 0);
                    });
                  }),
                  child: const Icon(Icons.arrow_right),
                )),
            Positioned(
                right: 100,
                bottom: 60,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      upperLeft = upperLeft.translate(-(renderWidth / 30), 0);
                    });
                  }),
                  child: const Icon(Icons.arrow_left),
                )),
            // floatingActionButton: FloatingActionButton(
            Positioned(
                right: 60,
                bottom: 20,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      upperLeft = upperLeft.translate(0, (renderWidth / 30));
                    });
                  }),
                  child: const Icon(Icons.arrow_drop_down),
                )),
            Positioned(
                right: 85,
                bottom: 150,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      renderWidth = renderWidth - (renderWidth / 30);
                      upperLeft = upperLeft.translate(
                          (renderWidth / 60), (renderWidth / 60));
                    });
                  }),
                  child: const Icon(Icons.zoom_in),
                )),
            // floatingActionButton: FloatingActionButton(
            Positioned(
                right: 35,
                bottom: 150,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: (() {
                    setState(() {
                      renderWidth = renderWidth + 0.1;
                      upperLeft = upperLeft.translate(-0.05, -0.05);
                    });
                  }),
                  child: const Icon(Icons.zoom_out),
                ))
          ],
        );
      },
    );
  }
}
