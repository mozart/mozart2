# Example app based on Mozart2 and its bootcompiler

This is a trivial example application, whose only purpose is to show how to actually use the [Mozart2 VM](https://github.com/mozart/mozart2) and its [bootstrap compiler](https://github.com/mozart/mozart2-bootcompiler).

## Build instructions

First open `CMakeLists.txt` and adapt the three paths at the top of the file to your installation:

```cmake
# Configure paths
set(MOZART_DIR "/path/to/mozart2")
set(BOOTCOMPILER_DIR "/path/to/mozart2-bootcompiler")
set(SCALA "/usr/bin/scala")
```

Then:

    mozart-app-test$ mkdir build
    mozart-app-test$ cd build
    build$ cmake .. && make

## To run the generated program

    build$ ./testmozart
