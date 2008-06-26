%%%
%%% Authors:
%%%   Yves Jaradin (yves.jaradin@uclouvain.be)
%%%
%%% Copyright:
%%%   Yves Jaradin, 2008
%%%
%%% Last change:
%%%   $Date: 2008-03-06 13:33:44 +0100 (Thu, 06 Mar 2008) $ by $Author: yjaradin $
%%%   $Revision: 16860 $
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
   Site
   Error
export
   Incoming
   Send
   Register
   GetServices
define
   ServicesDic={NewDictionary}
   {Property.put 'dp.services' ServicesDic}
   proc{Incoming From service(to:Serv msg:M)}
      {{Dictionary.condGet ServicesDic Serv
        {Dictionary.condGet ServicesDic 'oz:default'
         proc{$ _ _ _}skip end}} Serv From M}
   end
   proc{Send To Serv M}
      {DP.init}
      {Glue.sendSite To service(to:Serv msg:M)}
   end
   proc{Register On Serv HandlerProc}
      {Send On 'oz:services' register(Serv HandlerProc)}
   end
   fun{GetServices On}
      {Send On 'oz:services' getAll($)}
   end
   ServicesDic.'oz:services':=proc{$ 'oz:services' From M}
                                 case M
                                 of getAll(?X) then
                                    X={Dictionary.keys ServicesDic}
                                 [] register(S H) then
                                    if From=={Site.this} then
                                       ServicesDic.S:=H
                                    else
                                       {Error.printException {Exception.error dp(service localOnly 'oz:services' M)}}
                                    end
                                 else
                                    {Error.printException {Exception.error dp(service unknownMessage 'oz:services' M)}}
                                 end
                              end
end
