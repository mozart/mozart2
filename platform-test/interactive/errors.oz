%%%%%%%%%%%
%%%%%%%%%%% Emulator
%%%%%%%%%%%

thread {Raise _} end

\switch -optimize
thread {Show a b} end

thread
   _ = {Space.new proc {$ _} if {Show a b} then skip else skip end end}
end

thread
   if {Show a b} then {Show ok} end {Show ey}
end

% no_else

\switch +optimize
thread 
   proc {P X}
      case X of a then {Show ok} end
      {Show ok}
   end
in
   {P b}
end

try
   case false then {Show ok} end
   catch no then skip
end   

thread
   case false then {Show ok} end
end

% long traceback stack

thread
   proc {P X} case X>0 then {P X-1} {P X-1} end end
   proc {Q X} {P X} {P X} end
in
   {Q 2}
end

% toplevel failure

thread fail end

% INSTR
declare X Y in
thread X=Y end
X=1 Y=2

\switch -optimize
thread
   proc {P X} X=1 end
in
   {P b}
end

\switch +optimize
thread
   proc {P X} X=a end
in
   {P b}
end

thread
   proc {P X} X=a(a:_) end
in
   {P b}
end

thread
   proc {P X} X=a(_) end
in
   {P b}
end

thread
   proc {P X Y} X=Y end
in
   {P a b}
end

% apply

thread {{Atom.is a} a} end

thread
   if a.1=_ then skip end
end

thread {Show BaseObject.a} end

thread
   _ = {Space.new proc {$ _} {Show BaseObject.a} end}  
end

thread {"hallo" "hallo"} end

thread {proc {$ X} {X "hallo"} end nil} end

thread {f(nil) a} end

\switch -optimize
thread {17 a(1) 1 _} end

%% field selection

thread f(a:1).Show = _ end

thread f(a:1)^Show = _ end

thread f(a:1)^1 = _ end

thread nil . a = 1 end

thread f(nil) . a = 1 end

thread
   fun {Id X} X end
in
   {Show {{Id `.`} f(a:a) b}}
end

thread {Show a.a} end

thread {Show f(a).2} end

thread {Show f(a).a} end

thread {Show f(a:a).b} end

thread {Show f(a:a b:b c:c d:d e:e f:f g:g).h} end

thread X in thread {Show X.b} end X=f(a) end

%% arithmetics

thread {Show 4/8} end

thread {Show 4+8.0} end

thread
   _ = {Space.new proc {$ _} {Show 4+8.0} end}
end

thread {Show 4-8.0} end

thread {Show 4*7.0} end

thread {Show 0.0/0.0} end

thread {Show 0 div 0} end

thread {Show a div 0} end

thread {Show 0 mod 0} end

thread {Show 4.0/0.0} end

% type

thread X in thread {Show X.a} end X=1 end

thread {Show 1.0.a} end

thread {Show 1.0+1} end

thread {Show 1+1.0} end

thread {BaseObject m} end

thread _={New BaseObject noop(a)} end

thread {`,` a n} end

thread X in X::3#a end

declare A B in [A B]:::0#10 {FD.times A A} + {FD.times B B} =: 27

thread X Y in [X Y] ::: 0#10 X-Y=:1 X=Y end

thread X Y in [X Y] ::: 0#10 X=Y X-Y=:1 end

thread X Y in [X Y] ::: 0#10 X<:Y X=Y end

%% overloaded types

thread {Show s < 1} end

thread case s < 1 then {Show ok} end end

thread case {NewName} < a then {Show ok} end end

%% exceptions

thread {Raise test(a)} end

thread {Raise _} end

thread {`RaiseError` test(a)} end

%%%% Builtins

thread _={`Builtin` 1 1} end

thread _ = {`Builtin` gargel 2} end

thread X={`Builtin` a 0} in {Show X} end 

\switch -optimize
thread {{`Builtin` 'Max' 3} 4 5} end

\switch +optimize
thread
   _ = {Space.new proc {$ _} {{`Builtin` 'Max' 2} _ _} end}
end

%% failure

thread or fail [] fail end {Show ok} end

thread if fail then skip else fail end end

thread or fail then skip [] fail then fail end end

% globalState

thread
   C={NewCell a} in if {Exchange C _ _} then {Show ok} else skip end
end

thread
   C={NewArray 0 100 1} in if {Put C 1 _} then {Show ok} else skip end
end

thread
   C={NewDictionary} in if {Dictionary.put C d1 _} then {Show ok} else skip end
end

% array/dict

thread C={NewArray 0 100 1} in {Get C 101 _} end
 
thread C={NewDictionary} in {Dictionary.get C d1 _} end


%% string conversion

thread {String.toAtom [ 0 10 ] _} end
thread {String.toAtom [ 10 0 10 ] _} end

thread {String.toFloat "0.1," _} end
thread {String.toFloat [ 45 69 45 0 ] _} end
thread {String.toInt "5a" _} end
thread {String.toInt [ 45 0 ] _} end

thread if {Delay 10} then {Show ok} else skip end end

thread
   {Show {OS.getDir {ForThread 0 100000 1 fun {$ In C} 65|In end nil}}}
end

thread
   {Show {OS.pipe "ok" {ForThread 0 110 1 fun {$ In C} 65|In end nil} _}}
end

thread {Show {OS.tmpnam}} end


local 
   class X from BaseObject 
      meth do a <- 1 end
      meth go 7 = @a end
   end
in
   thread {{New X noop} go} end
   thread {{New X noop} do} end
end

%%%%%%%%%%%
%%%%%%%%%%% Object System
%%%%%%%%%%%

