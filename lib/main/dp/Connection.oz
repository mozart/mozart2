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

local

   %%
   %% Mapping between integers and characters
   %%
   local
      %% int -> char
      IntMap  = {List.toTuple '#'
                 {ForThread 1 127 1 fun {$ S I}
                                       case {Char.isAlNum I} then I|S
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
                       case {IsDet C} then skip else C=0 end
                    end}

      fun {IntToKey I}
         case I<Base then [IntMap.(I+1)]
         else IntMap.((I mod Base) + 1)|{IntToKey I div Base}
         end
      end

      fun {KeyToInt Is}
         {ToInt {Reverse Is} 0}
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
      fun {CheckSum Is N}
         case Is of nil then N mod 997
         [] I|Ir then {CheckSum Ir N * 13 + I}
         end
      end
   in
      fun {TicketToString T}
         Stamp#Pid = T.time
         S = {App ["ozticket://"
                   T.host
                   &:|{Int.toString T.port}
                   &:|{IntToKey Stamp}
                   &:|{IntToKey Pid}
                   &/|{IntToKey T.key}
                   [&: case T.single then &s else &m end]] nil}
      in
         {Append S &:|{IntToKey {CheckSum S 0}}}
      end
      fun {VsToTicket V}
         try
            %% Raises an exception if has wrong checksum or if
            %% syntactically illegal
            S={VirtualString.toString V}
            [_ nil ProcPart KeyPart]  = {String.tokens S &/}
            [HostS PortS Stamp Pid]   = {String.tokens ProcPart &:}
            [KeyS SingS _]            = {String.tokens KeyPart  &:}
            Ticket = ticket(host:   HostS
                            port:   {String.toInt PortS}
                            time:   {KeyToInt Stamp}#{KeyToInt Pid}
                            key:    {KeyToInt KeyS}
                            single: SingS=="s")
         in
            S={TicketToString Ticket}
            Ticket
         catch _ then
            {Exception.raiseError dp(connection(illegalTicket V))} _
         end
      end
   end

in

   functor $ prop once

   import
      Fault.{install deinstall}

      PID.{get received toPort}
          from 'x-oz://boot/PID'

      Distribution.{'export'}
          from 'x-oz://boot/Distribution'

   export
      offer: Offer
      take:  Take
      gate:  Gate

   body
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
            {Adjoin ThisPid ticket(single: IsSingle
                                   key:    {KeyCtr get($)})}
         end
      end


      %% Mapping of Keys to values
      KeyDict   = {Dictionary.new}


      thread
         {ForAll ReqStream
          proc {$ T#A}
             case
                T.time == ThisPid.time andthen
                {Dictionary.member KeyDict T.key}
             then Y={Dictionary.get KeyDict T.key} in
                case T.single then {Dictionary.remove KeyDict T.key}
                else skip
                end
                thread A=yes(Y) end
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
            {Exception.raiseError dp(connection(ticketToDeadSite V))}
         end
      in
         {Fault.install P watcher('cond':permHome) Watch}
         {Fault.install P handler('cond':perm)     Handle}
         {Send P T#X}
         case X#Y
         of no#_ then
            {Exception.raiseError dp(connection(refusedTicket V))}
         [] _#no then
            {Exception.raiseError dp(connection(ticketToDeadSite V))}
         [] yes(A)#_ then
            Entity=A
         end
         {Fault.deinstall P watcher('cond':permHome) Watch}
         {Fault.deinstall P handler('cond':perm)     Handle}
      end

   end

end
