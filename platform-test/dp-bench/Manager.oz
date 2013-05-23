functor
import
   Application
   Pickle
   System
   Connection
define
   PP
   DD = {NewDictionary}
   
      Args = {Application.getCmdArgs record('ticket'(single type:string)
					    'help'(   single   type:bool default:false))}
   if Args.help then
      {System.showInfo '--ticket\n'#
       '\tThe file where the server should save its ticket\n'}
      {Application.exit 0}
   end
   thread 
      {List.forAll {NewPort $ PP} proc{$  M}
				     thread 
					case M of new_port(P) then 
					   {Send P {NewPort _}}
					elseof  old_port(P) then
					   {Send P PP}
					elseof no_port(P) then
					   {Send P p}
					elseof bind(V) then
					   V = unit
					elseof id_var(Id) then
					   {Send DD.Id _}
					elseof start(V) then
					   {Dictionary.removeAll DD}
					   {System.gcDo}
					   {System.gcDo}
					   V = unit
					elseof register(P Id) then 
					   DD.Id:=P
					elseof send(Id) then
					   {Send DD.Id a}
					elseof send_port(Id) then
					   {Send DD.Id {NewPort _}}
					elseof kill then
					   {Application.exit 0}
					end
				     end
				  end}
   end
   {Pickle.save {Connection.offerUnlimited PP} Args.ticket}
end
