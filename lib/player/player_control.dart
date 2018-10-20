import 'package:flutter/material.dart';

class PlayerControl extends StatefulWidget {
  PlayerControl({
    Key key,
    @required this.playing,
    @required this.position,
    this.onPlayPause,
    this.onStop,
    this.onSeek,
  }) : super(key: key);

  final bool playing;
  final double position;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<double> onSeek;

  @override
  _PlayerControlState createState() => new _PlayerControlState();
}

class _PlayerControlState extends State<PlayerControl> {
  @override
  Widget build(BuildContext context) {
    return new ListTile(
      leading: new IconButton(
          color: Colors.white,
          icon: new Icon(widget.playing ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            try {
              widget.onPlayPause();
            } catch (_) {}
          }),
      title: new ListTile(
        contentPadding: const EdgeInsets.all(0.0),
        leading: new IconButton(
            color: Colors.white,
            icon: new Icon(Icons.stop),
            onPressed: () {
              try {
                widget.onStop();
              } catch (_) {}
            }),
        title: new Slider(
            value: widget.position,
            onChanged: (value) {
              try {
                widget.onSeek(value.clamp(0.0, 1.0));
              } catch (_) {}
            }),
      ),
    );
  }
}
