// lib/utils/capture_widget.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures a painted widget (wrapped in RepaintBoundary) into a PNG.
/// Use with a GlobalKey assigned to that RepaintBoundary.
/// pixelRatio 2–3 yields crisp output for PDFs.
Future<Uint8List> capturePng(GlobalKey repaintKey, {double pixelRatio = 3.0}) async {
  // Ensure the widget has painted
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await WidgetsBinding.instance.endOfFrame;

  final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('RepaintBoundary not found for key: $repaintKey');
  }

  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw StateError('Failed to encode chart to PNG.');
  return byteData.buffer.asUint8List();
}
