%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
%%%   Anna Neiderud (annan@sics.se)
%%%
%%% Copyright:
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

%\define DBG
functor
import
   DPMisc
   Module
   System
%   Browser
   Pickle
   OS
export
   GetAppState
   PutAppState
   CondGetAppState
   InitConnection
%   InitAccept
define
   AppState = {NewDictionary}
   GetAppState
   PutAppState
   CondGetAppState
   InitConnection
%   InitAccept

   %% Gets a unique id out of the Requsteor structure
   fun{GetIdFromRequestor Requestor}
      Requestor.id
   end
   %% Check the functor, it is only allowed to importthe ConnectionWrapper
   fun{CheckFunctor Func}
      true
   end
   fun{GetConnectionWrapper Obj}
      {Module.apply
       [functor
        export
           GetConnGrant
           Handover
           ConnFailed
           FreeConnGrant
           GetLocalState
           PutLocalState
           GetAppState
           CondGetAppState
           PutAppState
           Socket
           Connect
           Write
           Read
           WriteSelect
           ReadSelect
           Close
        define
           proc{GetConnGrant Type CanWait ?Grant}
              {DPMisc.getConnGrant Obj.requestor Type CanWait Grant}
              case Grant of grant(...) then
                 {Obj registerResource(grant(Grant))}
              else
                 skip
              end
           end

           proc{Handover Grant SetUpParameter}
              {Obj unregisterResource(grant(Grant))}

              % This is a fix and not a solution. If another
              % ConnectionFunctor than the default one keeps a
              % filedescriptor via handover, it must use the same
              % syntax in SetUpParameter.
              case SetUpParameter of settings(fd:FD) then
                 {Obj unregisterResource(fd(FD))}
              else skip end

              if {Dictionary.member OngoingRequests Obj.id} then
                 {DPMisc.handover Obj.requestor Grant SetUpParameter}
              end
           end

           proc{ConnFailed Reason}
              {Obj freeResources}
              if {Dictionary.member OngoingRequests Obj.id} then
                 {DPMisc.connFailed Obj.requestor Reason}
              end
           end

           proc{FreeConnGrant Grant}
              {Obj unregisterResource(grant(Grant))}
              if {Dictionary.member OngoingRequests Obj.id} then
                 {DPMisc.freeConnGrant Obj.requestor Grant}
              end
           end

           % Could be a consistency problem if abort happens... AN!
           % Add a Dictionary.member test?
           proc{GetLocalState State}
              {Obj getLocalState(State)}
           end
           proc{PutLocalState State}
              {Obj putLocalState(State)}
           end

           proc{Socket A B C ?FD}
              FD={OS.socket A B C}
              if FD\=~1 then
                 {Obj registerResource(fd(FD))}
              end
           end

           proc{Close FD}
              {OS.close FD}
              {Obj unregisterResource(fd(FD))}
           end

           Connect=OS.connectNonblocking
           Write=OS.write
           Read=OS.read
           WriteSelect=OS.writeSelect
           ReadSelect=OS.readSelect
        end]}.1
   end


   class ConnectionController
      prop
         locking
      feat
         id
         requestor
         moduleManager
      attr
         allocatedResources:nil
         localState
      meth init(Id Requestor LocalOzState DistOzState)
         ConnectionFunctor
         ConnectModule
      in
         try
            self.id=Id
            self.requestor = Requestor
            case DistOzState.type of
               ordinary then
               ConnectionFunctor = LocalOzState.connectionFunctor
            elseof dynamic then
               ConnectionFunctor = {Pickle.load  DistOzState.location}
            elseof replicated then
               raise notImplementedYet end
               %% Do a lot of loading and shit ...
            end
            if {Not {CheckFunctor ConnectionFunctor}} then
               raise malishiousFunctor end
            end
            self.moduleManager ={New Module.manager init}
            {self.moduleManager
             enter(url:'x-oz://connection/ConnectionWrapper.ozf'
                   {GetConnectionWrapper self})}
            {self.moduleManager apply(ConnectionFunctor ConnectModule)}
            localState <- LocalOzState.localState
            {ConnectModule.connect DistOzState.parameter}
\ifdef DBG
         catch X then
%           {System.show warning(X)}
            thread raise X end end
\else
         catch _ then
            skip
\endif
         end
         {self freeResources}
      end

      meth getLocalState($) @localState end
      meth putLocalState(S)
         localState <- S
         {DPMisc.putLocalState self.requestor S}
      end
      meth registerResource(R)
         lock
            allocatedResources<-{Append @allocatedResources [R]}
         end
      end
      meth unregisterResource(R)
         lock
            allocatedResources<-{Filter @allocatedResources
                                  fun{$ RC} RC\=R end}
         end
      end
      meth freeResources
         lock
            {ForAll @allocatedResources
             proc{$ R}
                case R of grant(Grant) then
                   {DPMisc.freeConnGrant self.requestor Grant}
                elseof fd(FD) then
                   {OS.close FD}
                end
             end}
            allocatedResources<-nil
         end
      end
   end
   OngoingRequests
in
   proc{InitConnection Stream}
      OngoingRequests = {NewDictionary}
%      thread {Browser.browse Stream} end
      {ForAll Stream
       proc{$ Request}
\ifdef DBG
          {Wait Request}
          {System.show got(Request)}
\endif
          case Request of
             connect(Requestor LocalOzState DistOzState) then
             Id = {GetIdFromRequestor Requestor}
          in
             if {Dictionary.member OngoingRequests Id} then
                raise already_connecting(Id) end
             end
             OngoingRequests.Id:=r(thr:{Thread.this} fd:_)
             thread
                try
                   _ = {New ConnectionController init(Id Requestor
                                                      LocalOzState
                                                      DistOzState)}
\ifdef DBG
                catch X then
                   raise X end
\else
                catch _ then
                   skip
\endif
                end
                {Dictionary.remove OngoingRequests Id}
             end
          elseof abort(Requestor) then
             Id = {GetIdFromRequestor Requestor}
          in
             try
                case {CondSelect OngoingRequests Id notfound}
                of r(thr:T fd:FD) then
                   {Dictionary.remove OngoingRequests Id}
                   {Thread.terminate T}
                   if {IsDet FD} then
                      {OS.close FD}
                   end
                else
                   skip
                end
             catch _ then skip end
          else
             {System.showError "Warning Connection Wrapper called with wrong parameters"}
%            {System.showError {Value.toVirtualString Request 100 100}}
             raise error end
          end
       end}
   end


   proc{GetAppState Key Val}
      Val = AppState.Key
   end

   proc{PutAppState Key Val}
      AppState.Key:=Val
   end

   proc{CondGetAppState Key AltVal Val}
      {Dictionary.condGet AppState Key AltVal Val}
   end

%    proc{InitAccept AcceptFunc}
%       {AcceptProc.accept}
%    end
end
