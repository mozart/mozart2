# Mozart2 Continuous Integration

We use a continuous integration system for Mozart2. This means that at every
change made in source code, we check if it did not break the build.
More specifically, every commit sent to this repository triggers two builds. We
use [Travis CI](https://travis-ci.org/) to build the pre-generated sources and Mozart2 on Linux. We also use
[Appveyor](https://www.appveyor.com/) to build on Windows. If you wish to use those tools, you can fork this
repository and active both Appveyor and Travis to your fork. The Travis CI job is probably
the easiest way to rebuild the pre-generated sources.

## Travis CI

[![Travis CI build status](https://travis-ci.org/mozart/mozart2.svg?branch=master)](https://travis-ci.org/mozart/mozart2)

The build process is written in [.travis.yml](.travis.yml). Specifically, we use the
[trusty](https://docs.travis-ci.com/user/reference/overview/#virtualisation-environment-vs-operating-system) environnement. Currently, we implement a build on
Linux. We create two jobs. The first one, builds the pre-generated sources
with LLVM and CLANG. It then compares the generated sources with those already
in the repository. If this job succeed, a second one is started to build
Mozart2.

## Appveyor

[![Appveyor build status](https://ci.appveyor.com/api/projects/status/github/mozart/mozart2?branch=master&svg=true)](https://ci.appveyor.com/project/layus/mozart2)

The build process is written in [appveyor.yml](appveyor.yml). It uses mainly MingW to build.
The build uploads a Windows installer as an artifact.
