%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
   DPB                             at 'x-oz://boot/DPB'
   PID(get getCRC received toPort) at 'x-oz://boot/PID'

   Error(registerFormatter)
   Fault(install installWatcher deInstall deInstallWatcher)
   Property(get)
   DPInit
export
   Offer OfferUnlimited Take Gate TakeWithTimer

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
   {DPInit.init connection_settings _}

   %% ERIK
   %% Har skall varan connect starter kora!!!
   %%

   %%
   %% Base Process Identifier package
   %%
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
         Major#Minor = {Property.get 'dp.version'}
      in
         {Adjoin ThisPid ticket(single:  IsSingle
                                key:     {KeyCtr get($)}
                                minor:   Minor
                                major:   Major)}
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
                   [&: if T.single  then &s else &m end]] nil}
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
             SingS _]       = {String.tokens KeyPart  &:}
            Ticket = ticket(host:    HostS
                            port:    {String.toInt PortS}
                            time:    {KeyToInt Stamp}#{KeyToInt Pid}
                            key:     {KeyToInt KeyS}
                            major:   {KeyToInt MajorS}
                            minor:   {KeyToInt MinorS}
                            single:  SingS=="s")
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
      {ForAll {PID.received}
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

   fun {OfferUnlimited X}
      {{New Gate init(X)} getTicket($)}
   end

   proc {TakeWithTimer V Time Entity}
      T = {VsToTicket V}
      P = {ToPort T}
      X Alarm
      thread
         {Delay Time}
         Alarm=_#time
      end
      proc {Watch _ _}
         Alarm=watch#_
      end
      proc {Handle _ _ _}
         {Fault.deInstallWatcher P Watch _}
         {Fault.deInstall P 'thread'(this) _}
         {Exception.raiseError connection(ticketToDeadSite V)}
      end
   in
      if T.major#T.minor \= {Property.get 'dp.version'} then
         {Exception.raiseError connection(differentDssVersion V)}
      end

      {Fault.installWatcher P [permFail] Watch true}
      {Fault.install P 'thread'(this) [permFail] Handle true}
      {Send P T#X}

      case {Record.waitOr X#Alarm}
      of 1 then
         case X of no then
            {Fault.deInstall P 'thread'(this) _}
            {Fault.deInstallWatcher P Watch _}
            {Exception.raiseError connection(refusedTicket V)}
         [] yes(A) then
            {Fault.deInstall P 'thread'(this) _}
            {Fault.deInstallWatcher P Watch _}
            Entity=A
         end
      [] 2 then
         case{Record.waitOr Alarm} of 1 then
            {Fault.deInstall P 'thread'(this) _}
            {Fault.deInstallWatcher P Watch _}
            {Exception.raiseError connection(ticketToDeadSite V)}
         [] 2 then
            {Fault.deInstall P 'thread'(this) _}
            {Fault.deInstallWatcher P Watch _}
            {Exception.raiseError connection(ticketTakeTimeOut V)}
         end
      end
   end

   proc {Take V Entity}
      {TakeWithTimer V {Property.get 'dp.probeTimeout'} Entity}
   end


   %%
   %% Register error formatter
   %%

   {Error.registerFormatter connection
    fun {$ E}
       T = 'Error: connections'
    in
       case E
       of connection(illegalTicket V) then
          error(kind: T
                msg: 'Illegal ticket for connection'
                items: [hint(l:'Ticket' m:oz(V))])
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
       [] connection(differentDssVersion V) then
          error(kind: T
                msg: 'Ticket refused: different distribution subsystem version'
                items: [hint(l:'Ticket' m:V)])
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

end