{{New BaseObject noop} 1 1}

thread
   class A from BaseObject attr a:2 end
   class B from A end
   class C from BaseObject attr a:1 end
   class D from C B end
in skip end

thread
   class A from BaseObject end
   class B from A end
   class C from B A end
in skip end

thread 
   class C meth bla {self blo} end end
in
   {New C bla _}
end

thread
   class C from BaseObject meth bla {self blo} end end
in
   {New C bla _}
end

thread
   M={New Object.master init}
   S={New Object.slave becomeSlave(M)}
in
   {S becomeSlave(M)}
end

thread
   M={New Object.master init}
   S={New Object.slave becomeSlave(M)}
in
   {S free}
   {S free}
end

local
   class X from BaseObject
      meth m {NewName} <- 1 end
      meth n f(a b) <- 1 end
   end
in
   thread _ = {New X m} end
   thread _ = {New X n} end
end

%%%%%%%%%%%
%%%%%%%%%%% Finite Domains 
%%%%%%%%%%%

%type('Convert' [In] vector 1 "A propagator expected a vector as input
%argument.")
thread 8 ::: 9#10 end 

%type('ConvertToTuple' [In] vector 1 "A propagator expected a vector as input
%argument.")
thread {FD.sumC 9 [4 5] '=:' 9} end

%type('FD.reified.card' [Low Ds Up B] fd 1 "The lower limit of
%cardinality must be a finite domain."
thread {FD.reified.card k [1 2] 4 _} end 

%type('FD.reified.card' [Low Ds Up B] fd 3 "The upper limit of
%cardinality must be a finite domain."
thread {FD.reified.card 1 [1 2] j _} end 

%scheduling('Check' [Tasks Start Dur] vector(vector) 1 "Scheduling
%applications expect that all task symbols are features of the records
%denoting the start times and durations.")
thread {FD.schedule.serializedDisj [[a]] s(b:10) d(b:10)} end 

%type('Check' [Tasks Start Dur] record(fd) 2 "For scheduling applications
%the record denoting the start times must contain finite domains.")
thread {FD.schedule.firstsLasts [[a]] s(a:l) d(a:2)} end  

%type('Check' [Tasks Start Dur] record(int) 2 "For scheduling applications
%the record denoting the durations must contain integers.")
thread {FD.schedule.firstsLasts [[a]] s(a:1) d(a:g)} end 

%recordWidth('Check' [Tasks Start Dur] vector(vector) 1 "For scheduling
%distribution are atmost 30 resources allowed, i.e., the vector
%denoting the tasks must have a width of atmost 30.")
thread {FD.schedule.firstsLasts {Map {MakeList 40} fun{$ _} {MakeList 20} end} s(a:0) d(a:0)} end 

%recordWidth('Check' [Tasks Start Dur] vector(vector) 1 "For scheduling
%distribution are atmost 30 jobs allowed, i.e., each field of the vector
%denoting the tasks must have a width of atmost 30.")
thread {FD.schedule.firstLasts {Map {MakeList 20} fun{$ _} {MakeList 40} end} s(a:0) d(a:0)} end 

%scheduling('Check' [Tasks Start Dur] record 2 "For scheduling
%distribution, the record denoting the start times of tasks must
%contain the task 'pe'.")
thread {FD.schedule.firstsLasts [[a]] s(a:2) d(a:2)} end 

%type('ListToTuple' [Xs I T] list(fd) 1 "For FD.distribute and
%FD.choose, the vector to distribute must contain finite domains.")
thread {Search.base.one proc{$ _} {FD.distribute ff [a]} end _} end 

%type('TupleToTuple' [T1 I T2] list(fd) 1 "For FD.distribute and
%FD.choose, the vector to distribute must contain finite domains.")
thread {Search.base.one proc{$ _} {FD.distribute ff f(a)} end _} end 

%type('RecordToTuple' [T1 I T2] list(fd) 1 "For FD.distribute and
%FD.choose, the vector to distribute must contain finite domains.")
thread {Search.base.one proc{$ _} {FD.distribute ff f(a:a)} end _} end 

%type('MakeDistrTuple' [V T] vector 1 "For FD.distribute and
%FD.choose, the input argument must be a vector.")
thread {Search.base.one proc{$ _} {FD.distribute generic(order: size) [a]} end _} end 

%fdNoChoice('FD.choose' [T Order Value Selected Spec] tuple 1 "The
%vector to choose from does not contain non-determined elements.")
thread {FD.choose ff [3 4] a b} end 

%type('FD.distribute' [Dist Vector] 1 fdDistrDesc "Incorrect
%specification for distribution.")
thread {Search.base.one proc{$ _} {FD.distribute gr [3]} end _} end 

%type('FD.choose' [Dist Vector Selected Spec] 1 fdDistrDesc "Incorrect
%specification for choice.")
thread {FD.choose gr [4 3] _ _} end 


%%%%%%%%%%%
%%%%%%%%%%% FD Propagators
%%%%%%%%%%%

%% propagator type error
thread X Y Z in X + Y =: Z X=a end

%% propagator simplified to unification failure
thread X Y Z in 16 + 23 =: 50 end 

%% propagator failure 
thread	  
   X Y Z
in
   [X Y Z] ::: 1#100
   X + Y =: Z
   X >: 50 Y >: 50 Z <: 500
end

%% propagator failure
thread X in X::1#50 X >: 20 X <: 10 end

%% propagator failure
thread X in X=1 X \=: 1 end	

%% propagator failure
thread X Y in X::1#5 Y::10#20 Y =: X end
