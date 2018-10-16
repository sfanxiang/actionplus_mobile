import 'dart:ui';

class ActionMetadata {
  String title = '';
  String scoreAgainst = '';

  @override
  bool operator ==(other) {
    return runtimeType == other.runtimeType &&
        title == other.title &&
        scoreAgainst == other.scoreAgainst;
  }

  @override
  int get hashCode {
    return hashValues(title, scoreAgainst);
  }
}
