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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   NewUniqueName = {`Builtin` 'NewUniqueName' 2}

   RaiseDebugCheck = {`Builtin` 'Exception.raiseDebugCheck' 2}

   local
      ThreadTaskStack = {`Builtin` 'Thread.taskStackError' 3}
      ThreadLocation  = {`Builtin` 'Thread.location'       2}
   in
      proc {RaiseDebugExtend T1 T2}
         L        = {Label T1.debug}
         This     = {Thread.this}
         Stack    = {ThreadTaskStack This false}
         Location = {ThreadLocation This}
      in
         {Raise {AdjoinAt
                 T1
                 debug
                 {Adjoin T1.debug
                  L(stack:Stack loc:Location info:T2)}}}
      end
   end

   local
      proc {DescendArity Ls1 Ls2}
         case Ls1 of nil then skip
         [] L1|Lr1 then
            case Ls2 of L2|Lr2 then
               case L1==L2 then {DescendArity Lr1 Lr2}
               else {DescendArity Ls1 Lr2}
               end
            else {Exception.raiseError object(arityMismatchDefaultMethod L1)}
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
         [] X|Xr then T.I=X {Match Xr I+1 T}
         end
      end
   in
      proc {DoTuple L Xs I T}
         T={MakeTuple L I} {Match Xs 1 T}
      end
   end
in
   LiteralValues = env('true': true
                       'false': false
                       'unit': unit
                       'ooDefaultVar': {NewUniqueName 'ooDefaultVar'}
                       'ooFreeFlag': {NewUniqueName 'ooFreeFlag'}
                       'ooRequiredArg': {NewUniqueName 'ooRequiredArg'})

   TokenValues = env('true': true
                     'false': false)

   ProcValues = env('=<': Value.'=<'
                    '<': Value.'<'
                    '>=': Value.'>='
                    '>': Value.'>'
                    '==': Value.'=='
                    '=': Value.'='
                    '\\=': Value.'\\='
                    '.': Value.'.'
                    'hasFeature': Value.hasFeature
                    'byNeed': Value.byNeed
                    '!!': {`Builtin` 'Future' 2}
                    '+': Number.'+'
                    '-': Number.'-'
                    '*': Number.'*'
                    '~': Number.'~'
                    '/': Float.'/'
                    'div': Int.'div'
                    'mod': Int.'mod'
                    '^': Record.'^'
                    'width': Record.width

                    ',': Object.','
                    '<-': Object.'<-'
                    '@': Object.'@'
                    'ooExch': {`Builtin` 'ooExch' 3}
                    'class': Object.'class'
                    'NewFunctor': Functor.new
                    'RaiseError': Exception.raiseError
                    'Raise': Exception.'raise'

                    'RaiseDebugCheck': RaiseDebugCheck
                    'RaiseDebugExtend': RaiseDebugExtend

                    'ooGetLock': {`Builtin` 'ooGetLock' 1}
                    'ooPrivate': NewName
                    'aritySublist': AritySublist

                    'record': {`Builtin` 'record' 3}
                    'tellRecordSize': {`Builtin` 'tellRecordSize' 3}
                    'tuple': DoTuple)
end
