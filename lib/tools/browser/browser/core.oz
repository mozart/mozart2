%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  (Oz)Machine-specific things like extra builtins, etc.
%%%
%%%
%%%

%%
%% ... to be used in 'reflect.oz' *only*;
IntToAtom = {`Builtin` 'intToAtom'
             fun {$ I} case {IsInt I} then {IntToAtom I} end end}

%%
%% These are non-monotonic tests, that is, they never suspend.
%% Since we don't have job...end anymore, they actually must present
%% somewhere and somehow in Oz Kernel(?);
IsVar =        fun {$ X} {Value.isDet X} == False end
IsFdVar =      {`Builtin` 'fdIsVarB' noHandler}
IsRecordCVar = {`Builtin` 'recordCIsVarB' noHandler}
IsMetaVar =    {`Builtin` 'metaIsVarB' noHandler}

%%
%% The first argument is a meta variable, and the second -
%% reference strength. Binds 'True' to the second argument when
%% *something* ("reference strength"?) changes. *It never suspends*.
%%
%% Ask Tobias (Mueller) for further details - that's his child. I
%% don't event know whether it's subsumed by 'GetsTouched'!
WatchMetaVar = {`Builtin` metaWatchVarB noHandler}

%%
%% The first argument is a meta variable, and the second -
%% constraint data;
MetaGetDataAsAtom = {`Builtin` metaGetDataAsAtom noHandler}

%%
%% The first argument is a meta variable, and the second -
%% name of constraint system;
MetaGetNameAsAtom = {`Builtin` metaGetNameAsAtom noHandler}

%%
%% The first argument is a meta variable, and the second -
%% strength of current cnstr;
MetaGetStrength = {`Builtin` metaGetStrength noHandler}

%%
%% Equality on terms using their physical location (pointers);
EQ = !System.eq


%%
%% it takes three arguments - a term, depth and width has to be
%% walked through;
TermSize = {`Builtin` 'getTermSize' noHandler}

%%
%% Its argument is a term. It bounds its second argument to 'True'
%% when the first one gets ever touched. *It never suspends*.
%% It is useful for three purposes:
%% a) subsumes 'Det'
%% b) fires when the name of a variable is changed;
%% c) fires when a variable becomes an fd-variable or some other
%%    'kindof' variable;
GetsTouched = {`Builtin` getsBoundB noHandler}

%%
DeepFeed =
{`Builtin` deepFeed proc {$ C X} {Wait C} {DeepFeed C X} end}

%%
%% Yield arity/width of a chunk, suspend on variables,
%% or rise type errors;
ChunkArity = {`Builtin` 'chunkArity' noHandler}
ChunkWidth = {`Builtin` 'chunkWidth' noHandler}

%%
AddrOf = {`Builtin` 'addr' noHandler}

%%
OnToplevel = {`Builtin` 'onToplevel' noHandler}
