
PLATFORM ?= "iOS Simulator,OS=12.1,name=iPhone 7 Plus"

PROJECT ?= PanoController.xcodeproj
SCHEME ?= PanoController

# https://github.com/xcpretty/xcpretty - override with "cat" to see actual output
XCPRETTY := xcpretty

all: build test

build: $(PROJECT)
	set -o pipefail && \
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination platform=$(PLATFORM) | $(XCPRETTY)

test: $(PROJECT)
	set -o pipefail && \
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination platform=$(PLATFORM) | $(XCPRETTY)

clean:
	set -o pipefail && \
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME) | $(XCPRETTY)
	rm -rf build

.PHONY: all clean build test

