%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  (Oz)Machine-specific things like extra builtins, etc.
%%%
%%%
%%%

%%
IntToAtom = {`Builtin` 'intToAtom'
             fun {$ I}
                case {IsInt I}
                then {IntToAtom I}
                end
             end}

%%
RealArity = {`Builtin` trueArity noHandler}

%%
%%  (of course, non-monotonic operations;)
IsVar = {`Builtin` 'isVarB' noHandler}
IsFdVar = {`Builtin` 'fdIsVar' noHandler}           % logical;
IsRecordCVar = {`Builtin` 'recordCIsVar' noHandler} % logical;
IsMetaVar = {`Builtin` 'metaIsVar' noHandler}       % logical;

%%
%%  first argument is a FD variable, and second - reference cardinality;
WatchDomain = {`Builtin` fdWatchDom1 noHandler}

%%
%%  first argument is a meta variable, and second - reference strength;
WatchMetaVar = {`Builtin` metaWatchVar noHandler}

%%
%%  first argument is a meta variable, and second - constraint data;
MetaGetDataAsAtom = {`Builtin` metaGetDataAsAtom noHandler}

%%
%%  first argument is a meta variable, and second - name of constraint system;
MetaGetNameAsAtom = {`Builtin` metaGetNameAsAtom noHandler}

%%
%%  first argument is a meta variable, and second - strength of current cnstr;
MetaGetStrength = {`Builtin` metaGetStrength noHandler}

%%
%%  Equality on terms using their physical location (pointers);
EQ = {`Builtin` eqB noHandler}

%% X is an undetermined record, F is a literal.  Do an immediate test whether
%% X has the feature F.  Gives a type error if X or F is of wrong type.
%% No suspensions are ever created.
TestC = {`Builtin` 'testCB' noHandler}

%%
%%  single argument is a term; suspends till this variable is bound to something;
%%  Useful for three reasons:
%%  a) subsumes the 'IsValue'
%%  b) fires when the name of a variable is changed;
%%  c) fires when a variable becomes fd-variable;
GetsBound = {`Builtin` getsBound noHandler}

%%
DeepFeed = {`Builtin` deepFeed proc {$ C X}
                                  case {Det C} then {DeepFeed C X}
                                  else true
                                  end
                               end}

%%
GenericSet = {`Builtin`
              genericSet
              proc {$ X Y Z}
                 case {Det X} andthen {Det Y} then {GenericSet X Y Z} end
              end}

%%
local
   ProperWidth ProcZeroWidth CellZeroWidth
in
   ProperWidth = {`Builtin` 'width'         noHandler}
   %%
   ProcZeroWidth = {ProperWidth proc{$} true end}
   CellZeroWidth = {ProperWidth {NewCell _ $}}
   %%
   Width = fun {$ X}
              {ProperWidth X} - case {Value.type X}
                                of procedure then ProcZeroWidth
                                [] cell then CellZeroWidth
                                else 0
                                end
           end
end
