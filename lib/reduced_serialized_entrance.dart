import 'dart:async';

class ReducedSerializedEntrance {
  final Future<Null> Function() _callback;

  bool _running = false, _continue = false;

  ReducedSerializedEntrance(Future<Null> Function() callback)
      : _callback = callback;

  void call() {
    _continue = true;
    if (!_running) _doCallback();
  }

  void _doCallback() async {
    _running = true;

    while (_continue) {
      _continue = false;

      try {
        await _callback();
      } catch (e) {}
    }

    _running = false;
  }
}
