%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local

   %% General help routines
   proc {NewKiller ?Killer ?KillFlag}
      proc {Killer}
         KillFlag=kill
      end
   end

   %%
   %% Different wrappers for creation of output
   %%
   fun {WrapS S}
      S
   end

   fun {WrapP S}
      proc {$ X}
         {Space.merge {Space.clone S} X}
      end
   end

   %%
   %% Make copy of space and recompute choices
   %%
   local
      proc {ReDo Is C}
         case Is of nil then skip
         [] I|Ir then {ReDo Ir C} {Space.commit C I}
         end
      end
   in
      proc {Recompute S Is C}
         C={Space.clone S} {ReDo Is C}
      end
   end

   %%
   %% Injection of solution constraints for best solution search
   %%
   proc {Better S O SS}
      CS={Space.clone SS}
   in
      {Space.inject S proc {$ X} {O {Space.merge CS} X} end}
   end

   %%
   %% The one solution search module
   %%

   fun {OneDepthNR KF S}
      case {IsFree KF} then
         case {Space.ask S}
         of failed then nil
         [] succeeded then S
         [] alternatives(N) then C={Space.clone S} in
            {Space.commit S 1}
            case {OneDepthNR KF S}
            of nil then {Space.commit C 2#N} {OneDepthNR KF C}
            elseof O then O
            end
         end
      else nil
      end
   end

   local
      fun {AltCopy KF I M S MRD}
         case I==M then
            {Space.commit S I}
            {OneDepthR KF S S nil MRD MRD}
         else C={Space.clone S} in
            {Space.commit C I}
            case {OneDepthR KF C S [I] 1 MRD}
            of nil then {AltCopy KF I+1 M S MRD}
            elseof O then O
            end
         end
      end

      fun {Alt KF I M S C As RD MRD}
         {Space.commit S I}
         case I==M then {OneDepthR KF S C I|As RD MRD}
         elsecase {OneDepthR KF S C I|As RD MRD}
         of nil then S={Recompute C As} in
            {Alt KF I+1 M S C As RD MRD}
         elseof O then O
         end
      end
   in
      fun {OneDepthR KF S C As RD MRD}
         case {IsFree KF} then
            case {Space.ask S}
            of failed    then nil
            [] succeeded then S
            [] alternatives(M) then
               case RD==MRD then {AltCopy KF 1 M S MRD}
               else {Alt KF 1 M S C As RD+1 MRD}
               end
            end
         else nil
         end
      end
   end

   local
      fun {OneDepth P MRD ?KP}
         KF={NewKiller ?KP} S={Space.new P}
      in
         case MRD==1 then {OneDepthNR KF S}
         else {OneDepthR KF S S nil MRD MRD}
         end
      end

      local
         fun {AltCopy KF I M S CD MRD CO}
            case I==M then
               {Space.commit S I}
               {OneBoundR KF S S nil CD MRD MRD CO}
            else
               C={Space.clone S}
               {Space.commit C I}
               O={OneBoundR KF C S [I] CD 1 MRD CO}
            in
               case {Space.is O} then O
               else {AltCopy KF I+1 M S CD MRD O}
               end
            end
         end

         fun {Alt KF I M S C As CD RD MRD CO}
            {Space.commit S I}
            case I==M then {OneBoundR KF S C I|As CD RD MRD CO}
            else O={OneBoundR KF S C I|As CD RD MRD CO} in
               case {Space.is O} then O
               else S={Recompute C As} in
                  {Alt KF I+1 M S C As CD RD MRD O}
               end
            end
         end

         fun {OneBoundR KF S C As CD RD MRD CO}
            case {IsFree KF} then
               case {Space.ask S}
               of failed    then CO
               [] succeeded then S
               [] alternatives(M) then
                  case CD=<0 then cut
                  elsecase RD==MRD then {AltCopy KF 1 M S CD-1 MRD CO}
                  else {Alt KF 1 M S C As CD-1 RD+1 MRD CO}
                  end
               end
            else nil
            end
         end

         fun {OneIterR KF S CD MRD}
            case {IsFree KF} then C={Space.clone S} in
               case {OneBoundR KF C C nil CD MRD MRD nil}
               of cut then {OneIterR KF S CD+1 MRD}
               elseof O then O
               end
            else nil
            end
         end
      in

         fun {OneBound P MD MRD ?KP}
            S={Space.new P}
         in
            {OneBoundR {NewKiller ?KP} S S nil MD MRD MRD nil}
         end

         fun {OneIter P MRD ?KP}
            {OneIterR {NewKiller ?KP} {Space.new P} 1 MRD}
         end
      end

      local
         proc {Probe S D KF}
            case {IsDet KF} then
               raise killed end
            elsecase {Space.ask S}
            of failed then skip
            [] succeeded then
               raise succeeded(S) end
            [] alternatives(N) then
               case D==0 then
                  {Space.commit S 1} {Probe S 0 KF}
               else C={Space.clone S} in
                  {Space.commit S 2#N} {Probe S D-1 KF}
                  {Space.commit C 1}   {Probe C D KF}
               end
            end
         end

         proc {Iterate S D M KF}
            case M==D then {Probe S D KF} else
               {Probe {Space.clone S} D KF} {Iterate S D+1 M KF}
            end
         end
      in
         proc {LDS P D ?KP}
            {Iterate {Space.new P} 0 D {NewKiller ?KP}}
         end
      end

   in

      OneModule = one(depth:    fun {$ P MRD ?KP}
                                   case {OneDepth P MRD ?KP}
                                   of nil then nil
                                   elseof S then [{Space.merge S}]
                                   end
                                end
                      depthP:   fun {$ P MRD ?KP}
                                   case {OneDepth P MRD ?KP}
                                   of nil then nil
                                   elseof S then [{WrapP S}]
                                   end
                                end
                      depthS:   fun {$ P MRD ?KP}
                                   case {OneDepth P MRD ?KP}
                                   of nil then nil
                                   elseof S then [S]
                                   end
                                end

                      bound:    fun {$ P MD MRD ?KP}
                                   case {OneBound P MD MRD ?KP}
                                   of nil then nil
                                   [] cut then cut
                                   elseof S then [{Space.merge S}]
                                   end
                                end
                      boundP:   fun {$ P MD MRD ?KP}
                                   case {OneBound P MD MRD ?KP}
                                   of nil then nil
                                   [] cut then cut
                                   elseof S then [{WrapP S}]
                                   end
                                end
                      boundS:   fun {$ P MD MRD ?KP}
                                   case {OneBound P MD MRD ?KP}
                                   of nil then nil
                                   [] cut then cut
                                   elseof S then [S]
                                   end
                                end

                      iter:     fun {$ P MRD ?KP}
                                   case {OneIter P MRD ?KP}
                                   of nil then nil
                                   elseof S then [{Space.merge S}]
                                   end
                                end
                      iterP:    fun {$ P MRD ?KP}
                                   case {OneIter P MRD ?KP}
                                   of nil then nil
                                   elseof S then [{WrapP S}]
                                   end
                                end
                      iterS:    fun {$ P MRD ?KP}
                                   case {OneIter P MRD ?KP}
                                   of nil then nil
                                   elseof S then [S]
                                   end
                                end

                      lds:      fun {$ P D ?KP}
                                   try {LDS P D ?KP} nil
                                   catch killed then nil
                                   [] succeeded(S) then [{Space.merge S}]
                                   end
                                end
                      ldsP:     fun {$ P D ?KP}
                                   try {LDS P D ?KP} nil
                                   catch killed then nil
                                   [] succeeded(S) then [{WrapP S}]
                                   end
                                end
                      ldsS:     fun {$ P D ?KP}
                                   try {LDS P D ?KP} nil
                                   catch killed then nil
                                   [] succeeded(S) then [S]
                                   end
                                end
                     )

   end

   %%
   %% The all solution search module
   %%
   local

      proc {AllNR KF S W Or Os}
         case {IsFree KF} then
            case {Space.ask S}
            of failed then Os=Or
            [] succeeded then Os={W S}|Or
            [] alternatives(N) then C={Space.clone S} Ot in
               {Space.commit S 1} {Space.commit C 2#N}
               Os={AllNR KF S W Ot}
               Ot={AllNR KF C W Or}
            end
         else Os=Or
         end
      end

      local
         proc {AltCopy KF I M S MRD W Or Os}
            case I==M then
               {Space.commit S I}
               {AllR KF S S nil MRD MRD W Or Os}
            else C={Space.clone S} Ot in
               {Space.commit C I}
               Os={AllR KF C S [I] 1 MRD W Ot}
               Ot={AltCopy KF I+1 M S MRD W Or}
            end
         end

         proc {Alt KF I M S C As RD MRD W Or Os}
            {Space.commit S I}
            case I==M then
               {AllR KF S C I|As RD MRD W Or Os}
            else Ot NewS={Recompute C As} in
               Os={AllR KF S C I|As RD MRD W Ot}
               Ot={Alt KF I+1 M NewS C As RD MRD W Or}
            end
         end
      in
         fun {AllR KF S C As RD MRD W Or}
            case {IsFree KF} then
               case {Space.ask S}
               of failed    then Or
               [] succeeded then {W S}|Or
               [] alternatives(M) then
                  case RD==MRD then {AltCopy KF 1 M S MRD W Or}
                  else {Alt KF 1 M S C As RD+1 MRD W Or}
                  end
               end
            else Or
            end
         end
      end
   in
      fun {All P MRD ?KP}
         KF={NewKiller ?KP} S={Space.new P}
      in
         case MRD==1 then {AllNR KF S Space.merge nil}
         else {AllR KF S S nil MRD MRD Space.merge nil}
         end
      end

      fun {AllS P MRD ?KP}
         KF={NewKiller ?KP} S={Space.new P}
      in
         case MRD==1 then {AllNR KF S WrapS nil}
         else {AllR KF S S nil MRD MRD WrapS nil}
         end
      end

      fun {AllP P MRD ?KP}
         KF={NewKiller ?KP} S={Space.new P}
      in
         case MRD==1 then {AllNR KF S WrapP nil}
         else {AllR KF S S nil MRD MRD WrapP nil}
         end
      end
   end


   %%
   %% The best solution search module
   %%

   local

      local
         fun {BABNR KF S O SS}
            case {IsFree KF} then
               case {Space.ask S}
               of failed then SS
               [] succeeded then S
               [] alternatives(N) then C={Space.clone S} NewSS in
                  {Space.commit S 1} {Space.commit C 2#N}
                  NewSS={BABNR KF S O SS}
                  case SS==NewSS then {BABNR KF C O SS}
                  elsecase NewSS==nil then nil
                  else {Better C O NewSS} {BABNR KF C O NewSS}
                  end
               end
            else nil
            end
         end

         local
            fun {AltCopy KF I M S MRD O SS}
               case I==M then
                  {Space.commit S I}
                  {BABR KF S S nil MRD MRD O SS}
               else C={Space.clone S} NewSS in
                  {Space.commit C I}
                  NewSS = {BABR KF C S [I] 1 MRD O SS}
                  case NewSS==SS then
                     {AltCopy KF I+1 M S MRD O SS}
                  elsecase NewSS==nil then nil
                  else
                     {Space.commit S I+1#M}
                     {Better S O NewSS}
                     {BABR KF S S nil MRD MRD O NewSS}
                  end
               end
            end

            fun {Alt KF I M S C As RD MRD O SS}
               {Space.commit S I}
               case I==M then
                  {BABR KF S C I|As RD MRD O SS}
               else
                  NewSS = {BABR KF S C I|As RD MRD O SS}
               in
                  case NewSS==SS then
                     {Alt KF I+1 M {Recompute C As} C As RD MRD O SS}
                  elsecase NewSS==nil then nil
                  else NewS={Recompute C As} in
                     {Space.commit NewS I+1#M}
                     {Better NewS O NewSS}
                     {BABR KF NewS NewS nil MRD MRD O NewSS}
                  end
               end
            end
         in
            fun {BABR KF S C As RD MRD O SS}
               case {IsFree KF} then
                  case {Space.ask S}
                  of failed    then SS
                  [] succeeded then S
                  [] alternatives(M) then
                     case RD==MRD then {AltCopy KF 1 M S MRD O SS}
                     else {Alt KF 1 M S C As RD+1 MRD O SS}
                     end
                  end
               else nil
               end
            end
         end

      in
         fun {BestBAB P O MRD ?KP}
            KF={NewKiller ?KP} S={Space.new P}
         in
            case MRD==1 then {BABNR KF S O nil}
            else {BABR KF S S nil MRD MRD O nil}
            end
         end
      end

      local
         fun {RestartNR KF S O PS}
            case {IsFree KF} then C={Space.clone S} in
               case {OneDepthNR KF S}
               of nil then PS
               elseof S then {Better C O S} {RestartNR KF C O S}
               end
            else nil
            end
         end

         fun {RestartR KF S O PS MRD}
            case {IsFree KF} then C={Space.clone S} in
               case {OneDepthR KF S S nil MRD MRD}
               of nil then PS
               elseof S then {Better C O S} {RestartR KF C O S MRD}
               end
            else nil
            end
         end
      in
         fun {BestRestart P O MRD ?KP}
            KF={NewKiller ?KP} S={Space.new P}
         in
            case MRD==1 then {RestartNR KF S O nil}
            else {RestartR KF S O nil MRD}
            end
         end
      end


   in

      BestModule = best(bab:      fun {$ P O MRD ?KP}
                                     case {BestBAB P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [{Space.merge S}]
                                     end
                                  end
                        babP:     fun {$ P O MRD ?KP}
                                     case {BestBAB P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [{WrapP S}]
                                     end
                                  end
                        babS:     fun {$ P O MRD ?KP}
                                     case {BestBAB P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [S]
                                     end
                                  end

                        restart:  fun {$ P O MRD ?KP}
                                     case {BestRestart P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [{Space.merge S}]
                                     end
                                  end
                        restartP: fun {$ P O MRD ?KP}
                                     case {BestRestart P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [{WrapP S}]
                                     end
                                  end
                        restartS: fun {$ P O MRD ?KP}
                                     case {BestRestart P O MRD ?KP}
                                     of nil then nil
                                     elseof S then [S]
                                     end
                                  end)

   end

   local

      local
         proc {Recompute S|Sr C}
            case {Space.is S} then C={Space.clone S}
            else {Recompute Sr C} {Space.commit C S.1}
            end
         end

         class ReClass
            attr
               stack:nil cur rd sol:nil prev:nil
               isStopped:false backtrack:false
            feat
               mrd manager order

            meth init(P O D)
               cur       <- {Space.new P}
               rd        <- D
               isStopped <- false
               backtrack <- false
               self.mrd   = D
               self.order = O
            end

            meth stop
               isStopped <- true
            end

            meth resume
               isStopped <- false
            end

            meth last($)
               case {self next($)}
               of stopped then stopped
               [] nil     then @prev
               elseof S   then prev<-S ReClass,last($)
               end
            end

            meth next($)
               case @backtrack then
                  ReClass, backtrack
                  backtrack <- false
               else skip
               end
               {self explore($)}
            end

            meth push(M)
               case self.mrd==@rd then
                  rd    <- 1
                  stack <- 1#M#@sol|{Space.clone @cur}|@stack
               else
                  rd    <- @rd + 1
                  stack <- 1#M#@sol|@stack
               end
            end

            meth backtrack
               case @stack of nil then cur <- false
               [] S1|Sr then
                  case S1
                  of I#M#Sol then
                     case I==M then
                        stack <- Sr rd <- @rd - 1
                        ReClass,backtrack
                     else NextI=I+1 S2|Srr=Sr in
                        case M==NextI andthen {Space.is S2} then
                           {Space.commit S2 M}
                           stack <- Srr
                           rd    <- self.mrd
                           cur   <- S2
                           case @sol==Sol then skip else
                              {Better S2 self.order @sol}
                           end
                        elsecase @sol==Sol then
                           stack <- NextI#M#Sol|Sr
                           cur   <- {Recompute @stack}
                        else
                           cur   <- {Recompute Sr}
                           {Space.commit @cur NextI#M}
                           {Better @cur self.order @sol}
                           rd    <- self.mrd
                           stack <- Sr
                        end
                     end
                  else stack <- Sr ReClass,backtrack
                  end
               end
            end
         end

      in

         class All from ReClass prop final
            meth explore(S)
               C = @cur
            in
               case @isStopped then S=stopped
               elsecase C==false then S=nil
               elsecase {Space.ask C}
               of failed then
                  All,backtrack All,explore(S)
               [] succeeded then
                  S=C backtrack <- true
               [] alternatives(M) then
                  All,push(M) {Space.commit C 1} All,explore(S)
               end
            end
         end

         class Best from ReClass prop final
            meth explore(S)
               C = @cur
            in
               case @isStopped then S=stopped
               elsecase C==false then S=nil
               elsecase {Space.ask C}
               of failed then
                  Best,backtrack Best,explore(S)
               [] succeeded then
                  S=C sol<-C backtrack<-true
               [] alternatives(M) then
                  ReClass,push(M) {Space.commit C 1} Best,explore(S)
               end
            end
         end
      end

      proc {Dummy _}
         skip
      end

   in

      class SearchObject from BaseObject
         prop
            locking
         attr
            RCD:     1
            MyAgent: Dummy

         meth script(P ...) = M
            lock
               D = {CondSelect M rcd @RCD}
            in
               MyAgent <- case {HasFeature M 2} then {New Best init(P M.2 D)}
                          else {New All init(P false D)}
                          end
               RCD     <- D
            end
         end

         meth Next($)
            lock A=@MyAgent in {A resume} {A next($)} end
         end

         meth next($)
            S=SearchObject,Next($)
         in
            case {Space.is S} then [{Space.merge {Space.clone S}}]
            else S
            end
         end

         meth nextS($)
            S=SearchObject,Next($)
         in
            case {Space.is S} then [{Space.clone S}]
            else S
            end
         end

         meth nextP($)
            S=SearchObject,Next($)
         in
            case {Space.is S} then [{WrapP S}]
            else S
            end
         end

         meth Last($)
            lock A=@MyAgent in {A resume} {A last($)} end
         end

         meth last($)
            S=SearchObject,Last($)
         in
            case {Space.is S} then [{Space.merge {Space.clone S}}]
            else S
            end
         end

         meth lastS($)
            S=SearchObject,Last($)
         in
            case {Space.is S} then [{Space.clone S}]
            else S
            end
         end

         meth lastP($)
            S=SearchObject,Last($)
         in
            case {Space.is S} then [{WrapP S}]
            else S
            end
         end

         meth stop
            {@MyAgent stop}
         end

         meth clear
            lock
               {@MyAgent stop}
               MyAgent <- Dummy
            end
         end

      end
   end

   %%
   %% Often used short cuts
   %%
   fun {SearchOne P}
      {OneModule.depth P 1 _}
   end

   fun {SearchAll P}
      {All P 1 _}
   end

   fun {SearchBest P O}
      {BestModule.bab P O 1 _}
   end

   SearchBase = base(one:  SearchOne
                     all:  SearchAll
                     best: SearchBest)

in

   functor

   export
      one:    OneModule
      all:    All
      allS:   AllS
      allP:   AllP
      best:   BestModule
      object: SearchObject
      base:   SearchBase
   define

      skip

   end

end
