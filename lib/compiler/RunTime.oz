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
   Combinator('cond' 'or' 'dis')
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

                     %% List
                     'List.toTuple': List.toTuple
                     'List.toRecord': List.toRecord

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

   proc {SpaceChoose X Y}
      {Space.choose X Y}
   end

   ProcValues = {Adjoin ProcValues0
                 env(%% Operators
                     '^': RecordC.'^'
                     'RecordC.tellSize': RecordC.tellSize

                     %% Functor
                     'ApplyFunctor': ApplyFunctor

                     %% Combinators
                     'Combinator.\'cond\'': Combinator.'cond'
                     'Combinator.\'or\'': Combinator.'or'
                     'Combinator.\'dis\'': Combinator.'dis'

                     %% Space
                     %'Space.choose': Space.choose   %--** doesn't work!
                     'Space.choose': SpaceChoose)}

   Procs = {Record.mapInd ProcValues MakeVar}
end
