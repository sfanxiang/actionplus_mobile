import 'package:flutter/foundation.dart';

enum BodyPartIndex {
  nose,
  neck,
  shoulderR,
  elbowR,
  wristR,
  shoulderL,
  elbowL,
  wristL,
  hipR,
  kneeR,
  ankleR,
  hipL,
  kneeL,
  ankleL,
  eyeR,
  eyeL,
  earR,
  earL,
  end
}

class BodyPart {
  final BodyPartIndex partIndex;
  final double x;
  final double y;
  final double score;

  const BodyPart(
      {@required this.partIndex,
      @required this.x,
      @required this.y,
      @required this.score});

  @override
  String toString() {
    return 'Part: ' +
        partIndex.index.toString() +
        '; position: (' +
        x.toString() +
        ', ' +
        y.toString() +
        '); score: ' +
        score.toString();
  }

  static String indexToString(BodyPartIndex index) {
    switch (index) {
      case BodyPartIndex.nose:
        return 'Nose';
      case BodyPartIndex.neck:
        return 'Neck';
      case BodyPartIndex.shoulderR:
        return 'Right shoulder';
      case BodyPartIndex.elbowR:
        return 'Right elbow';
      case BodyPartIndex.wristR:
        return 'Right hand';
      case BodyPartIndex.shoulderL:
        return 'Left shoulder';
      case BodyPartIndex.elbowL:
        return 'Left elbow';
      case BodyPartIndex.wristL:
        return 'Left hand';
      case BodyPartIndex.hipR:
        return 'Right hip';
      case BodyPartIndex.kneeR:
        return 'Right knee';
      case BodyPartIndex.ankleR:
        return 'Right ankle';
      case BodyPartIndex.hipL:
        return 'Left hip';
      case BodyPartIndex.kneeL:
        return 'Left knee';
      case BodyPartIndex.ankleL:
        return 'Left ankle';
      case BodyPartIndex.eyeR:
         return 'Right eye';
      case BodyPartIndex.eyeL:
        return 'Left eye';
      case BodyPartIndex.earR:
        return 'Right ear';
      case BodyPartIndex.earL:
        return 'Left ear';
      case BodyPartIndex.end:
        return 'Unknown';
    }
    return 'Unknown';
  }
}
