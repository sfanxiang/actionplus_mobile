package com.actionplus.actionplusmobile;

import android.os.Bundle;

import java.util.ArrayList;
import java.util.Arrays;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String ACTION_MANAGER_EVENT_CHANNEL = "actionplusmobile/action_manager_event";
    private static final String ACTION_MANAGER_METHOD_CHANNEL = "actionplusmobile/action_manager_method";

    private EventChannel.EventSink event;

    private void tryCallEvent(String callback, Object result) {
        if (event == null)
            return;
        try {
            event.success(new ArrayList<Object>(Arrays.asList(callback, result)));
        } catch (Throwable e) {
        }
    }

    private ArrayList<ArrayList<ArrayList<Object>>> decodeHumans(Object[][] humans) {
        if (humans == null)
            return null;

        ArrayList<ArrayList<ArrayList<Object>>> decoded = new ArrayList<>();
        for (Object[] human : humans) {
            if (human == null) {
                decoded.add(null);
                continue;
            }
            ArrayList<ArrayList<Object>> humanDecode = new ArrayList<>();
            for (int j = 0; j < human.length; j += 4) {
                ArrayList<Object> bodyPart = new ArrayList<Object>(Arrays.asList(
                        (Integer) human[j],
                        (Double) human[j + 1],
                        (Double) human[j + 2],
                        (Double) human[j + 3]));
                humanDecode.add(bodyPart);
            }
            decoded.add(humanDecode);
        }

        return decoded;
    }

    private ArrayList<int[]> decodeScore(Integer[] score) {
        if (score == null)
            return null;
        ArrayList<int[]> decoded = new ArrayList<>();
        for (int i = 0; i < score.length; i += 3) {
            decoded.add(new int[]{score[i], score[i + 1], score[i + 2]});
        }
        return decoded;
    }

    private ArrayList<int[]> decodeMissedMoveFrame(Integer[] frame) {
        if (frame == null)
            return null;
        ArrayList<int[]> decoded = new ArrayList<>();
        for (int i = 0; i < frame.length; i += 4) {
            decoded.add(new int[]{frame[i], frame[i + 1], frame[i + 2], frame[i + 3]});
        }
        return decoded;
    }

    private ArrayList<ArrayList<int[]>> decodeMissedMoves(Integer[][] moves) {
        if (moves == null)
            return null;
        ArrayList<ArrayList<int[]>> decoded = new ArrayList<>();
        for (Integer[] frame : moves) {
            decoded.add(decodeMissedMoveFrame(frame));
        }
        return decoded;
    }

    private void safeRunOnUiThread(final MethodChannel.Result result, final Runnable runnable) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    runnable.run();
                } catch (Throwable e) {
                    try {
                        result.error(e.toString(), e.getMessage(), "");
                    } catch (Throwable e2) {
                    }
                }
            }
        });
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new EventChannel(getFlutterView(), ACTION_MANAGER_EVENT_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object o, EventChannel.EventSink eventSink) {
                        if (event != null) {
                            event.endOfStream();
                            event = null;
                        }
                        event = eventSink;
                    }

                    @Override
                    public void onCancel(Object o) {
                        event.endOfStream();
                        event = null;
                    }
                }
        );

        new MethodChannel(getFlutterView(), ACTION_MANAGER_METHOD_CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {
                        try {
                            if (call.method.equals("init")) {
                                String dir = call.argument("dir");
                                byte[] graph = call.argument("graph");
                                int graphHeight = call.argument("graphHeight");
                                int graphWidth = call.argument("graphWidth");

                                if (dir == null || graph == null)
                                    throw new NullPointerException();

                                ActionManager.init(dir, graph, graphHeight, graphWidth, new ActionManager.GlobalCallbacks() {
                                    @Override
                                    public void onAnalyzeRead() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalAnalyzeRead", null);
                                            }
                                        });
                                    }

                                    @Override
                                    public void onAnalyzeWrite() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalAnalyzeWrite", null);
                                            }
                                        });
                                    }

                                    @Override
                                    public void onImport() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalImport", null);
                                            }
                                        });
                                    }

                                    @Override
                                    public void onExport() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalExport", null);
                                            }
                                        });
                                    }

                                    @Override
                                    public void onStorageRead() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalStorageRead", null);
                                            }
                                        });
                                    }

                                    @Override
                                    public void onStorageWrite() {
                                        runOnUiThread(new Runnable() {
                                            @Override
                                            public void run() {
                                                tryCallEvent("onGlobalStorageWrite", null);
                                            }
                                        });
                                    }
                                }, new ActionManager.InitCallbacks() {
                                    @Override
                                    public void onInit() {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(null);
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("list")) {
                                ActionManager.list(new ActionManager.ListCallbacks() {
                                    @Override
                                    public void onList(final String[] list) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(new ArrayList<String>(Arrays.asList(list)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("info")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.info(id, new ActionManager.InfoCallbacks() {
                                    @Override
                                    public void onInfo(final String title, final String scoreAgainst) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(new ArrayList<Object>(Arrays.asList(
                                                        title, scoreAgainst)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("video")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.video(id, new ActionManager.VideoCallbacks() {
                                    @Override
                                    public void onVideo(final String videoFile) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(videoFile);
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("thumbnail")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.thumbnail(id, new ActionManager.ThumbnailCallbacks() {
                                    @Override
                                    public void onThumbnail(final String thumbnailFile) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(thumbnailFile);
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("isAnalyzed")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.isAnalyzed(id, new ActionManager.IsAnalyzedCallbacks() {
                                    @Override
                                    public void onIsAnalyzed(final boolean analyzed) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(analyzed);
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("getAnalysis")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.getAnalysis(id, new ActionManager.GetAnalysisCallbacks() {
                                    @Override
                                    public void onGetAnalysis(final Object[][] humans) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                ArrayList<ArrayList<ArrayList<Object>>> humansDecode
                                                        = decodeHumans(humans);
                                                result.success(humansDecode);
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("currentAnalysisMeta")) {
                                ActionManager.currentAnalysisMeta(new ActionManager.CurrentAnalysisMetaCallbacks() {
                                    @Override
                                    public void onCurrentAnalysisMeta(final String id, final int length, final int pos) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(new ArrayList<Object>(
                                                        Arrays.asList(id, length, pos)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("currentAnalysis")) {
                                ActionManager.currentAnalysis(new ActionManager.CurrentAnalysisCallbacks() {
                                    @Override
                                    public void onCurrentAnalysis(final String id, final int length, final Object[][] humans) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                ArrayList<ArrayList<ArrayList<Object>>> humansDecode
                                                        = decodeHumans(humans);
                                                result.success(new ArrayList<Object>(
                                                        Arrays.asList(id, length, humansDecode)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("quickScore")) {
                                String sampleId = call.argument("sampleId");
                                String standardId = call.argument("standardId");

                                if (sampleId == null || standardId == null)
                                    throw new NullPointerException();

                                ActionManager.quickScore(sampleId, standardId, new ActionManager.QuickScoreCallbacks() {
                                    @Override
                                    public void onQuickScore(final boolean scored, final int mean) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                result.success(new ArrayList<Object>(Arrays.asList(
                                                        scored, mean)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("score")) {
                                String sampleId = call.argument("sampleId");
                                String standardId = call.argument("standardId");
                                int missedThreshold = call.argument("missedThreshold");
                                int missedMaxLength = call.argument("missedMaxLength");

                                if (sampleId == null || standardId == null)
                                    throw new NullPointerException();

                                ActionManager.score(sampleId, standardId, missedThreshold, missedMaxLength, new ActionManager.ScoreCallbacks() {
                                    @Override
                                    public void onScore(final boolean scored, final Integer[][] scores,
                                                        final Integer[] partMeans, final int mean,
                                                        final Integer[][] missedMoves) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                ArrayList<ArrayList<int[]>> scoresDecoded = null;
                                                if (scores != null) {
                                                    scoresDecoded = new ArrayList<>();
                                                    for (Integer[] score : scores) {
                                                        scoresDecoded.add(decodeScore(score));
                                                    }
                                                }
                                                ArrayList<int[]> partMeansDecoded = decodeScore(partMeans);
                                                ArrayList<ArrayList<int[]>> missedMovesDecoded =
                                                        decodeMissedMoves(missedMoves);
                                                result.success(new ArrayList<Object>(Arrays.asList(
                                                        scored, scoresDecoded, partMeansDecoded, mean,
                                                        missedMovesDecoded)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("liveScore")) {
                                String sampleId = call.argument("sampleId");

                                if (sampleId == null)
                                    throw new NullPointerException();

                                ArrayList<ArrayList<ArrayList<Object>>> sample = call.argument("sample");
                                if (sample == null) {
                                    result.error("sample == null", "sample == null", "");
                                    return;
                                }
                                Object[][] sampleDecoded = new Object[sample.size()][];
                                for (int i = 0; i < sample.size(); i++) {
                                    ArrayList<ArrayList<Object>> frame = sample.get(i);
                                    if (frame == null) {
                                        sampleDecoded[i] = null;
                                    } else {
                                        Object[] frameDecoded = new Object[frame.size() * 4];
                                        for (int j = 0; j < frame.size(); j++) {
                                            ArrayList<Object> bodyPart = frame.get(j);
                                            if (bodyPart == null) {
                                                result.error("bodyPart == null", "bodyPart == null", "");
                                                return;
                                            }
                                            frameDecoded[j * 4] = bodyPart.get(0);
                                            frameDecoded[j * 4 + 1] = bodyPart.get(1);
                                            frameDecoded[j * 4 + 2] = bodyPart.get(2);
                                            frameDecoded[j * 4 + 3] = bodyPart.get(3);
                                            if (frameDecoded[j * 4] == null || frameDecoded[j * 4 + 1] == null ||
                                                    frameDecoded[j * 4 + 2] == null || frameDecoded[j * 4 + 3] == null) {
                                                result.error("frameDecoded[] has null", "frameDecoded[] has null", "");
                                                return;
                                            }
                                        }
                                        sampleDecoded[i] = frameDecoded;
                                    }
                                }

                                String standardId = call.argument("standardId");

                                if (standardId == null)
                                    throw new NullPointerException();

                                ActionManager.liveScore(sampleId, sampleDecoded, standardId, new ActionManager.LiveScoreCallbacks() {
                                    @Override
                                    public void onLiveScore(final boolean scored, final Integer[][] scores, final Integer[] partMeans, final int mean) {
                                        safeRunOnUiThread(result, new Runnable() {
                                            @Override
                                            public void run() {
                                                ArrayList<ArrayList<int[]>> scoresDecoded = null;
                                                if (scores != null) {
                                                    scoresDecoded = new ArrayList<>();
                                                    for (Integer[] score : scores) {
                                                        scoresDecoded.add(decodeScore(score));
                                                    }
                                                }
                                                ArrayList<int[]> partMeansDecoded = decodeScore(partMeans);
                                                result.success(new ArrayList<Object>(Arrays.asList(
                                                        scored, scoresDecoded, partMeansDecoded, mean)));
                                            }
                                        });
                                    }
                                });
                            } else if (call.method.equals("importAction")) {
                                String path = call.argument("path");
                                String title = call.argument("title");
                                String scoreAgainst = call.argument("scoreAgainst");
                                boolean move = call.argument("move");

                                if (path == null || title == null)
                                    throw new NullPointerException();

                                ActionManager.importAction(path, title, scoreAgainst, move);

                                result.success(null);
                            } else if (call.method.equals("exportVideo")) {
                                String id = call.argument("id");
                                String path = call.argument("path");

                                if (id == null || path == null)
                                    throw new NullPointerException();

                                ActionManager.exportVideo(id, path);

                                result.success(null);
                            } else if (call.method.equals("update")) {
                                String id = call.argument("id");
                                String title = call.argument("title");
                                String scoreAgainst = call.argument("scoreAgainst");

                                if (id == null || title == null)
                                    throw new NullPointerException();

                                ActionManager.update(id, title, scoreAgainst);

                                result.success(null);
                            } else if (call.method.equals("remove")) {
                                String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.remove(id);

                                result.success(null);
                            } else if (call.method.equals("analyze")) {
                                final String id = call.argument("id");

                                if (id == null)
                                    throw new NullPointerException();

                                ActionManager.analyze(id);

                                result.success(null);
                            } else if (call.method.equals("cancelOneImport")) {
                                ActionManager.cancelOneImport();

                                result.success(null);
                            } else if (call.method.equals("cancelOneExport")) {
                                ActionManager.cancelOneExport();

                                result.success(null);
                            } else if (call.method.equals("cancelOneAnalyze")) {
                                ActionManager.cancelOneAnalyze();

                                result.success(null);
                            } else if (call.method.equals("analyzeReadTasks")) {
                                String[] res = ActionManager.analyzeReadTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else if (call.method.equals("analyzeWriteTasks")) {
                                String[] res = ActionManager.analyzeWriteTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else if (call.method.equals("importTasks")) {
                                String[] res = ActionManager.importTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else if (call.method.equals("exportTasks")) {
                                String[] res = ActionManager.exportTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else if (call.method.equals("storageReadTasks")) {
                                String[] res = ActionManager.storageReadTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else if (call.method.equals("storageWriteTasks")) {
                                String[] res = ActionManager.storageWriteTasks();

                                result.success(new ArrayList<String>(Arrays.asList(res)));
                            } else {
                                result.notImplemented();
                            }
                        } catch (Throwable e) {
                            try {
                                result.error(e.toString(), e.getMessage(), "");
                            } catch (Throwable e2) {
                            }
                        }
                    }
                });
    }
}
