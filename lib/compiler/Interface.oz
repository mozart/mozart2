%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
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
%% This file defines some operations on interface descriptions,
%% which are constructed as follows:
%%
%%    Interface = number(value: Number)
%%              | literal(value: Literal)
%%              | record(subtrees: Subtrees)
%%              | builtin(name: BuiltinName)
%%              | procedure(arity: Arity)
%%              | top.
%%
%%    Subtrees = [Feature#Interface].
%%    Feature = Int | Literal.
%%    PrintName = Atom.
%%    BuiltinName = Atom.
%%    Arity = Int.
%%

local
   % This constant states to what depth the interface description of
   % records should be computed.
   %--** this should correspond to the depth used in the static
   %--** analyzer in valToSubst!  valToSubst should not check for
   %--** cyclic structures but for a maximum depth instead.
   MaxDepth = 2

%   IsBuiltin = {`Builtin` 'isBuiltin' 2}
%   GetBuiltinName = {`Builtin` 'getBuiltinName' 2}

   fun {InterfaceOfValue X Depth}
      case Depth == 0 then
         top
      elsecase {Not {IsDet X}} then
         top
      elsecase {IsNumber X} then
         number(value: X)
      elsecase {IsLiteral X} then
         literal(value: X)
      elsecase {IsRecord X} then
         record(subtrees: {Map {Arity X}
                           fun {$ F} F#{InterfaceOfValue X.F Depth - 1} end})
      elsecase {IsBuiltin X} then
         builtin(name: {GetBuiltinName X})
      elsecase {IsProcedure X} then
         procedure(arity: {Procedure.arity X})
      else
         top
      end
   end

   fun {InterfaceCheck X I}
      case {Label I} of number then
         {IsDet X} andthen
         case {HasFeature I value} then X == I.value
         else {IsNumber X}
         end
      [] literal then
         {IsDet X} andthen
         case {HasFeature I value} then X == I.value
         else {IsLiteral X}
         end
      [] record then
         {IsRecordC X} andthen
         case {HasFeature I subtrees} then P As in
            {Record.monitorArity X P As} {P}
            {All I.subtrees
             fun {$ F#I0}
                {Member F As} andthen {InterfaceCheck X^F I0}
             end}
         else true
         end
      [] builtin then
         {IsDet X} andthen {IsBuiltin X} andthen
         case {HasFeature I name} then {GetBuiltinName X} == I.name
         else true
         end
      [] procedure then
         {IsDet X} andthen {IsProcedure X} andthen
         case {HasFeature I arity} then {Procedure.arity X} == I.arity
         else true
         end
      elseof top then true
      end
   end
in
   Interface = interface(ofValue: fun {$ X} {InterfaceOfValue X MaxDepth} end
                         check: InterfaceCheck)
end
