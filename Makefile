APP = ClawdBar.app

.PHONY: build test bundle run clean

build:
	swift build -c release

test:
	swift test

bundle: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/clawdbar $(APP)/Contents/MacOS/clawdbar
	cp packaging/Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: bundle
	./$(APP)/Contents/MacOS/clawdbar

clean:
	rm -rf .build $(APP)
