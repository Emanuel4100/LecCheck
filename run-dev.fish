#!/usr/bin/env fish
# Run the LecCheck Flutter app on web (Chrome) or another device target.
# Usage:  ./run-dev.fish [target]
#         fish run-dev.fish chrome
# Optional: set FLUTTER_BIN to your flutter binary; CHROME_EXECUTABLE if Chrome/Chromium is non-standard.

set target $argv[1]
if test -z "$target"
    set target chrome
end

if test -z "$FLUTTER_BIN"
    set -gx FLUTTER_BIN "$HOME/development/flutter/bin/flutter"
end

if not test -x "$FLUTTER_BIN"
    if test -x "$HOME/Development/flutter/bin/flutter"
        set -gx FLUTTER_BIN "$HOME/Development/flutter/bin/flutter"
    end
end

if not test -x "$FLUTTER_BIN"
    echo "Flutter not found at $FLUTTER_BIN"
    echo "Set FLUTTER_BIN or install Flutter under ~/development/flutter (or ~/Development/flutter)"
    exit 1
end

set script_dir (dirname (status filename))
cd "$script_dir/flutter_app" || exit 1

if test "$target" = chrome; and test -z "$CHROME_EXECUTABLE"
    for browser in /usr/bin/brave-browser /usr/bin/brave-browser-stable /usr/bin/chromium-browser /usr/bin/chromium /usr/bin/google-chrome
        if test -x "$browser"
            set -gx CHROME_EXECUTABLE "$browser"
            echo "Using browser executable: $CHROME_EXECUTABLE"
            break
        end
    end
end

echo "Starting LecCheck Flutter app on target: $target"
echo "Press Ctrl+C to stop."

"$FLUTTER_BIN" run -d "$target"
