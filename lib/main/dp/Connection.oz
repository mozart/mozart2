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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local

   %%
   %% Base Process Identifier package
   %%
   local
      PID = pid(get:      {`Builtin` 'PID.get'      1}
                send:     {`Builtin` 'PID.send'     4}
                received: {`Builtin` 'PID.received' 1}
                close:    {`Builtin` 'PID.close'    0})
   in
      {PID.close}

      ReqStream = {PID.received}
      ThisPid   = {PID.get}

      proc {SendToPid T X}
         X = {Promise.new}
         {PID.send T.host T.port T.time T#X}
      end
   end


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
         S = {App ["ozticket://"
                   T.host
                   &:|{Int.toString T.port}
                   &:|{IntToKey T.time}
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
            [HostS PortS TimeS]       = {String.tokens ProcPart &:}
            [KeyS SingS _]            = {String.tokens KeyPart  &:}
            Ticket = ticket(host:   HostS
                            port:   {String.toInt PortS}
                            time:   {KeyToInt TimeS}
                            key:    {KeyToInt KeyS}
                            single: SingS=="s")
         in
            S={TicketToString Ticket}
            Ticket
         catch _ then
            {`RaiseError` dp(connection(illegalTicket V))} _
         end
      end
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
          A := case
                  T.time == ThisPid.time andthen
                  {Dictionary.member KeyDict T.key}
               then Y={Dictionary.get KeyDict T.key} in
                  case T.single then {Dictionary.remove KeyDict T.key}
                  else skip
                  end
                  yes(Y)
               else
                  no
               end
       end}
   end


   %%
   %% Single connections
   %%

   Export = {`Builtin` 'export' 1}

   fun {Offer X}
      T={NewTicket true}
   in
      {Export X}
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
      attr
         Stream

      meth init(X ?AT <= _)
         T={NewTicket false}
      in
         {Export X}
         {Dictionary.put KeyDict T.key X}
         self.Ticket     = T
         self.TicketAtom = {String.toAtom {TicketToString T}}
         AT = self.TicketAtom
      end

      meth getTicket($)
         self.TicketAtom
      end

      meth close
         Stream <- _
         {Dictionary.remove KeyDict self.Ticket.key}
      end
   end

   proc {Take V X}
      case !!{SendToPid {VsToTicket V}}
      of no     then {`RaiseError` dp(connection(refusedTicket V))}
      [] yes(Y) then X=Y
      end
   end

in

   Connection = connection(offer: Offer
                           take:  Take
                           gate:  Gate)

end
