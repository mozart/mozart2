%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% StoreListener Functor
%%%

functor $

import
   BrowserSupport(getsBoundB) at 'x-oz://boot/Browser'
   System(eq)
   Debug(breakpoint) at 'x-oz://boot/Debug.ozf'

export
   storeListener : StoreListener

define
   WaitTouched = BrowserSupport.getsBoundB

   class StoreListener
      from
         BaseObject

      attr
         varDict %% Var Dictionary
         varNum  %% Var Numbers

      meth create
         @varDict = {Dictionary.new}
         @varNum  = 0
      end

      meth logVar(Node Value Mode)
         MatchNum = StoreListener, seekVar(Value $)
      in
         case MatchNum
         of 0 then
            CurNum = (@varNum + 1)
            Nodes  = Node|nil
         in
            {Dictionary.put @varDict CurNum Value|Nodes}
            varNum <- CurNum
            StoreListener, initListener(Value CurNum Mode)
         else
            VarDict     = @varDict
            Value|Nodes = {Dictionary.get VarDict MatchNum}
         in
            if {Member Node Nodes}
            then skip
            else {Dictionary.put VarDict MatchNum Value|(Node|Nodes)}
            end
         end
      end

      meth seekVar(Value $)
         case @varNum
         of 0 then 0
         else StoreListener, performSeekVar(1 Value $)
         end
      end

      meth performSeekVar(I Value $)
         CurValue|_ = {Dictionary.get @varDict I}
      in
         if {System.eq Value CurValue}
         then I
         elseif I < @varNum
         then StoreListener, performSeekVar((I + 1) Value $)
         else 0
         end
      end

      meth initListener(Value VarNum Mode)
         Server = @server
      in
         thread
            StoreListener, listen(Server Value VarNum Mode)
         end
      end

      meth listen(Server Value VarNum Mode)
         Touched = {WaitTouched Value}
      in
         {Wait Touched}
         %% Re-enter sync barrier
         {Server notifyNodes(VarNum Mode)}
         if {IsDet Value}
         then skip
         else
            %% Keep on running until determined
            StoreListener, listen(Server Value VarNum Mode)
         end
      end

      meth notifyNodes(VarNum Mode)
         VarDict     = @varDict
         Value|Nodes = {Dictionary.get VarDict VarNum}
      in
         {Dictionary.put VarDict VarNum Value|nil}
         {Debug.breakpoint}
         case Mode
         of normal then StoreListener, performNotifyNodes(nil Nodes)
         [] label  then StoreListener, performNotifyFeatureNodes(nil Nodes)
         end
      end

      meth performNotifyNodes(RIs Nodes)
         case Nodes
         of Node|Nr then
            RI = {Node getRootIndex(0 $)}
         in
            {Node tell}
            if {Member RI RIs}
            then StoreListener, performNotifyNodes(RIs Nr)
            else StoreListener, performNotifyNodes((RI|RIs) Nr)
            end
         else
            {self update(RIs)}
         end
      end

      meth performNotifyFeatureNodes(RIs Nodes)
         case Nodes
         of Node|Nr then
            RI = {Node getRootIndex(0 $)}
         in
            {Node tellLabel}
            if {Member RI RIs}
            then StoreListener, performNotifyFeatureNodes(RIs Nr)
            else StoreListener, performNotifyFeatureNodes((RI|RIs) Nr)
            end
         else
            {self update(RIs)}
         end
      end
   end
end
