.PHONY: help test lint format gen build-web build-macos build-ios build-android build-linux build-windows clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Run all tests
	flutter test

lint: ## Run static analysis and format check
	flutter analyze
	dart format --set-exit-if-changed .

format: ## Auto-format all Dart files
	dart format .

gen: ## Run build_runner code generation
	dart run build_runner build --delete-conflicting-outputs

build-web: gen ## Build web output
	flutter build web

build-macos: gen ## Build macOS app
	flutter build macos

build-ios: gen ## Build iOS (no codesign)
	flutter build ios --no-codesign

build-android: gen ## Build Android APK
	flutter build apk

build-linux: gen ## Build Linux binary
	flutter build linux

build-windows: gen ## Build Windows executable
	flutter build windows

clean: ## Clean build artifacts
	flutter clean
	rm -rf build/
