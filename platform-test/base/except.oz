functor

import
   Property
   Open
   Space

export
   Return

define

   local
      fun {Deref S}
	 case S of suspended(S) then {Deref S} else S end
      end
   in
      fun {AskVerbose S}
	 {Deref {Space.askVerbose S}}
      end
   end
   
   % tests may be performed (1) either at top-level or in a space
   % and (2) either width debugging on or off.
   local
      proc {DebugGet B} {Property.get 'errors.debug' B} end
      proc {DebugSet B} {Property.put 'errors.debug' B} end
      LOCK = {NewLock}
      % perform the test in the appropriate context
      fun {Test Fun Debug TopLevel}
	 D = {DebugGet}
      in
	 lock LOCK then
	    try
	       {DebugSet Debug}
	       if TopLevel then {Fun Debug true}
	       elsecase {AskVerbose
			 {Space.new fun {$} {Fun Debug false} end}}
	       of succeeded(entailed) then true else false end
	    finally
	       {DebugSet D}
	    end
	 end
      end
   in
      % L is a list of pairs of booleans DEBUG#TOPLEVEL, each
      % describing a context in which the test is to be performed
      % TEST returns true iff the test succeeds in all the
      % given contexts
      fun {TEST F L}
	 case L of nil then true
	 elseof (D#T)|L then
	    {Test F D T} andthen {TEST F L}
	 end
      end
   end
   % the various lists of contexts used in this test suite
   `?debug ?toplevel` = [true#true false#true false#true false#false]
   `-debug +toplevel` = [false#true]
   `+debug ?toplevel` = [true#true true#false]
   `-debug ?toplevel` = [false#true false#false]

   % NOTATION: each test is preceded by a comment that indicates
   % in what contexts the test should be performed. ?debug means
   % that both debug on and debug off should be tried. +debug
   % means only debug on. -debug means only debug off.

   % TELL	failure 2=3	(?debug ?toplevel)
   fun {TELL Debug Toplevel}
      proc {Fail X} 2=X end
   in
      try {Fail 3} false
      catch E then
	 if Debug then
	    case E of failure(debug:d(info:_ stack:_))
	    then true else false end
	 else
	    case E of failure(debug:unit)
	    then true else false end
	 end
      end
   end

   % DOT1	a(1).b==unit	(?debug ?toplevel)
   fun {DOT1 Debug TopLevel}
      try {Id a(1)}.b==unit catch F then
	 case F of error(_ debug:d(info:_ stack:_))
	 then true else false end
      end
   end
   fun {Id X} X end

   % OPEN	system Open non existent file	(?debug ?toplevel)
   fun {OPEN Debug TopLevel}
      try {New Open.file init(name:"NoSuchFile") _} false
      catch F then
	 if TopLevel then
	    if Debug then
	       case F of system(_ debug:d(info:_ stack:_))
	       then true else false end
	    else
	       case F of system(_ debug:unit)
	       then true else false end
	    end
	 else
	    case F of error(kernel(globalState io)
			    debug:d(info:_ stack:_))
	    then true else false end
	 end
      end
   end

   % LOCK	raising exception out LOCK/END	(-debug +toplevel)
   fun {LOCK Debug TopLevel}
      S={Space.new
	 proc {$ Root}
	    Zlock={NewLock}
	    T1 T2 T3 Synch
	 in
	    Root=(T3#Synch)
	    thread
	       try
		  lock Zlock then
		     T1=a {Wait Synch} raise t end
		  end
	       catch t then skip end
	    end
	    thread T2=b lock Zlock then T3=c end end
	 end}
   in
      case (thread {AskVerbose S} end)
      of succeeded(stuck) then
	 {Space.inject S
	  proc {$ _#Synch} Synch=unit end}
	 case (thread {AskVerbose S} end)
	 of succeeded(entailed) then
	    case {Space.merge S} of
	       c#unit then true
	    else false end
	 else false end
      else false end
   end

   % DOT2:	type error for '.'	(+debug ?toplevel)
   fun {DOT2 Debug TopLevel}
      try a.{Id a(b)}
      catch F then
	 case F of error(kernel(type _ _ _ _ _) debug:_)
	 then true end
      end
   end

   % Finally:	finally		(-debug ?toplevel)
   fun {FINALLY Debug TopLevel}
      fun {Boom} raise t end end
      proc {Set X} X=a end
      X
   in
      try
	 try {Boom} finally {Set X} end
      catch t then
	 {IsDet X} andthen X==a
      end
   end

   Return=except({Map
	   [
	    tell(     fun{$}{TEST TELL    `?debug ?toplevel`}end)
	    dot1(     fun{$}{TEST DOT1    `?debug ?toplevel`}end)
	    open(     fun{$}{TEST OPEN    `?debug ?toplevel`}end)
	    'lock'(   fun{$}{TEST LOCK    `-debug +toplevel`}end)
	    dot2(     fun{$}{TEST DOT2    `+debug ?toplevel`}end)
	    'finally'(fun{$}{TEST FINALLY `-debug ?toplevel`}end)
	   ]
	   fun {$ T}
	      L={Label T}
	   in
	      L(equal(T.1 true) keys:[except])
	   end}
	 )
end
