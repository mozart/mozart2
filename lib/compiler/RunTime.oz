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

   BootException('fail')
   at 'x-oz://boot/Exception'

   BootThread(create)
   at 'x-oz://boot/Thread'

   BootName(newUnique: NewUniqueName)
   at 'x-oz://boot/Name'
prepare
   ProcValues0 = env(%% Operators
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

   ProcValues = {Adjoin ProcValues0
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
                     'Space.choose': SpaceChoose)}

   Procs = {Record.mapInd ProcValues MakeVar}
end
