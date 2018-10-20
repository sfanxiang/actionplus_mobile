import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import 'action_metadata.dart';
import 'current_analysis_meta_result.dart';
import 'current_analysis_result.dart';
import 'live_score_result.dart';
import 'quick_score_result.dart';
import 'score_result.dart';
import '../libaction/body_part.dart';
import '../libaction/human.dart';

// Note: Write tasks finish their Future when the task is created, not when the
// task completes.
class ActionManager {
  static const int graphHeight = 432;
  static const int graphWidth = 240;
  static const String graphAsset = 'graphs/single_pose.tflite';
  static const int readFrameRate = 10;

  static Stream<Null> get analyzeReadStream =>
      _ActionManagerEvents.analyzeReadStream;

  static Stream<Null> get analyzeWriteStream =>
      _ActionManagerEvents.analyzeWriteStream;

  static Stream<Null> get importStream => _ActionManagerEvents.importStream;

  static Stream<Null> get exportStream => _ActionManagerEvents.exportStream;

  static Stream<Null> get storageReadStream =>
      _ActionManagerEvents.storageReadStream;

  static Stream<Null> get storageWriteStream =>
      _ActionManagerEvents.storageWriteStream;

  static const _method =
      const MethodChannel('actionplusmobile/action_manager_method');

  static String _dataPath;

  static String get dataPath => _dataPath;

  static Future<Null> init() async {
    _ActionManagerEvents.init();

    _dataPath = (await getApplicationDocumentsDirectory()).path + '/data';
    ByteData graphData = await rootBundle.load(graphAsset);
    Uint8List graph = graphData.buffer.asUint8List();
    await _method.invokeMethod('init', {
      'dir': _dataPath,
      'graph': graph,
      'graphHeight': graphHeight,
      'graphWidth': graphWidth
    });
    rootBundle.evict(graphAsset);
  }

  static Future<List<String>> list() async {
    return ((await _method.invokeMethod('list')) as List<dynamic>)
        .cast<String>();
  }

  static Future<ActionMetadata> info(String id) async {
    List<dynamic> result = await _method.invokeMethod('info', {'id': id});
    ActionMetadata metadata = new ActionMetadata();
    metadata.title = result[0];
    metadata.scoreAgainst = result[1];
    return metadata;
  }

  static Future<String> video(String id) async {
    return await _method.invokeMethod('video', {'id': id});
  }

  static Future<String> thumbnail(String id) async {
    return await _method.invokeMethod('thumbnail', {'id': id});
  }

  static Future<bool> isAnalyzed(String id) async {
    return await _method.invokeMethod('isAnalyzed', {'id': id});
  }

  static Future<List<Human>> getAnalysis(String id) async {
    List<dynamic> res = await _method.invokeMethod('getAnalysis', {'id': id});
    if (res == null) return null;

    return res.map((item) => _listToHuman(item as List<dynamic>)).toList();
  }

  static Future<CurrentAnalysisMetaResult> currentAnalysisMeta() async {
    List<dynamic> res = await _method.invokeMethod('currentAnalysisMeta');
    if (res == null) return null;

    String id = res[0];
    int length = res[1];
    int pos = res[2];

    return new CurrentAnalysisMetaResult(id: id, length: length, pos: pos);
  }

  static Future<CurrentAnalysisResult> currentAnalysis() async {
    List<dynamic> res = await _method.invokeMethod('currentAnalysis');
    if (res == null) return null;

    String id = res[0];
    int length = res[1];
    List<dynamic> humans = res[2];
    List<Human> humansDecoded =
        humans?.map((item) => _listToHuman(item as List<dynamic>))?.toList();

    return new CurrentAnalysisResult(
        id: id, length: length, humans: humansDecoded);
  }

  static Future<QuickScoreResult> quickScore(
      String sampleId, String standardId) async {
    List data = await _method.invokeMethod(
        'quickScore', {'sampleId': sampleId, 'standardId': standardId});

    bool scored = data[0];
    int mean = data[1];

    return new QuickScoreResult(scored: scored, mean: mean);
  }

  static Future<ScoreResult> score(String sampleId, String standardId,
      int missedThreshold, int missedMaxLength) async {
    List data = await _method.invokeMethod('score', {
      'sampleId': sampleId,
      'standardId': standardId,
      'missedThreshold': missedThreshold,
      'missedMaxLength': missedMaxLength
    });

    bool scored = data[0];
    List<Map<Tuple2<BodyPartIndex, BodyPartIndex>, int>> scores =
        (data[1] as List)?.map((item) => _decodeScore(item))?.toList();
    Map<Tuple2<BodyPartIndex, BodyPartIndex>, int> partMeans =
        _decodeScore(data[2]);
    int mean = data[3];
    List<Map<Tuple2<BodyPartIndex, BodyPartIndex>, Tuple2<int, int>>>
        missedMoves =
        (data[4] as List)?.map((item) => _decodeMissedMove(item))?.toList();

    return new ScoreResult(
        scored: scored,
        scores: scores,
        partMeans: partMeans,
        mean: mean,
        missedMoves: missedMoves);
  }

  static Future<LiveScoreResult> liveScore(
      String sampleId, List<Human> sample, String standardId) async {
    List data = await _method.invokeMethod('liveScore', {
      'sampleId': sampleId,
      'sample': sample.map((item) => _humanToList(item)).toList(),
      'standardId': standardId
    });

    bool scored = data[0];
    List<Map<Tuple2<BodyPartIndex, BodyPartIndex>, int>> scores =
        (data[1] as List)?.map((item) => _decodeScore(item))?.toList();
    Map<Tuple2<BodyPartIndex, BodyPartIndex>, int> partMeans =
        _decodeScore(data[2]);
    int mean = data[3];

    return new LiveScoreResult(
        scored: scored, scores: scores, partMeans: partMeans, mean: mean);
  }

