%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

export
   Return
import
   System RecordC(width: WidthC)

define
   Return =

   records(proc {$}
	      fun {Id X} X end
	      proc {FF B} if B then {System.show B} fail else skip end end
	      proc {Eq X Y} if X==Y then skip else {System.show eq(X Y)} fail end end
	      proc {Neq X Y} if X==Y then {System.show neq(X Y)} fail else skip end end
	   in


% record construction
	      {Eq a() a}
	      local X={NewName} in {Eq X() X} end
	      {Eq f(a) f(a)}
	      {Eq f(a b) f(a b)}
	      {Eq f(1:a) f(a)}
	      {Eq f(a:b) f(a:b)}
	      {Eq f(a:a) f(a:a)}
	      {Eq f(1:a 2:h 3:b) f(3:b 2:h 1:a)}
	      {Eq f(1:a 2:h 3:b) f(a h b)}
	      {Neq f(1:a) f(a:a)}


% record unification
	      local X Y in
		 f(1:X a:a) = f(a:Y 1:b)
		 {Eq X#Y b#a}
	      end

% should not suspend
	      {Wait f(a b _)}


% .
	      {Eq f(1:a).1 a}

	      try _={Id f(3:a)}.1 fail catch error(kernel('.' ...) ...) then skip end

% ^
	      {Eq f(a)^1 a}

	      local X=f(...) in
		 X^1=67
		 {Eq X.1 67}
		 {Eq {Label X} f}
	      end


% AdjoinAt
	      {Eq {AdjoinAt f 1 test} f(test)}
	      {Eq {AdjoinAt f(a:b) 1 test} f(1:test a:b)}
	      {Eq {AdjoinAt {AdjoinAt f(a:b) 1 test} 1 null} f(a:b 1:null)}

% Adjoin
	      {Eq {Adjoin f(a:b) f(1:9)} f(a:b 1:9)}
	      {Eq {Adjoin f(a:b) f(9)} f(a:b 1:9)}
	      {Eq {Adjoin f(1:a 3:b) f(2:c)} f(a c b)}
	      {Eq {Adjoin f(a b c) g(d e f g)} g(d e f g)}
	      {Eq {Adjoin f(a b c) g(d e)} g(d e c)}

% optimized cases
	      {Eq {Adjoin f(a:a) g(b:a a:b)} g(b:a a:b)}
	      {Eq {Adjoin f(a:a) g} g(a:a)}
	      {Eq {Adjoin f g(a:b)} g(a:b)}
	      {Eq {Adjoin f(a) g(a b)} g(a b)}
	      {Eq {Adjoin f(a) g} g(a)}
	      {Eq {Adjoin f g(b)} g(b)}

% List optimization
	      local
		 X = '|'(2:nil)
	      in
		 {Eq {AdjoinAt X 1 foo} foo|nil}
	      end
	      {Eq {Adjoin a a|b} a|b}
	      {Eq {Adjoin a(b c) '|'} b|c}
	      {Eq {Adjoin b|c a|d} a|d}

% `.` suspends for Open
	      local X=f(...) in
		 thread {Eq X.a i} end
		 X^a=i
	      end

% bigint feature
	      local
		 X = {Pow 100 10}
		 XX = {Pow 100 10}
		 Y=X+1
		 YY=X+1
		 Z=Y+1
	      in
		 {Eq a(X:a) a(XX:a)}
		 {Eq a(X:a Y:b) a(XX:a YY:b)}
		 {Neq a(X:a Y:b) a(X:a Z:b)}

		 {Eq a(X:a ...).X a}
		 local
		    R = a(X:a Y:b ...)
		 in
		    {Eq R.X a}
		    {Eq R.Y b}
		 end
		 {Eq a(X:a).XX a}
		 {Eq a(X:a ...).XX a}
		 {Eq a(X:a ...).X a}
		 {Eq a(XX:a ...).X a}

		 local
		    R1=a(X:a ...) R2=a(XX:a ...)
		 in
		    {WidthC R1 1}
		    {WidthC R2 1}
		    {Eq R1 R2}
		 end
	      end

% Record.toList
	      {Eq {Record.toList f(a)} [a]}
	      {Eq {Record.toList f(a:a b:c)} [a c]}

	      {FF {Char.is ~1}}

	   end
	   keys:[module record])
end


