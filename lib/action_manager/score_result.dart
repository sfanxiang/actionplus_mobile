import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

import '../libaction/body_part.dart';

class ScoreResult {
  final bool scored;
  final List<Map<Tuple2<BodyPartIndex, BodyPartIndex>, int>> scores;
  final Map<Tuple2<BodyPartIndex, BodyPartIndex>, int> partMeans;
  final int mean;
  final List<Map<Tuple2<BodyPartIndex, BodyPartIndex>, Tuple2<int, int>>>
      missedMoves;

  ScoreResult(
      {@required this.scored,
      @required this.scores,
      @required this.partMeans,
      @required this.mean,
      @required this.missedMoves});
}
