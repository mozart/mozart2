Mozart-Oz bootstrap compiler
----------------------------

This is the bootstrap compiler for Mozart-Oz v2. The complete Oz compiler is written itself in Oz, which makes bootstrapping an issue. This compiler is a naive compiler that we use to compile the complete Oz compiler.

For this reason, a design goal of this bootstrap compiler is to stay minimal. In particular, we will not attempt to perform any optimization of the resulting code.

### See also ###

*   [Mozart-Oz v2](https://github.com/yjaradin/mozart2)
