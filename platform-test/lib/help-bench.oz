'Usage: ozbench [options]

The following options are supported:
--[no]verbose           [default=no]
        Print verbose output
--usage, --help
        Print this text
--gc=<int>              [default=0]
        If non zero, run garbage collection each <int> milliseconds
--mintime=<int>         [default=1500]
        Minimal time a test should run
--tests=<s1>,...,<sn>   [default=all]
        Run only those tests in which names at least one <si> occurs
--keys=<s1>,...,<sn>    [default=all]
        Run only those tests that feature at least one <si> as key.
--ignores=<s1>,...,<sn> [default="none"]
        Ignore tests specified by <si>.
'
