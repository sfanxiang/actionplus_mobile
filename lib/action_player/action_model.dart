import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/score_result.dart';
import '../libaction/body_part.dart';
import '../libaction/human.dart';

class ActionModelData {
  final List<Map<BodyPartIndex, Tuple2<double, double>>> standardData;
  final List<bool> highlights;

  ActionModelData({
    @required this.standardData,
    @required this.highlights,
  });
}

class ActionModel {
  final String _id, _standardId;

  ActionModel(this._id, this._standardId);

  Future<ActionModelData> getData() async {
    List<Human> sampleAnalysis = await ActionManager.getAnalysis(_id);
    List<Human> standardAnalysis = await ActionManager.getAnalysis(_standardId);
    ScoreResult scoreResult =
        await ActionManager.score(_id, _standardId, 72, 32);

    if (sampleAnalysis == null ||
        standardAnalysis == null ||
        !scoreResult.scored) {
      return null;
    }

    var whitelist = <BodyPartIndex>[
      BodyPartIndex.nose,
      BodyPartIndex.eyeR,
      BodyPartIndex.eyeL,
      BodyPartIndex.earR,
      BodyPartIndex.earL,
      BodyPartIndex.shoulderR,
      BodyPartIndex.shoulderL,
      BodyPartIndex.hipR,
      BodyPartIndex.hipL,
    ];

    // Calculate scale
    var sampleCornersTotal = <double>[0.0, 0.0, 0.0, 0.0];
    int sampleCornersCount = 0;
    var standardCornersTotal = <double>[0.0, 0.0, 0.0, 0.0];
    int standardCornersCount = 0;

    for (int i = 0; i < scoreResult.scores.length; i++) {
      var sampleCorners = <double>[1.0, 1.0, 0.0, 0.0];
      var standardCorners = <double>[1.0, 1.0, 0.0, 0.0];

      if (sampleAnalysis[i] != null) {
        for (var part in sampleAnalysis[i]
            .bodyParts
            .entries
            .where((e) => whitelist.contains(e.key))) {
          sampleCorners[0] = min(sampleCorners[0], part.value.y);
          sampleCorners[1] = min(sampleCorners[1], part.value.x);
          sampleCorners[2] = max(sampleCorners[2], part.value.y);
          sampleCorners[3] = max(sampleCorners[3], part.value.x);
        }
      }
      if (standardAnalysis[i] != null) {
        for (var part in standardAnalysis[i]
            .bodyParts
            .entries
            .where((e) => whitelist.contains(e.key))) {
          standardCorners[0] = min(standardCorners[0], part.value.y);
          standardCorners[1] = min(standardCorners[1], part.value.x);
          standardCorners[2] = max(standardCorners[2], part.value.y);
          standardCorners[3] = max(standardCorners[3], part.value.x);
        }
      }

      if (sampleCorners[2] > sampleCorners[0] &&
          sampleCorners[3] > sampleCorners[1]) {
        for (int j = 0; j < 4; j++) sampleCornersTotal[j] += sampleCorners[j];
        sampleCornersCount++;
      }
      if (standardCorners[2] > standardCorners[0] &&
          standardCorners[3] > standardCorners[1]) {
        for (int j = 0; j < 4; j++)
          standardCornersTotal[j] += standardCorners[j];
        standardCornersCount++;
      }
    }

    for (int i = 0; i < 4; i++) {
      if (sampleCornersCount > 0) sampleCornersTotal[i] /= sampleCornersCount;
      if (standardCornersCount > 0)
        standardCornersTotal[i] /= standardCornersCount;
    }

    double scaleX, scaleY;

    if (sampleCornersTotal[2] > sampleCornersTotal[0] &&
        standardCornersTotal[2] > standardCornersTotal[0]) {
      double sampleRangeX = sampleCornersTotal[2] - sampleCornersTotal[0];
      double standardRangeX = standardCornersTotal[2] - standardCornersTotal[0];
      scaleX = sampleRangeX / standardRangeX;
    }
    if (sampleCornersTotal[3] > sampleCornersTotal[1] &&
        standardCornersTotal[3] > standardCornersTotal[1]) {
      double sampleRangeY = sampleCornersTotal[3] - sampleCornersTotal[1];
      double standardRangeY = standardCornersTotal[3] - standardCornersTotal[1];
      scaleY = sampleRangeY / standardRangeY;
    }

    if (scaleX == null) scaleX = scaleY;
    if (scaleY == null) scaleY = scaleX;
    if (scaleX == null) scaleX = 1.0;
    if (scaleY == null) scaleY = 1.0;

    // Calculate data
    List<Map<BodyPartIndex, Tuple2<double, double>>> standardData = [];
    List<bool> highlights = scoreResult.scores.map((_) => false).toList();

    for (int i = 0; i < scoreResult.scores.length; i++) {
      standardData.add(new Map<BodyPartIndex, Tuple2<double, double>>());

      if (standardAnalysis[i] == null) continue;

      int count = 0;
      var sampleCenter = <double>[0.0, 0.0];
      var standardCenter = <double>[0.0, 0.0];

      if (sampleAnalysis[i] != null) {
        for (var part in sampleAnalysis[i]
            .bodyParts
            .entries
            .where((e) => whitelist.contains(e.key))) {
          if (standardAnalysis[i].bodyParts.containsKey(part.key)) {
            sampleCenter[0] += part.value.y;
            sampleCenter[1] += part.value.x;
            standardCenter[0] += standardAnalysis[i].bodyParts[part.key].y;
            standardCenter[1] += standardAnalysis[i].bodyParts[part.key].x;
            count++;
          }
        }

        if (count > 0) {
          sampleCenter[0] /= count;
          sampleCenter[1] /= count;
          standardCenter[0] /= count;
          standardCenter[1] /= count;
        }
      }

      for (var part in standardAnalysis[i].bodyParts.entries) {
        double x = part.value.y;
        double y = part.value.x;

        if (count > 0) {
          x = (x - standardCenter[0]) * scaleX + sampleCenter[0];
          y = (y - standardCenter[1]) * scaleY + sampleCenter[1];
        }

        standardData.last[part.key] = new Tuple2<double, double>(x, y);
      }
    }

    for (int i = 0; i < scoreResult.missedMoves.length; i++) {
      for (var move in scoreResult.missedMoves[i].values) {
        for (int j = i + 1 - move.item1; j <= i; j++) {
          highlights[j] = true;
        }
        const int minLength = 9;
        assert(minLength % 2 == 1);
        if (move.item1 < minLength) {
          for (int j =
                  max(i - move.item1 ~/ 2, minLength ~/ 2) - minLength ~/ 2;
              j < (i - move.item1 ~/ 2) + minLength ~/ 2 &&
                  j < highlights.length;
              j++) {
            highlights[j] = true;
          }
        }
      }
    }

    return new ActionModelData(
        standardData: standardData, highlights: highlights);
  }
}
