# Mozart2 Continuous Integration

CI runs on GitHub Actions, see [.github/workflows/ci.yml](.github/workflows/ci.yml).
It runs on every push, on pull requests, and on tags.

Compiled Oz code (`.ozf` files) does not depend on the platform, so the
pipeline builds it only once:

1. **Linux x86_64** does a full build: bootcompiler, VM, the whole library,
   the platform tests, the VM unit tests (`vmtest`), and the `.deb`/`.tar.gz` packages. The `.ozf`, `.elc`
   and image files of its build tree are published as the `mozart2-ozf`
   artifact.
2. **Linux arm64, macOS arm64, macOS x86_64 and Windows x86_64** only build the
   native executables (`ozemulator`/`ozengine`, `ozwish`, the `vmtest` unit
   tests, and on Windows `ozc` and `oz`). They unpack `mozart2-ozf` into their build tree, run the
   platform tests with `ctest`, and package the result. They are configured
   with `CMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON`, so installing and packaging do
   not rebuild the `.ozf` files.

Each job uploads its packages as a `package-*` artifact. Pushing a `v*` tag
also creates a draft GitHub release with all the packages attached.

## Windows

Windows builds use [MSYS2](https://www.msys2.org/) with the UCRT64
(MinGW-w64 GCC) environment. MSVC is not supported. Tcl/Tk 8.6 is built from
source into `C:\tcltk` (and cached), so that the Inno Setup installer can
bundle it. The installer does not include Emacs.

## Reproducing a job locally

On Linux:

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build build
    cmake --build build --target platform-test vmtest
    ctest --test-dir build --output-on-failure
