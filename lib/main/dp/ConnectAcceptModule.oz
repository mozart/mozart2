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
                 {Obj registerResource(Grant)}
              else
                 skip
              end
           end

           proc{Handover Grant SetUpParameter}
              {Obj unregisterResource(Grant)}
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
              {Obj unregisterResource(Grant)}
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

           Socket=OS.socket
           Connect=OS.connectNonblocking
           Write=OS.write
           Read=OS.read
           WriteSelect=OS.writeSelect
           ReadSelect=OS.readSelect
           Close=OS.close
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
              {DPMisc.freeConnGrant self.requestor R}
             end}
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
             thread
                Id = {GetIdFromRequestor Requestor}
             in
                if {Dictionary.member OngoingRequests Id} then
                   raise already_connecting(Id) end
                end
                OngoingRequests.Id:={Thread.this}
                try
                   _ = {New ConnectionController init(Id Requestor
                                                      LocalOzState
                                                      DistOzState)}
                catch X then
                   raise X end % AN! this is not the release behaviour, it
                               % should simply be discarded
%                  {System.showError "Connection proc failed to execute"}
                end
                {Dictionary.remove OngoingRequests Id}
             end
          elseof abort(Requestor) then
             Id = {GetIdFromRequestor Requestor}
          in
             try
                if{Dictionary.member OngoingRequests Id} then
                   {Dictionary.remove OngoingRequests Id}
                   {Thread.terminate OngoingRequests.Id}
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
