functor
import
   Timer(setTimer mTime) at 'x-oz://boot/Timer'
export
   Alarm Delay TimerHandler DelayHandler
define
   TimerBox
   proc {TimerHandler _}
      {Send TimerBox tick}
   end
   proc {DelayHandler E}
      case E of delay(T V) then {Alarm T V} end
   end
   fun {Alarm T}
      Synch
   in
      {Send TimerBox task({Timer.mTime}+T Synch)}
      !!Synch
   end
   proc {Delay T}
      {Wait {Alarm T}}
   end
   proc {ProcessTask Msgs Tasks}
      case Tasks of nil then {ProcessMsg Msgs nil}
      [] task(T V)|Tail then
         if T=<{Timer.mTime} then V=unit {ProcessTask Msgs Tail}
         else {Timer.setTimer T} {ProcessMsg Msgs Tasks} end
      end
   end
   proc {ProcessMsg Msgs Tasks}
      case Msgs of M|Msgs then
         case M
         of tick then {ProcessTask Msgs Tasks}
         [] task(T _) then {ProcessTask Msgs {Insert Tasks T M}}
         end
      end
   end
   fun {Insert Tasks T Task}
      case Tasks of nil then [Task]
      [] (Head=task(T2 _))|Tail then
         if T<T2 then Task|Tasks
         else Head|{Insert Tail T Task} end
      end
   end
   thread {ProcessMsg {NewPort $ TimerBox} nil} end
end
