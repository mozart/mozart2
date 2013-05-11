%%%
%%% Authors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%   Yves Jaradin <yjaradin@uclouvain.be>
%%%
%%% Contributors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
%%%   Yves Jaradin, 2008
%%%
%%% Last change:
%%%   $Date: 2004-10-28 17:28:16 +0200 (jeu, 28 oct 2004) $ by $Author: duchier $
%%%   $Revision: 16048 $
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%This file should be merged in share/lib/sp/ErrorFormatters.oz
functor
import
export
   dp:DP
define
   fun {DP E}
      T = 'Error: distributed programming'
   in
      case E
      of dp(line badChar C) then
         error(kind:T
               msg:'The character '#[C]#' is not allowed in pre-DSS messages')
      [] dp(line dropped) then
         error(kind:T
               msg:'Connection dropped unexpectedly before passing it to the DSS')
      [] dp(line unknownConnMeth M) then
         error(kind:T
               msg:'Unknown connection method'
               items:[hint(l:'method' m:oz(M))])
      [] dp(connection noLuck ToSite URIs) then
         error(kind:T
               msg:'Unable to open a connection to site with the given URIs'
               items: (hint(l:'site' m:oz(ToSite)) |
                       {Map URIs fun {$ URI} hint(l:'URI' m:URI) end}))
      [] dp(dssLimit distributedURI URIs) then
         error(kind:T
               msg:'Site URIs expected format is: oz-site://<ip>:<port>/<id>'
               items:{Map URIs fun {$ URI} hint(l:'URI' m:URI) end})
      [] dp(dss unknownNotification M) then
         error(kind:T
               msg:'Received an unexpected DSS notification'
               items:[hint(l:'notification' m:oz(M))])
      [] dp(service unknownMessage S M) then
         error(kind:T
               msg:'The service '#oz(S)#' received an unexpected message'
               items:[hint(l:'message' m:oz(M))])
      [] dp(service localOnly S M) then
         error(kind:T
               msg:'The service '#oz(S)#' rejected a remote message'
               items:[hint(l:'message' m:oz(M))
                      line('This message is only allowed locally.')])
      [] dp(ticket bad Ticket) then
         error(kind:T
               msg:'Ticket is unknown or has been retracted'
               items:[hint(l:'ticket' m:Ticket)])
      [] dp(ticket make URIs) then
         error(kind:T
               msg:'Unable to find a suitable URI to make a ticket'
               items:{Map URIs fun {$ URI} hint(l:'URI' m:URI) end})
      [] dp(ticket parse Ticket) then
         error(kind:T
               msg:'Unable to parse ticket'
               items:[hint(l:'ticket' m:Ticket)])
      [] dp(generic _ Msg Hints) then
         error(kind: T
               msg: Msg
               items: line('Old distribution system error!')|
               {Map Hints fun {$ L#M} hint(l:L m:oz(M)) end})
      [] dp(modelChoose) then
         error(kind: T
               msg: ('Cannot change distribution model: '#
                     'distribution layer already started')
               items: [line('Old distribution system error!')])
      [] dp('annotation format error' Annot) then
         error(kind:T
               msg('Invalid annotation')
               items:[hint(l:'annotation' m:oz(Annot))])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end
end