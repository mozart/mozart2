'Usage: ozbench [options]

ozbench -- run benchmarks

ozbench prints the average times of REPEAT (default 5) runs in the
form

<name>: t:<t>ms (<var>%) ...

where <t> is the total time in milliseconds and <var> is the
variation.  The variation is only printed if it is more than 10
percent.  The other times shown are:
 r:run, g:garbage collection, c:copying, p:propagators, l:loading, s:system.
Every benchmark runs at least MINTIME (default 1500) milliseconds.

The following options are supported:
--[no]verbose           [default=no]
        Print verbose output
--usage, --help
        Print this text
--gc=<int>              [default=0]
        If non zero, run garbage collection each <int> milliseconds
--mintime=<int>         [default=1500]
        Minimal time a benchmark should run
--repeat=<int>  [default=5]
        Number of runs
--tests=<s1>,...,<sn>   [default=all]
        Run only those tests in which names at least one <si> occurs
--keys=<s1>,...,<sn>    [default=all]
        Run only those tests that feature at least one <si> as key.
--ignores=<s1>,...,<sn> [default="none"]
        Ignore tests specified by <si>.
'
