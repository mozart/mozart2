'Usage: oztest [options]

The following options are supported:
--[no]do                [default=yes]
        Run tests
--[no]verbose           [default=no]
        Print verbose output
--usage, --help
        Print this text
--gc=<int>              [default=0]
        If non zero, run garbage collection each <int> milliseconds
--threads=<int>         [default=1]
        Run <int> threads concurrently (for each test)
--tests=<s1>,...,<sn>   [default=all]
        Run only those tests in which names at least one <si> occurs
--keys=<s1>,...,<sn>    [default=all]
        Run only those tests that feature at least one <si> as key.
'
