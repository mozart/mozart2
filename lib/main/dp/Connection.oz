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

      fun {IsKey Is}
         case Is of nil then true
         [] I|Ir then {Char.isAlNum I} andthen {IsKey Ir}
         end
      end

      fun {KeyToInt Is}
         {ToInt {Reverse Is} 0}
      end

      fun {IdToKey Id}
         {List.take
          {Append
           {IntToKey {FoldL Id
                      fun {$ N I}
                         N + (I mod 13)
                      end 0}} "aA1"} 3}
      end

   end


   {{`Builtin` 'CloseGate' 0}}

   ReqStream = {{`Builtin` 'OpenGate'  1}}
   ProcId    = {{`Builtin` 'GateId'    1}}
   ProcKey   = {IdToKey {Atom.toString ProcId}}
   ProcSend  = {`Builtin` 'SendGate'  2}

   KeyDict   = {Dictionary.new}

   local
      IdCtr = {New class $
                      prop final locking
                      attr n:0
                      meth get(N)
                         lock N=@n n<-N+1 end
                      end
                   end get(_)}
   in

      proc {MakeTicket IsSingle ?Key ?Ticket}
         Key    = {IdCtr get($)}
         Ticket = {Append {VirtualString.toString ProcId}
                   &@|{Append ProcKey
                       case IsSingle then &s
                       else &m end|{IntToKey Key}}}
      end

      proc {DeTicket Ticket ?ProcId ?IsSingle ?Key}
         try
            [PI R]           = {String.tokens Ticket &@}
            PK1|PK2|PK3|IS|K = R
         in
            {IdToKey PI}=[PK1 PK2 PK3]
            ProcId   = PI
            IsSingle = case IS
                       of &s then true
                       [] &m then false
                       end
            Key      = {KeyToInt K}
         catch _ then
            raise ticket(illegal) end
         end
      end
   end

   thread
      {ForAll ReqStream
       proc {$ T#A}
          try
             IsSingle Key
             {DeTicket {Atom.toString T} _ ?IsSingle ?Key}
             Y = {Dictionary.get KeyDict Key}
          in
             case IsSingle then
                {Dictionary.remove KeyDict Key}
                A = yes(Y)
             else Z in
                A = yes(Z) {Port.send Y Z}
             end
          catch _ then
             A = no
          end
       end}
   end


   %%
   %% Single connections
   %%

   fun {Offer X}
      %% return ticket
      Ticket Key
   in
      {MakeTicket true ?Key ?Ticket}
      {Dictionary.put KeyDict Key X}
      {String.toAtom Ticket}
   end

   proc {Take TicketV X}
      Ticket = {VirtualString.toString TicketV}
      ProcId IsSingle
   in
      {DeTicket Ticket ?ProcId ?IsSingle _}
      case IsSingle then A in
         {ProcSend ProcId {String.toAtom Ticket}#A}
         case A
         of no     then
            raise ticket(refused) end
         [] yes(Y) then
            X=Y
         end
      else
         raise ticket(illegal) end
      end
   end

   %%
   %% One to many connections
   %%
   class Gate
      feat Ticket Key
      attr Stream
      meth init
         ThisTicket ThisKey
         P = {Port.new @Stream}
      in
         {MakeTicket false ?ThisKey ?ThisTicket}
         {Dictionary.put KeyDict ThisKey P}
         self.Key    = ThisKey
         self.Ticket = ThisTicket
      end
      meth getTicket($)
         {String.toAtom self.Ticket}
      end
      meth receive(X)
         NS S
      in
         S = (Stream <- NS)
         case S of Y|R then
            NS=R X=Y
         end
      end
      meth close
         Stream <- _
         {Dictionary.remove KeyDict self.Key}
      end
   end

   proc {Send TicketV X}
      Ticket = {VirtualString.toString TicketV}
      ProcId IsSingle
   in
      {DeTicket Ticket ?ProcId ?IsSingle _}
      case IsSingle then
         raise ticket(illegal) end
      else A in
         {ProcSend ProcId {String.toAtom Ticket}#A}
         case A
         of no     then
            raise ticket(refused) end
         [] yes(Y) then
            X=Y
         end
      end
   end

in

   Connection = connection(offer: Offer
                           take:  Take
                           gate:  Gate
                           send:  Send)

end
