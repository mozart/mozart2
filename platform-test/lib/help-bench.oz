% -*- Mode: text -*-
'
Usage: ./ozbench [options]

ozbench runs benchmarks and prints the average times of <repeat>
(default 5) runs in the form

<name>:
 times in ms: t:<t>  ...

where <t> is the total time in milliseconds.  The other times shown are:

 r:run, g:garbage collection, c:copying, p:propagators, s:system.

Every benchmark runs at least <mintime> (default 1500) milliseconds.
A star (*) after the timings indicates that the variation is more than
ten percent.

The following options are supported:
--[no]verbose, -v	[default=no]
	Print verbose output
--[no]detailed, 	[default=no]
	Print detailed timings
--usage, --help, -h, -?
	Print this text
--gc=<int>		[default=0]
	If non zero, run garbage collection each <int> milliseconds
--mintime=<int> 	[default=1500]
	Minimal time a benchmark should run
--[no]variance         [default=no]
        Print the standard variance
--repeat=<int> 	        [default=5]
	Number of runs
--tests=<s1>,...,<sn>	[default=all]
	Run only those tests in which names at least one <si> occurs
--keys=<s1>,...,<sn>	[default=all]
	Run only those tests that feature at least one <si> as key
--ignores=<s1>,...,<sn> [default=none]
        Ignore tests specified by <si>
'
