import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders the Student QR card to PNG bytes off-screen.
Future<Uint8List> renderStudentQRCardToPng({
  required String qrData,
  required String studentName,
  required String className,
  double pixelRatio = 3.0,
}) async {
  const double cardWidth = 300;
  const double cardHeight = 440;
  const double padding = 20;

  final double pWidth = cardWidth * pixelRatio;
  final double pHeight = cardHeight * pixelRatio;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, pWidth, pHeight));
  canvas.scale(pixelRatio);

  // Background
  final Paint bgPaint = Paint()..color = Colors.white;
  final RRect cardRRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, cardWidth, cardHeight),
    const Radius.circular(20),
  );
  canvas.drawRRect(cardRRect, bgPaint);
  canvas.drawRRect(
    cardRRect,
    Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  double y = padding;

  void drawText(
    String text,
    double fontSize,
    FontWeight weight,
    Color color,
    double yPos,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: cardWidth - padding * 2);
    tp.paint(canvas, Offset((cardWidth - tp.width) / 2, yPos));
  }

  drawText('SMP MUHAMMADIYAH 1', 15, FontWeight.w900, const Color(0xFF1E88E5), y);
  y += 20;
  drawText('SEKAMPUNG UDIK', 12, FontWeight.w900, Colors.black87, y);
  y += 18;

  const double qrSize = 190;
  final QrPainter qrPainter = QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: false,
    color: Colors.black,
    emptyColor: Colors.white,
  );
  canvas.save();
  canvas.translate((cardWidth - qrSize) / 2, y);
  qrPainter.paint(canvas, const Size(qrSize, qrSize));
  canvas.restore();
  y += qrSize + 12;

  drawText('KARTU PRESENSI SISWA', 10, FontWeight.bold, Colors.black54, y);
  y += 16;
  drawText(studentName, 18, FontWeight.bold, Colors.black, y);
  y += 24;
  drawText('KELAS: $className', 13, FontWeight.bold, const Color(0xFF1E88E5), y);
  y += 22;
  drawText(
    'Tunjukkan QR Code ini kepada Guru untuk dicatat kehadirannya.',
    9,
    FontWeight.normal,
    Colors.black54,
    y,
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(pWidth.toInt(), pHeight.toInt());
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) throw 'Gagal merender data gambar';
  return byteData.buffer.asUint8List();
}

/// Legacy render for class card if needed
Future<Uint8List> renderQRCardToPng({
  required String qrData,
  required String className,
  double pixelRatio = 3.0,
}) async {
  return renderStudentQRCardToPng(
    qrData: qrData,
    studentName: 'KELAS $className',
    className: className,
    pixelRatio: pixelRatio,
  );
}
