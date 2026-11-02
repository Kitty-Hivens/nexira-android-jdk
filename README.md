# nexira-android-jdk

OpenJDK builds for Android (aarch64, bionic) that the Nexira launcher downloads to run Minecraft on a phone. Android ships no desktop JVM, so the game needs one of its own, loaded into the app process through the JNI invocation API.

## What is built

Upstream OpenJDK update releases, cross compiled with the Android NDK, with a small patch series on top. Headless only (no AWT windowing, the game draws through LWJGL). The series starts from the patches the Termux project maintains for its `openjdk-25` package, minus the four that hard code Termux paths or link extra libraries Android does not need, plus two changes of our own.

| Directory                | Content                                                                 |
|--------------------------|-------------------------------------------------------------------------|
| `versions/<major>.env`   | upstream repository, release tag and commit, boot JDK, pinned checksums |
| `toolchain.env`          | NDK revision and checksum                                               |
| `patches/jdk-<major>/`   | patch series applied to the pinned upstream commit, in file name order  |
| `scripts/`               | fetch, patch, configure, package and the whole pipeline                 |

## Building

Needs a Linux x86_64 host with `clang`, `llvm`, `autoconf`, `make`, `zip`, `unzip`, and the cups, fontconfig and alsa development headers (they are only read, nothing links against them).

    scripts/build.sh 25

Everything lands under `work/`. The result is `work/out/jdk-<version>-android-aarch64.zip` with a `.sha256` file beside it. The steps can also run on their own: `fetch.sh`, `patch.sh`, `configure.sh`, `package.sh`, each taking the major as its argument. `WORK` moves the work directory, `JOBS` sets the parallelism.

The archive is cut down to what the embedded VM loads: no launcher binaries, no debugging and attach agents, no `src.zip`, shared libraries stripped.

## Releases

A release is a tag `jdk-<version>` (for example `jdk-25.0.5`). The workflow builds it, checks the built version against the tag, and attaches the zip and its SHA-256. The launcher verifies the checksum after download.

## Status

| Major | Upstream release | State                                                        |
|-------|------------------|--------------------------------------------------------------|
| 25    | 25.0.5           | Runs on an arm64 Android 16 device (JIT, threads, GC, nio)   |
| 21    | 21.0.13          | Runs on an arm64 Android 16 device (JIT, threads, GC, nio)   |
| 17    | 17.0.21          | Runs on an arm64 Android 16 device (JIT, threads, GC, nio)   |
| 8     | 8u492            | Builds (JRE image), the VM stops while linking its first class |

## License

The patches and scripts are licensed under GPL-2.0 with the Classpath Exception, the same terms as the OpenJDK they apply to (see `LICENSE`). The built runtime is OpenJDK and carries its own license files in the archive.
