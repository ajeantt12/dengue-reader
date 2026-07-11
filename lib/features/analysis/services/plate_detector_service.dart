import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../../../core/exceptions/analysis_exception.dart';
import '../../../shared/models/dot_reading.dart';

/// Content-based detector for the dengue test plate.
///
/// The plate carries a 3×3 grid of reagent wells above a printed 7-patch CMYK
/// colour strip (top row: black, yellow, magenta, cyan; bottom row: grey,
/// white, orange). Rather than sampling fixed positions relative to the whole
/// frame — which fails whenever the plate is small, off-centre, or rotated in
/// the shot — this detector *scans the whole bright enclosure*:
///
///   1. Find the colour strip using its unique magenta / cyan / yellow blocks.
///   2. Find the yellow reactive-line wells (when present).
///   3. Fit an affine plate model (canonical → image) from those landmarks.
///   4. Project the full 3×3 well grid and the neutral strip patches.
///   5. White-balance with the strip's neutral patches, then sample each well.
///
/// The canonical landmark coordinates are calibrated from the frontal
/// reference sample (DR005) and expressed in "column-pitch" units with the
/// top-left well at the origin.
class PlateDetectorService {
  /// Longest edge the analysis runs at. Phone captures are ~12 MP; working at
  /// ~1000 px keeps the pure-Dart passes fast without losing the wells.
  static const int _workingMaxDim = 1000;

  /// Canonical landmark coordinates (column-pitch units, origin at well R1C1).
  /// Derived from the frontal reference plate; see CALIBRATION.md.
  static const double _rowPitch = 0.754; // well row pitch / column pitch
  static const Map<String, List<double>> _canonicalPatches = {
    'K': [0.088, 2.271],
    'Y': [0.709, 2.271],
    'M': [1.331, 2.271],
    'C': [1.953, 2.271],
    'grey': [0.088, 2.971],
    'white': [0.709, 2.971],
    'orange': [1.953, 2.971],
  };

  static const int gridRows = 3;
  static const int gridCols = 3;

