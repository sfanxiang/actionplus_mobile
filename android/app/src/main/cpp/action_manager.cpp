#include <cmath>
#include <cstdlib>

namespace std
{
    // fix broken Android stuff
    using ::copysign;
    using ::_Exit;
}

#include <actionplus_lib/action_init.hpp>
#include <actionplus_lib/action_manager.hpp>
#include <actionplus_lib/action_metadata.hpp>
#include <cstddef>
#include <cstdint>
#include <jni.h>
#include <libaction/body_part.hpp>
#include <libaction/human.hpp>
#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>

// Kept for the lifetime of the process:
JavaVM *jvm{};
std::mutex action_manager_callbacks_mtx{};

// Replaced after each initialization:
jobject action_manager_callbacks{};
jmethodID analyze_read_callback{};
jmethodID analyze_write_callback{};
jmethodID import_callback{};
jmethodID export_callback{};
jmethodID storage_read_callback{};
jmethodID storage_write_callback{};

// Kept for the lifetime of the process:
std::unique_ptr<actionplus_lib::ActionManager> action_manager{};

void java_throw(JNIEnv *env, const char *klass, const char *message)
{
    jclass cls = env->FindClass(klass);
    if (cls)
        env->ThrowNew(cls, message);
}

static void action_manager_task_callback(const jmethodID &method)
{
    JNIEnv* env{};
    if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
        return;

    {
        std::lock_guard<std::mutex> lk(action_manager_callbacks_mtx);
        if (action_manager_callbacks)
            env->CallVoidMethod(action_manager_callbacks, method);
    }

    jvm->DetachCurrentThread();
}

static jobjectArray string_list_to_jobject(JNIEnv *env, const std::list<std::string> &list)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(list.size(), env->FindClass("java/lang/String"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get String class");
    }
    std::size_t i = 0;
    for (auto &item: list) {
        if (env->PushLocalFrame(32) != 0)
            throw std::runtime_error("PushLocalFrame failed");
        env->SetObjectArrayElement(arr, i++, env->NewStringUTF(item.c_str()));
        env->PopLocalFrame(nullptr);
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static jobject get_integer_jobject(JNIEnv *env, int value)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jclass klass = env->FindClass("java/lang/Integer");
    if (!klass) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Integer class");
    }
    jmethodID method = env->GetMethodID(klass, "<init>", "(I)V");
    if (!method) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Integer constructor");
    }
    jobject obj = env->NewObject(klass, method, value);
    if (!obj) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Integer object");
    }

    return env->PopLocalFrame(obj);
}

static int get_jobject_int(JNIEnv *env, jobject object)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jclass klass = env->FindClass("java/lang/Integer");
    if (!klass) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Integer class");
    }
    jmethodID method = env->GetMethodID(klass, "intValue", "()I");
    if (!method) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get intValue method");
    }

    int res = env->CallIntMethod(object, method);
    env->PopLocalFrame(nullptr);

    return res;
}

static jobject get_double_jobject(JNIEnv *env, float value)
{
    // Flutter only supports Double

    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jclass klass = env->FindClass("java/lang/Double");
    if (!klass) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Double class");
    }
    jmethodID method = env->GetMethodID(klass, "<init>", "(D)V");
    if (!method) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Double constructor");
    }
    jobject obj = env->NewObject(klass, method, static_cast<double>(value));
    if (!obj) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Double object");
    }

    return env->PopLocalFrame(obj);
}

static float get_jobject_float(JNIEnv *env, jobject object)
{
    // Flutter only supports Double

    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jclass klass = env->FindClass("java/lang/Double");
    if (!klass) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get Double class");
    }
    jmethodID method = env->GetMethodID(klass, "doubleValue", "()I");
    if (!method) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("Failed to get doubleValue method");
    }

    float res = env->CallDoubleMethod(object, method);
    env->PopLocalFrame(nullptr);

    return res;
}

static std::list<std::tuple<int, float, float, float>> human_to_list(const libaction::Human &human)
{
    std::list<std::tuple<int, float, float, float>> result;
    for (auto &part: human.body_parts()) {
        result.push_back(std::make_tuple(static_cast<int>(part.first),
            part.second.x(), part.second.y(), part.second.score()));
    }
    return result;
}

