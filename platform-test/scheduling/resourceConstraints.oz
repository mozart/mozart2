%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   CardDisjunction = FD.schedule.disjoint
   CDDisjunction   = FD.disjoint

   proc {Help Disjunction ExclusiveTasks Start Dur}
      {ForAll ExclusiveTasks
       proc{$ Tasks}
          {ForAllTail Tasks
           proc{$ T1|Tail}
              {ForAll Tail
               proc{$ T2}
                  {Disjunction Start.T1 Dur.T1 Start.T2 Dur.T2}
               end}
           end}
       end}
   end

in
   proc {ResourceConstraintCard Start Dur ExclusiveTasks}
      {Help CardDisjunction ExclusiveTasks Start Dur}
   end

   proc {ResourceConstraintCD Start Dur ExclusiveTasks}
      {Help CDDisjunction ExclusiveTasks Start Dur}
   end

   proc {ResourceConstraintEF Start Dur ExclusiveTasks}
      {FD.schedule.serialized ExclusiveTasks Start Dur}
   end

   proc {ResourceConstraintTI Start Dur ExclusiveTasks}
      {FD.schedule.taskIntervals ExclusiveTasks Start Dur}
   end

   proc {ResourceConstraintDisj Start Dur ExclusiveTasks}
      {FD.schedule.serializedDisj ExclusiveTasks Start Dur}
   end

   proc {ResourceConstraintCumDisj Start Dur ExclusiveTasks}
      Use = {MakeRecord use {Arity Start}}
      Capacity = {Map {MakeList {Length ExclusiveTasks}} fun{$ _} 1 end}
   in
      {Record.forAll Use proc{$ U} U=1 end}
      {FD.schedule.cumulativeEF ExclusiveTasks Start Dur Use Capacity}
   end

   proc {ResourceConstraintCumMulti Start Dur Use Capacity ExclusiveTasks}
      {FD.schedule.cumulativeEF ExclusiveTasks Start Dur Use Capacity}
   end

end
