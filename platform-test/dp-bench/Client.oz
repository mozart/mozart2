functor

import
   System
   Connection
   Application
   Pickle
   DPStatistics
   Property
   Module
define

fun{ThreadUniquePort Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind  _}
       Ans
    in
       thread
          {For 1 I 1
           proc{$ _}
              S Np in
              Np = {NewPort S}
              {Send P port(Np)}
              {Wait S}
           end}
          Ind = Ans
       end
       Ans
    end
    unit}
end

fun{ThreadSemiUniquePort Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind Id}
       Ans
       Np
    in
       thread
          {List.forAllInd {NewPort $ Np}
           proc{$ In _}
              if In == I then
                 Ind = Ans
              else
                 {Send P port(Np)}
              end
           end}
       end
       {Send P port(Np)}
       Ans
    end
    unit}
end


fun{ThreadNoPort Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind Id}
       Ans
       Np
    in
       thread
          {List.forAllInd {NewPort $ Np}
           proc{$ In _}
              if In == I then
                 Ind = Ans
              else
                 {Send P send(Id)}
              end
           end}
       end
       {Send P register(Np Id)}
       {Send P send(Id)}
       Ans
    end
    unit}
end


fun{ThreadComPing Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind  _}
       Ans
    in
       thread
          {For 1 I 1
           proc{$ _}
              {DS.sendcp Site.ip Site.port
               Site.timestamp Site.pid 1}
           end}
          Ind = Ans
       end
       Ans
    end
    unit}
end


fun{ThreadProtPing Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind  _}
       Ans
    in
       thread
          {For 1 I 1
           proc{$ _}
              {DS.sendmpp Site.ip Site.port
               Site.timestamp Site.pid 1}
           end}
          Ind = Ans
       end
       Ans
    end
    unit}
end



fun{ThreadListPing Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind  _}
       Ans
    in
       thread
          {For 1 I 1
           proc{$ _}
              {DS.sendmpt Site.ip Site.port
               Site.timestamp Site.pid 1 [a b c d e f g h i]}
           end}
          Ind = Ans
       end
       Ans
    end
    unit}
end



fun{ThreadEntityPing Th I P}
   {Loop.forThread  1 Th 1
    fun{$ Ind  _}
       Ans
    in
       thread
          {For 1 I 1
           proc{$ _}
              {DS.sendmpt Site.ip Site.port
               Site.timestamp Site.pid 1 P}
           end}
          Ind = Ans
       end
       Ans
    end
    unit}
end

fun{ConcurentSinglePort Th I P}
   Np
   CC = {NewCell {NewPort $ Np}}
in
   {For 1 Th 1 proc{$ _} {Send P port(Np)} end}
   {For  (I-1)*Th 1 ~1
    proc{$ Ind}
       {Wait {Access CC}}
       {Assign CC {Access CC}.2}
       if Ind > Th then {Send P port(Np)} end
    end}
   unit
end


fun{ConcurentNoPort Th I P}
   Np
   CC = {NewCell {NewPort $ Np}}
in
   {Send P register(Np 1)}
   {For 1 Th 1 proc{$ _} {Send P send(1)} end}
   {For  (I-1)*Th 1 ~1
    proc{$ Ind}
       {Wait {Access CC}}
       {Assign CC {Access CC}.2}
       if Ind > Th then {Send P send(1)} end
    end}
   unit
end

fun{ConcurentComPing Th I P}
   {ForAll {Loop.forThread 1 Th 1
            fun{$ Acc _}
               V in
               thread
                  {DS.sendcp Site.ip Site.port
                   Site.timestamp Site.pid I}
                  V = unit
               end
               V|Acc
            end nil}
    Wait}
   unit
end


fun{ConcurentProtPing Th I P}
   {ForAll {Loop.forThread 1 Th 1
            fun{$ Acc _}
                  V in
               thread
                  {DS.sendmpp Site.ip Site.port
                   Site.timestamp Site.pid I}
                  V = unit
               end
               V|Acc
            end nil}
    Wait}
   unit
end

fun{ConcurentListPing Th I P}
   {ForAll {Loop.forThread 1 Th 1
            fun{$ Acc _}
                  V in
               thread
                  {DS.sendmpt Site.ip Site.port
                   Site.timestamp Site.pid I [a b c d e f g h i]}
                  V = unit
               end
               V|Acc
            end nil}
    Wait}
   unit
end