  PlateDetectionResult analyse(img.Image raw, {bool assertQuality = true}) {
    final work = _toWorking(raw);
    final W = work.width, H = work.height;
    final workScale = W / raw.width;

    // Per-pixel HSV, cached in flat arrays for the segmentation passes.
    final hsv = _HsvField.fromImage(work);
    final minBlobArea = (W * H) * 0.0006; // ignore specks / dust

    // Segment by *hue band* (not one shared vivid mask): adjacent strip
    // patches share saturated borders and merge into a single component under
    // a plain vivid mask, so their circular-mean hue reads as neither colour.
    // A per-hue mask keeps magenta, cyan, yellow, and orange separate.
    List<_Blob> band(double lo, double hi, double minSat) {
      final mask = List<bool>.filled(W * H, false);
      for (int i = 0; i < W * H; i++) {
        mask[i] =
            _hueInRange(hsv.h[i], lo, hi) && hsv.s[i] > minSat && hsv.v[i] > 0.15;
      }
      return _connectedBlobs(mask, W, H, hsv)
          .where((b) => b.area >= minBlobArea)
          .toList();
    }

    _Blob? largestNearY(List<_Blob> bs, double y, double yTol) {
      _Blob? best;
      for (final b in bs) {
        if ((b.cy - y).abs() > yTol) continue;
        if (best == null || b.area > best.area) best = b;
      }
      return best;
    }

    // --- 1. Locate the colour strip via its unique magenta / cyan patches ---
    final magentaBlobs = band(275, 345, 0.40);
    final cyanBlobs = band(150, 210, 0.30);
    final magenta = _largest(magentaBlobs);
    final cyan = _largest(cyanBlobs);
    if (magenta == null && cyan == null) {
      // No strip found at all — we cannot anchor the plate.
      throw const PlateNotDetectedException();
    }

    // Strip row baseline and patch pitch from the magenta/cyan pair.
    final double stripRowY =
        _avg([magenta?.cy, cyan?.cy].whereType<double>().toList());
    double patchPitch;
    if (magenta != null && cyan != null) {
      patchPitch = (cyan.cx - magenta.cx).abs();
    } else {
      // Fall back to the block width if only one of the pair was found.
      patchPitch = (magenta ?? cyan)!.width.toDouble();
    }
    if (patchPitch < 4) patchPitch = 4;

    // Yellow blobs appear both on the strip (Y patch) and as reactive wells.
    // Split them by vertical position relative to the strip row.
    final yellowBlobs = band(44, 80, 0.30);
    final orangeBlobs = band(15, 50, 0.45);

    // Strip yellow patch: yellow blob sitting on the top strip row.
    final stripYellow =
        largestNearY(yellowBlobs, stripRowY, patchPitch * 0.85);
    // Orange patch: warm blob on the bottom strip row.
    final orange =
        largestNearY(orangeBlobs, stripRowY + patchPitch * 1.1, patchPitch);

    // --- 2. Reactive-line wells: yellow blobs above the strip. The reactive
    // line is the top row in portrait; if several rows are yellow we take the
    // topmost complete row as the anchor. ---
    final wellBand = stripRowY - patchPitch * 1.6;
    final wellCandidates = yellowBlobs
        .where((b) => b.cy < wellBand && b.roundness > 0.5)
        .toList();
    final reactiveRow = _topRow(wellCandidates, patchPitch * 0.6)
      ..sort((a, b) => a.cx.compareTo(b.cx));

    // --- 4. Fit a strip map (canonical → image) from the strip patches only ---
    // The strip is rigid within itself, so this affine reliably locates its
    // own neutral (white/grey) patches for white balance. The wells are *not*
    // included here: the strip is a loose card whose distance below the wells
    // varies per shot, so it must not constrain the well rows.
    final srcU = <double>[]; // canonical x
    final srcV = <double>[]; // canonical y
    final dstX = <double>[];
    final dstY = <double>[];
    void addCorr(_Blob? b, String patch) {
      if (b == null) return;
      srcU.add(_canonicalPatches[patch]![0]);
      srcV.add(_canonicalPatches[patch]![1]);
      dstX.add(b.cx);
      dstY.add(b.cy);
    }

    addCorr(magenta, 'M');
    addCorr(cyan, 'C');
    addCorr(stripYellow, 'Y');
    addCorr(orange, 'orange');

    // Needs ≥3 non-collinear strip points (the top row is collinear, so orange
    // is what makes it solvable). May be null under heavy glare on the strip.
    final _PlaneMap? map = _AffineFit.solve(srcU, srcV, dstX, dstY);

    // We can still read the plate if the reactive line is visible even when the
    // strip map failed — we just skip white balance in that case.
    if (map == null && reactiveRow.length != gridCols) {
      throw const PlateNotDetectedException();
    }

    // --- 5. White-balance using the neutral strip patches ---
    final wb =
        map != null ? _whiteBalance(work, hsv, map) : _WbGains.identity();

    // --- 6. Lay out the 3×3 well grid ---
    // The colour strip is a loose card whose distance below the wells varies
    // shot to shot, so it cannot fix the well *rows*. When the reactive line
    // is visible we anchor the grid directly on those yellow wells and step
    // down by the plate's row pitch; otherwise we fall back to the strip map.
    final List<List<double>> wellCentresWork =
        _layOutWells(reactiveRow, stripRowY, map);

    // --- 7. Sample each well on the (white-balanced) working image ---
    final readings = <DotReading>[];
    final sampleRadius = math.max(6, (patchPitch * 0.28).round());
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        final p = wellCentresWork[r * gridCols + c];
        final rgb = _sampleDisc(work, wb, p[0].round(), p[1].round(),
            sampleRadius);
        final hsvv = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
        readings.add(DotReading(
          dotId: 'R${r + 1}C${c + 1}',
          hue: hsvv[0],
          saturation: hsvv[1],
          value: hsvv[2],
          rawR: rgb[0],
          rawG: rgb[1],
          rawB: rgb[2],
        ));
      }
    }

    if (assertQuality) _assertQuality(readings);

    return PlateDetectionResult(
      readings: readings,
      rows: gridRows,
      cols: gridCols,
      stripFound: true,
      reactiveLineWellsFound: reactiveRow.length,
      workScale: workScale,
      wellCentresWork: wellCentresWork,
      debug: {
        'magenta': magenta == null ? null : [magenta.cx, magenta.cy],
        'cyan': cyan == null ? null : [cyan.cx, cyan.cy],
        'stripYellow':
            stripYellow == null ? null : [stripYellow.cx, stripYellow.cy],
        'orange': orange == null ? null : [orange.cx, orange.cy],
        'patchPitch': patchPitch,
        'reactiveRow': reactiveRow.map((b) => [b.cx, b.cy]).toList(),
      },
    );
  }

  /// Compute the 9 well centres (working px). Prefers a layout anchored on the
  /// three detected reactive-line wells (robust to the loose strip); otherwise
  /// projects the canonical grid through the strip [map].
  List<List<double>> _layOutWells(
      List<_Blob> reactiveRow, double stripRowY, _PlaneMap? map) {
    if (reactiveRow.length == gridCols) {
      final p0 = [reactiveRow[0].cx, reactiveRow[0].cy];
      final pLast = [reactiveRow[gridCols - 1].cx, reactiveRow[gridCols - 1].cy];
      // Column step vector (per one column) from the reactive line.
      final ex = [
        (pLast[0] - p0[0]) / (gridCols - 1),
        (pLast[1] - p0[1]) / (gridCols - 1),
      ];
      final exLen = math.sqrt(ex[0] * ex[0] + ex[1] * ex[1]);
      // Row step: perpendicular to the columns, pointing toward the strip
      // (downward in image space), length = plate row pitch.
      var down = [-ex[1], ex[0]];
      if (down[1] < 0) down = [ex[1], -ex[0]]; // ensure it points down-image
      final downLen = math.sqrt(down[0] * down[0] + down[1] * down[1]);
      final ey = [
        down[0] / downLen * _rowPitch * exLen,
        down[1] / downLen * _rowPitch * exLen,
      ];
      final centres = <List<double>>[];
      for (int r = 0; r < gridRows; r++) {
        for (int c = 0; c < gridCols; c++) {
          centres.add([
            p0[0] + c * ex[0] + r * ey[0],
            p0[1] + c * ex[1] + r * ey[1],
          ]);
        }
      }
      return centres;
    }
    // Fallback (no reactive line detected): project the canonical grid through
    // the strip map. The caller guarantees the map is non-null on this path.
    final centres = <List<double>>[];
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        centres.add(map!.project(c.toDouble(), r * _rowPitch));
      }
    }
    return centres;
  }

  // ---- image quality gates (unchanged spirit from the old detector) ----
  void _assertQuality(List<DotReading> readings) {
    final avgValue =
        readings.map((d) => d.value).reduce((a, b) => a + b) / readings.length;
    final avgSat = readings.map((d) => d.saturation).reduce((a, b) => a + b) /
        readings.length;
    if (avgValue < 0.12) throw const ImageTooDataarkException();
    if (avgValue > 0.95 && avgSat < 0.03) throw const ImageOverexposedException();
  }

  // ---- orient upright, then downscale to working resolution ----
  img.Image _toWorking(img.Image raw) {
    // Phone captures often store the frame rotated with an EXIF orientation
    // tag; apply it so "strip below the wells" holds. No-op for images
    // without an orientation tag (e.g. the research samples).
    final upright = img.bakeOrientation(raw);
    final maxDim = math.max(upright.width, upright.height);
    if (maxDim <= _workingMaxDim) return upright;
    final scale = _workingMaxDim / maxDim;
    return img.copyResize(
      upright,
      width: (upright.width * scale).round(),
      height: (upright.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  // ---- white balance from the strip's white + grey patches ----
  _WbGains _whiteBalance(img.Image im, _HsvField hsv, _PlaneMap affine) {
    final samples = <List<int>>[];
    for (final name in ['white', 'grey']) {
      final cc = _canonicalPatches[name]!;
      final p = affine.project(cc[0], cc[1]);
      final rgb = _sampleDisc(im, null, p[0].round(), p[1].round(), 8);
      // Only trust a genuinely neutral, bright-ish sample.
      final h = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
      if (h[1] < 0.28 && h[2] > 0.2) samples.add(rgb);
    }
    if (samples.isEmpty) return _WbGains.identity();

    double r = 0, g = 0, b = 0;
    for (final s in samples) {
      r += s[0];
      g += s[1];
      b += s[2];
    }
    r /= samples.length;
    g /= samples.length;
    b /= samples.length;
    final lum = (r + g + b) / 3.0;
    if (r < 1 || g < 1 || b < 1) return _WbGains.identity();
    return _WbGains(lum / r, lum / g, lum / b);
  }

  // ---- disc sampling with optional white-balance gains applied ----
  List<int> _sampleDisc(img.Image im, _WbGains? wb, int cx, int cy, int radius) {
    final r2 = radius * radius;
    double sr = 0, sg = 0, sb = 0;
    int n = 0;
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx * dx + dy * dy > r2) continue;
        final x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= im.width || y >= im.height) continue;
        final px = im.getPixel(x, y);
        sr += px.r;
        sg += px.g;
        sb += px.b;
        n++;
      }
    }
    if (n == 0) return [0, 0, 0];
    double r = sr / n, g = sg / n, b = sb / n;
    if (wb != null) {
      r = (r * wb.r).clamp(0, 255);
      g = (g * wb.g).clamp(0, 255);
      b = (b * wb.b).clamp(0, 255);
    }
    return [r.round(), g.round(), b.round()];
  }

  /// The topmost horizontal row of blobs (those whose centre-y is within [tol]
  /// of the minimum centre-y in the set).
  static List<_Blob> _topRow(List<_Blob> blobs, double tol) {
    if (blobs.isEmpty) return [];
    double minY = blobs.first.cy;
    for (final b in blobs) {
      if (b.cy < minY) minY = b.cy;
    }
    return blobs.where((b) => (b.cy - minY) <= tol).toList();
  }

  // ---- blob helpers ----
  static _Blob? _largest(List<_Blob> blobs) {
    _Blob? best;
    for (final b in blobs) {
      if (best == null || b.area > best.area) best = b;
    }
    return best;
  }

  static bool _hueInRange(double h, double lo, double hi) {
    if (lo <= hi) return h >= lo && h <= hi;
    return h >= lo || h <= hi; // wrap-around band
  }

  static double _avg(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  // ---- connected-component labelling on a boolean mask ----
  List<_Blob> _connectedBlobs(
      List<bool> mask, int W, int H, _HsvField hsv) {
    final visited = List<bool>.filled(W * H, false);
    final blobs = <_Blob>[];
    final stack = <int>[];
    for (int start = 0; start < W * H; start++) {
      if (!mask[start] || visited[start]) continue;
      stack
        ..clear()
        ..add(start);
      visited[start] = true;
      int area = 0, minX = W, minY = H, maxX = 0, maxY = 0;
      double sumX = 0, sumY = 0;
      // Mean hue via unit-vector accumulation (hue is circular).
      double hx = 0, hy = 0, sumS = 0, sumV = 0;
      while (stack.isNotEmpty) {
        final idx = stack.removeLast();
        final x = idx % W, y = idx ~/ W;
        area++;
        sumX += x;
        sumY += y;
        final hRad = hsv.h[idx] * math.pi / 180.0;
        hx += math.cos(hRad);
        hy += math.sin(hRad);
        sumS += hsv.s[idx];
        sumV += hsv.v[idx];
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
        // 4-connectivity
        if (x > 0) _push(mask, visited, stack, idx - 1);
        if (x < W - 1) _push(mask, visited, stack, idx + 1);
        if (y > 0) _push(mask, visited, stack, idx - W);
        if (y < H - 1) _push(mask, visited, stack, idx + W);
      }
      double meanHue = math.atan2(hy, hx) * 180.0 / math.pi;
      if (meanHue < 0) meanHue += 360;
      final bw = (maxX - minX + 1), bh = (maxY - minY + 1);
      blobs.add(_Blob(
        area: area,
        cx: sumX / area,
        cy: sumY / area,
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        meanHue: meanHue,
        meanSat: sumS / area,
        meanVal: sumV / area,
        roundness: area / (bw * bh),
      ));
    }
    return blobs;
  }

  static void _push(
      List<bool> mask, List<bool> visited, List<int> stack, int idx) {
    if (mask[idx] && !visited[idx]) {
      visited[idx] = true;
      stack.add(idx);
    }
  }

  // Returns [H(0–360), S(0–1), V(0–1)]
  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0, gf = g / 255.0, bf = b / 255.0;
    final maxc = math.max(rf, math.max(gf, bf));
    final minc = math.min(rf, math.min(gf, bf));
    final delta = maxc - minc;
    double h = 0;
    if (delta != 0) {
      if (maxc == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (maxc == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
      if (h < 0) h += 360;
    }
    return [h, maxc == 0 ? 0.0 : delta / maxc, maxc];
  }
}

/// Outcome of [PlateDetectorService.analyse].
class PlateDetectionResult {
  final List<DotReading> readings;
  final int rows;
  final int cols;
  final bool stripFound;
  final int reactiveLineWellsFound;

  /// working-image dimension / raw dimension (for mapping debug coords back).
  final double workScale;

  /// Projected well centres in *working-image* pixel coordinates.
  final List<List<double>> wellCentresWork;

  /// Detected landmark coordinates (working px), for diagnostics/overlays.
  final Map<String, Object?> debug;

  const PlateDetectionResult({
    required this.readings,
    required this.rows,
    required this.cols,
    required this.stripFound,
    required this.reactiveLineWellsFound,
    this.workScale = 1.0,
    this.wellCentresWork = const [],
    this.debug = const {},
  });
}

class _Blob {
  final int area;
  final double cx, cy;
  final int minX, minY, maxX, maxY;
  final double meanHue, meanSat, meanVal, roundness;
  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
  const _Blob({
    required this.area,
    required this.cx,
    required this.cy,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.meanHue,
    required this.meanSat,
    required this.meanVal,
    required this.roundness,
  });
}

class _HsvField {
  final List<double> h, s, v;
  _HsvField(this.h, this.s, this.v);
  factory _HsvField.fromImage(img.Image im) {
    final n = im.width * im.height;
    final h = List<double>.filled(n, 0);
    final s = List<double>.filled(n, 0);
    final v = List<double>.filled(n, 0);
    int i = 0;
    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        final px = im.getPixel(x, y);
        final hsv = PlateDetectorService._rgbToHsv(
            px.r.toInt(), px.g.toInt(), px.b.toInt());
        h[i] = hsv[0];
        s[i] = hsv[1];
        v[i] = hsv[2];
        i++;
      }
    }
    return _HsvField(h, s, v);
  }
}

