%\define DBG
functor
export
   Accept
import
   OS
\ifdef DBG
   System
\endif
   DPMisc
define
   class ResourceHandler
      prop
         locking
      attr
         r
         q
      meth init(I)
         r<-I
         q<-nil
      end
      meth getResource
         lock W in
            if @r>0 then
               r<-@r-1
               W=unit
            else
               q<-{Append @q [W]}
            end
            {Wait W}
         end
      end
      meth returnResource
         lock
            if @q==nil then
               r<-@r+1
            else
               Q1|QR=@q
            in
               @r=0 % Check
               q<-QR
               Q1=unit
            end
         end
      end
   end

   MaxRead = 1000

   FDHandler = {New ResourceHandler init(5)}
   fun{BindSocket FD PortNum}
      try
         {OS.bind FD PortNum}
         PortNum
      catch _ then
         {BindSocket FD PortNum + 1}
      end
   end

   proc{AcceptSelect FD}
      NewFD in
      {FDHandler getResource}
      {OS.acceptSelect FD}
      {OS.accept FD _ _ NewFD} %InAddress InIPPort NewFD}
\ifdef DBG
      {System.showInfo 'Accepted channel (old '#FD#' new '#NewFD#')'}
\endif
      thread
         {AcceptProc NewFD}
         {FDHandler returnResource}
      end
      {AcceptSelect FD}
   end

   proc{Accept}
%      InAddress InIPPort
      FD
      PortNum
   in
      /* Create socket */
      FD={OS.socket 'PF_INET' 'SOCK_STREAM' "tcp"}
      PortNum = {BindSocket FD 9000}
      {OS.listen FD 5}
      {DPMisc.setListenPort PortNum {OS.uName}.nodename}
\ifdef DBG
      {System.showInfo 'Listening on port '#PortNum#' using fd '#FD}
\endif
      thread {AcceptSelect FD} end
   end

   proc{AcceptProc FD}
      Read InString
   in
      {OS.readSelect FD}
      {OS.read FD MaxRead ?InString nil ?Read}

      if Read>0 then
         case InString of "tcp" then
            Grant = {DPMisc.getConnGrant accept tcp false}
         in
            case Grant of grant(...) then
               _={OS.write FD "ok"}
                {DPMisc.handover accept Grant settings(fd:FD)}
            else % could be busy or no tcp, wait for anoter try
               _={OS.write FD "no"}
               {AcceptProc FD}
            end
         [] "give_up" then
            {OS.close FD}
         else
            {OS.close FD}
         end
      else
         % Check errno, could be worth another try
         {OS.close FD}
      end
   end
end
