class Mandelbrot {
  static const int maxIterations = 2000;

  static List<List<int>> levelColors = [
    [0, 0xff000435],
    [1, 0xff00086b], // dark blue background
    [2, 0xff0010d6],
    [100, 0xffffff00], // yellow
    [200, 0xffff0000], // red
    [400, 0xff00ff00], // green
    [600, 0xff00ffff], // cyan
    [800, 0xfffefefe], // white
    [900, 0xff808080], // gray
    [1000, 0xff000000], // black
    [1200, 0xff00ffff],
    [1400, 0xff00ff00],
    [1600, 0xffff0000],
    [1800, 0xffffff00],
    [1900, 0xffffff00],
    [2000, 0xff000000]
  ];

  int iterations(double x0, double y0) {
    if (y0 < 0) {
      y0 = -y0;
    }
    double x = x0;
    double y = y0;
    double xT;

    double x2 = x * x;
    double y2 = y * y;

    // Filter out points in the main cardiod
    if (-0.75 < x && x < 0.38 && y < 0.66) {
      double q = (x - 0.25) * (x - 0.25) + y2;
      if (q * (q + x - 0.25) < 0.25 * y2) {
        return maxIterations;
      }
    }

    // Filter out points in bulb of radius 1/4 around (-1,0)
    if (-1.25 < x && x < -0.75 && y < 0.25) {
      double d = (x + 1) * (x + 1) + y2;
      if (d < 1 / 16) {
        return maxIterations;
      }
    }

    for (int i = 0; i < maxIterations; i++) {
      if (x * x + y * y > 4) {
        return i;
      }

      xT = x * x - y * y + x0;
      y = 2 * x * y + y0;
      x = xT;
    }
    return maxIterations;
  }

  static int colorFromLevel(int level) {
    // Interpolate control points in this.levelColors
    // to map levels to colors.
    int iMin = 0;
    int iMax = levelColors.length;
    while (iMin < iMax - 1) {
      int iMid = (iMin + iMax) ~/ 2;
      int levelT = levelColors[iMid][0];
      if (levelT == level) {
        return levelColors[iMid][1];
      }
      if (levelT < level) {
        iMin = iMid;
      } else {
        iMax = iMid;
      }
    }

    int levelMin = levelColors[iMin][0];
    int levelMax = levelColors[iMax][0];
    // Make sure we are not overly sensitive to rounding
    double p = (level - levelMin) / (levelMax - levelMin);

    int color = 0;
    for (var i = 0; i < 4; i++) {
      int cMin = levelColors[iMin][1] >> i * 8 & 0xff;
      int cMax = levelColors[iMax][1] >> i * 8 & 0xff;
      var value = (cMin + p * (cMax - cMin)).toInt();
      color = color + (value << i * 8);
    }

    return color;
  }

  renderData({
    required List<int> data,
    required double xMin,
    required double xMax,
    required double yMin,
    required double yMax,
    required int bitmapWidth,
    required int bitMapHeight,
  }) async {
    // Per-pixel step values
    double dx = (xMax - xMin) / bitmapWidth;
    double dy = (yMax - yMin) / bitMapHeight;

    double y = yMin + dy / 2;
    int ib = 0;
    for (int iy = 0; iy < bitMapHeight; iy++) {
      double x = xMin + dx / 2;
      for (int ix = 0; ix < bitmapWidth; ix++) {
        int iters = iterations(x, y);
        data[ib++] = colorFromLevel(iters);
        x += dx;
      }
      y += dy;
    }
  }
}
