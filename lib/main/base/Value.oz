%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% Module
%%
local
   fun {ByNeedDot X F}
      if {IsDet X} andthen {IsDet F}
      then try X.F catch E then {FailedValue E} end
      else {ByNeedFuture fun {$} X.F end}
      end
   end
in
   Value = value(wait:            Wait
                 waitQuiet:       WaitQuiet
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
                 isFuture:        IsFuture
                 isFailed:        IsFailed
                 isDet:           IsDet
                 status:          Boot_Value.status
                 type:            Boot_Value.type

                 isNeeded:        IsNeeded
                 waitNeeded:      WaitNeeded
                 makeNeeded:      MakeNeeded
                 byNeed:          ByNeed
                 byNeedFuture:    ByNeedFuture
                 byNeedDot:       ByNeedDot

                 '!!':            Boot_Value.readOnly
                 byNeedFail:      FailedValue
                 failed:          FailedValue

                 toVirtualString: Boot_Value.toVirtualString
                )
end