  static Future<Null> importAction(String path, ActionMetadata metadata,
      {bool move = false}) async {
    await _method.invokeMethod('importAction', {
      'path': path,
      'title': metadata.title,
      'scoreAgainst': metadata.scoreAgainst,
      'move': move,
    });
  }

  static Future<Null> exportVideo(String id, String path) async {
    await _method.invokeMethod('exportVideo', {'id': id, 'path': path});
  }

  static Future<Null> update(String id, ActionMetadata metadata) async {
    await _method.invokeMethod('update', {
      'id': id,
      'title': metadata.title,
      'scoreAgainst': metadata.scoreAgainst,
    });
  }

  static Future<Null> remove(String id) async {
    await _method.invokeMethod('remove', {'id': id});
  }

  static Future<Null> analyze(String id) async {
    await _method.invokeMethod('analyze', {'id': id});
  }

  static void cancelOneImport() {
    _method.invokeMethod('cancelOneImport');
  }

  static void cancelOneExport() {
    _method.invokeMethod('cancelOneExport');
  }

  static void cancelOneAnalyze() {
    _method.invokeMethod('cancelOneAnalyze');
  }

  static Future<List<String>> analyzeReadTasks() async {
    return ((await _method.invokeMethod('analyzeReadTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Future<List<String>> analyzeWriteTasks() async {
    return ((await _method.invokeMethod('analyzeWriteTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Future<List<String>> importTasks() async {
    return ((await _method.invokeMethod('importTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Future<List<String>> exportTasks() async {
    return ((await _method.invokeMethod('exportTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Future<List<String>> storageReadTasks() async {
    return ((await _method.invokeMethod('storageReadTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Future<List<String>> storageWriteTasks() async {
    return ((await _method.invokeMethod('storageWriteTasks')) as List<dynamic>)
        .cast<String>();
  }

  static Human _listToHuman(List<dynamic> data) {
    if (data == null) return null;

    return new Human(data.map((item) {
      List<dynamic> part = item;
      return new BodyPart(
          partIndex: BodyPartIndex.values[part[0] as int],
          x: part[1] as double,
          y: part[2] as double,
          score: part[3] as double);
    }));
  }

  static Map<Tuple2<BodyPartIndex, BodyPartIndex>, int> _decodeScore(
      List<dynamic> data) {
    if (data == null) return null;

    List<Int32List> dataCast = data.cast<Int32List>();

    return Map.fromIterables(
        dataCast.map((item) => Tuple2(
            BodyPartIndex.values[item[0]], BodyPartIndex.values[item[1]])),
        dataCast.map((item) => item[2]));
  }

  static Map<Tuple2<BodyPartIndex, BodyPartIndex>, Tuple2<int, int>>
      _decodeMissedMove(List<dynamic> data) {
    if (data == null) return null;

    List<Int32List> dataCast = data.cast<Int32List>();

    return Map.fromIterables(
        dataCast.map((item) => Tuple2(
            BodyPartIndex.values[item[0]], BodyPartIndex.values[item[1]])),
        dataCast.map((item) => Tuple2(item[2], item[3])));
  }

  static List<List<num>> _humanToList(Human human) {
    if (human == null) return null;

    return human.bodyParts.values
        .map((part) => [part.partIndex.index, part.x, part.y, part.score])
        .toList();
  }
}

class _ActionManagerEvents {
  static Stream<Null> analyzeReadStream;
  static Stream<Null> analyzeWriteStream;
  static Stream<Null> importStream;
  static Stream<Null> exportStream;
  static Stream<Null> storageReadStream;
  static Stream<Null> storageWriteStream;

  static const _event =
      const EventChannel('actionplusmobile/action_manager_event');

  static StreamController<Null> _analyzeReadStreamController =
      new StreamController.broadcast();
  static StreamController<Null> _analyzeWriteStreamController =
      new StreamController.broadcast();
  static StreamController<Null> _importStreamController =
      new StreamController.broadcast();
  static StreamController<Null> _exportStreamController =
      new StreamController.broadcast();
  static StreamController<Null> _storageReadStreamController =
      new StreamController.broadcast();
  static StreamController<Null> _storageWriteStreamController =
      new StreamController.broadcast();

  static void init() {
    analyzeReadStream = _analyzeReadStreamController.stream;
    analyzeWriteStream = _analyzeWriteStreamController.stream;
    importStream = _importStreamController.stream;
    exportStream = _exportStreamController.stream;
    storageReadStream = _storageReadStreamController.stream;
    storageWriteStream = _storageWriteStreamController.stream;

    _event.receiveBroadcastStream().listen((event) {
      String eventName = (event as List<dynamic>)[0];

      if (eventName == 'onGlobalAnalyzeRead') {
        _analyzeReadStreamController.add(null);
      } else if (eventName == 'onGlobalAnalyzeWrite') {
        _analyzeWriteStreamController.add(null);
      } else if (eventName == 'onGlobalImport') {
        _importStreamController.add(null);
      } else if (eventName == 'onGlobalExport') {
        _exportStreamController.add(null);
      } else if (eventName == 'onGlobalStorageRead') {
        _storageReadStreamController.add(null);
      } else if (eventName == 'onGlobalStorageWrite') {
        _storageWriteStreamController.add(null);
      }
    });
  }
}
