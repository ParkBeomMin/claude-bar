APP = ClaudeBar.app
# Homebrew 빌드는 샌드박스 안에서 돌므로 SWIFT_FLAGS=--disable-sandbox 를 넘긴다
SWIFT_FLAGS ?=

.PHONY: build test bundle run clean

build:
	swift build -c release $(SWIFT_FLAGS)

test:
	swift test

bundle: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/claude-bar $(APP)/Contents/MacOS/claude-bar
	cp packaging/Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: bundle
	./$(APP)/Contents/MacOS/claude-bar

clean:
	rm -rf .build $(APP)
