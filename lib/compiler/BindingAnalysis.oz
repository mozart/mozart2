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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   BindingAnalysisError = 'binding analysis error'

   fun {IsDeclared Env PrintName}
      case Env of E|Er then
         {Dictionary.member E.1 PrintName} orelse {IsDeclared Er PrintName}
      [] nil then false
      end
   end

   fun {Generate Env TopLevel Origin N} PrintName in
      PrintName = {ConcatenateAtomAndInt Origin N}
      case {IsDeclared Env PrintName}
         orelse {TopLevel lookupVariableInEnv(PrintName $)} \= undeclared
      then
         {Generate Env TopLevel Origin N + 1}
      else
         {Dictionary.put Env.1.2 Origin N + 1}
         PrintName
      end
   end
in
   class BindingAnalysis
      prop final
      attr env: nil freeVariablesOfQuery: unit
      feat MyTopLevel MyReporter
      meth init(TopLevel Reporter)
         env <- nil
         freeVariablesOfQuery <- {NewDictionary}
         self.MyTopLevel = TopLevel
         self.MyReporter = Reporter
      end
      meth openScope() Env = @env X in
         case Env of E|_ then
            env <- ({NewDictionary}#{Dictionary.clone E.2}#X#X)|Env
         else
            env <- [{NewDictionary}#{NewDictionary}#X#X]
         end
      end
      meth getVars(?Vs) E = @env.1 in
         _#_#Vs#nil = E
      end
      meth getAllVariables($)
         {Record.foldR
          {FoldR @env
           fun {$ D#_#_#_ Vs0}
              {Adjoin Vs0 {Dictionary.toRecord x D}}
           end x}
          fun {$ X In}
             X|In
          end nil}
      end
      meth closeScope(?Vs) Dr Env = @env in
         (_#_#Vs#nil)|Dr = Env
         env <- Dr
      end
      meth bind(PrintName Coord ?V) X Env = @env (D#G#Hd#Tl)|Dr = Env in
         X = {Dictionary.condGet D PrintName undeclared}
         case X == undeclared then NewTl in
            V = {New Core.variable init(PrintName user Coord)}
            {Dictionary.put D PrintName V}
            Tl = V|NewTl
            env <- (D#G#Hd#NewTl)|Dr
         else
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
            {V occ(Coord ?VO)}
         end
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
         case Env of E|Er then X D#_#_#_ = E in
            X = {Dictionary.condGet D PrintName undeclared}
            case X == undeclared then
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
      meth generate(Origin Coord ?V)
         Env = @env (D#G#Hd#Tl)|Dr = Env N PrintName NewTl in
         N = {Dictionary.condGet G Origin 1}
         PrintName = {Generate Env self.MyTopLevel Origin N}
         V = {New Core.variable init(PrintName generated Coord)}
         {Dictionary.put D PrintName V}
         Tl = V|NewTl
         env <- (D#G#Hd#NewTl)|Dr
      end
      meth generateForOuterScope(Origin Coord ?V)
         Env = @env E1|(D#G#Hd#Tl)|Dr = Env N PrintName NewTl in
         % This method is provided to generate a variable that is not
         % to be declared in the currently open scope, but in the scope
         % surrounding it.
         N = {Dictionary.condGet G Origin 1}
         PrintName = {Generate Env self.MyTopLevel Origin N}
         V = {New Core.variable init(PrintName generated Coord)}
         {Dictionary.put D PrintName V}
         Tl = V|NewTl
         env <- E1|(D#G#Hd#NewTl)|Dr
      end
      meth getFreeVariablesOfQuery(?Vs)
         Vs = {Dictionary.items @freeVariablesOfQuery}
         freeVariablesOfQuery <- {NewDictionary}
      end
   end
end
