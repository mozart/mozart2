%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%   Christian Schulte, 1999
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


%%% TODO: every test should be a new procedure


functor

export
   Return

prepare
   fun {Confuse X}
      X
   end
   proc {Assert X Y}
      {Wait X} X=Y
   end
   proc {NotDet X}
      {IsDet X}=false
   end

define
   Return =
   
   guards([g1(entailed(proc {$} X in
			  cond skip then X=1 else fail end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g2(entailed(proc {$} X in
			  cond skip  then X=1
			  []   fail  then fail
			  else fail
			  end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g3(entailed(proc {$} X in
			  cond skip  then X=1
			  []   fail  then fail
			  else fail
			  end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g4(entailed(proc {$} X in
			  cond fail  then fail
			  else X=1
			  end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g5(entailed(proc {$} X in
			  cond fail  then fail
			  []   fail  then fail
			  else X=1
			  end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g6(entailed(proc {$} X in
			  cond fail  then fail
			  []   fail  then fail
			  []   fail  then fail
			  []   fail  then fail
			  else X=1
			  end
			  {Assert X 1}
		       end)
	      keys: ['cond'])

	   g7(entailed(proc {$} X Y Z in
			  thread
			     cond X=Y then Z=1 else fail end
			  end
			  {NotDet Z}
			  X=Y
			  {Assert Z 1}
		       end)
	      keys: ['cond'])
	   
	   g8(entailed(proc {$} X Z in
			  thread
			     cond X=1 then Z=1 else fail end
			  end
			  {NotDet Z}
			  X=1
			  {Assert Z 1}
		       end)
	      keys: ['cond'])

	   g9(entailed(proc {$} X Z in
			  thread
			     cond X=1 then Z=1
			     []   X=2 then Z=2
			     else fail
			     end
			  end
			  {NotDet Z}
			  X=1
			  {Assert Z 1}
		       end)
	      keys: ['cond'])

	   g10(entailed(proc {$} X Z in
			   thread
			      cond X=2 then Z=2
			      []   X=1 then Z=1
			      else fail
			      end
			   end
			   {NotDet Z}
			   X=1
			   {Assert Z 1}
			end)
	       keys: ['cond'])

	   g11(entailed(proc {$} X in
			   cond cond skip then skip else fail end then X=1
			   else fail
			   end
			   {Assert X 1}
			end)
	       keys: ['cond'])

	   g12(entailed(proc {$} X in
			   cond cond fail then skip else fail end then fail
			   else X=1
			   end
			   {Assert X 1}
			end)
	       keys: ['cond'])

	   g13(entailed(proc {$} X Y in
			   thread
			      or X=1 then Y=1
			      [] X=2 then fail
			      [] X=3 then fail
			      end
			   end
			   {NotDet Y}
			   X=1
			   {Assert Y 1}
			end)
	       keys: ['or'])

	   g14(entailed(proc {$} Y in
			   cond X={Confuse 4} in
			      or X=1 then skip
			      [] X=2 then skip
			      [] X=3 then skip
			      end
			   then fail
			   else Y=1
			   end
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g15(entailed(proc {$} Y in
			   cond X={Confuse 4} in
			      or X=1  then skip
			      [] skip then skip
			      end
			   then Y=1
			   else fail
			   end
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g16(entailed(proc {$} X Y in
			   thread
			      cond
				 or X=1  then skip
				 [] skip then skip
				 end
			      then Y=1
			      else fail
			      end
			   end
			   {NotDet Y}
			   X=3
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g17(entailed(proc {$} X Y in
			   thread
			      or X=1
			      [] X=2
			      end
			      Y=1
			   end
			   {NotDet Y}
			   X=1
			   {Assert Y 1}
			end)
	       keys: ['or'])

	   g18(entailed(proc {$} X Y in
			   thread
			      or X=1
			      [] X=2
			      end
			      Y=1
			   end
			   {NotDet Y}
			   X=2
			   {Assert Y 1}
			end)
	       keys: ['or'])

	   g19(entailed(proc {$} X Y in
			   thread
			      cond
				 or X=1
				 [] X=2
				 end
			      then Y=1
			      else fail
			      end
			   end
			   {NotDet Y}
			   X=2
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g20(entailed(proc {$} X Y in
			   thread
			      cond
				 or X=1
				 [] X=2
				 end
			      then Y=1
			      else fail
			      end
			   end
			   {NotDet Y}
			   X=1
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g21(entailed(proc {$} X Y in
			   thread
			      cond
				 or X=1
				 [] X=2
				 end
			      then fail
			      else Y=1
			      end
			   end
			   {NotDet Y}
			   X=3
			   {Assert Y 1}
			end)
	       keys: ['cond' 'or'])

	   g22(entailed(proc {$}
			   or fail
			   [] skip
			   end
			end)
	       keys: ['or'])

	   g23(entailed(proc {$}
			   or skip
			   [] fail
			   end
			end)
	       keys: ['or'])

	   g24(entailed(proc {$}
			   cond
			      or skip
			      [] fail
			      [] fail
			      [] fail
			      end
			   then skip else fail end
			end)
	       keys: ['cond' 'or'])

	   g25(entailed(proc {$}
			   cond
			      or fail
			      [] skip
			      end
			   then skip else fail end
			end)
	       keys: ['cond' 'or'])

	   g26(entailed(proc {$}
			   cond
			      or skip
			      [] fail
			      end
			   then skip else fail end
			end)
	       keys: ['cond' 'or'])

	   g27(entailed(proc {$}
			   cond
			      or skip
			      [] fail
			      [] fail
			      [] fail
			      end
			   then skip else fail end
			end)
	       keys: ['cond' 'or'])
	   
	   
	 
	   g28(entailed(proc {$}
			   X Y 
			   proc {Loop} {Loop} end
			in
			   thread
			      cond
				 cond X=1 then skip else fail end
				 {Loop}
			      then fail
			      else Y=1
			      end
			   end
			   {NotDet Y}
			   X=2
			   {Assert Y 1}
			end)
	       keys: ['cond'])
	   g29(stuck(proc {$} X Y in
			{Wait cond X = Y then unit
			      else unit
			      end}
		     end)
	       keys: ['cond'])
	  ])
end

