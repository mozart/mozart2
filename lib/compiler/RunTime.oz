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
   NewUniqueName = {`Builtin` 'NewUniqueName' 2}

   LiteralValues = env('true': true
                       'false': false
                       'unit': unit
                       'ooDefaultVar': {NewUniqueName 'ooDefaultVar'}
                       'ooFreeFlag': {NewUniqueName 'ooFreeFlag'}
                       'ooRequiredArg': {NewUniqueName 'ooRequiredArg'})

   TokenValues = env('true': true
                     'false': false)
in
   functor prop once
   import
      Module(manager)
      RunTimeLibrary
      Core(nameToken variable)
   export
      Literals
      Tokens
      Procs
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
               {AdjoinAt RunTimeLibrary 'ApplyFunctor' ApplyFunctor}
               proc {$ X Value ?V} PrintName in
                  PrintName = {VirtualString.toAtom '`'#X#'`'}
                  V = {New Core.variable init(PrintName runTimeLibrary unit)}
                  {V valToSubst(Value)}
                  {V setUse(multiple)}
                  {V reg(~1)}
               end}
   end
end
