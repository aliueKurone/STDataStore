PROJECT = STDataStore.xcodeproj
TARGET = STDataStore
TEST_TARGET = STDataStoreTests

.PHONY: clean test build

build:
	xcodebuild -project ${PROJECT} -scheme ${TARGET} ONLY_ACTIVE_ARCH=NO build 

clean:
	xcodebuild -project ${PROJECT} clean

test:
	xcodebuild -project ${PROJECT} -scheme ${TARGET} ONLY_ACTIVE_ARCH=NO test
