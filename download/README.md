# Release build outputs (scripts)

Release binaries are **not** stored in this repo.

From the **repository root**, run:

```bash
./scripts/build-download-linux.sh
./scripts/build-download-android.sh
```

By default, artifacts go to your **Linux Downloads** folder (`xdg-user-dir DOWNLOAD`, or `~/Downloads`):

- `leccheck-linux-x64-<version>.tar.gz` — extract and run `bundle/leccheck`
- `leccheck-android-<version>.apk` — side-load or share outside the Play Store

Override the output directory:

```bash
LEC_CHECK_OUT_DIR=/tmp ./scripts/build-download-linux.sh
```

If `flutter` is on your `PATH`, the scripts use it automatically. Otherwise:

```bash
export FLUTTER_BIN=/path/to/flutter/bin/flutter
./scripts/build-download-linux.sh
```

For **Google Play**, build an **AAB**: `cd flutter_app && flutter build appbundle`.
