%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare
   Value Wait WaitOr IsFree IsKinded IsDet Min Max CondSelect HasFeature
   ByNeed
in


%%
%% Global
%%
Wait       = {`Builtin` 'Wait'       1}
WaitOr     = {`Builtin` 'WaitOr'     2}
IsFree     = {`Builtin` 'IsFree'     2}
IsKinded   = {`Builtin` 'IsKinded'   2}
IsDet      = {`Builtin` 'IsDet'      2}
Max        = {`Builtin` 'Max'        3}
Min        = {`Builtin` 'Min'        3}
CondSelect = {`Builtin` 'CondSelect' 4}
HasFeature = {`Builtin` 'HasFeature' 3}
ByNeed     = {`Builtin` 'ByNeed'     2}


%%
%% Run time library
%%
{`runTimePut` '.' {`Builtin` '.'   3}}
{`runTimePut` '==' {`Builtin` '=='  3}}
{`runTimePut` '=' {`Builtin` '='   2}}
{`runTimePut` '\\=' {`Builtin` '\\=' 3}}
{`runTimePut` '<' {`Builtin` '<'   3}}
{`runTimePut` '=<' {`Builtin` '=<'  3}}
{`runTimePut` '>=' {`Builtin` '>='  3}}
{`runTimePut` '>' {`Builtin` '>'   3}}
{`runTimePut` 'hasFeature' HasFeature}
{`runTimePut` 'byNeed' ByNeed}
{`runTimePut` '!!' {`Builtin` 'Future' 2}}

%%
%% Module
%%

Value = value(wait:       Wait
              waitOr:     WaitOr

              '=<':       {`Builtin` '=<'  3}
              '<':        {`Builtin` '<'   3}
              '>=':       {`Builtin` '>='  3}
              '>':        {`Builtin` '>'   3}
              '==':       {`Builtin` '=='  3}
              '=':        {`Builtin` '='   2}
              '\\=':      {`Builtin` '\\=' 3}
              max:        Max
              min:        Min

              '.':        {`Builtin` '.'   3}
              hasFeature: HasFeature
              condSelect: CondSelect

              isFree:     IsFree
              isKinded:   IsKinded
              isDet:      IsDet
              status:     {`Builtin` 'Value.status' 2}
              type:       {`Builtin` 'Value.type'   2}
              byNeed:     ByNeed
             )
