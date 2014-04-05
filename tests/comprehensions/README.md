# Test files for comprehensions
---
This directory contains all the files composed with all the tests executed. 

### Simple tests to execute in shell
---
They aim to be executed by shell using the command

    run.sh
Use the -h option to get help.

All the *.oz* files are test files except *Tester.oz* which is a functor used by all tests to execute. Performance tests are in all the files *(Space|Time)_Performance_X.oz* where X goes from 01 to 10. The results of all the performance tests are in *results.txt*. To parse these results into a Matlab script generating a graph, use

    run.sh -n results.txt && python results_parse.py results.txt

### More complex tests to run in Mozart2
---
The directory *Applications* contains small examples.

The directory *Concurrency* contains concurrent examples.
