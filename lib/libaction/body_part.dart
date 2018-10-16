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
}
