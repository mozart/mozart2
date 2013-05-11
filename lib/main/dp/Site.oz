%%%
%%% Authors:
%%%   Yves Jaradin (yves.jaradin@uclouvain.be)
%%%
%%% Copyright:
%%%   Yves Jaradin, 2008
%%%
%%% Last change:
%%%   $Date: 2008-03-19 15:03:37 +0100 (Wed, 19 Mar 2008) $ by $Author: raph $
%%%   $Revision: 16898 $
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

functor
import
   Glue at 'x-oz://boot/Glue'
   DP
   Property
   DPService
   Error
export
   This
   Resolve
   DistributedURIs
   AllURIs
   AddURI
define
   {DP.init}
   fun{This}
      {Glue.getThisSite}
   end
   {DPService.register
    {This}
    'oz:URIs'
    proc{$ 'oz:URIs' S M}
       case M
       of getAll(?X) then
          X=@URIs
       [] add(Uri)then
          if S=={This} then
             O in O=URIs:=Uri|O
          else
             {Error.printException {Exception.error dp(service localOnly 'oz:URIs' M)}}
          end
       else
          {Error.printException {Exception.error dp(service unknownMessage 'oz:URIs' M)}}
       end
    end}
   fun{Resolve UriVS}
      Uri={VirtualString.toString UriVS}
      Scheme={String.toAtom {List.takeWhile Uri fun{$C}C\=&:end}}
   in
      {{Property.get 'dp.resolver'}.Scheme Uri}.site
   end
   fun{DistributedURIs S}
      [{VirtualString.toString S.info}]
   end
   fun{AllURIs S}
      {DPService.send S 'oz:URIs' getAll($)}
   end
   fun{AddURI S Uri}
      {DPService.send S 'oz:URIs' add(Uri)}
   end
   URIs={NewCell {DistributedURIs {This}}}
end