functor

import

   FD

   Search

export
   Return
define

   proc {StateConstraints ?Campaigns ?Steps ?CampaignsDur ?StepsDur
         Maximal ?AllSteps}
      Campaigns = [{List.make 6} {List.make 3} {List.make 1} {List.make 3}]
      CampaignsDur = 6#7#7#8
      {List.forAllInd Campaigns proc{$ Ind X} X = {FD.dom 1#Maximal.Ind} end}
      Steps = [{List.make 18} {List.make 9} {List.make 3} {List.make 9}]
      {List.forAllInd Steps proc{$ Ind X} X = {FD.dom 1#Maximal.Ind} end}
      StepsDur = ((2#1)#(1#2)#(3#1))#
      ((4#1)#(1#2)#(2#2))#
      ((3#2)#(2#1)#(2#1))#
      ((2#2)#(3#1)#(3#1))
      local proc{Connect CS}
               case CS of nil#nil then skip
               [] (C|Cs)#(S1|S2|S3|Ss) then C=S1 {Connect Cs#Ss}
               end
            end
         fun{Help Steps D1 D2 D3}
            case Steps of nil then nil
            [] S1|S2|S3|Tail
            then S1#D1|S2#D2|S3#D3|{Help Tail D1 D2 D3}
            end
         end
      in
         {ForAll {List.zip Campaigns Steps fun{$ I1 I2} I1#I2 end} Connect}
         AllSteps = {List.foldLInd Steps
                     fun{$ Ind I X}
                        {Append {Help X StepsDur.Ind.1 StepsDur.Ind.2 StepsDur.Ind.3} I}
                     end nil}
      end
   end

   proc {ChargeConstraints Campaigns CampaignsDur}
      {List.forAllInd Campaigns
       proc{$ Ind Campaign}
          {List.forAllTail Campaign
           proc{$ C|Cs}
              case Cs of nil then skip
              [] H|R then C+CampaignsDur.Ind =<: H
              end
           end}
       end}
   end

   proc {StepConstraints Steps StepsDur}
      local proc{Help Steps Ind}
               case Steps of nil then skip
               [] S1|S2|S3|Tail
               then local (D1#_)#(D2#_)#(_#_)=StepsDur.Ind
                    in
                       S1+D1 =: S2
                       S2+D2 =: S3
                       {Help Tail Ind}
                    end
               end
            end
      in
         {List.forAllInd Steps proc{$ Ind X} {Help X Ind} end}
      end
   end

   proc {ChainingCharges Campaigns CampaignsDur}
      local
         proc {Help1 Campaign1 Campaign2 Dur}
            case Campaign1#Campaign2 of nil#nil then skip
            [] (_|C1|Tail1)#(C2|Tail2)
            then
               C1+Dur =<: C2
               {Help1 Tail1 Tail2 Dur}
            end
         end
         proc {Help2 Campaign1 Campaign2 Dur}
            case Campaign1#Campaign2 of nil#nil then skip
            [] (_|_|C1|Tail1)#(C2|Tail2)
            then C1+Dur =<: C2
               {Help2 Tail1 Tail2 Dur}
            end
         end
         C1|C2|C3|_ = !Campaigns
      in
         {Help1 C1 C2 CampaignsDur.1}
         {Help2 C2 C3 CampaignsDur.2}
      end
   end

   proc {MaxConstraints Campaigns CampaignsDur Maximal}
      {List.forAllInd Campaigns
       proc{$ Ind X}
          {Reverse X}.1 + CampaignsDur.Ind =<: Maximal.Ind
       end}
   end

   proc {ConnectConstraints Campaigns Steps CampaignsDur}
      local proc{Help1 Campaigns Steps Count}
               case Campaigns#Steps
               of nil#nil then skip
               [] (C|Cs)#(S|Ss)
               then {Help2 C S CampaignsDur.Count}
                  {Help1 Cs Ss Count+1}
               end
            end
         proc {Help2 Campaign Steps Dur}
            case Campaign#Steps
            of (C1|C2|Tail1)#(S1|_|_|Tail2)
            then C1=<:S1  S1+Dur=<:C2
               {Help2 C2|Tail1 Tail2 Dur}
            [] [C1]#[S1 _ _]
            then C1=<:S1
            else skip
            end
         end
      in
         {Help1 Campaigns Steps 1}
      end
   end


   fun {Tr X} if X < 0 then 0 else X end end

   proc {PersonalConstraints AllSteps Workers}
      proc{SumUp Ind AllSteps Bs Ps}
         case AllSteps of nil then Bs=nil Ps=nil
         [] A|Ar
         then S#(D#P)=!A Br Pr in
            Bs= {FD.reified.int {Tr Ind-D+1}#Ind S }|Br
            Ps=P|Pr
            {SumUp Ind Ar Br Pr}
         end
      end
   in
      {Loop.for 1 60 1 proc{$ Ind}
                          Bs Ps in
                          {SumUp Ind AllSteps Bs Ps}
                          {FD.sumC Ps Bs '=<:' Workers}
                          /*
                          {`GenLeq`
                           {AdjoinAt {List.toTuple '#' Ps} {Width Ps}+1 ~1}
                           {AdjoinAt {List.toTuple '#' Bs} {Width Bs}+1 Workers}
                           0}
                          */
                       end}
   end

   XYZSol = [[[1 7 13 19 25 31]
               [24 31 38]
               [45]
               [1 10 18]]#
              [[1 3 4 7 9 10 13 15 16 19 21 22 25 27 28 31 33 34]
               [24 28 29 31 35 36 38 42 43] [45 48 50]
               [1 3 6 10 12 15 18 20 23]]]

   proc {XYZProblem Campaigns Steps}
      local CampaignsDur StepsDur Maximal=40#50#60#30 AllSteps

         Workers=3  in
         {StateConstraints Campaigns Steps CampaignsDur StepsDur Maximal
          AllSteps}
         {ChargeConstraints Campaigns CampaignsDur}
         {StepConstraints Steps StepsDur}
         {ChainingCharges Campaigns CampaignsDur}
         {MaxConstraints Campaigns CampaignsDur Maximal}
         {ConnectConstraints Campaigns Steps CampaignsDur}
         {PersonalConstraints AllSteps Workers}
         {ForAll Campaigns proc{$ C} {FD.distribute ff C} end}
         {ForAll Steps proc{$ E} {FD.distribute ff E} end}
      end
   end

   Return=
   schedule([
             company([one(equal(fun {$} {Search.base.one proc{$ X}
                                                   local C#S = !X
                                                   in {XYZProblem C S}
                                                   end
                                                end}
                             end
                             XYZSol)
                       keys: [fd scheduling])
                  ])
             company_entailed([one(entailed(proc {$} {Search.base.one proc{$ X}
                                                            local C#S = !X
                                                            in {XYZProblem C S}
                                                            end
                                                          end _}
                                      end)
                                keys: [fd scheduling entailed])
                           ])
            ])

end