fun{ConcurentEntityPing Th I P}
   {ForAll {Loop.forThread 1 Th 1
            fun{$ Acc _}
                  V in
               thread
                  {DS.sendmpt Site.ip Site.port
                   Site.timestamp Site.pid I P}
                  V = unit
               end
               V|Acc
            end nil}
    Wait}
   unit
end
Args
Help
try
Args={Application.getCmdArgs record('ticket'(single type:string)
                                    'iterations'(single type:int)
                                    'jobs'(single type:list(int))
                                    'linear'(single type:bool default:false)
                                    'help'(   single   type:bool default:false)
                                    'tests'(single type:list(atom) default:[concurentSinglePort
                                                                            concurentNoPort
                                                                            threadUniquePort
                                                                            threadSemiUniquePort
                                                                            threadNoPort
                                                                            threadComPing
                                                                            threadProtPing
                                                                            threadListPing
                                                                            threadEntityPing
                                                                            concurentComPing
                                                                            concurentProtPing
                                                                            concurentListPing
                                                                            concurentEntityPing
                                                                           ])
                                   )}
   Args.ticket = _
   Args.iterations = _
   Help = false
catch _ then
   Help = true
end
if Args.help orelse Help then
   {System.showInfo '--ticket\n'#
    '\tThe file that contains the ticket saved from the server\n'#
    '--iterations\n'#
    '\tSets the number of messages\n'#
    '\n--jobs'#
    '\tThe degree of paralellism\n'#
    '\n--linear'#
    '\tIf set the all the parallel jobs will send iterations messages.\n'#
    '\tOtherwise, iteration messages will be evenly spread among the jobs,\n'#
    '\tresulting in fewer iterations per job when jobs increase\n' #
    '\n--tests'#
    '\tDefault value is all tests, if specified it must be one or more of\n'#
   '\tthe following:\n'#
   '\t\tconcurentSinglePort\n'#
    '\t\tconcurentNoPort\n'#
    '\t\tthreadUniquePort\n'#
    '\t\tthreadSemiUniquePort\n'#
    '\t\tthreadNoPort\n'#
    '\t\tthreadComPing\n'#
    '\t\tthreadProtPing\n'#
    '\t\tthreadListPing\n'#
    '\t\tthreadEntityPing\n'#
    '\t\tconcurentComPing\n'#
    '\t\tconcurentProtPing\n'#
    '\t\tconcurentListPing\n'#
    '\t\tconcurentEntityPing\n'
   }
   {Application.exit 0}
end


PP = {Pickle.load Args.ticket}
P = {Connection.take PP}

M = {New Module.manager init}

DS = {M link(url:'x-oz://boot/DPMisc' $)}
Site = {Filter {DPStatistics.siteStatistics} fun{$ S} S.state \= mine end}.1

{Property.put 'print.depth' 100}
{Property.put 'print.width' 100}
{ForAll  Args.jobs
 proc{$ X}
    {ForAll {Filter [
             ConcurentSinglePort#concurentSinglePort
             ConcurentNoPort#concurentNoPort
             ConcurentComPing#concurentComPing

             ConcurentProtPing#concurentProtPing
             ConcurentListPing#concurentListPing
             ConcurentEntityPing#concurentEntityPing

             ThreadUniquePort#threadUniquePort
             ThreadSemiUniquePort#threadSemiUniquePort
             ThreadNoPort#threadNoPort

             ThreadComPing#threadComPing
             ThreadProtPing#threadProtPing
             ThreadListPing#threadListPing
             ThreadEntityPing#threadEntityPing
            ]
             fun{$ P#A}
                {List.member A Args.tests}
             end}
     proc{$ M}
        Th = X
        I = if Args.linear then Args.iterations else  Args.iterations div X end
        T0 M0
     in

        {Wait {Send P start($)}}{System.gcDo}
        {Wait {Send P start($)}}{System.gcDo}
        {Wait {Send P start($)}}{System.gcDo}
        T0 = {Property.get 'time'}
        M0 = {DPStatistics.messageCounter}
        {Wait {M.1 Th I P}}

        {System.show {Record.adjoin {Record.adjoin
                                     {Record.adjoin
                                      {Record.zip {DPStatistics.messageCounter} M0 Number.'-'}
                                      r( th: Th it:I)}
                                     {Record.zip {Record.filter {Property.get time} IsInt} {Record.filter T0 IsInt} Number.'-'}}
                      M.2}
        }

     end}
 end}
{Send P kill}
{Delay 100}
{Application.exit 0}

end
