#!/usr/bin/env bash
set -e

echo "🔍 [1/3] Running Flutter Analyze on modified files..."
MODIFIED_DART_FILES=$(git diff --name-only --diff-filter=d HEAD | grep '\.dart$' || true)

if [ -z "$MODIFIED_DART_FILES" ]; then
  echo "✅ No modified Dart files found."
  exit 0
fi

flutter analyze $MODIFIED_DART_FILES

echo "📏 [2/3] Checking Line Limits (Max 300 LOC per file)..."
EXCEEDED_FILES=0
for file in $MODIFIED_DART_FILES; do
  if [ -f "$file" ]; then
    LINES=$(wc -l < "$file")
    if [ "$LINES" -gt 300 ]; then
      echo "❌ FAIL: $file has $LINES lines (Limit is 300)."
      EXCEEDED_FILES=$((EXCEEDED_FILES + 1))
    fi
  fi
done

if [ "$EXCEEDED_FILES" -gt 0 ]; then
  echo "🚨 Quality Gate Failed: Files exceed 300 lines limit."
  exit 1
fi

echo "🚫 [3/3] Checking for Forbidden Legacy Patterns..."
LEGACY_MATCHES=$(git diff HEAD | grep -E "^\+[ ]*.*(AppColors|AppTextStyles|AppDimens|Color\(0x|BorderRadius\.circular|CircularProgressIndicator)" || true)

if [ -n "$LEGACY_MATCHES" ]; then
  echo "❌ FAIL: New legacy code detected in git diff:"
  echo "$LEGACY_MATCHES"
  echo "🚨 Quality Gate Failed: Use Qeran Design System tokens/widgets instead."
  exit 1
fi

echo "🎉 ALL GATES PASSED! Ready for review."
exit 0
