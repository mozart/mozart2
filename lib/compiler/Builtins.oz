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
%%    noBuiltin
%%       if A does not denote a known builtin.
%%
%%    builtin(types: [procedure] det: [procedure]...)
%%       if A denotes a known builtin with argument types as given.
%%       The following features may or may not be contained in the
%%       record, as appropriate:
%%
%%          inlineFun: B
%%             if this feature is present and B is true, than A may
%%             be called using one the `inlineFun...' instructions.
%%             This feature cannot be present at the same time as
%%             an inlineRel feature.
%%          eqeq: B
%%             if this feature is present and B is true, then A must
%%             be called using the `inlineEqEq' instruction.
%%             The inlineFun feature must be present and true.
%%          inlineRel: B
%%             if this feature is present and B is true, than A may
%%             be called using one the `inlineRel...' instructions.
%%             This feature cannot be present at the same time as
%%             an inlineFun feature.
%%          rel: A2
%%             if this feature is present, then A2 is the name of
%%             another builtin that may be used in a shallowTest
%%             instruction instead of this builtin.
%%          doesNotReturn: B
%%             if this feature is present and B is true, then any
%%             statement following the call to A is not executed.
%%          destroysArguments: B
%%             if this feature is present and B is true, then after
%%             the builtin application the contents of the argument
%%             registers is not guaranteed.
%%
%% This function really should be a builtin itself so that it becomes
%% easier to keep this information up-to-date when the emulator is
%% modified.
%%

local
   BuiltinTable = builtinTable(
                               \insert compiler-Builtins.oz
                              )
in
   %%
   %% Do some consistency checks on the builtin table
   %%

   {Record.forAllInd BuiltinTable
    proc {$ Name Entry}
       try
          case {HasFeature Entry types} andthen {HasFeature Entry det} then
             case {Length Entry.types} == {Length Entry.det}
             then skip
             else raise bad(1) end
             end
          else raise bad(2) end
          end
          case {HasFeature Entry inlineFun} then
             case {HasFeature Entry eqeq} then
                case {IsBool Entry.eqeq} then skip
                else raise bad(3) end
                end
             else skip
             end
             case {HasFeature Entry inlineRel} then raise bad(4) end
             elsecase {IsBool Entry.inlineFun} then skip
             else raise bad(5) end
             end
          elsecase {HasFeature Entry eqeq} then raise bad(6) end
          elsecase {HasFeature Entry inlineRel} then
             case {IsBool Entry.inlineRel} then skip
             else raise bad(7) end
             end
          else skip
          end
          case {HasFeature Entry rel} then
             case {HasFeature Entry inlineFun} then
                case {HasFeature BuiltinTable Entry.rel} then
                   case {Length Entry.types} - 1 ==
                      {Length (BuiltinTable.(Entry.rel)).types} then skip
                   else raise bad(8) end
                   end
                else raise bad(9) end
                end
             else raise bad(10) end
             end
          else skip
          end
          case {HasFeature Entry doesNotReturn} then
             case {IsBool Entry.doesNotReturn} then skip
             else raise bad(11) end
             end
          else skip
          end
       catch bad(N) then
          {System.showError 'bad ('#N#') BuiltinTable entry for \''#Name#'\''}
       end
    end}

   %%
   %% Accessing the Builtin Table
   %%

   fun {GetBuiltinInfo Name}
      {CondSelect BuiltinTable Name noInformation}
   end
end
