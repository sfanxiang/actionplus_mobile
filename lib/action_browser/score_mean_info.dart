import 'dart:async';

import 'package:flutter/foundation.dart';

import '../action_manager/action_manager.dart';
import '../reduced_serialized_entrance.dart';

class ScoreMeanInfo {
  final String id;
  ValueChanged<int> callback;

  StreamSubscription<Null> _analyzeWriteSub;
  StreamSubscription<Null> _storageWriteSub;

  ReducedSerializedEntrance _updateCaller;

  ScoreMeanInfo({@required this.id, @required this.callback}) {
    _updateCaller = new ReducedSerializedEntrance(_update);

    _updateCaller.call();
    _analyzeWriteSub =
        ActionManager.analyzeWriteStream.listen((_) => _updateCaller.call());
    _storageWriteSub =
        ActionManager.storageWriteStream.listen((_) => _updateCaller.call());
  }

  void dispose() {
    try {
      _analyzeWriteSub.cancel();
    } catch (e) {}
    try {
      _storageWriteSub.cancel();
    } catch (e) {}
  }

  int _lastScore;

  Future<Null> _update() async {
    int score = await _getScore();
    if (score != _lastScore) {
      _lastScore = score;
      try {
        this.callback(score);
      } catch (e) {}
    }
  }

  Future<int> _getScore() async {
    var info = await ActionManager.info(id);

    if (info.scoreAgainst != '') {
      bool analyzed = ((await ActionManager.isAnalyzed(id)) &&
          (await ActionManager.isAnalyzed(info.scoreAgainst)));
      if (analyzed) return _getCachedScore(info.scoreAgainst);
    }

    return null;
  }

  int _cachedScore;
  String _lastStandardId;

  Future<int> _getCachedScore(String standardId) async {
    if (standardId == _lastStandardId) return _cachedScore;

    var result = await ActionManager.quickScore(id, standardId);
    if (result.scored && result.mean != null) {
      _cachedScore = result.mean;
      _lastStandardId = standardId;
      return result.mean;
    } else {
      return null;
    }
  }
}
