%%%  (c) Perdio Project, DFKI & SICS
%%%  Universit"at des Saarlandes
%%%   Postfach 15 11 59, D-66041 Saarbruecken
%%%   Phone (+49) 681 302-5312
%%%  SICS
%%%   Box 1263, S-16428 Sweden
%%%   Phone (+46) 8 7521500
%%%
%%%  Author: Michael Mehl
%%%  Email: mehl@ps.uni-sb.de

declare
local

   proc {ReadAll Stream Print}
      case {Stream read(list:$)}
      of nil then
         {Print "* Connection closed\n"}
         {Stream close}
      elseof S then
         {Print S}
         {ReadAll Stream Print}
      end
   end

   S
   GG = {NewCell S}
   {Gate.close}
   {Gate.open S}
   proc {Listener P}
      Old New in {Exchange GG Old New}
      case Old of H|R then H=P New = R end
   end
in
   class ComputeServer from Open.pipe
      prop
         locking
      attr
         pipe:nil
         port
         host
         closed:false
      meth init(rshCmd:     Cmd      <= rsh
                host:       HostName
                ozHome:     OzHome   <= unit
                showWindow: SW       <= unit
               )
         lock
            case @closed then
               raise system(perdio computeServer alreadyClosed) end
            elsecase @pipe of nil then
               OzCS = case OzHome of unit then ozcs
                      else OzHome#"/bin/"#ozcs end
            in
               thread {Listener @port} end
               pipe <- {New Open.pipe
                        init(cmd:Cmd
                             args:[HostName OzCS#" http://www.ps.uni-sb.de/~mehl/ozrcs -gate "#{Gate.id}])}
               case SW == unit then skip
               else {self ShowWindow(SW HostName)} end
            else
               raise error(perdio computeServer alreadyInitialized) end
            end
         end
      end
      meth exec(P)
         lock
            case @closed then
               raise system(perdio computeServer alreadyClosed) end
            else
               {Send @port P}
            end
         end
      end
      meth close()
         lock
            case @closed then
               skip
            else
               {self exec(proc {$} {Exit 0} end)}
               closed<-true
               % {@pipe close}
            end
         end
      end
      meth ShowWindow(Tk HostName)
\ifdef BACKGROUND
         thread
            try
               {ReadAll @pipe System.printInfo}
            catch system(open(alreadyClosed _  _) ...) then
               {Print "* Connection closed\n"}
            end
         end
\else
         proc {DelProc} {W tkClose} {self close} end
         W={New Tk.toplevel tkInit(title:"Oz Compute Server@"#HostName
                                   delete:DelProc)}
         T={New Tk.text tkInit(parent:W font:fixed)}
         S={New Tk.scrollbar tkInit(parent:W)}
         proc {Print VS}
            {T tk(insert 'end' VS)}
            {T tk(yview moveto 1)}
         end
      in
         {Tk.addYScrollbar T S}
         {Tk.send pack(T S o(side:left expand:yes fill:both))}
         thread
            try
               {ReadAll @pipe Print}
            catch system(tk(alreadyClosed _) ...) then skip
            [] system(open(alreadyClosed _  _) ...) then
               {Print "* Connection closed\n"}
            end
         end
\endif
      end
   end
end

proc {MakeOZRCS File}
{Application.exec
 File
 %% What do we need
 c('SP':       lazy
                                   % System programming, contains Show
                                   % ...only load if it is requested
   'Browser':  lazy
   'DP': lazy)
                                   % Contains browse
                                   % ...only load if it is requested
 fun {$ IMPORT}
   %% Introduce system programming modules
    \insert 'SP.env'
    = IMPORT.'SP'
   %% Introduce browser
    \insert 'Browser.env'
    = IMPORT.'Browser'
    \insert 'DP.env'
    = IMPORT.'DP'
 in
   %% The application
   fun {$ Argv}
      Stream
      Port={NewPort Stream}
      Stop
   in
      {Gate.send Argv.gate Port}
      {Show 'Slave running'}
      try
         {ForAll Stream proc {$ P} {P} end}
      end
      0
   end
 end
 single(gate(type:string optional:false))
}
end
