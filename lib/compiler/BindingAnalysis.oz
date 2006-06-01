%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   BindingAnalysisError = 'binding analysis error'
   BindingAnalysisWarning = 'binding analysis warning'
in
   class BindingAnalysis
      prop final
      attr env: nil freeVariablesOfQuery: unit
      feat MyTopLevel MyReporter WarnRedecl WarnShadowedVars
      meth init(TopLevel Reporter State)
         env <- nil
         freeVariablesOfQuery <- {NewDictionary}
         self.MyTopLevel = TopLevel
         self.MyReporter = Reporter
         self.WarnRedecl = {State getSwitch(warnredecl $)}
         self.WarnShadowedVars = {State getSwitch(warnshadow $)}
      end
      meth openScope() X in
         env <- {NewDictionary}#X#X|@env
      end
      meth getVars(?Vs) Env = @env in
         _#Vs#nil|_ = Env
      end
      meth getAllVariables($)
         {Record.foldR
          {FoldR @env
           fun {$ D#_#_ Vs0}
              {Adjoin Vs0 {Dictionary.toRecord x D}}
           end x}
          fun {$ X In}
             X|In
          end nil}
      end
      meth closeScope(?Vs) Env = @env Dr in
         _#Vs#nil|Dr = Env
         env <- Dr
      end
      meth bind(PrintName Coord ?V) X Env = @env D#Hd#Tl|Dr = Env in
         if self.WarnShadowedVars then
            if {Some
                %% Check for Variable in outer scopes
                case @env of _|TailEnv then TailEnv else nil end
                fun {$ D#_#_} {Dictionary.member D PrintName} end}
            then
               {self.MyReporter warn(coord: Coord
                                     kind: BindingAnalysisWarning
                                     msg: ('shadowing variable `'#
                                           pn(PrintName)#'\''))}
            end
         end
         if self.WarnRedecl orelse self.WarnShadowedVars then TopV in
            {self.MyTopLevel lookupVariableInEnv(PrintName ?TopV)}
            case TopV of undeclared then skip
            else
               {self.MyReporter warn(coord: Coord
                                     kind: BindingAnalysisWarning
                                     msg: ('redeclaring top-level variable `'#
                                           pn(PrintName)#'\''))}
            end
         end
         X = {Dictionary.condGet D PrintName undeclared}
         case X of undeclared then NewTl in
            V = {New Core.userVariable init(PrintName Coord)}
            {Dictionary.put D PrintName V}
            Tl = V|NewTl
            env <- D#Hd#NewTl|Dr
         else
            V = X
         end
      end
      meth bindImport(PrintName Coord Features ?V)
         X Env = @env D#Hd#Tl|Dr = Env
      in
         X = {Dictionary.condGet D PrintName undeclared}
         case X of undeclared then NewTl in
            V = {New Core.restrictedVariable init(PrintName Features Coord)}
            {Dictionary.put D PrintName V}
            Tl = V|NewTl
            env <- D#Hd#NewTl|Dr
         else
            {self.MyReporter
             error(coord: Coord kind: BindingAnalysisError
                   msg: 'variable '#pn(PrintName)#' imported more than once')}
            V = X
         end
      end
      meth refer(PrintName Coord ?VO) V in
         BindingAnalysis, Refer(PrintName Coord @env ?V)
         case V of undeclared then
            {self.MyReporter
             error(coord: Coord kind: BindingAnalysisError
                   msg: 'variable '#pn(PrintName)#' not introduced')}
            {BindingAnalysis, bind(PrintName Coord $) occ(Coord ?VO)}
         else
            if {V isRestricted($)} then
               {self.MyReporter
                error(coord: Coord kind: BindingAnalysisError
                      msg: 'illegal use of imported variable '#pn(PrintName))}
            end
            {V occ(Coord ?VO)}
         end
      end
      meth referImport(PrintName Coord Feature ?IsImport ?VO) V in
         BindingAnalysis, Refer(PrintName Coord @env ?V)
         case V of undeclared then
            {self.MyReporter
             error(coord: Coord kind: BindingAnalysisError
                   msg: 'variable '#pn(PrintName)#' not introduced')}
            IsImport = false
            {BindingAnalysis, bind(PrintName Coord $) occ(Coord ?VO)}
         else GV in
            {V isRestricted(?IsImport)}
            if {V isDenied(Feature ?GV $)} then
               {self.MyReporter
                error(coord: Coord kind: BindingAnalysisError
                      msg: 'illegal use of imported variable '#pn(PrintName)
                      items: [hint(l: 'Unknown feature' m: oz(Feature))])}
            end
            if GV \= unit then
               {GV occ(Coord ?VO)}
            else
               {V occ(Coord ?VO)}
            end
         end
      end
      meth referUnchecked(PrintName Coord ?VO) V in
         BindingAnalysis, Refer(PrintName Coord @env ?V)
         {V occ(Coord ?VO)}
      end
      meth referExpansionOcc(PrintName Coord ?VO) V in
         BindingAnalysis, Refer(PrintName Coord @env ?V)
         case V of undeclared then
            VO = undeclared
         else
            {V occ(Coord ?VO)}
         end
      end
      meth Refer(PrintName Coord Env ?V)
         case Env of E|Er then X D#_#_ = E in
            X = {Dictionary.condGet D PrintName undeclared}
            case X of undeclared then
               BindingAnalysis, Refer(PrintName Coord Er ?V)
            else
               V = X
            end
         [] nil then
            {self.MyTopLevel lookupVariableInEnv(PrintName ?V)}
            case V of undeclared then skip
            else {Dictionary.put @freeVariablesOfQuery PrintName V}
            end
         end
      end
      meth generate(Origin Coord ?V) Env = @env D#Hd#Tl|Dr = Env NewTl in
         V = {New Core.generatedVariable init(Origin Coord)}
         Tl = V|NewTl
         env <- D#Hd#NewTl|Dr
      end
      meth generateForOuterScope(Origin Coord ?V)
         Env = @env E1|D#Hd#Tl|Dr = Env NewTl in
         %% This method is provided to generate a variable that is not
         %% to be declared in the currently open scope, but in the scope
         %% surrounding it.
         V = {New Core.generatedVariable init(Origin Coord)}
         Tl = V|NewTl
         env <- E1|D#Hd#NewTl|Dr
      end
      meth isBoundLocally(PrintName $) Env = @env D#_#_|_ = Env in
         {Dictionary.member D PrintName}
      end
      meth getFreeVariablesOfQuery(?Vs)
         Vs = {Dictionary.items @freeVariablesOfQuery}
         freeVariablesOfQuery <- {NewDictionary}
      end
   end
end
