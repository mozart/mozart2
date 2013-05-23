%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1999
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

functor
import Search FS
export Return
define
   N=20

   proc {BugSolution L}
      {List.make N L}
      {List.forAllInd L proc {$ I Var}
			   Var={FS.var.upperBound 1#N}
			   {FS.include I Var}
			end}
      {List.foldL L
       fun {$ Vars Var}
	  thread
	     if Vars==nil then skip else
		or {ForAll Vars proc {$ V} V=Var end}
		[] {ForAll Vars proc {$ V} {FS.disjoint V Var} end}
		end
	     end
	  end
	  Var|Vars
       end nil _}
      {FS.distribute naive L}
   end
   fun {SetBounds S}
      {FS.reflect.lowerBoundList S}#{FS.reflect.upperBoundList S}
   end
   Return = fs([denys(entailed(proc {$}
				  Ss={Search.base.all BugSolution}
			       in
				  {Length Ss}=20
			       end)
		      keys: [space fs])
		seq3(
		   proc {$}
		      case {Search.base.one
			    proc {$ L}
			       S1={FS.var.upperBound 1#5}
			       S2={FS.var.upperBound 1#5}
			       S3={FS.var.upperBound 1#5}
			    in
			       L=[S1 S2 S3]
			       {FS.int.seq L}
			       {FS.cardRange 1 5 S1}
			       {FS.cardRange 1 5 S3}
			    end}
		      of [[S1 S2 S3]] then
			 case {SetBounds S1}#{SetBounds S2}#{SetBounds S3}
			 of (nil#[1 2 3 4])#(nil#[2 3 4])#(nil#[2 3 4 5])
			 then skip else
			    raise fs_denys_seq3 end
			 end
		      end
		   end
		   keys:[fs])
		seq(
		   proc {$}
		      case {Search.base.one
			    proc {$ L}
			       S1={FS.var.upperBound 1#2}
			       S2={FS.var.upperBound 1#2}
			    in
			       L=[S1 S2]
			       {FS.cardRange 1 1 S1}
			       {FS.cardRange 1 1 S2}
			       {FS.int.seq [S1 S2]}
			    end}
		      of [[S1 S2]] then
			 case {SetBounds S1}#{SetBounds S2}
			 of ([1]#[1])#([2]#[2]) then skip
			 else raise fs_denys_seq end end
		      end
		   end
		   keys:[fs])
		convex(
		   proc {$}
		      case {Search.base.one
			    proc {$ S}
			       {FS.var.decl S}
			       {FS.include 1 S}
			       {FS.int.convex S}
			    end}
		      of [_] then skip
		      else raise fs_denys_convex end end
		   end
		   keys:[fs])
	       ])
end