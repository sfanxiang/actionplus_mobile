import 'dart:io';

import 'package:tuple/tuple.dart';

import '../action_manager/action_manager.dart';

class ActionPlayerInitializer {
  static Future<File> initializeVideoFile(String id) async {
    String file = await ActionManager.video(id);

    if (file == '') throw new Exception("Failed to initialize video file");

    return new File(file);
  }

  static Future<Tuple2<File, File>> initializeVideoFile2(
      String id, String standardId) async {
    String sampleFile = await ActionManager.video(id);
    String standardFile = await ActionManager.video(standardId);

    if (sampleFile == '')
      throw new Exception("Failed to initialize video file");

    if (standardFile != '')
      return new Tuple2(new File(sampleFile), new File(standardFile));
    else
      return new Tuple2(new File(sampleFile), null);
  }
}