static jobjectArray human_to_jarray(JNIEnv *env, const libaction::Human &human)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    auto list = human_to_list(human);
    jobjectArray arr = env->NewObjectArray(list.size() * 4, env->FindClass("java/lang/Object"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: list) {
        if (env->PushLocalFrame(32) != 0) {
            env->PopLocalFrame(nullptr);
            throw std::runtime_error("PushLocalFrame failed");
        }

        jobject a0{}, a1{}, a2{}, a3{};
        try {
            a0 = get_integer_jobject(env, std::get<0>(item));
            a1 = get_double_jobject(env, std::get<1>(item));
            a2 = get_double_jobject(env, std::get<2>(item));
            a3 = get_double_jobject(env, std::get<3>(item));
        } catch (...) {}
        env->SetObjectArrayElement(arr, i++, a0);
        env->SetObjectArrayElement(arr, i++, a1);
        env->SetObjectArrayElement(arr, i++, a2);
        env->SetObjectArrayElement(arr, i++, a3);

        env->PopLocalFrame(nullptr);
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static jobjectArray human_list_to_jarray(JNIEnv *env, const std::list<std::unique_ptr<libaction::Human>> &list)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(list.size(), env->FindClass("[Ljava/lang/Object;"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: list) {
        if (item) {
            try {
                if (env->PushLocalFrame(32) != 0)
                    throw std::runtime_error("PushLocalFrame failed");

                jobjectArray human = human_to_jarray(env, *item);
                env->SetObjectArrayElement(arr, i, human);

                env->PopLocalFrame(nullptr);
            } catch (...) {}
        }
        i++;
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static std::unique_ptr<libaction::Human> jarray_to_human(JNIEnv *env, jobjectArray array)
{
    auto human = std::unique_ptr<libaction::Human>(new libaction::Human(
        std::vector<libaction::BodyPart>()));

    auto size = env->GetArrayLength(array);
    for (std::size_t i = 0; i < static_cast<std::size_t>(size); i += 4) {
        jobject o0 = env->GetObjectArrayElement(array, i);
        jobject o1 = env->GetObjectArrayElement(array, i + 1);
        jobject o2 = env->GetObjectArrayElement(array, i + 2);
        jobject o3 = env->GetObjectArrayElement(array, i + 3);

        try {
            int index = get_jobject_int(env, o0);
            if (index > static_cast<int>(libaction::BodyPart::PartIndex::end) || index < 0)
                index = 0;
            libaction::BodyPart::PartIndex part_index = static_cast<libaction::BodyPart::PartIndex>(
                index);
            float x = get_jobject_float(env, o1);
            float y = get_jobject_float(env, o2);
            float score = get_jobject_float(env, o3);
            human->body_parts()[part_index] = libaction::BodyPart(part_index, x, y, score);
        } catch (...) {
            env->DeleteLocalRef(o0);
            env->DeleteLocalRef(o1);
            env->DeleteLocalRef(o2);
            env->DeleteLocalRef(o3);
            throw;
        }
        env->DeleteLocalRef(o0);
        env->DeleteLocalRef(o1);
        env->DeleteLocalRef(o2);
        env->DeleteLocalRef(o3);
    }

    return human;
}

static std::unique_ptr<std::list<std::unique_ptr<libaction::Human>>> jarray_to_human_list(
    JNIEnv *env, jobjectArray array)
{
    auto list = std::unique_ptr<std::list<std::unique_ptr<libaction::Human>>>(
        new std::list<std::unique_ptr<libaction::Human>>());

    auto size = env->GetArrayLength(array);
    for (std::size_t i = 0; i < static_cast<std::size_t>(size); i++) {
        jobject obj = env->GetObjectArrayElement(array, i);
        try {
            if (!obj) {
                list->push_back(nullptr);
            } else {
                list->push_back(jarray_to_human(env, static_cast<jobjectArray>(static_cast<void*>(obj))));
            }
        } catch (...) {
            env->DeleteLocalRef(obj);
            throw;
        }
        env->DeleteLocalRef(obj);
    }

    return list;
}

static jobjectArray score_to_jarray(JNIEnv *env,
                                    const std::map<std::pair<libaction::BodyPart::PartIndex,
                                        libaction::BodyPart::PartIndex>, std::uint8_t> &score)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(score.size() * 3, env->FindClass("java/lang/Integer"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: score) {
        jobject a0{}, a1{}, a2{};
        try {
            a0 = get_integer_jobject(env, static_cast<int>(item.first.first));
            a1 = get_integer_jobject(env, static_cast<int>(item.first.second));
            a2 = get_integer_jobject(env, item.second);
        } catch (...) {}
        env->SetObjectArrayElement(arr, i++, a0);
        env->SetObjectArrayElement(arr, i++, a1);
        env->SetObjectArrayElement(arr, i++, a2);

        if (a0)
            env->DeleteLocalRef(a0);
        if (a1)
            env->DeleteLocalRef(a1);
        if (a2)
            env->DeleteLocalRef(a2);
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static jobjectArray score_list_to_jarray(JNIEnv *env,
                                         const std::list<std::map<std::pair<libaction::BodyPart::PartIndex,
                                             libaction::BodyPart::PartIndex>, std::uint8_t>> &list)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(list.size(), env->FindClass("[Ljava/lang/Integer;"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: list) {
        try {
            jobjectArray score = score_to_jarray(env, item);
            env->SetObjectArrayElement(arr, i, score);

            env->DeleteLocalRef(score);
        } catch (...) {}
        i++;
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static jobjectArray missed_move_frame_to_jarray(JNIEnv *env,
                                                const std::map<std::pair<
                                                     libaction::BodyPart::PartIndex, libaction::BodyPart::PartIndex>,
                                                         std::pair<std::uint32_t, std::uint8_t>> &frame)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(frame.size() * 4, env->FindClass("java/lang/Integer"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: frame) {
        jobject a0{}, a1{}, a2{}, a3{};
        try {
            a0 = get_integer_jobject(env, static_cast<int>(item.first.first));
            a1 = get_integer_jobject(env, static_cast<int>(item.first.second));
            a2 = get_integer_jobject(env, item.second.first);
            a3 = get_integer_jobject(env, item.second.second);
        } catch (...) {}
        env->SetObjectArrayElement(arr, i++, a0);
        env->SetObjectArrayElement(arr, i++, a1);
        env->SetObjectArrayElement(arr, i++, a2);
        env->SetObjectArrayElement(arr, i++, a3);

        if (a0)
            env->DeleteLocalRef(a0);
        if (a1)
            env->DeleteLocalRef(a1);
        if (a2)
            env->DeleteLocalRef(a2);
        if (a3)
            env->DeleteLocalRef(a3);
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

static jobjectArray missed_moves_to_jarray(JNIEnv *env,
                                           const std::list<std::map<std::pair<
                                               libaction::BodyPart::PartIndex, libaction::BodyPart::PartIndex>,
                                                   std::pair<std::uint32_t, std::uint8_t>>> &moves)
{
    if (env->PushLocalFrame(32) != 0)
        throw std::runtime_error("PushLocalFrame failed");

    jobjectArray arr = env->NewObjectArray(moves.size(), env->FindClass("[Ljava/lang/Integer;"),
        nullptr);
    if (!arr) {
        env->PopLocalFrame(nullptr);
        throw std::runtime_error("failed to create object array");
    }
    std::size_t i = 0;
    for (auto &item: moves) {
        try {
            jobjectArray frame = missed_move_frame_to_jarray(env, item);
            env->SetObjectArrayElement(arr, i, frame);

            env->DeleteLocalRef(frame);
        } catch (...) {}
        i++;
    }

    return static_cast<jobjectArray>(static_cast<void*>(env->PopLocalFrame(arr)));
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_init(JNIEnv* env, jobject,
                                                        jstring dir,
                                                        jbyteArray graph,
                                                        jint graphHeight,
                                                        jint graphWidth,
                                                        jobject callbacks,
                                                        jobject initCallback)
{
    if (!jvm) {
        if (env->GetJavaVM(&jvm) < 0) {
            jvm = nullptr;
            java_throw(env, "java/lang/Exception", "Failed to get JVM");
            return;
        }
    }

    try {
        std::lock_guard<std::mutex> lk(action_manager_callbacks_mtx);

        if (action_manager_callbacks) {
            env->DeleteGlobalRef(action_manager_callbacks);
            action_manager_callbacks = nullptr;
        }

        action_manager_callbacks = env->NewGlobalRef(callbacks);
        if (!action_manager_callbacks)
            throw std::runtime_error("Failed to obtain global ref");

        jclass klass = env->GetObjectClass(action_manager_callbacks);
        analyze_read_callback = env->GetMethodID(klass, "onAnalyzeRead", "()V");
        analyze_write_callback = env->GetMethodID(klass, "onAnalyzeWrite", "()V");
        import_callback = env->GetMethodID(klass, "onImport", "()V");
        export_callback = env->GetMethodID(klass, "onExport", "()V");
        storage_read_callback = env->GetMethodID(klass, "onStorageRead", "()V");
        storage_write_callback = env->GetMethodID(klass, "onStorageWrite", "()V");
        if (!(analyze_read_callback && analyze_write_callback && import_callback &&
                export_callback && storage_read_callback && storage_write_callback)) {
            env->DeleteGlobalRef(action_manager_callbacks);
            action_manager_callbacks = nullptr;
            analyze_read_callback = analyze_write_callback = import_callback =
                export_callback = storage_read_callback = storage_write_callback = nullptr;
            throw std::runtime_error("Failed to get methods");
        }
    } catch (std::exception &e) {
        java_throw(env, "java/lang/Exception", e.what());
        return;
    } catch (...) {
        java_throw(env, "java/lang/Exception", "Unknown exception");
        return;
    }

    jobject init_callback_ref = env->NewGlobalRef(initCallback);
    if (!init_callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass init_klass = env->GetObjectClass(init_callback_ref);
    jmethodID init_method = env->GetMethodID(init_klass, "onInit", "()V");

    if (action_manager) {
        env->CallVoidMethod(init_callback_ref, init_method);
        env->DeleteGlobalRef(init_callback_ref);
        return;
    }

    const char* dir_c_str = env->GetStringUTFChars(dir, nullptr);
    if (!dir_c_str) {
        java_throw(env, "java/lang/Exception", "Failed to get dir string");
        return;
    }

    jbyte* buffer_byte = env->GetByteArrayElements(graph, nullptr);
    if (!buffer_byte) {
        env->ReleaseStringUTFChars(dir, dir_c_str);
        java_throw(env, "java/lang/Exception", "Failed to get buffer");
        return;
    }
    size_t buffer_size = env->GetArrayLength(graph);

    try {
        std::string dir_str(dir_c_str);
        env->ReleaseStringUTFChars(dir, dir_c_str);

        auto buffer = new std::vector<std::uint8_t>();
        buffer->resize(buffer_size);
        std::copy(buffer_byte, buffer_byte + buffer_size, buffer->data());
        env->ReleaseByteArrayElements(graph, buffer_byte, JNI_ABORT);

        actionplus_lib::action_init::action_init(dir_str, [dir_str, buffer, graphHeight, graphWidth,
                init_callback_ref, init_method] {
            JNIEnv* env{};
            if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
                return;

            try {
                std::unique_ptr<std::vector<std::uint8_t>> buffer_ptr(buffer);

                using task_cb = std::function<void()>;

                task_cb analyze_read_cb =
                    std::bind(action_manager_task_callback, std::cref(analyze_read_callback));
                task_cb analyze_write_cb =
                    std::bind(action_manager_task_callback, std::cref(analyze_write_callback));
                task_cb import_cb =
                    std::bind(action_manager_task_callback, std::cref(import_callback));
                task_cb export_cb =
                    std::bind(action_manager_task_callback, std::cref(export_callback));
                task_cb storage_read_cb =
                    std::bind(action_manager_task_callback, std::cref(storage_read_callback));
                task_cb storage_write_cb =
                    std::bind(action_manager_task_callback, std::cref(storage_write_callback));

                action_manager.reset(new actionplus_lib::ActionManager(dir_str, std::move(buffer_ptr),
                    graphHeight, graphWidth,
                    analyze_read_cb, analyze_write_cb, import_cb, export_cb,
                    storage_read_cb, storage_write_cb));
            } catch (...) {}

            env->CallVoidMethod(init_callback_ref, init_method);
            env->DeleteGlobalRef(init_callback_ref);
            jvm->DetachCurrentThread();
        });
    } catch (std::exception &e) {
        java_throw(env, "java/lang/Exception", e.what());
    } catch (...) {
        java_throw(env, "java/lang/Exception", "Unknown exception");
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_list(JNIEnv* env, jobject,
                                                        jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onList", "([Ljava/lang/String;)V");
    action_manager->list([callback_ref, method] (const std::list<std::string> &list) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        jobjectArray arr = env->NewObjectArray(list.size(), env->FindClass("java/lang/String"),
            nullptr);
        if (!arr) {
            env->DeleteGlobalRef(callback_ref);
            return;
        }
        std::size_t i = 0;
        for (auto &item: list)
            env->SetObjectArrayElement(arr, i++, env->NewStringUTF(item.c_str()));
        env->CallVoidMethod(callback_ref, method, arr);
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_info(JNIEnv* env, jobject,
                                                        jstring id,
                                                        jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    // NOTE: ActionMetadata format below:
    jmethodID method = env->GetMethodID(klass, "onInfo", "(Ljava/lang/String;Ljava/lang/String;)V");
    action_manager->info(id_string, [callback_ref, method]
            (const actionplus_lib::ActionMetadata &metadata) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        env->CallVoidMethod(callback_ref, method, env->NewStringUTF(metadata.title.c_str()),
            env->NewStringUTF(metadata.score_against.c_str()));
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_video(JNIEnv* env, jobject,
                                                         jstring id,
                                                         jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onVideo", "(Ljava/lang/String;)V");
    action_manager->video(id_string, [callback_ref, method] (const std::string &video_file) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        env->CallVoidMethod(callback_ref, method, env->NewStringUTF(video_file.c_str()));
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_thumbnail(JNIEnv* env, jobject,
                                                             jstring id,
                                                             jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onThumbnail", "(Ljava/lang/String;)V");
    action_manager->thumbnail(id_string, [callback_ref, method] (const std::string &thumbnail_file) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        env->CallVoidMethod(callback_ref, method, env->NewStringUTF(thumbnail_file.c_str()));
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_isAnalyzed(JNIEnv* env, jobject,
                                                              jstring id,
                                                              jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onIsAnalyzed", "(Z)V");
    action_manager->is_analyzed(id_string, [callback_ref, method] (bool analyzed) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        env->CallVoidMethod(callback_ref, method, static_cast<jboolean>(analyzed));
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_getAnalysis(JNIEnv* env, jobject,
                                                               jstring id,
                                                               jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onGetAnalysis", "([[Ljava/lang/Object;)V");
    action_manager->get_analysis(id_string, [callback_ref, method]
            (std::unique_ptr<std::list<std::unique_ptr<libaction::Human>>> humans) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        try {
            jobjectArray arr = humans ? human_list_to_jarray(env, *humans) : nullptr;
            env->CallVoidMethod(callback_ref, method, arr);
        } catch (...) {}
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_currentAnalysisMeta(JNIEnv* env, jobject,
                                                                       jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onCurrentAnalysisMeta", "(Ljava/lang/String;II)V");
    action_manager->current_analysis_meta([callback_ref, method]
            (const std::string &id, std::size_t length, std::size_t pos) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;

        env->CallVoidMethod(callback_ref, method, env->NewStringUTF(id.c_str()),
            static_cast<jint>(length), static_cast<jint>(pos));

        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_waitForAnalysis(JNIEnv* env, jobject,
                                                                   jstring id,
                                                                   jint pos,
                                                                   jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onWaitForAnalysis", "(ZI[[Ljava/lang/Object;)V");
    action_manager->wait_for_analysis(id_string, pos, [callback_ref, method]
            (bool running, std::size_t length,
                std::unique_ptr<std::list<std::unique_ptr<libaction::Human>>> humans) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        try {
            jobjectArray arr = humans ? human_list_to_jarray(env, *humans) : nullptr;
            env->CallVoidMethod(callback_ref, method, static_cast<jboolean>(running),
                static_cast<jint>(length), arr);
        } catch (...) {}
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_quickScore(JNIEnv* env, jobject,
                                                              jstring sampleId,
                                                              jstring standardId,
                                                              jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* sample_id_tmp = env->GetStringUTFChars(sampleId, nullptr);
    std::string sample_id_string(sample_id_tmp);
    env->ReleaseStringUTFChars(sampleId, sample_id_tmp);
    const char* standard_id_tmp = env->GetStringUTFChars(standardId, nullptr);
    std::string standard_id_string(standard_id_tmp);
    env->ReleaseStringUTFChars(standardId, standard_id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onQuickScore", "(ZI)V");
    action_manager->quick_score(sample_id_string, standard_id_string,
            [callback_ref, method] (bool scored, std::uint8_t mean) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        try {
            env->CallVoidMethod(callback_ref, method, static_cast<jboolean>(scored),
                static_cast<jint>(mean));
        } catch (...) {}
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_score(JNIEnv* env, jobject,
                                                         jstring sampleId,
                                                         jstring standardId,
                                                         jint missedThreshold,
                                                         jint missedMaxLength,
                                                         jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* sample_id_tmp = env->GetStringUTFChars(sampleId, nullptr);
    std::string sample_id_string(sample_id_tmp);
    env->ReleaseStringUTFChars(sampleId, sample_id_tmp);
    const char* standard_id_tmp = env->GetStringUTFChars(standardId, nullptr);
    std::string standard_id_string(standard_id_tmp);
    env->ReleaseStringUTFChars(standardId, standard_id_tmp);

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onScore",
        "(Z[[Ljava/lang/Integer;[Ljava/lang/Integer;I[[Ljava/lang/Integer;)V");
    action_manager->score(sample_id_string, standard_id_string, missedThreshold, missedMaxLength,
            [callback_ref, method] (
                bool scored,
                std::unique_ptr<std::list<std::map<std::pair<libaction::BodyPart::PartIndex,
                    libaction::BodyPart::PartIndex>, std::uint8_t>>> scores,
                std::unique_ptr<std::map<std::pair<libaction::BodyPart::PartIndex,
                    libaction::BodyPart::PartIndex>, std::uint8_t>> part_means,
                std::uint8_t mean,
                std::unique_ptr<std::list<std::map<std::pair<
                    libaction::BodyPart::PartIndex, libaction::BodyPart::PartIndex>,
                        std::pair<std::uint32_t, std::uint8_t>>>> missed_moves) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        try {
            jobjectArray scores_arr = scores ? score_list_to_jarray(env, *scores) : nullptr;
            jobjectArray part_means_arr = part_means ? score_to_jarray(env, *part_means) : nullptr;
            jobjectArray missed_moves_arr = missed_moves ?
                missed_moves_to_jarray(env, *missed_moves) : nullptr;
            env->CallVoidMethod(callback_ref, method,
                static_cast<jboolean>(scored), scores_arr, part_means_arr, static_cast<jint>(mean),
                missed_moves_arr);
        } catch (...) {}
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_liveScore(JNIEnv* env, jobject,
                                                             jstring sampleId,
                                                             jobjectArray sample,
                                                             jstring standardId,
                                                             jobject callback)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* sample_id_tmp = env->GetStringUTFChars(sampleId, nullptr);
    std::string sample_id_string(sample_id_tmp);
    env->ReleaseStringUTFChars(sampleId, sample_id_tmp);
    const char* standard_id_tmp = env->GetStringUTFChars(standardId, nullptr);
    std::string standard_id_string(standard_id_tmp);
    env->ReleaseStringUTFChars(standardId, standard_id_tmp);

    std::unique_ptr<std::list<std::unique_ptr<libaction::Human>>> human_list;
    try {
        human_list = jarray_to_human_list(env, sample);
    } catch (...) {
        return;
    }

    jobject callback_ref = env->NewGlobalRef(callback);
    if (!callback_ref) {
        java_throw(env, "java/lang/Exception", "Failed to obtain global ref");
        return;
    }
    jclass klass = env->GetObjectClass(callback_ref);
    jmethodID method = env->GetMethodID(klass, "onLiveScore", "(Z[[Ljava/lang/Integer;[Ljava/lang/Integer;I)V");
    action_manager->live_score(sample_id_string, std::move(human_list), standard_id_string,
            [callback_ref, method] (
                bool scored,
                std::unique_ptr<std::list<std::map<std::pair<libaction::BodyPart::PartIndex,
                    libaction::BodyPart::PartIndex>, std::uint8_t>>> scores,
                std::unique_ptr<std::map<std::pair<libaction::BodyPart::PartIndex,
                    libaction::BodyPart::PartIndex>, std::uint8_t>> part_means,
                std::uint8_t mean) {
        JNIEnv* env{};
        if (jvm->AttachCurrentThreadAsDaemon(&env, nullptr) != JNI_OK)
            return;
        try {
            jobjectArray scores_arr = scores ? score_list_to_jarray(env, *scores) : nullptr;
            jobjectArray part_means_arr = part_means ? score_to_jarray(env, *part_means) : nullptr;
            env->CallVoidMethod(callback_ref, method,
                static_cast<jboolean>(scored), scores_arr, part_means_arr, static_cast<jint>(mean));
        } catch (...) {}
        env->DeleteGlobalRef(callback_ref);
        jvm->DetachCurrentThread();
    });
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_importAction(JNIEnv* env, jobject,
                                                                jstring path,
                                                                jstring title,
                                                                jstring scoreAgainst,
                                                                jboolean move)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* path_tmp = env->GetStringUTFChars(path, nullptr);
    std::string path_string(path_tmp);
    env->ReleaseStringUTFChars(path, path_tmp);

    actionplus_lib::ActionMetadata metadata{};

    const char* title_tmp = env->GetStringUTFChars(title, nullptr);
    metadata.title = title_tmp;
    env->ReleaseStringUTFChars(title, title_tmp);

    const char* score_against_tmp = env->GetStringUTFChars(scoreAgainst, nullptr);
    metadata.score_against = score_against_tmp;
    env->ReleaseStringUTFChars(scoreAgainst, score_against_tmp);

    action_manager->import(path_string, metadata, move);
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_exportVideo(JNIEnv* env, jobject,
                                                               jstring id,
                                                               jstring path)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    const char* path_tmp = env->GetStringUTFChars(path, nullptr);
    std::string path_string(path_tmp);
    env->ReleaseStringUTFChars(path, path_tmp);

    action_manager->export_video(id_string, path_string);
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_update(JNIEnv* env, jobject,
                                                          jstring id,
                                                          jstring title,
                                                          jstring scoreAgainst)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    actionplus_lib::ActionMetadata metadata{};

    const char* title_tmp = env->GetStringUTFChars(title, nullptr);
    metadata.title = title_tmp;
    env->ReleaseStringUTFChars(title, title_tmp);

    const char* score_against_tmp = env->GetStringUTFChars(scoreAgainst, nullptr);
    metadata.score_against = score_against_tmp;
    env->ReleaseStringUTFChars(scoreAgainst, score_against_tmp);

    action_manager->update(id_string, metadata);
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_remove(JNIEnv* env, jobject,
                                                          jstring id)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    action_manager->remove(id_string);
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_analyze(JNIEnv* env, jobject,
                                                           jstring id)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    const char* id_tmp = env->GetStringUTFChars(id, nullptr);
    std::string id_string(id_tmp);
    env->ReleaseStringUTFChars(id, id_tmp);

    action_manager->analyze(id_string);
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_cancelOneImport(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    action_manager->cancel_one_import();
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_cancelOneExport(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    action_manager->cancel_one_export();
}

extern "C" JNIEXPORT void JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_cancelOneAnalyze(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return;
    }

    action_manager->cancel_one_analyze();
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_analyzeReadTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->analyze_read_tasks());
    } catch (...) {
        return nullptr;
    }
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_analyzeWriteTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->analyze_write_tasks());
    } catch (...) {
        return nullptr;
    }
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_importTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->import_tasks());
    } catch (...) {
        return nullptr;
    }
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_exportTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->export_tasks());
    } catch (...) {
        return nullptr;
    }
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_storageReadTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->storage_read_tasks());
    } catch (...) {
        return nullptr;
    }
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_actionplus_actionplusmobile_ActionManager_storageWriteTasks(JNIEnv* env, jobject)
{
    if (!action_manager) {
        java_throw(env, "java/lang/Exception", "Not initialized");
        return nullptr;
    }

    try {
        return string_list_to_jobject(env, action_manager->storage_write_tasks());
    } catch (...) {
        return nullptr;
    }
}
