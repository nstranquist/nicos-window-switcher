SHELL := /bin/zsh
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: build bundle run install uninstall clean test headless-smoke verify icons

APP_NAME := Nicos Window Switcher
EXECUTABLE := WindowSwitcher
SWIFT ?= swift
APP_DIR := .build/app/$(APP_NAME).app
APP_VERSION ?= 0.1.0
BUILD_NUMBER ?= 1
INSTALL_DIR := /Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app
BUNDLE_ID := com.nstranquist.nicos-window-switcher
CODE_SIGN_IDENTITY ?= -
ENTITLEMENTS ?= Resources/WindowSwitcher.entitlements
CODE_SIGN_FLAGS = --force --sign "$(CODE_SIGN_IDENTITY)" --entitlements "$(ENTITLEMENTS)"

build:
	$(SWIFT) build -c release
	@bin_dir="$$( $(SWIFT) build -c release --show-bin-path )"; \
		$(MAKE) bundle BINARY_PATH="$$bin_dir/$(EXECUTABLE)" OUTPUT_APP="$(APP_DIR)"

bundle:
	@test -n "$(BINARY_PATH)" || (echo "BINARY_PATH is required" >&2; exit 2)
	@test -n "$(OUTPUT_APP)" || (echo "OUTPUT_APP is required" >&2; exit 2)
	@test -x "$(BINARY_PATH)" || (echo "missing binary: $(BINARY_PATH)" >&2; exit 2)
	@test -f "$(ENTITLEMENTS)" || (echo "missing entitlements: $(ENTITLEMENTS)" >&2; exit 2)
	@plutil -lint "$(ENTITLEMENTS)" >/dev/null
	@mkdir -p "$(OUTPUT_APP)/Contents/MacOS" "$(OUTPUT_APP)/Contents/Resources"
	@cp "$(BINARY_PATH)" "$(OUTPUT_APP)/Contents/MacOS/$(EXECUTABLE)"
	@cp Resources/Info.plist "$(OUTPUT_APP)/Contents/Info.plist"
	@if [[ -f Resources/AppIcon.icns ]]; then cp Resources/AppIcon.icns "$(OUTPUT_APP)/Contents/Resources/AppIcon.icns"; fi
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(APP_VERSION)" "$(OUTPUT_APP)/Contents/Info.plist"
	@/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(BUILD_NUMBER)" "$(OUTPUT_APP)/Contents/Info.plist"
	@plutil -lint "$(OUTPUT_APP)/Contents/Info.plist" >/dev/null
	@codesign $(CODE_SIGN_FLAGS) --deep "$(OUTPUT_APP)"
	@echo "  Signed: $(CODE_SIGN_IDENTITY)"
	@echo "  Built: $(OUTPUT_APP)"
	@echo "  Executable: $(OUTPUT_APP)/Contents/MacOS/$(EXECUTABLE)"

run: build
	@open "$(APP_DIR)"

install: build
	@ditto "$(APP_DIR)" "$(INSTALLED_APP)"
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(INSTALLED_APP)" 2>/dev/null || true
	@if pgrep -xq "$(EXECUTABLE)"; then pkill -x "$(EXECUTABLE)" || true; sleep 0.3; fi
	@echo "  Installed: $(INSTALLED_APP)"

uninstall:
	@pkill -x "$(EXECUTABLE)" 2>/dev/null || true
	@rm -rf "$(INSTALLED_APP)"
	@echo "  Uninstalled: $(INSTALLED_APP)"

test:
	$(SWIFT) test

headless-smoke: build
	@./scripts/headless_smoke.sh

verify: test build headless-smoke
	@codesign --verify --deep --strict "$(APP_DIR)"
	@test -x "$(APP_DIR)/Contents/MacOS/$(EXECUTABLE)"
	@plutil -lint "$(APP_DIR)/Contents/Info.plist" >/dev/null
	@test "$$('/usr/libexec/PlistBuddy' -c 'Print :CFBundleIdentifier' "$(APP_DIR)/Contents/Info.plist")" = "$(BUNDLE_ID)"
	@test "$$('/usr/libexec/PlistBuddy' -c 'Print :CFBundleDisplayName' "$(APP_DIR)/Contents/Info.plist")" = "$(APP_NAME)"
	@echo "  verify ok"

icons:
	@./scripts/generate_icon.py
	@echo "  generated Resources/AppIcon.icns"

clean:
	$(SWIFT) package clean
	@rm -rf .build
