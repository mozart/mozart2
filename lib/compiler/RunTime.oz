%%%
%%% Author:
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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

functor
import
   Module(manager)
   Core(valueNode userVariable)
   Combinator('not' 'cond' 'or' 'dis')
   Space('choose')
   RecordC('^' tellSize)
   FD(int dom sum sumC sumCN reified)
export
   Literals
   Tokens
   Procs
   ProcValues
   MakeVar
require
   BootRecord(test testLabel testFeature aritySublist)
   at 'x-oz://boot/Record'

   BootObject(ooGetLock ',' '@' '<-' ooExch)
   at 'x-oz://boot/Object'

   BootException('fail' raiseError:RaiseError)
   at 'x-oz://boot/Exception'

   BootThread(create)
   at 'x-oz://boot/Thread'

   BootName(newUnique: NewUniqueName)
   at 'x-oz://boot/Name'

   BootValue(dotAssign dotExchange catAccess catAssign catExchange catAccessOO catAssignOO catExchangeOO) at 'x-oz://boot/Value'
prepare
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
                     'Value.byNeedDot': Value.byNeedDot
                     'Value.byNeed': Value.byNeed

                     %% Name
                     'Name.new': Name.new

                     %% Cell
                     'Cell.exchange': Exchange
                     'Cell.new': NewCell

                     %% List
                     'List.toTuple': List.toTuple
                     'List.toRecord': List.toRecord
                     'List.append': Append

                     %% Record
                     'Record.width': Record.width
                     'Record.test': BootRecord.test
                     'Record.testLabel': BootRecord.testLabel
                     'Record.testFeature': BootRecord.testFeature

                     %% Object
                     'Object.\'@\'': BootObject.'@'
                     'Object.\'<-\'': BootObject.'<-'
                     'Object.exchange': BootObject.ooExch
                     'Object.\',\'': BootObject.','
                     'Object.\'class\'': OoExtensions.'class'

                     %% Thread

                     %% Exception
                     'Exception.\'raise\'': Exception.'raise'
                     'Exception.raiseError': Exception.raiseError
                     'Exception.\'fail\'': BootException.'fail'

                     %% Functor
                     'Functor.new': Functor.new

                     %% Internal
                     'ooGetLock': BootObject.ooGetLock
                     'aritySublist': BootRecord.aritySublist
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
         'For.retlist'       : RetList)
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
                     'FD.reified.sumCN': FDReifiedSumCN)}

   Procs = {Record.mapInd ProcValues MakeVar}
end
