PROJECT = STDataStore.xcodeproj
TEST_TARGET = STDataStoreTests

.PHONY: clean test build

build:
	xcodebuild -project ${PROJECT} -scheme STDataStore build

clean:
	xcodebuild -project ${PROJECT} clean

test:
	xcodebuild -project ${PROJECT} -scheme STDataStore \
	TEST_AFTER_BUILD=YES TEST_HOST=
