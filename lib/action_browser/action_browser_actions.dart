import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_manager/action_metadata.dart';
import '../analyze_page/analyze_page.dart';
import '../reduced_serialized_entrance.dart';
import '../score_page/score_page.dart';
import 'score_mean_info.dart';

class ActionBrowserActions extends StatefulWidget {
  ActionBrowserActions({Key key, this.id}) : super(key: key);

  final String id;

  @override
  _ActionBrowserActionsState createState() => new _ActionBrowserActionsState();
}

enum _MoreActions { rename, remove, chooseScore, clearScore }

class _ActionBrowserActionsState extends State<ActionBrowserActions> {
  bool _analyzed;
  bool _analyzing = false;
  double _analyzingProgress = 0.0;
  ActionMetadata _metadata;
  int _score;

  StreamSubscription _analyzeWriteStreamSub;
  StreamSubscription _storageWriteStreamSub;

  ScoreMeanInfo scoreMeanInfo;

  ReducedSerializedEntrance analyzeUpdateCaller;
  ReducedSerializedEntrance storageUpdateCaller;

  @override
  void initState() {
    super.initState();

    scoreMeanInfo = new ScoreMeanInfo(id: widget.id, callback: onScoreChanged);

    analyzeUpdateCaller = new ReducedSerializedEntrance(_onAnalyzeUpdate);
    storageUpdateCaller = new ReducedSerializedEntrance(_onStorageUpdate);

    analyzeUpdateCaller.call();
    storageUpdateCaller.call();

    _analyzeWriteStreamSub = ActionManager.analyzeWriteStream.listen((e) {
      analyzeUpdateCaller.call();
    });
    _storageWriteStreamSub = ActionManager.storageWriteStream.listen((e) {
      storageUpdateCaller.call();
    });
  }

  @override
  void dispose() {
    try {
      scoreMeanInfo.dispose();
    } catch (e) {}
    try {
      _analyzeWriteStreamSub.cancel();
    } catch (e) {}
    try {
      _storageWriteStreamSub.cancel();
    } catch (e) {}

    super.dispose();
  }

  Future<Null> _onAnalyzeUpdate() async {
    bool analyzed = await ActionManager.isAnalyzed(widget.id);
    if (!mounted) return;

    var tasks = await ActionManager.analyzeWriteTasks();
    if (!mounted) return;

    bool analyzing = (tasks.indexOf(widget.id) >= 0);
    double analyzingProgress;

    if (analyzing) {
      var meta = await ActionManager.currentAnalysisMeta();
      if (!mounted) return;

      if (meta.id != widget.id)
        analyzingProgress = 0.0;
      else if (meta.length == 0)
        analyzingProgress = 0.0;
      else
        analyzingProgress = min((meta.pos + 1) / meta.length, 1.0);
    } else {
      analyzingProgress = 0.0;
    }

    if (analyzed != _analyzed ||
        analyzing != _analyzing ||
        analyzingProgress != _analyzingProgress) {
      _analyzed = analyzed;
      _analyzing = analyzing;
      _analyzingProgress = analyzingProgress;

      setState(() {});
    }
  }

  Future<Null> _onStorageUpdate() async {
    var info = await ActionManager.info(widget.id);
    if (!mounted) return;

    if (_metadata != info) {
      _metadata = info;

      setState(() {});
    }
  }

  void onScoreChanged(int score) {
    if (!mounted) return;
    _score = score;
    setState(() {});
  }

