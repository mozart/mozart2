%%%
%%% Author:
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
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

functor
import
   Module(manager)
   Core(valueNode userVariable)
export
   Literals
   Tokens
   Procs
   ProcValues
require
   BootException(raiseDebugCheck: RaiseDebugCheck
                 taskStackError:  ThreadTaskStack
                 location:        ThreadLocation)
   at 'x-oz://boot/Exception'

   BootRecord(tellRecordSize test testLabel testFeature)
   at 'x-oz://boot/Record'

   BootObject(ooGetLock ',' '@' '<-' ooExch)
   at 'x-oz://boot/Object'

   BootName(newUnique: NewUniqueName)
   at 'x-oz://boot/Name'

   BootThread(create)
   at 'x-oz://boot/Thread'
prepare
   proc {RaiseDebugExtend T1 T2}
      L = {Label T1.debug}
   in
      {Raise {AdjoinAt T1 debug
              {Adjoin T1.debug
               L(stack: {ThreadTaskStack}
                 loc:   {ThreadLocation}
                 info:  T2)}}}
   end

   local
      proc {DescendArity Ls1 Ls2}
         case Ls1 of nil then skip
         [] L1|Lr1 then
            case Ls2 of L2|Lr2 then
               if L1 == L2 then {DescendArity Lr1 Lr2}
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

   ProcValues = env(%% Operators
                    '.': Value.'.'
                    '==': Value.'=='
                    '=': Value.'='
                    '\\=': Value.'\\='
                    '<': Value.'<'
                    '=<': Value.'=<'
                    '>=': Value.'>='
                    '>': Value.'>'
                    '!!': Value.'!!'
                    'div': Int.'div'
                    'mod': Int.'mod'
                    '/': Float.'/'
                    '+': Number.'+'
                    '-': Number.'-'
                    '*': Number.'*'
                    '~': Number.'~'
                    '^': Record.'^'

                    %% Value
                    'Value.byNeedDot': Value.byNeedDot
                    'Value.byNeed': Value.byNeed

                    %% Name
                    'Name.new': Name.new

                    %% List
                    'List.toTuple': List.toTuple
                    'List.toRecord': List.toRecord

                    %% Record
                    'Record.width': Record.width
                    'Record.test': BootRecord.test
                    'Record.testLabel':   BootRecord.testLabel
                    'Record.testFeature': BootRecord.testFeature

                    %% Object
                    'Object.\'@\'':     BootObject.'@'
                    'Object.\'<-\'':    BootObject.'<-'
                    'Object.exchange':  BootObject.ooExch
                    'Object.\',\'':     BootObject.','
                    'Object.\'class\'': OoExtensions.'class'

                    %% Thread

                    %% Exception
                    'Exception.\'raise\'': Exception.'raise'
                    'Exception.raiseError': Exception.raiseError

                    %% Functor
                    'Functor.new': Functor.new

                    %% Internal
                    'tellRecordSize': BootRecord.tellRecordSize
                    'ooGetLock': BootObject.ooGetLock
                    'aritySublist': AritySublist
                    'Thread.create': BootThread.create
                    'RaiseDebugCheck': RaiseDebugCheck
                    'RaiseDebugExtend': RaiseDebugExtend)

   LiteralValues = env('ooDefaultVar':  {NewUniqueName 'ooDefaultVar'}
                       'ooFreeFlag':    {NewUniqueName 'ooFreeFlag'}
                       'ooRequiredArg': {NewUniqueName 'ooRequiredArg'})

   TokenValues = env('true': true
                     'false': false)
define
   fun {ApplyFunctor FileName F}
      ModMan = {New Module.manager init()}
   in
      {ModMan apply(url: FileName F $)}
   end

   Literals = LiteralValues

   Tokens = {Record.mapInd TokenValues
             fun {$ X Value}
                {New Core.valueNode init(Value unit)}
             end}

   Procs = {Record.mapInd
            {AdjoinAt ProcValues 'ApplyFunctor' ApplyFunctor}
            proc {$ X Value ?V} PrintName in
               PrintName = {VirtualString.toAtom '`'#X#'`'}
               V = {New Core.userVariable init(PrintName unit)}
               {V valToSubst(Value)}
               {V setUse(multiple)}
               {V reg(~1)}
            end}
end
