functor
import
   VS           at 'x-oz://boot/VirtualSite'
   Timer(delay) at 'x-oz://system/Timer'
   Event(put)
%   System(showError:MSG)
define

   %% garbage collection of message chunks

   proc {GarbageCollect}
      {Timer.delay 60000}
%      {MSG '[VS] garbage collection'}
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
%      {MSG '[VS] probes'}
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
%      {MSG '[VS] SIGUSR2'}
      {Exchange SIGUSR2 unit _}
   end
   {Event.put 'SIGUSR2' USR2Handler}
   thread
      This = {Thread.this}
      {Thread.setPriority This high}
      proc {Mailbox}
         Again = {Access SIGUSR2}
      in
%        {MSG '[VS] mailbox'}
         if {VS.processMailbox} then
            {Thread.preempt This}
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
%      {MSG '[VS] VSMsgQ'}
      {Exchange VSMsgQ unit _}
   end
   {Event.put 'VSMsgQ' VSMsgQHandler}
   thread
      This = {Thread.this}
      {Thread.setPriority This high}
      proc {MessageQ}
         Again = {Access VSMsgQ}
      in
%        {MSG '[VS] message Q'}
         if {VS.processMessageQ} then
            {Thread.preempt This}
         else
            {Wait Again}
         end
         {MessageQ}
      end
   in
      {MessageQ}
   end
end