class _WbGains {
  final double r, g, b;
  const _WbGains(this.r, this.g, this.b);
  factory _WbGains.identity() => const _WbGains(1, 1, 1);
}

/// A planar map from canonical plate coordinates to image pixels.
abstract class _PlaneMap {
  List<double> project(double u, double v);
}

/// Least-squares affine map (canonical u,v) → (image x,y).
/// x = ax*u + bx*v + cx ;  y = ay*u + by*v + cy
class _AffineFit implements _PlaneMap {
  final double ax, bx, cx, ay, by, cy;
  const _AffineFit(this.ax, this.bx, this.cx, this.ay, this.by, this.cy);

  @override
  List<double> project(double u, double v) =>
      [ax * u + bx * v + cx, ay * u + by * v + cy];

  static _AffineFit? solve(
      List<double> u, List<double> v, List<double> x, List<double> y) {
    final n = u.length;
    if (n < 3) return null;
    // Normal equations for [a b c] against x, shared design matrix M=[u v 1].
    // Build 3×3 A = MᵀM and RHS bx (for x), by (for y).
    final a = List.generate(3, (_) => List<double>.filled(3, 0));
    final rx = List<double>.filled(3, 0);
    final ry = List<double>.filled(3, 0);
    for (int i = 0; i < n; i++) {
      final row = [u[i], v[i], 1.0];
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          a[r][c] += row[r] * row[c];
        }
        rx[r] += row[r] * x[i];
        ry[r] += row[r] * y[i];
      }
    }
    // _solve3 mutates its matrix in place, so give each solve its own copy.
    final sx = _solve3(_clone3(a), rx);
    final sy = _solve3(_clone3(a), ry);
    if (sx == null || sy == null) return null;
    return _AffineFit(sx[0], sx[1], sx[2], sy[0], sy[1], sy[2]);
  }

  static List<List<double>> _clone3(List<List<double>> m) =>
      [m[0].toList(), m[1].toList(), m[2].toList()];

  // Gaussian elimination with partial pivoting for a 3×3 system.
  static List<double>? _solve3(List<List<double>> a, List<double> b) {
    for (int col = 0; col < 3; col++) {
      int piv = col;
      for (int r = col + 1; r < 3; r++) {
        if (a[r][col].abs() > a[piv][col].abs()) piv = r;
      }
      if (a[piv][col].abs() < 1e-9) return null;
      if (piv != col) {
        final t = a[piv];
        a[piv] = a[col];
        a[col] = t;
        final tb = b[piv];
        b[piv] = b[col];
        b[col] = tb;
      }
      for (int r = 0; r < 3; r++) {
        if (r == col) continue;
        final f = a[r][col] / a[col][col];
        for (int c = col; c < 3; c++) {
          a[r][c] -= f * a[col][c];
        }
        b[r] -= f * b[col];
      }
    }
    return [b[0] / a[0][0], b[1] / a[1][1], b[2] / a[2][2]];
  }
}
