#!/bin/bash
#
# Runs every test in the project and writes a results file.
#
# Rev 3 C4 asks for one command that runs everything and reports what it found,
# so this is the only test entry point anyone should need. It builds, tests,
# measures coverage, and writes build/test-results/results.md.
#
#   ./scripts/test.sh                       # iPhone 17 simulator
#   DEVICE="iPhone 16" ./scripts/test.sh    # a different simulator
#   SCHEME="Gentex_iOS (Dev)" ./scripts/test.sh   # unit tests only
#
# Exits non-zero when a test fails, so CI can use it as-is.

set -o pipefail

cd "$(dirname "$0")/.." || exit 1

SCHEME="${SCHEME:-Gentex_iOS}"
DEVICE="${DEVICE:-iPhone 17}"
PROJECT="Gentex_iOS.xcodeproj"
OUT_DIR="build/test-results"
BUNDLE="$OUT_DIR/latest.xcresult"
LOG="$OUT_DIR/xcodebuild.log"
REPORT="$OUT_DIR/results.md"

# A result bundle cannot be written over, so the previous run goes first.
rm -rf "$BUNDLE"
mkdir -p "$OUT_DIR"

echo "Testing $SCHEME on $DEVICE..."

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -resultBundlePath "$BUNDLE" \
    -enableCodeCoverage YES \
    test > "$LOG" 2>&1
STATUS=$?

# ---------------------------------------------------------------------------
# Counts
#
# Swift Testing and XCTest report differently, so both are counted. XCTest
# prints one "Test Case '…' passed" line per test; Swift Testing prints its own
# summary. Falling back to the log keeps this working whether or not
# `xcrun xcresulttool` supports the flags this Xcode ships with.
# ---------------------------------------------------------------------------

passed=$(grep -c "^Test Case .* passed" "$LOG")
failed=$(grep -c "^Test Case .* failed" "$LOG")
swift_testing=$(grep -oE "Test run with [0-9]+ test" "$LOG" | grep -oE "[0-9]+" | tail -1)
[ -z "$swift_testing" ] && swift_testing=0

if grep -q "\*\* TEST SUCCEEDED \*\*" "$LOG"; then
    verdict="PASSED"
else
    verdict="FAILED"
fi

# ---------------------------------------------------------------------------
# Coverage
#
# `--only-testing` builds and Xcode version differences both change what xccov
# can read, so a missing report is reported as unavailable rather than failing
# the run. The number is information, not a gate.
# ---------------------------------------------------------------------------

coverage_line="not available"
coverage_table=""
if [ -d "$BUNDLE" ]; then
    if xcrun xccov view --report --only-targets "$BUNDLE" > "$OUT_DIR/coverage.txt" 2>/dev/null; then
        # Row shape: "0  Gentex_iOS.app  44  15.20% (2152/14156)", so the
        # percentage is the second-to-last field and the ratio is the last.
        coverage_line=$(grep -m1 "Gentex_iOS.app" "$OUT_DIR/coverage.txt" \
            | awk '{print $(NF-1) " " $NF}')
        [ -z "$coverage_line" ] && coverage_line="not available"
        coverage_table=$(cat "$OUT_DIR/coverage.txt")

        # Per-file, least covered first. This is the list that says where the
        # next test is worth writing.
        xcrun xccov view --report --files-for-target Gentex_iOS.app "$BUNDLE" \
            > "$OUT_DIR/coverage-by-file.txt" 2>/dev/null
    fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

{
    echo "# Test results"
    echo
    echo "- **Verdict:** $verdict"
    echo "- **Scheme:** \`$SCHEME\` on $DEVICE"
    echo "- **Run:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **Commit:** $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "- **Swift Testing tests:** $swift_testing"
    echo "- **XCTest cases:** $passed passed, $failed failed"
    echo "- **App coverage:** $coverage_line"
    echo
    if [ "$verdict" = "FAILED" ]; then
        echo "## Failures"
        echo
        echo '```'
        grep -E "error:|Test Case .* failed|✘|XCTAssert" "$LOG" | head -50
        echo '```'
        echo
    fi
    if [ -n "$coverage_table" ]; then
        echo "## Coverage by target"
        echo
        echo '```'
        echo "$coverage_table"
        echo '```'
        echo
    fi
    if [ -s "$OUT_DIR/coverage-by-file.txt" ]; then
        echo "## Least covered files"
        echo
        echo "Where the next test is worth writing."
        echo
        echo '```'
        awk '
            /\.swift/ {
                pct = ""; path = ""
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /%$/) pct = $i
                    if ($i ~ /\.swift$/) path = $i
                }
                if (pct == "" || path == "") next
                sub(/.*\/Gentex_iOS\/Gentex_iOS\//, "", path)
                sub(/%$/, "", pct)
                printf "%7.2f%%  %s\n", pct, path
            }
        ' "$OUT_DIR/coverage-by-file.txt" | sort -n | head -15
        echo '```'
        echo
    fi
    echo "Full log: \`$LOG\`"
    echo
    echo "Result bundle: \`$BUNDLE\` — open with \`xed $BUNDLE\`."
} > "$REPORT"

echo
cat "$REPORT"

exit $STATUS