  Widget build(BuildContext context) {
    List<Widget> widgets = new List<Widget>();

    if (_analyzed != null) {
      if (!_analyzed) {
        // Not analyzed

        if (_analyzing != null) {
          if (!_analyzing) {
            // Not analyzing

            widgets.add(new RaisedButton(
                onPressed: () {
                  // Analyze

                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) =>
                              new AnalyzePage(id: widget.id)));
                },
                child: new Text('Analyze'.toUpperCase()),
                color: Colors.amberAccent));
          } else {
            // Analyzing

            widgets.add(new Padding(padding: new EdgeInsets.only(right: 2.0)));
            widgets.add(new CircularProgressIndicator(
                value: _analyzingProgress > 0.0 ? _analyzingProgress : null,
                valueColor: new AlwaysStoppedAnimation<Color>(
                    analyzeProgressColor(_analyzingProgress))));
          }
        }
      } else {
        // Analyzed

        if (_score == null) {
          // No score

          if (_metadata != null && _metadata.scoreAgainst == '') {
            // Actually not scored

            widgets.add(new RaisedButton(
                onPressed: () {
                  // Score

                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => new ScorePage(id: widget.id)));
                },
                child: new Text('Score'.toUpperCase()),
                color: new Color(0xff00ddff)));
          } else {
            widgets.add(new IconButton(
                icon: new Icon(Icons.info),
                iconSize: 32.0,
                onPressed: () {
                  showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          title: new Text('Score unavailable'),
                          content: new Text(
                              'Please wait for a few seconds and make sure that the standard video is not removed. Click on the menu button for options to clear the score.'),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text('OK'.toUpperCase()),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                            ),
                          ],
                        );
                      });
                }));
          }
        } else {
          // Score available

          widgets.add(new Container(width: 4.0));
          widgets.add(new Container(
              decoration: new ShapeDecoration(
                  shape: new StadiumBorder(), color: scoreColor(_score)),
              child: new Padding(
                  padding: EdgeInsets.only(
                      left: 12.0, right: 12.0, top: 8.0, bottom: 8.0),
                  child: new Text(scoreToHumanRepresentation(_score),
                      style: new TextStyle(
                          color: Colors.white, fontSize: 18.0)))));
        }
      }
    }

    widgets.add(new Container(width: 4.0));

    widgets.add(new PopupMenuButton<_MoreActions>(
        tooltip: 'More actions',
        onSelected: (_MoreActions result) {
          if (!mounted) return;

          if (result == _MoreActions.rename) {
            TextEditingController titleFieldController =
                new TextEditingController(text: _metadata.title);
            TextField titleField = new TextField(
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                controller: titleFieldController,
                onSubmitted: (value) {
                  _metadata.title = value;
                  ActionManager.update(widget.id, _metadata);
                  Navigator.of(context, rootNavigator: true).pop();
                });

            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return new AlertDialog(
                    title: new Text('Rename'),
                    content: titleField,
                    actions: <Widget>[
                      new FlatButton(
                        child: new Text('Cancel'.toUpperCase()),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                      new FlatButton(
                          child: new Text('Rename'.toUpperCase()),
                          onPressed: () {
                            _metadata.title = titleField.controller.text;
                            ActionManager.update(widget.id, _metadata);
                            Navigator.of(context, rootNavigator: true).pop();
                          })
                    ],
                  );
                });
          } else if (result == _MoreActions.remove) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return new AlertDialog(
                      content: new Text('Remove this video?'),
                      actions: <Widget>[
                        new FlatButton(
                            child: new Text('Cancel'.toUpperCase()),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            }),
                        new FlatButton(
                            child: new Text('Remove'.toUpperCase()),
                            textColor: Colors.red,
                            onPressed: () {
                              ActionManager.remove(widget.id);
                              Navigator.of(context, rootNavigator: true).pop();
                            }),
                      ]);
                });
          } else if (result == _MoreActions.chooseScore) {
            // Score

            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new ScorePage(id: widget.id)));
          } else if (result == _MoreActions.clearScore) {
            if (_metadata != null) {
              _metadata.scoreAgainst = '';
              ActionManager.update(widget.id, _metadata);
            }
          }
        },
        itemBuilder: (context) {
          var entries = <PopupMenuEntry<_MoreActions>>[
            new PopupMenuItem<_MoreActions>(
                value: _MoreActions.rename, child: new Text('Rename')),
            new PopupMenuItem<_MoreActions>(
                value: _MoreActions.remove, child: new Text('Remove')),
          ].toList();
          if (_analyzed != null &&
              !_analyzed &&
              _metadata != null &&
              _metadata.scoreAgainst == '') {
            entries.add(new PopupMenuItem<_MoreActions>(
                value: _MoreActions.chooseScore,
                child: new Text('Choose a scoring video')));
          }
          if (_metadata != null && _metadata.scoreAgainst != '') {
            entries.add(new PopupMenuItem<_MoreActions>(
                value: _MoreActions.clearScore,
                child: new Text('Clear scoring video')));
          }
          return entries;
        }));

    return new SingleChildScrollView(
        scrollDirection: Axis.horizontal, child: new Row(children: widgets));
  }

  Color analyzeProgressColor(double progress) {
    if (progress == null || progress <= 0.0) progress = 0.0;
    if (progress >= 1.0) progress = 1.0;
    progress *= progress;

    return transitionColor(Colors.amberAccent, new Color(0xff00ddff), progress);
  }

  Color scoreColor(int score) {
    if (score < 0) score = 0;
    if (score > 128) score = 128;

    Color c1 = new Color(0xffff7705);
    Color c2 = Colors.cyan;
    Color c3 = Colors.deepPurple;

    if (score < 77) {
      return transitionColor(c1, c2, score / 77.0);
    } else {
      return transitionColor(c2, c3, (score - 77) / (128 - 77).toDouble());
    }
  }

  Color transitionColor(Color from, Color to, double value) {
    Color result = new Color(0);

    result = result
        .withAlpha(from.alpha + ((to.alpha - from.alpha) * value).toInt());

    result = result.withRed(from.red + ((to.red - from.red) * value).toInt());

    result = result
        .withGreen(from.green + ((to.green - from.green) * value).toInt());

    result =
        result.withBlue(from.blue + ((to.blue - from.blue) * value).toInt());

    return result;
  }

  String scoreToHumanRepresentation(int score) {
    if (score < 0) score = 0;
    if (score > 128) score = 128;

    int raw = (score * 1000 / 128.0).truncate();
    String result;
    if (raw % 10 == 0)
      result = (raw ~/ 10).toString();
    else
      result = (raw / 10.0).toStringAsFixed(1);

    return result;
  }
}
