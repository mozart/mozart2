%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
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

%%
%% This defines a function `GetBuiltinInfo' that returns information
%% about the builtin with a given name A.  This information is either:
%%
%%    noInformation
%%       if A does not denote a known builtin.
%%
%%    builtin(types: [...] det: [...] imods: [bool] ...)
%%       if A denotes a known builtin with argument types and determinancy
%%       as given.  The following features may or may not be contained in
%%       the record, as appropriate:
%%
%%          imods: [bool]
%%             for each input argument for which this list has a `true',
%%             no assumptions may be made about the contents of the
%%             corresponding register after the builtin application.
%%          test: B
%%             if this feature is present and B is true, then this
%%             builtin may be used as argument to the testBI instruction.
%%          negated: A
%%             if this feature is present then A is the name of a builtin
%%             that returns the negated result from this builtin.
%%          doesNotReturn: B
%%             if this feature is present and B is true, then the
%%             instructions following the call to A are never executed
%%             unless branched to from elsewhere.
%%

local
   BuiltinTable = builtinTable(
                               \insert compiler-Builtins
                              )

   proc {E Name T}
      {Exception.raiseError compiler(badBuiltinTableEntry Name T)}
   end
in
   %%
   %% Do some consistency checks on the builtin table
   %%

   {Record.forAllInd BuiltinTable
    proc {$ Name Entry}
       case {HasFeature Entry types} andthen {IsList Entry.types} then skip
       else {E Name types}
       end
       case {HasFeature Entry det} andthen {IsList Entry.det} then skip
       else {E Name det}
       end
       case {Length Entry.types} == {Length Entry.det} then skip
       else {E Name typesdet}
       end
       case {Not {HasFeature Entry imods}} then skip
       elsecase {IsList Entry.imods} then skip
       elsecase {Length Entry.imods} =< Entry.iarity then skip
       else {E Name imods}
       end
       case {Not {HasFeature Entry test}} then skip
       elsecase {IsBool Entry.test} then skip
       else {E Name test}
       end
       case {HasFeature Entry negated} then NBI = Entry.negated in
          case {IsAtom NBI} then
             case {HasFeature Entry test} then
                case {HasFeature BuiltinTable NBI} then
                   case {HasFeature BuiltinTable.NBI test} then skip
                   else {E Name negatedNotTest2}
                   end
                else {E Name undefinedNegatedBuiltin}
                end
             else {E Name negatedNotTest}
             end
          else {E Name negated}
          end
       else skip
       end
       case {Not {HasFeature Entry doesNotReturn}} then skip
       elsecase {IsBool Entry.doesNotReturn} then skip
       else {E Name doesNotReturn}
       end
    end}

   %%
   %% Accessing the Builtin Table
   %%

   fun {GetBuiltinInfo Name}
      {CondSelect BuiltinTable Name noInformation}
   end
end
