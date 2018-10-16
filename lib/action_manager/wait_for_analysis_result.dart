import 'package:flutter/foundation.dart';

import '../libaction/human.dart';

class WaitForAnalysisResult {
  final bool running;
  final int length;
  final List<Human> humans;

  WaitForAnalysisResult(
      {@required this.running, @required this.length, @required this.humans});
}
