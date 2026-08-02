#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh

xcodebuild -scheme Voxelia-Package -destination 'generic/platform=macOS' ONLY_ACTIVE_ARCH=YES ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=iOS' ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=iOS Simulator' ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=tvOS' ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=tvOS Simulator' ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=visionOS' ARCHS=arm64 build
xcodebuild -scheme Voxelia-Package -destination 'generic/platform=visionOS Simulator' ARCHS=arm64 build
printf 'Apple platform matrix builds passed.
'
