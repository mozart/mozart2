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
Wait       = {`Builtin` 'Value.wait'       1}
WaitOr     = {`Builtin` 'Value.waitOr'     2}
IsFree     = {`Builtin` 'Value.isFree'     2}
IsKinded   = {`Builtin` 'Value.isKinded'   2}
IsDet      = {`Builtin` 'Value.isDet'      2}
Max        = {`Builtin` 'Value.max'        3}
Min        = {`Builtin` 'Value.min'        3}
CondSelect = {`Builtin` 'Value.condSelect' 4}
HasFeature = {`Builtin` 'Value.hasFeature' 3}
ByNeed     = {`Builtin` 'Value.byNeed'     2}


%%
%% Run time library
%%
{`runTimePut` '.' {`Builtin` 'Record.\'.\''   3}}
{`runTimePut` '==' {`Builtin` 'Value.\'==\''  3}}
{`runTimePut` '=' {`Builtin` 'Value.\'=\''   2}}
{`runTimePut` '\\=' {`Builtin` 'Value.\'\\=\'' 3}}
{`runTimePut` '<' {`Builtin` 'Value.\'<\''   3}}
{`runTimePut` '=<' {`Builtin` 'Value.\'=<\''  3}}
{`runTimePut` '>=' {`Builtin` 'Value.\'>=\''  3}}
{`runTimePut` '>' {`Builtin` 'Value.\'>\''   3}}
{`runTimePut` 'hasFeature' HasFeature}
{`runTimePut` 'byNeed' ByNeed}
{`runTimePut` '!!' {`Builtin` 'Value.future' 2}}

%%
%% Module
%%

Value = value(wait:       Wait
              waitOr:     WaitOr

              '=<':       {`Builtin` 'Value.\'=<\''  3}
              '<':        {`Builtin` 'Value.\'<\''   3}
              '>=':       {`Builtin` 'Value.\'>=\''  3}
              '>':        {`Builtin` 'Value.\'>\''   3}
              '==':       {`Builtin` 'Value.\'==\''  3}
              '=':        {`Builtin` 'Value.\'=\''   2}
              '\\=':      {`Builtin` 'Value.\'\\=\'' 3}
              max:        Max
              min:        Min

              '.':        {`Builtin` 'Record.\'.\''   3}
              hasFeature: HasFeature
              condSelect: CondSelect

              isFree:     IsFree
              isKinded:   IsKinded
              isDet:      IsDet
              status:     {`Builtin` 'Value.status' 2}
              type:       {`Builtin` 'Value.type'   2}
              byNeed:     ByNeed
             )
