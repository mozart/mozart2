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

%%
%% Module
%%

Value = value(wait:            Wait
              waitOr:          WaitOr

              '=<':            Boot_Value.'=<'
              '<':             Boot_Value.'<'
              '>=':            Boot_Value.'>='
              '>':             Boot_Value.'>'
              '==':            Boot_Value.'=='
              '=':             Boot_Value.'='
              '\\=':           Boot_Value.'\\='
              max:             Max
              min:             Min

              '.':             Boot_Value.'.'
              hasFeature:      HasFeature
              condSelect:      CondSelect

              isFree:          IsFree
              isKinded:        IsKinded
              isDet:           IsDet
              status:          Boot_Value.status
              type:            Boot_Value.type

              '!!':            Boot_Value.'!!'
              byNeed:          ByNeed

              toVirtualString: Boot_Value.toVirtualString
             )
