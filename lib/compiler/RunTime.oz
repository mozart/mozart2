%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   local
      RaiseDebugCheck = Boot_Exception.raiseDebugCheck

      local
         ThreadTaskStack = Boot_Exception.taskStackError
         ThreadLocation  = Boot_Exception.location
      in
         proc {RaiseDebugExtend T1 T2}
            L = {Label T1.debug}
         in
            {Raise {AdjoinAt T1 debug
                    {Adjoin T1.debug
                     L(stack: {ThreadTaskStack}
                       loc:   {ThreadLocation}
                       info:  T2)}}}
         end
      end

      local
         proc {DescendArity Ls1 Ls2}
            case Ls1 of nil then skip
            [] L1|Lr1 then
               case Ls2 of L2|Lr2 then
                  case L1 == L2 then {DescendArity Lr1 Lr2}
                  else {DescendArity Ls1 Lr2}
                  end
               else
                  {Exception.raiseError object(arityMismatchDefaultMethod L1)}
               end
            end
         end
      in
         proc {AritySublist R1 R2}
            {DescendArity {Arity R1} {Arity R2}}
         end
      end

      local
         proc {Match Xs I T}
            case Xs of nil then skip
            [] X|Xr then
               T.I = X
               {Match Xr I + 1 T}
            end
         end
      in
         proc {DoTuple L Xs I T}
            T = {MakeTuple L I}
            {Match Xs 1 T}
         end
      end
   in
      ProcValues = env(%% Value
                       '.': Value.'.'
                       '==': Value.'=='
                       '=': Value.'='
                       '\\=': Value.'\\='
                       '<': Value.'<'
                       '=<': Value.'=<'
                       '>=': Value.'>='
                       '>': Value.'>'
                       'hasFeature': HasFeature
                       'byNeed': ByNeed
                       '!!': Boot_Value.future
                       %% Int
                       'div': Int.'div'
                       'mod': Int.'mod'
                       %% Float
                       '/': Float.'/'
                       %% Number
                       '+': Number.'+'
                       '-': Number.'-'
                       '*': Number.'*'
                       '~': Number.'~'
                       %% Tuple
                       'tuple': DoTuple
                       %% Record
                       'record': List.toRecord
                       'width': Width
                       '^': Record.'^'
                       'tellRecordSize': Boot_Record.tellRecordSize
                       %% Object
                       'ooPrivate': NewName
                       '@': Object.'@'
                       '<-': Object.'<-'
                       'ooExch': Boot_Object.ooExch
                       ',': Object.','
                       'ooGetLock': Boot_Object.ooGetLock
                       'class': Object.'class'
                       'aritySublist': AritySublist
                       %% Exception
                       'Raise': Raise
                       'RaiseError': Exception.raiseError
                       'RaiseDebugCheck': RaiseDebugCheck
                       'RaiseDebugExtend': RaiseDebugExtend
                       %% Functor
                       'NewFunctor': Functor.new)
   end

   NewUniqueName = Boot_Name.newUnique

   LiteralValues = env('true': `true`
                       'false': `false`
                       'unit': `unit`
                       'ooDefaultVar': {NewUniqueName 'ooDefaultVar'}
                       'ooFreeFlag': {NewUniqueName 'ooFreeFlag'}
                       'ooRequiredArg': {NewUniqueName 'ooRequiredArg'})

   TokenValues = env('true': `true`
                     'false': `false`)
in
   functor prop once
   import
      Module(manager)
      Core(nameToken variable)
   export
      Literals
      Tokens
      Procs
      ProcValues
   define
      fun {ApplyFunctor FileName F}
         ModMan = {New Module.manager init()}
      in
         {ModMan apply(url: FileName F $)}
      end

      Literals = LiteralValues
      Tokens = {Record.mapInd TokenValues
                fun {$ X Value}
                   {New Core.nameToken init(Value true)}
                end}
      Procs = {Record.mapInd
               {AdjoinAt ProcValues 'ApplyFunctor' ApplyFunctor}
               proc {$ X Value ?V} PrintName in
                  PrintName = {VirtualString.toAtom '`'#X#'`'}
                  V = {New Core.variable init(PrintName runTimeLibrary unit)}
                  {V valToSubst(Value)}
                  {V setUse(multiple)}
                  {V reg(~1)}
               end}
   end
end
