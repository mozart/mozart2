functor
import
   VS           at 'x-oz://boot/VirtualSite'
   Timer(delay) at 'x-oz://system/Timer'
   Event(put)
define

   %% garbage collection of message chunks

   proc {GarbageCollect}
      {Timer.delay 60000}
      {VS.processGC _}
      {GarbageCollect}
   end
   thread
      {Thread.setThisPriority low}
      {GarbageCollect}
   end

   %% probing of known virtual sites

   proc {Probes}
      {Timer.delay 1000}
      {VS.processProbes _}
      {Probes}
   end
   thread
      {Thread.setThisPriority low}
      {Probes}
   end

   %% processing the mailbox

   SIGUSR2 = {NewCell _}
   proc {USR2Handler _}
      {Exchange SIGUSR2 unit _}
   end
   {Event.put 'SIGUSR2' USR2Handler}
   thread
      This = {Thread.this}
      {Thread.setPriority This high}
      proc {Mailbox}
         Again = {Access SIGUSR2}
      in
         if {VS.processMailbox} then
            {Thread.preempt This}
%           skip
         else
            {Wait Again}
         end
         {Mailbox}
      end
   in
      {Mailbox}
   end

   %% processing the message queue

   VSMsgQ = {NewCell _}
   proc {VSMsgQHandler _}
      {Exchange VSMsgQ unit _}
   end
   {Event.put 'VSMsgQ' VSMsgQHandler}
   thread
      This = {Thread.this}
      {Thread.setPriority This high}
      proc {MessageQ}
         Again = {Access VSMsgQ}
      in
         if {VS.processMessageQ} then
            {Thread.preempt This}
%           skip
         else
            {Wait Again}
         end
         {MessageQ}
      end
   in
      {MessageQ}
   end
end
