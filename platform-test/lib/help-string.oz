'Usage: oztest [options]

The following options are supported:
--[no]do		[default=yes]
	Run tests
--[no]verbose, -v	[default=no]
	Print verbose output
--usage, --help, -h, -?
	Print this text
--gc=<int>		[default=0]
	If non zero, run garbage collection each <int> milliseconds
--threads=<int> 	[default=1]
	Run <int> threads concurrently (for each test)
--repeat=<int>		[default=1]
	Each thread repeats the test <int> times
--delay=<int>           [default=0]
	Wait <int> ms before a next run (kludge for (linux) inetd)
--tests=<s1>,...,<sn>	[default=all]
	Run only those tests in which names at least one <si> occurs
--keys=<s1>,...,<sn>	[default=all]
	Run only those tests that feature at least one <si> as key
--ignores=<s1>,...,<sn> [default=none]
        Ignore tests specified by <si>
--time=<string>         [default=""]
        Print run times in verbose mode. If one of the following keys
        is in <string> the corresponding information is printed:
            r:run g:gc s:system c:copy p:propagate l:load t:total
        Example: "time=rgs" prints the run, gc and system time.
--memory=<string>         [default=""]
        Print memory consumption. If one of the following keys
        is in <string> the corresponding information is printed:
            v:virtual memory
            h:heap (active size)
            a:byte for atoms
            c:atoms for code
            f:bytes in free lists
            n:bytes for names
'
