import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../libaction/body_part.dart';

class ModelPainter extends CustomPainter {
  final Map<BodyPartIndex, Tuple2<double, double>> data;

  ModelPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double extent = (size.width + size.height) / 2.0 / 15.0 / 2.0;

    if (data.containsKey(BodyPartIndex.nose)) {
      canvas.drawCircle(
        _inflatedFlippedOffset(
          data[BodyPartIndex.nose].item1,
          data[BodyPartIndex.nose].item2,
          size,
        ),
        extent * 2,
        new Paint()
          ..color = new Color(0x88000000)
          ..style = PaintingStyle.fill,
      );

      if (data.containsKey(BodyPartIndex.shoulderR) &&
          data.containsKey(BodyPartIndex.shoulderL)) {
        canvas.drawLine(
            _inflatedFlippedOffset(
              data[BodyPartIndex.nose].item1,
              data[BodyPartIndex.nose].item2,
              size,
            ),
            _inflatedFlippedOffset(
              (data[BodyPartIndex.shoulderR].item1 +
                      data[BodyPartIndex.shoulderL].item1) /
                  2.0,
              (data[BodyPartIndex.shoulderR].item2 +
                      data[BodyPartIndex.shoulderL].item2) /
                  2.0,
              size,
            ),
            new Paint()
              ..color = new Color(0x88000000)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = extent);
      }
    }

    for (var pair in <List<BodyPartIndex>>[
      [BodyPartIndex.shoulderR, BodyPartIndex.shoulderL],
      [BodyPartIndex.shoulderR, BodyPartIndex.elbowR],
      [BodyPartIndex.elbowR, BodyPartIndex.wristR],
      [BodyPartIndex.shoulderL, BodyPartIndex.elbowL],
      [BodyPartIndex.elbowL, BodyPartIndex.wristL],
      [BodyPartIndex.shoulderR, BodyPartIndex.hipR],
      [BodyPartIndex.shoulderL, BodyPartIndex.hipL],
      [BodyPartIndex.hipR, BodyPartIndex.hipL],
      [BodyPartIndex.hipR, BodyPartIndex.kneeR],
      [BodyPartIndex.kneeR, BodyPartIndex.ankleR],
      [BodyPartIndex.hipL, BodyPartIndex.kneeL],
      [BodyPartIndex.kneeL, BodyPartIndex.ankleL],
    ]) {
      if (data.containsKey(pair[0]) && data.containsKey(pair[1])) {
        canvas.drawLine(
            _inflatedFlippedOffset(
                data[pair[0]].item1, data[pair[0]].item2, size),
            _inflatedFlippedOffset(
                data[pair[1]].item1, data[pair[1]].item2, size),
            new Paint()
              ..color = new Color(0x88000000)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = extent);
      }
    }
  }

  Offset _inflatedFlippedOffset(double x, double y, Size size) {
    return new Offset((1.0 - x) * size.width, y * size.height);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
