%%%
%%% Authors:
%%%   Konstantin Popov
%%%
%%% Copyright:
%%%   Konstantin Popov, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

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
fun {IntToAtom I}
   {String.toAtom {Int.toString I}}
end

%%
%% These are non-monotonic tests, that is, they never suspend.
%% Since we don't have job...end anymore, they actually must present
%% somewhere and somehow in Oz Kernel(?);
IsVar =        fun {$ X} {Value.isDet X} == false end
IsFdVar =      FDB.isVarB
IsRecordCVar = BrowserSupport.isRecordCVar

%%
%% Yields 'true' if a record given has a label already. Never
%% suspends;
HasLabel = RecordC.hasLabel


EQ = {fun {$ X} X end System.eq}

%%
%% it takes three arguments - a term, depth and width has to be
%% walked through;
fun {TermSize X Depth Width}
   {VirtualString.length {Value.toVirtualString X Depth Width}}
end

%%
%% Its argument is a term. It bounds its second argument to 'true'
%% when the first one gets ever touched. *It never suspends*.
%% It is useful for three purposes:
%% a) subsumes 'Det'
%% b) fires when the name of a variable is changed;
%% c) fires when a variable becomes an fd-variable or some other
%%    'kindof' variable;
GetsTouched = BrowserSupport.getsBoundB

%%
%% Yield arity/width of a chunk, suspend on variables,
%% or rise type errors;

local
   BSCW = BrowserSupport.chunkWidth
in
   fun {ChunkHasFeatures Chunk}
      {BSCW Chunk}>0
   end
   ChunkArity = BrowserSupport.chunkArity
end

%%
AddrOf = BrowserSupport.addr
ProcLoc = BrowserSupport.procLoc

%%
OnToplevel = System.onToplevel

%%
FSetGetGlb  = FSB.'reflect.lowerBound'
FSetGetLub  = FSB.'reflect.upperBound'
FSetGetCard = FSB.'reflect.card'
IsFSetVar   = FSB.'var.is'

%%
GetCtVarNameAsAtom       = CTB.getNameAsAtom
GetCtVarConstraintAsAtom = CTB.getConstraintAsAtom
IsCtVar                  = CTB.isB
