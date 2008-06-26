%%%
%%% Authors:
%%%   Yves Jaradin (yves.jaradin@uclouvain.be)
%%%   Raphael Collet (raphael.collet@uclouvain.be)
%%%
%%% Copyright:
%%%   Yves Jaradin, 2008
%%%
%%% Last change:
%%%   $Date: 2008-03-06 15:46:11 +0100 $ by $Author: yjaradin $
%%%   $Revision: 16863 $
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
   Glue(setSiteState
        setConnection
        acceptConnection
        getThisSite
        initDP
        setRPC
        annotate
        getAnnotation
        kill
        break
        getFaultStream) at 'x-oz://boot/Glue'
   Property
   DPDefaults(listen:DefaultListenFunc init)
   Error
   DPErrorFormatters
   DPService
export
   Init
   InitWith
   Prepare
   Initialized
   service:DPService
   Kill
   Break
   GetFaultStream
   Annotate
   GetAnnotation
define
   {Error.registerFormatter dp DPErrorFormatters.dp}
   {DPDefaults.init}
   ListenFuncC={NewCell DefaultListenFunc}
   InitializedC={NewCell false}
   fun{Initialized}
      @InitializedC
   end
   proc{Prepare ListenFunc}
      ListenFuncC:=ListenFunc
   end
   proc{Init}
      N in
      if {Not InitializedC:=N} then
         InStream
         DistributedURIs={@ListenFuncC {NewPort InStream}}
         Info={ExtractDistributedInfo DistributedURIs}
      in
         {Glue.setRPC proc {$ P Args Ret}
                         try
                            {Procedure.apply P Args}
                            Ret=unit
                         catch E then
                            Ret={Value.failed E}
                         end
                      end}
         {Glue.initDP {NewPort thread {ForAll $ ProcessDSS} end}}
         {Glue.getThisSite}.info := Info
         thread
            {ForAll InStream DoAccept}
         end
      end
      N=true
   end
   %% initialize DP with user settings (ip, portnum, etc)
   proc {InitWith Settings}
      {Property.put 'dp.listenerParams'
       {Adjoin {Property.get 'dp.listenerParams'} Settings}}
      {Init}
   end
   fun{ExtractDistributedInfo DistributedURIs}
      case DistributedURIs
      of [VH] andthen H={VirtualString.toString VH} in {List.isPrefix "oz-site://" H} then
         H
      [] URIs then
         {Exception.raiseError dp(dssLimit distributedURI URIs)}
         unit
      end
   end
   proc{ProcessDSS M}
      case M
      of connect(ToSite) then
         thread
            URI={VirtualString.toString ToSite.info}
            Connect={{Property.get 'dp.resolver'}.'oz-site' URI}.connect
         in
            if {Not {DoConnect ToSite Connect}} then
               {Exception.raiseError dp(connection noLuck ToSite [URI])}
            end
         end
      [] connection_received(_/*ToSite*/ _/*FD*/) then
         skip
      [] new_site(S) then
         {DPService.incoming S service(to:'oz:newSite' msg:hello(S))}
      [] deliver(src:S msg:M)then
         try
            case M
            of service(...) then
               {DPService.incoming S M}
            else
               {DPService.incoming S service(to:'oz:siteMessage'  msg:M)}
            end
         catch E then
            {PrintError E}
         end
      [] M then
         {PrintError {Exception.error dp(dss unknownNotification M)}}
      end
   end
   fun{DoConnect ToSite Connect}
      try
         case {Connect default}
         of X=fd(_ _) then
            {Glue.setConnection ToSite X}
            true
         [] none then
            true
         [] ignore then
            false
         [] permFail then
            {Glue.setSiteState ToSite permFail}
            true
         end
      catch E then
         {PrintError E}
         false
      end
   end
   proc{DoAccept X}
      try
         case X
         of fd(_ _) then
            {Glue.acceptConnection X}
         end
      catch E then
         {PrintError E}
      end
   end
   PrintError=Error.printException

   %% make something available once the module has been initialized
   fun lazy {WhenInit X} {Init} X end

   proc {DoAnnotate E A}
      {Glue.annotate E if {IsList A} then A else [A] end}
   end
   Annotate = {WhenInit DoAnnotate}
   GetAnnotation = {WhenInit Glue.getAnnotation}
   Kill = {WhenInit Glue.kill}
   Break = {WhenInit Glue.break}
   GetFaultStream = {WhenInit Glue.getFaultStream}
end
