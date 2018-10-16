TARGET_ABI ?= armeabi-v7a

../jniLibs/$(TARGET_ABI)/libactionplus.so: action_manager.cpp
	mkdir -p ../jniLibs/$(TARGET_ABI)
	$(CXX) -s -o $@ $< -std=c++11 -O3 -Wall -Wextra -Werror $(CXXFLAGS) -shared
