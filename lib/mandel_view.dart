import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_mandel/render_manager.dart';

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
  ui.Image? imageToDisplay;

  @override
  void initState() {
    renderMandel();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MandleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    renderMandel();
  }

  void renderMandel() {
    renderManager
        .renderTile(
            width: widget.width,
            height: widget.height,
            upperLeftCoord: widget.upperLeftCoord,
            renderWidth: widget.renderWidth)
        .then((image) => setState(() => imageToDisplay = image));
  }

  @override
  Widget build(BuildContext context) {
    if (imageToDisplay != null) {
      return RawImage(image: imageToDisplay);
    } else {
      return const SizedBox();
    }
  }
}
