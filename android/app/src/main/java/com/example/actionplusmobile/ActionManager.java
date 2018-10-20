package com.actionplus.actionplusmobile;

public class ActionManager {
    public interface GlobalCallbacks {
        void onAnalyzeRead();

        void onAnalyzeWrite();

        void onImport();

        void onExport();

        void onStorageRead();

        void onStorageWrite();
    }

    public interface InitCallbacks {
        void onInit();
    }

    public interface ListCallbacks {
        void onList(String[] list);
    }

    public interface InfoCallbacks {
        void onInfo(String title, String scoreAgainst);
    }

    public interface VideoCallbacks {
        void onVideo(String videoFile);
    }

    public interface ThumbnailCallbacks {
        void onThumbnail(String thumbnailFile);
    }

    public interface IsAnalyzedCallbacks {
        void onIsAnalyzed(boolean analyzed);
    }

    public interface GetAnalysisCallbacks {
        void onGetAnalysis(Object[][] humans);
    }

    public interface CurrentAnalysisMetaCallbacks {
        void onCurrentAnalysisMeta(String id, int length, int pos);
    }

    public interface CurrentAnalysisCallbacks {
        void onCurrentAnalysis(String id, int length, Object[][] humans);
    }

    public interface QuickScoreCallbacks {
        void onQuickScore(boolean scored, int mean);
    }

    public interface ScoreCallbacks {
        void onScore(boolean scored, Integer[][] scores, Integer[] partMeans, int mean,
                     Integer[][] missedMoves);
    }

    public interface LiveScoreCallbacks {
        void onLiveScore(boolean scored, Integer[][] scores, Integer[] partMeans, int mean);
    }

    public static native void init(String dir, byte[] graph, int graphHeight, int graphWidth,
                                   GlobalCallbacks callbacks, InitCallbacks initCallbacks);

    public static native void list(ListCallbacks callbacks);

    public static native void info(String id, InfoCallbacks callbacks);

    public static native void video(String id, VideoCallbacks callbacks);

    public static native void thumbnail(String id, ThumbnailCallbacks callbacks);

    public static native void isAnalyzed(String id, IsAnalyzedCallbacks callbacks);

    public static native void getAnalysis(String id, GetAnalysisCallbacks callbacks);

    public static native void currentAnalysisMeta(CurrentAnalysisMetaCallbacks callbacks);

    public static native void currentAnalysis(CurrentAnalysisCallbacks callbacks);

    public static native void quickScore(String sampleId, String standardId,
                                         QuickScoreCallbacks callbacks);

    public static native void score(String sampleId, String standardId, int missedThreshold,
                                    int missedMaxLength, ScoreCallbacks callbacks);

    public static native void liveScore(String sampleId, Object[][] sample, String standardId,
                                        LiveScoreCallbacks callbacks);

    public static native void importAction(String path, String title, String scoreAgainst,
                                           boolean move);

    public static native void exportVideo(String id, String path);

    public static native void update(String id, String title, String scoreAgainst);

    public static native void remove(String id);

    public static native void analyze(String id);

    public static native void cancelOneImport();

    public static native void cancelOneExport();

    public static native void cancelOneAnalyze();

    public static native String[] analyzeReadTasks();

    public static native String[] analyzeWriteTasks();

    public static native String[] importTasks();

    public static native String[] exportTasks();

    public static native String[] storageReadTasks();

    public static native String[] storageWriteTasks();

    static {
        System.loadLibrary("actionplus");
    }
}
