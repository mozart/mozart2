#!/bin/csh
# Works on linux, but not necessarily somewhere else.  But that
# (currently) does not really matter since (currently) 'oztest' does
# not collect virtual memory statistics on other systems either;
if $#argv == 0 then
 prusage:
  echo 'usage: oz-memstat [<options>] <file name base>'
  echo ' <file name base>.first and <file name base>.bulk are created,'
  echo ' with (possibly sorted) first run and bulk run results.'
  echo ' See also oztest --memory=<keys>.'
  echo 'options:'
  echo '   --help'
  echo '   --repeat=<int>              [default=1]'
  echo '   --delay=<int>               [default=0, i.e. no delays between runs]'
  echo '   --tests=<test name>,...     [default: "" (see oztest)]'
  echo '   --ignores=<test name>,...   [default: "" (see oztest)]'
  echo '   --keys=<test name>,...      [default: "" (see oztes)]'
  echo '   --memory=<oztest letters>   [default: 'vh' (virtual mem + active heap)]'
  echo '   --sort=<oztest memory key>  [default: do not sort at all]'
  echo '   --resort=<oztest memory key>'
  echo '   --append                    [default: truncate the output file first]'
  echo '   --skipfile=<name>           [default: none, spin until test succeeds]'
  echo '   --skipcount=<num>           [default: none, spin until test succeeds]'
  exit
endif

switch ($1)
case --help:
    goto prusage;
    breaksw
endsw

set tmpfile="/tmp/ozmst-res.txt"
set repeat=1
set tests=""
set ignores=""
set keys=""
set memopts="vh"
set sortfield=""
set skipfile=""
set skipcount=0
set run=true
set truncate=true
set delay=0

while ($#argv > 1)
    switch ($1)
    case --help:
        goto prusage;

    case --repeat=*:
        set repeat=`echo $1 | sed '1,$s/--repeat=//'`
        shift
        breaksw

    case --delay=*:
        set delay=`echo $1 | sed '1,$s/--delay=//'`
        shift
        breaksw

    case --ignores=*:
        set ignores=`echo $1 | sed '1,$s/--ignores=//'`
        shift
        breaksw

    case --keys=*:
        set keys=`echo $1 | sed '1,$s/--keys=//'`
        shift
        breaksw

    case --tests=*:
        set tests=`echo $1 | sed '1,$s/--tests=//' | sed '1,$s/,/ /g'`
        shift
        breaksw

    case --memory=*:
        set memopts=`echo $1 | sed '1,$s/--memory=//'`
        shift
        breaksw

    case --sort=*:
        set sortfield=`echo $1 | sed '1,$s/--sort=//'`
        set sortfield="$sortfield":
        shift
        breaksw

    case --resort=*:
        set sortfield=`echo $1 | sed '1,$s/--resort=//'`
        set sortfield="$sortfield":
        set run=false
        shift
        breaksw

    case --append:
        set truncate=false
        shift
        breaksw

    case --skipfile=*:
        set skipfile=`echo $1 | sed '1,$s/--skipfile=//'`
        shift
        breaksw

    case --skipcount=*:
        set skipcount=`echo $1 | sed '1,$s/--skipcount=//'`
        shift
        breaksw

    default:
        goto prusage;
    endsw
end

set baseout=$1
set fout=$baseout.first
set bout=$baseout.bulk

# do tests, if needed:
if $run == true then
    if $truncate == true then
        cat /dev/null > $fout
        cat /dev/null > $bout
    endif
    #
    set opts="--verbose --repeat=$repeat --delay=$delay --memory=$memopts \
       --ignores=$ignores --keys=$keys"
    #
    if "$tests" == "" then
        set tests=`oztest --nodo | sed 's/,/ /g;s/TESTS//;s/FOUND://'`
        set noglobbing=true     # all tests are choosen anyway;
    else
        set noglobbing=false
    endif

    #
    foreach i ($tests)
        echo doing test $i
        set repnum=0
        rm -f $tmpfile
        set res=false
        if $noglobbing == true then
            set ignopt="--ignores=${i}_"
        else
            set ignopt=""
        endif
        while ($res == false)
            oztest $opts --tests=$i $ignopt > $tmpfile && set res=true
            set repnum=`expr $repnum + 1`
            if ( $res == false && "$skipfile" != "" && -f "$skipfile" ) then
                echo $i failed, skipping..
                set res=true
                /bin/rm $skipfile
            endif
            if ( $res == false && $skipcount > 0 && $repnum >= $skipcount ) then
                echo $i failed, skipping after $repnum tries..
                set res=true
            endif
        end
        egrep "^>" $tmpfile | sed 's/^>//' >> $fout
        egrep "^:" $tmpfile | sed 's/^://' >> $bout
        rm -f $tmpfile
    end
endif

# figure out the sort field & sort, if at all:
if "$sortfield" != "" then
    # figure out the sort field;
    set sampleline=`sed q $fout`
    set ind=1
    set sortind=0
    foreach i ($sampleline)
        switch ("$i")
        case ${sortfield}*:
            set sortind=$ind
            breaksw
        endsw
        set ind=`expr $ind + 1`
    end
    set nextfield=`expr $ind + 1`

    # sort both files, if necessary;
    if $sortind != 0 then
        rm -f $tmpfile
        sort -g -r -t ' ' -k $sortind.3,$nextfield $fout > $tmpfile
        mv $tmpfile $fout
        rm -f $tmpfile
        sort -g -r -t ' ' -k $sortind.3,$nextfield $bout > $tmpfile
        mv $tmpfile $bout
    endif
endif
