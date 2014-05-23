%%% Copyright © 2011-2014, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice,
%%% this list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor
import
   Module(manager)
   Core(valueNode userVariable)
   Combinator('not' 'cond' 'or' 'dis')
   Space('choose')
   RecordC('^' tellSize)
   \ifdef HAS_CSS
   FD(int dom sum sumC sumCN reified)
   \endif
export
   Literals
   Tokens
   Procs
   ProcValues
   MakeVar
require
   BootRecord(test testLabel testFeature /*aritySublist*/)
   at 'x-oz://boot/Record'

   BootObject(attrGet attrPut attrExchangeFun)
   at 'x-oz://boot/Object'

   BootException('fail' raiseError:RaiseError)
   at 'x-oz://boot/Exception'

   BootThread(create)
   at 'x-oz://boot/Thread'

   BootName(newUnique: NewUniqueName)
   at 'x-oz://boot/Name'

   BootValue(dotAssign dotExchange
             catAccess catAssign catExchange
             catAccessOO catAssignOO catExchangeOO) at 'x-oz://boot/Value'
prepare
   % Emulation of weird things in BootRecord for now
   local
      fun {SortedSubList Xs Ys}
         case Xs#Ys
         of nil#_ then
            true
         [] (X|Xr)#(Y|Yr) then
            if X == Y then
               {SortedSubList Xr Yr}
            else
               {SortedSubList Xs Yr}
            end
         else
            false
         end
      end
   in
      fun {AritySubList X Y}
         {SortedSubList {Arity X} {Arity Y}}
      end
   end

   fun {BootRecord_test Val Lab Feats}
      {BootRecord.test Val Lab {List.toTuple '#' Feats}}
   end

   local
      `ooFallback` = {NewUniqueName ooFallback}
   in
      proc {`Object.','` Obj Class Message}
         {Class.`ooFallback`.apply Message Obj Class}
      end
   end

   proc {RecordWaitNeededFirst Rec}
      NeededWatch
   in
      {Record.forAll Rec
       proc {$ Val}
          thread
             {WaitNeeded Val}
             NeededWatch = unit
          end
       end}
      {Wait NeededWatch}
   end

   ProcValues0 = env(%% Operators
                     '.': Value.'.'
                     dotAssign: BootValue.dotAssign
                     dotExchange: BootValue.dotExchange
                     catAccess: BootValue.catAccess
                     catAssign: BootValue.catAssign
                     catExchange: BootValue.catExchange
                     catAccessOO: BootValue.catAccessOO
                     catAssignOO: BootValue.catAssignOO
                     catExchangeOO: BootValue.catExchangeOO
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

                     %% Value
                     'Value.byNeed': Value.byNeed
                     'Value.byNeedDot': Value.byNeedDot
                     'Value.byNeedFuture': Value.byNeedFuture

                     %% Name
                     'Name.new': Name.new

                     %% Cell
                     'Cell.exchange': Exchange
                     'Cell.new': NewCell

                     %% Lock
                     'Lock.\'lock\'': LockIn

                     %% List
                     'List.toTuple': List.toTuple
                     'List.toRecord': List.toRecord
                     'List.append': Append

                     %% Record
                     'Record.width': Record.width
                     'Record.waitNeededFirst': RecordWaitNeededFirst
                     'Record.test': BootRecord_test
                     'Record.testLabel': BootRecord.testLabel
                     'Record.testFeature': BootRecord.testFeature

                     %% Object
                     'Object.\'@\'': BootObject.attrGet
                     'Object.\'<-\'': BootObject.attrPut
                     'Object.exchange': BootObject.attrExchangeFun
                     'Object.\'class\'': OoExtensions.'class'
                     'Object.\',\'': `Object.','`

                     %% Thread

                     %% Exception
                     'Exception.\'raise\'': Exception.'raise'
                     'Exception.raiseError': Exception.raiseError
                     'Exception.\'fail\'': BootException.'fail'

                     %% Functor
                     'Functor.new': Functor.new

                     %% Internal
                     'ooGetLock': OoExtensions.getObjLock
                     'aritySublist': AritySubList % BootRecord.aritySublist
                     'Thread.create': BootThread.create)

   LiteralValues = env('ooDefaultVar': {NewUniqueName 'ooDefaultVar'}
                       'ooFreeFlag': {NewUniqueName 'ooFreeFlag'}
                       'ooRequiredArg': {NewUniqueName 'ooRequiredArg'})

   TokenValues = env('true': true
                     'false': false)

   %% For loop support
   local
      NONE={NewName}
      fun {MkOptimize} {NewCell NONE} end
      fun {MkCount} {NewCell 0} end

      %% Note that this new impl. for list accumulators has
      %% a pleasant effect on both memory and speed.  See cvs log
      %% msg. for details
      %%
      %% First cell contains the head of list, Second
      %% cell contains current unbound var at tail of list.
      fun {MkList} L in {NewCell L} | {NewCell L} end
      MkSum=MkCount
      fun {MkMultiply} {NewCell 1} end
      proc {Maximize C N} Old New in
         {Exchange C Old New}
         if Old==NONE orelse N>Old then New=N else New=Old end
      end
      proc {Minimize C N} Old New in
         {Exchange C Old New}
         if Old==NONE orelse N<Old then New=N  else New=Old end
      end
      proc {Count C B}
         if B then Old New in
            {Exchange C Old New}
            New=Old+1
         end
      end
      proc {Sum C N} Old New in
         {Exchange C Old New}
         New=Old+N
      end
      proc {Multiply C N} Old New in
         {Exchange C Old New}
         New=Old*N
      end
      %% Bind element to tail, and create new unbound tail var
      proc {Collect C X} Tail in
         {Exchange C.2 X|Tail Tail}
      end
      proc {Postpend C X} Tail in
         {Exchange C.2 {Append X Tail} Tail}
      end
      proc {Prepend C X} Head in
         {Exchange C.1 Head {Append X Head}}
      end
      fun {RetIntDefault C D} V in
         {Exchange C V unit}
         if V==NONE then D else V end
      end
      fun {RetInt C} V in
         {Exchange C V unit}
         if V==NONE
         then {RaiseError 'for'(noDefaultValue)} unit
         else V end
      end
      fun {RetList C}
         {Exchange C.2 nil unit}
         {Access C.1}
      end
      proc {RetYield C}
         %{BindReadOnly {Access C} nil}
         {Access C} = nil
      end
      proc {Yield C X}
         O
         N%={NewReadOnly}
      in
         {Exchange C O N}
         %{BindReadOnly O X|N}
         O = X|N
         {WaitNeeded N}
      end
      proc {MkYield C L}
         %{NewReadOnly L}
         {NewCell L C}
         {WaitNeeded L}
      end
      proc {YieldAppend C L}
         case L
         of nil then skip
         [] H|T then {Yield C H} {YieldAppend C T}
         end
      end
   in
      ProcValuesFor =
      env(
         'For.mkoptimize'    : MkOptimize
         'For.mkcount'       : MkCount
         'For.mklist'        : MkList
         'For.mksum'         : MkSum
         'For.mkmultiply'    : MkMultiply
         'For.maximize'      : Maximize
         'For.minimize'      : Minimize
         'For.count'         : Count
         'For.sum'           : Sum
         'For.multiply'      : Multiply
         'For.collect'       : Collect
         'For.append'        : Postpend
         'For.prepend'       : Prepend
         'For.retintdefault' : RetIntDefault
         'For.retint'        : RetInt
         'For.retlist'       : RetList
         'For.retyield'      : RetYield
         'For.yield'         : Yield
         'For.yieldAppend'   : YieldAppend
         'For.mkyield'       : MkYield
         )
   end
   ProcValuesAll = {Adjoin ProcValues0 ProcValuesFor}
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

   proc {MakeVar X Value ?V} PrintName in
      PrintName = {VirtualString.toAtom '`'#X#'`'}
      V = {New Core.userVariable init(PrintName unit)}
      {V valToSubst(Value)}
      {V setUse(multiple)}
      {V reg(~1)}
   end

   %--** The following built-in procedures should not need wrappers.
   %--** Unfortunately, code generation crashes if we omit them.

   proc {`RecordC.'^'` A B C}
      {RecordC.'^' A B C}
   end

   proc {RecordCTellSize A B C}
      {RecordC.tellSize A B C}
   end

   proc {CombinatorNot P}
      {Combinator.'not' P}
   end

   proc {CombinatorCond A B}
      {Combinator.'cond' A B}
   end

   proc {CombinatorOr A}
      {Combinator.'or' A}
   end

   proc {CombinatorDis A}
      {Combinator.'dis' A}
   end

   proc {SpaceChoose X Y}
      {Space.choose X Y}
   end

\ifdef HAS_CSS
   proc {FDInt A B}
      {FD.int A B}
   end

   proc {FDDom A B}
      {FD.dom A B}
   end

   proc {FDSum X O D}
      {FD.sum X O D}
   end

   proc {FDSumC A X O D}
      {FD.sumC A X O D}
   end

   proc {FDSumCN A X O D}
      {FD.sumCN A X O D}
   end

   fun {FDReifiedInt A B}
      {FD.reified.int A B}
   end

   fun {FDReifiedDom A B}
      {FD.reified.dom A B}
   end

   fun {FDReifiedSum X O D}
      {FD.reified.sum X O D}
   end

   fun {FDReifiedSumC A X O D}
      {FD.reified.sumC A X O D}
   end

   fun {FDReifiedSumCN A X O D}
      {FD.reified.sumCN A X O D}
   end
\endif

   ProcValues = {Adjoin ProcValuesAll
                 env(%% RecordC
                     'RecordC.\'^\'': `RecordC.'^'`
                     'RecordC.tellSize': RecordCTellSize

                     %% Functor
                     'ApplyFunctor': ApplyFunctor

                     %% Combinator
                     'Combinator.\'not\'': CombinatorNot
                     'Combinator.\'cond\'': CombinatorCond
                     'Combinator.\'or\'': CombinatorOr
                     'Combinator.\'dis\'': CombinatorDis

                     %% Space
                     'Space.choose': SpaceChoose

                     \ifdef HAS_CSS
                     %% FD
                     'FD.int': FDInt
                     'FD.dom': FDDom
                     'FD.sum': FDSum
                     'FD.sumC': FDSumC
                     'FD.sumCN': FDSumCN
                     'FD.reified.int': FDReifiedInt
                     'FD.reified.dom': FDReifiedDom
                     'FD.reified.sum': FDReifiedSum
                     'FD.reified.sumC': FDReifiedSumC
                     'FD.reified.sumCN': FDReifiedSumCN
                     \endif
                    )}

   Procs = {Record.mapInd ProcValues MakeVar}
end
