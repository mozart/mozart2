%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%   Christian Schulte, 1998
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


functor

import
   DPB                             at 'x-oz://boot/DPB'
   PID(get getCRC received toPort) at 'x-oz://boot/PID'
   Distribution('export')          at 'x-oz://boot/Distribution'

   ErrorRegistry(put)
   Fault(injector removeInjector siteWatcher removeSiteWatcher)
   Property(get)

export
   offer: Offer
   take:  Take
   gate:  Gate


prepare

   %%
   %% Mapping between integers and characters
   %%
   local
      %% int -> char
      IntMap  = {List.toTuple '#'
                 {ForThread 1 127 1 fun {$ S I}
                                       if {Char.isAlNum I} then I|S
                                       else S
                                       end
                                    end nil}}
      Base = {Width IntMap}
      %% char -> int
      CharMap = {MakeTuple '#' 255}

      fun {ToInt Is J}
         case Is of nil then J
         [] I|Ir then {ToInt Ir J*Base + CharMap.I - 1}
         end
      end
   in
      {For 1 Base 1 proc {$ I}
                       CharMap.(IntMap.I) = I
                    end}
      {For 1 255 1  proc {$ I}
                       C=CharMap.I
                    in
                       if {IsDet C} then skip else C=0 end
                    end}

      fun {IntToKey I}
         if I<Base then [IntMap.(I+1)]
         else IntMap.((I mod Base) + 1)|{IntToKey I div Base}
         end
      end

      fun {KeyToInt Is}
         {ToInt {Reverse Is} 0}
      end
   end

define

   %%
   %% Force linking of base library
   %%
   {Wait DPB}

   %%
   %% Base Process Identifier package
   %%
   ReqStream = {PID.received}

   ThisPid   = {PID.get}

   fun {ToPort T}
      {PID.toPort T.host T.port T.time.1 T.time.2}
   end

   local
      KeyCtr = {New class $
                       prop final locking
                       attr n:0
                       meth get(N)
                          lock N=@n n<-N+1 end
                       end
                    end get(_)}
   in
      fun {NewTicket IsSingle}
         Major#Minor = {Property.get 'perdio.version'}
      in
         {Adjoin ThisPid ticket(single:  IsSingle
                                key:     {KeyCtr get($)}
                                minor:   Minor
                                major:   Major
                                minimal: {Property.get 'perdio.minimal'})}
      end
   end


   %%
   %% Creating and parsing ticket strings
   %%
   local
      fun {App Xss Ys}
         case Xss of nil then Ys
         [] Xs|Xsr then {Append Xs {App Xsr Ys}}
         end
      end
   in

      fun {TicketToString T}
         Stamp#Pid = T.time
         S = {App ["x-ozticket://"
                   T.host
                   &:|{Int.toString T.port}
                   &:|{IntToKey Stamp}
                   &:|{IntToKey Pid}
                   &/|{IntToKey T.key}
                   &:|{IntToKey T.major}
                   &:|{IntToKey T.minor}
                   [&: if T.single  then &s else &m end
                    &: if T.minimal then &m else &f end]] nil}
      in
         {Append S &:|{IntToKey {PID.getCRC S}}}
      end

      fun {VsToTicket V}
         try
            %% Raises an exception if has wrong checksum or if
            %% syntactically illegal
            S={VirtualString.toString V}
            [_ nil ProcPart KeyPart] = {String.tokens S &/}
            [HostS PortS Stamp Pid]  = {String.tokens ProcPart &:}
            [KeyS MajorS MinorS
             SingS MinimalS _]       = {String.tokens KeyPart  &:}
            Ticket = ticket(host:    HostS
                            port:    {String.toInt PortS}
                            time:    {KeyToInt Stamp}#{KeyToInt Pid}
                            key:     {KeyToInt KeyS}
                            major:   {KeyToInt MajorS}
                            minor:   {KeyToInt MinorS}
                            single:  SingS=="s"
                            minimal: MinimalS=="m")
         in
            S={TicketToString Ticket}
            Ticket
         catch _ then
            {Exception.raiseError connection(illegalTicket V)} _
         end
      end
   end


   %% Mapping of Keys to values
   KeyDict   = {Dictionary.new}

   thread
      {ForAll ReqStream
       proc {$ T#A}
          if
             T.time == ThisPid.time andthen
             {Dictionary.member KeyDict T.key}
          then Y={Dictionary.get KeyDict T.key} in
             if T.single then {Dictionary.remove KeyDict T.key} end
             thread S = yes(Y) in A=S end
          else
             thread A=no end
          end
       end}
   end


   %%
   %% Single connections
   %%
   fun {Offer X}
      T={NewTicket true}
   in
      {Distribution.'export' X}
      {Dictionary.put KeyDict T.key X}
      {String.toAtom {TicketToString T}}
   end

   %%
   %% Gates
   %%
   class Gate
      feat
         Ticket
         TicketAtom

      meth init(X ?AT <= _)
         T={NewTicket false}
      in
         {Distribution.'export' X}
         {Dictionary.put KeyDict T.key X}
         self.Ticket     = T
         self.TicketAtom = {String.toAtom {TicketToString T}}
         AT = self.TicketAtom
      end

      meth getTicket($)
         self.TicketAtom
      end

      meth close
         {Dictionary.remove KeyDict self.Ticket.key}
      end
   end


   proc {Take V Entity}
      T = {VsToTicket V}
      P = {ToPort T}
      X Y
      proc {Watch _ _}
         Y=no
      end
      proc {Handle _ _}
         {Exception.raiseError connection(ticketToDeadSite V)}
      end
   in
      if T.minimal\={Property.get 'perdio.minimal'} then
         {Exception.raiseError connection(wrongModel V)}
      end

      {Fault.siteWatcher P  Watch}
      {Fault.injector    P  Handle}

      {Send P T#X}

      {Fault.removeInjector P Handle}

      case {Record.waitOr X#Y}
      of 1 then
         {Fault.removeSiteWatcher P Watch}
         case X
         of no then
            {Exception.raiseError connection(refusedTicket V)}
         [] yes(A) then
            Entity=A
         end
      [] 2 then
         case Y of no then
            {Exception.raiseError connection(ticketToDeadSite V)}
         end
      end
   end


   %%
   %% Register error formatter
   %%

   {ErrorRegistry.put connection
    fun {$ E}
       T = 'Error: connections'
    in
       case E
       of connection(illegalTicket V) then
          error(kind: T
                msg: 'Illegal ticket for connection'
                items: [hint(l:'Ticket' m:V)])
       [] connection(refusedTicket V) then
          error(kind: T
                msg: 'Ticket refused by offering site'
                items: [hint(l:'Ticket' m:V)])
       [] connection(ticketToDeadSite V) then
          error(kind: T
                msg: 'Ticket refused: refers to dead site'
                items: [hint(l:'Ticket' m:V)])
       [] connection(wrongModel V) then
          error(kind: T
                msg: 'Ticket presupposes wrong distribution model'
                items: [hint(l:'Ticket' m:V)])
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

end
