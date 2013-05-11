%%%
%%% Authors:
%%%   Andreas Sundstrom <andreas@sics.se>
%%%
%%% Copyright:
%%%   Andreas Sundstrom, 1999
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

functor
import
   Glue at 'x-oz://boot/Glue'
   Open(socket)
   Error(registerFormatter)
   Property(get)
export
   Server
   Client
   DefaultServerPort
define
   DatagramMaxSize = 65536
   DefaultServerPort = 5555

   class Server
      feat
         Socket
         ServerThread          % Thread in which the server is running
      attr
         NotInitialized: true
         TheInfo               % The answer to be sent on request from client

      meth init(info:Info port:PortNr <= DefaultServerPort)
         proc {Serv S} Data Host Port in
            {S receive(list:?Data size:DatagramMaxSize host:?Host port:?Port)}
            try
               case {String.toAtom Data}
               of get then
                  {S send(vs:@TheInfo port:Port host:Host)}
               end
            catch _ then
               skip
            end
            {Serv S}
         end
         S
      in
         if @NotInitialized then   % Create only one socket
            NotInitialized <- false
            TheInfo <- Info
            S = {New Open.socket init(type:datagram protocol:"udp")}
            self.Socket = S
            {S bind(takePort:PortNr)}
            thread self.ServerThread = {Thread.this} {Serv S} end
         end
      end
      meth replace(info:Info)
         TheInfo <- Info
      end
      meth close()
         {Thread.terminate self.ServerThread}
         {self.Socket close()}
      end
   end

   class Client
      feat
         Socket
      attr
         ReceiverThread    % Thread waiting on request
         Closed            % is the socket closed?
         Sync              % enables close() to cause timeout

      meth init(port:ServerPort <= DefaultServerPort) BAs in
         self.Socket = {New Open.socket init(type:datagram protocol:"udp")}
         Closed <- false
         {Wait Glue}
         {Glue.sockoptBroadcast {self.Socket getDesc(_ $)}}
         BAs = {Glue.getBroadcastAddresses}
         {List.forAll BAs proc {$ H}
                             {self.Socket send(vs:get port:ServerPort host:H)}
                          end}
      end
      meth getOne(timeOut:TimeOut <= 1000 info:?Info) Alarm in
         Sync <- Alarm
         if @Closed then
            {Raise {Exception.system discovery(closed 'Client')}}
         else
            if TimeOut \= inf then
               thread {Delay TimeOut} Alarm = unit end
            end
            thread
               ReceiverThread <- {Thread.this}
               {self.Socket receive(list:?Info size:DatagramMaxSize)}
            end
            {Value.waitOr Info Alarm}
            if {Value.isFree Info} then
               Info = timeout
            end
         end
      end
      meth getAll(timeOut:TimeOut  <= 1000 info:?List)
         fun {Reciever StartTime} TimeLeft in
            TimeLeft = TimeOut + StartTime - {Property.get 'time.user'}
            if TimeLeft < 0 then
               nil
            else X in
               Client, getOne(timeOut:TimeLeft info:?X)
               if X == timeout then
                  nil
               else
                  X|{Reciever StartTime}
               end
            end
         end
         fun {RecieverInf} X in
            Client, getOne(timeOut:inf info:?X)
            if X == timeout then % if client is closed
               nil
            else
               X|{RecieverInf}
            end
         end
      in
         if TimeOut == inf then
            List = {RecieverInf}
         else
            List = {Reciever {Property.get 'time.user'}}
         end
      end
      meth close()
         @Sync = unit
         {Thread.terminate @ReceiverThread}
         {self.Socket close()}
         Closed <- true
      end
   end

   %%
   %% Error formatting
   %%

   {Error.registerFormatter discovery
    fun {$ E}
       T = 'error in Directory module'
    in
       case E
       of dir(What Who) then
          %% expected What: atom, Who: atom
          error(kind: T
                msg: case What
                     of closed then
                        Who#' is closed'
                     else 'Unknown' end)
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}
end
