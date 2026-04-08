# Download artifacts (local builds)

Release binaries are **not committed** to git. Generate them from the repo root:

```bash
./scripts/build-download-linux.sh
./scripts/build-download-android.sh
```

Outputs appear here:

- `leccheck-linux-x64-<version>.tar.gz` — extract and run the `bundle/leccheck` binary (see Flutter Linux deploy docs).
- `leccheck-android-<version>.apk` — side-load or distribute outside the Play Store.

Override the Flutter SDK path:

```bash
FLUTTER_BIN=/path/to/flutter/bin/flutter ./scripts/build-download-linux.sh
```

For Play Store uploads, build an **AAB** separately: `cd flutter_app && flutter build appbundle`.
