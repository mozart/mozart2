%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

proc {CanonicTaskEnumeration Start Dur ET}
   {Record.forAll Start proc {$ S}
                           S = {FD.reflect.min S}
                        end}
end

proc {FFEnumeration Start Dur ET}
   {FD.distribute ff Start}
end

proc {DichoEnumeration Start Dur ET}
   {FD.distribute split Start}
end

proc {NaiveEnumeration Start Dur ET}
   {FD.distribute naive Start}
end

proc {NoTE Start Dur ET}
   skip
end


local
   proc {Enum Tasks All Start Dur Use Candidates Event}
      case Candidates of nil then fail
      [] C|Cr then
         choice
            Start.C = Event
            {CapEnum1 {List.subtract Tasks C} All Start Dur Use}
         [] NextEvent  = {FoldL All fun{$ I T}
                                       ECT = {FD.reflect.min Start.T}+Dur.T
                                    in
                                       case ECT > Event
                                       then {Min I ECT}
                                       else I
                                       end
                                    end FD.sup}
         in
            Start.C >=: NextEvent
            {Enum Tasks All Start Dur Use Cr Event}
         end
      end
   end
   /*
   proc {Enum Tasks All Start Dur Use Candidates Event}
      case Candidates of nil then fail
      else Mini = {FoldL Candidates.2
                   fun{$ B A}
                      case
                         {FD.reflect.max Start.A}+Dur.A < {FD.reflect.max Start.B} + Dur.B
                         orelse
                         ({FD.reflect.max Start.A}+Dur.A == {FD.reflect.max Start.B} + Dur.B
                          andthen
                          Use.A > Use.B)
                      then A else B
                      end
                   end Candidates.1}
      in
         choice
            Start.Mini = Event
            {CapEnum1 {List.subtract Tasks Mini} All Start Dur Use}
         [] NextEvent  = {FoldL All fun{$ I T}
                                       ECT = {FD.reflect.min Start.T}+Dur.T
                                    in
                                       case ECT > Event
                                       then {Min I ECT}
                                       else I
                                       end
                                    end FD.sup}
            Cr = {List.subtract Candidates Mini}
         in
            Start.Mini >=: NextEvent
            {Enum Tasks All Start Dur Use Cr Event}
         end
      end
   end
   */

   proc {CapEnum1 Tasks All Start Dur Use}
      choice
         case Tasks of nil then skip
         else
            Event = {FoldL Tasks fun{$ In T}
                                    case {FD.reflect.size Start.T} of 1 then In
                                    else {Min {FD.reflect.min Start.T} In}
                                    end
                                 end FD.sup}
            Candidates = {FoldL Tasks
                          fun{$ In T}
                             case {FD.reflect.size Start.T} of 1 then In
                             elsecase {FD.reflect.min Start.T} == Event
                             then T|In
                             else In
                             end
                          end nil}
            SortedCands = {Sort Candidates
                           fun{$ A B}
                              {FD.reflect.max Start.A}+Dur.A < {FD.reflect.max Start.B} + Dur.B
                              orelse
                              ({FD.reflect.max Start.A}+Dur.A == {FD.reflect.max Start.B} + Dur.B
                               andthen
                               Use.A > Use.B)
                           end}
         in
            case SortedCands of nil then skip
            else
               {Enum Tasks All Start Dur Use SortedCands Event}
            end
         end
      end
   end
in
   proc {CumulativeEnum Start Dur Use ExclusiveTasks}
      {CapEnum1 ExclusiveTasks ExclusiveTasks Start Dur Use}
   end
end
