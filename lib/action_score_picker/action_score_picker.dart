import 'dart:async';

import 'package:flutter/material.dart';

import '../action_manager/action_manager.dart';
import '../action_picker/action_picker.dart';

class ActionScorePicker extends StatefulWidget {
  ActionScorePicker({Key key, @required this.pickForId, this.onPicked})
      : super(key: key);

  final String pickForId;
  final ValueChanged<String> onPicked;

  @override
  _ActionScorePickerState createState() => new _ActionScorePickerState();
}

class _ActionScorePickerState extends State<ActionScorePicker> {
  Set<String> excludeIds = new Set<String>();
  bool excludeIdsInit = false;

  StreamSubscription storageWriteSub;
  StreamSubscription analyzeSub;

  @override
  void initState() {
    super.initState();

    storageWriteSub =
        ActionManager.storageWriteStream.listen((_) => _updateExcludeIds());
    analyzeSub =
        ActionManager.analyzeWriteStream.listen((_) => _updateExcludeIds());

    _updateExcludeIds();
  }

  @override
  void dispose() {
    storageWriteSub?.cancel();
    analyzeSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!excludeIdsInit) {
      return const Center(child: const CircularProgressIndicator());
    } else {
      return new ActionPicker(
        excludeIds: excludeIds.union(Set.from([widget.pickForId])),
        emptyText: 'No video to choose.\nOnly analyzed videos can be used.',
        onPicked: widget.onPicked,
      );
    }
  }

  void _updateExcludeIds() async {
    List<String> list = await ActionManager.list();
    if (!mounted) return;

    excludeIds = excludeIds.intersection(Set.from(list));
    setState(() {});

    for (int i = 0; i < list.length; i++) {
      String id = list[i];

      bool analyzed = await ActionManager.isAnalyzed(id);
      if (!mounted) return;

      if (analyzed) {
        excludeIds.remove(id);
      } else {
        excludeIds.add(id);
      }
      setState(() {});
    }

    excludeIdsInit = true;
    setState(() {});
  }
}
