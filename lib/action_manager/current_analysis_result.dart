import 'package:flutter/foundation.dart';

import '../libaction/human.dart';

class CurrentAnalysisResult {
  final String id;
  final int length;
  final List<Human> humans;

  CurrentAnalysisResult(
      {@required this.id, @required this.length, @required this.humans});
}
