%%%
%%% Authors:
%%%   Kevin Glynn <glynn@info.ucl.ac.be>
%%%
%%% Copyright:
%%%   Kevin Glynn, 2003
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

%%% Random tests of the Uniform State Syntax

functor

import

export Return

define
   Return =
   state([
	  'class'(proc {$}
		     C = {NewCell 0}
		     class MyClass 
			attr a la
			   d cd
			meth init()
			   a <- 0
			end
				   
			meth manip()
			   C := @C + 1      % Increments contents of cell C
			   a := @a + 1      % Increments contents of attr A
			   a := @C          % contents of attr A set to content of C
			   @C = 1
			   C := a           % contents of C is name of cell A
			   a := @@C + 1     % (indirectly) increments contents of attr A
			   C := @a          % update C with current content of A
			   a := C           % contents of A is name of cell C
			   C := @@a + 1     % (indirectly) increments contents of cell C
			   la := a := C := 7
			end
				   
			meth dict_manip()
			   d := {NewDictionary}
			   @d.k := 32       % Update dictionary in attr
			   cd := d          % assign attr name d to cd
			   @@cd#j := 64     % indirectly update dict
			   64 = @@cd.j := 96
			   96 = @@cd#j := 128
			end
				   
			meth test()
			   @a = 3
			   @@la = 7
			   @C=7
			   @(@d#j) = 128     
			   (@@cd.k) = 32
			end
		     end

		     M = {New MyClass init()}
		  in
		     {M manip()}
		     {M dict_manip()}
		     {M test()}
		  end
		  keys:[state syntax 'class' object])

	  dict(proc {$}
		  A={NewArray 0 50 ~1}
		  D={NewDictionary}
	       in
		  D.3 := 5
		  A.3 := 5
		  (if 5 < A.3 then D else A end).4 := 2
		  A.4 = @(D#3)-3
	       end
	       keys:[state syntax dictionary array])

	  cell(proc {$}
		  C = {NewCell ~1} V
	       in
		  V = C := 3
		  @C = V+4
	       end
	       keys:[state syntax cell])
	 ])
end




