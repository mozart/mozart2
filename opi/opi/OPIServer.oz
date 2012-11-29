functor
import
   System(showError:SHOW)
   Open(socket)
   Module(manager)
   Error(messageToVirtualString)
   Application(exit)
export
   Port
define

   EOA = &\001                  % end of argument
   EOM = &\002                  % end of message
   QUO = &\003                  % quoted char

   local
      fun {Loop L}
         case L
         of nil    then nil
         [] !EOA|L then QUO|EOA+100|{Loop L}
         [] !EOM|L then QUO|EOM+100|{Loop L}
         [] !QUO|L then QUO|QUO+100|{Loop L}
         []    C|L then           C|{Loop L}
         end
      end
   in
      fun {Escape S}
         {Loop {VirtualString.toString S}}
      end
   end

   fun {ReadMsgs L}
      if L==nil then nil else {ReadMsg L nil} end
   end

   fun {ReadMsg L Args}
      case L
      of nil then nil
      [] !EOM|L then {Reverse Args}|{ReadMsgs L}
      elsecase {ReadArg L nil}
      of Arg#L then
         {ReadMsg L Arg|Args}
      [] unit then nil end
   end

   fun {ReadArg L Arg}
      case L
      of nil      then unit
      [] !EOA  |L then {Reverse Arg}#L
      [] !QUO|N|L then {ReadArg L N-100|Arg}
      []      C|L then {ReadArg L     C|Arg}
      end
   end

   Handlers = {NewDictionary}
   Manager  = {New Module.manager init}

   fun {Close _ Server}
      {Server close}
      nil
   end

   fun {Exit _ _}
      {Application.exit 0}
      nil
   end

   fun lazy {LazyDot R F} R.F end

   fun {AddHandler [Method Url Feature] Server}
      M = {Manager link(url:Url $)}
   in
      Handlers.{String.toAtom Method} := {LazyDot M {String.toAtom Feature}}
      nil
   end

   fun {ShowHandler [S] Server}
      {SHOW S}
      nil
   end

   Handlers.close := Close
   Handlers.exit  := Exit
   Handlers.addHandler := AddHandler
   Handlers.show := ShowHandler

   class OPIServer from Open.socket
      feat port
      attr
         closed          : false
         thread_server   : unit
         thread_run      : unit
         thread_content  : unit
         thread_messages : unit
      meth init
         thread
            thread_server <- {Thread.this}
            {self server(port:self.port)}
         end
         thread
            thread_run <- {Thread.this}
            {self run({self getMessages($)})}
         end
      end
      meth getContent(L)
         thread
            thread_content <- {Thread.this}
            try
               {self read(list:L size:all)}
            catch _ then skip end
         end
      end
      meth getMessages(L)
         thread
            thread_messages <- {Thread.this}
            try
               {ReadMsgs {self getContent($)} L}
            catch _ then skip end
         end
      end
      meth close
         closed <- true
         try Open.socket,close catch _ then skip end
         try {Thread.terminate @thread_server  } catch _ then skip end
         try {Thread.terminate @thread_run     } catch _ then skip end
         try {Thread.terminate @thread_content } catch _ then skip end
         try {Thread.terminate @thread_messages} catch _ then skip end
      end
      meth run(L)
         if @closed then skip
         elsecase L of (ID|Method|Args)|T then
            {self processMessage({String.toInt ID}
                                 {String.toAtom Method}
                                 Args)}
            {self run(T)}
         end
      end
      meth processMessage(ID Method Args)
         H = {Dictionary.condGet Handlers Method unit}
      in
         if H==unit then
            {self putMessage(['replyError' ID 'no handler for `'#Method#'\''])}
         else
            try L={H Args self} in
               {self putMessage('reply'|ID|L)}
            catch E then
               S={Error.messageToVirtualString E}
            in
               {self putMessage(['replyError' ID S])}
            end
         end
      end
      meth putMessage(L)
         %for X in L do
         {ForAll L proc {$ X}
            {self write(vs:{Escape X}#[EOA])}
         end}
         {self write(vs:[EOM])}
         {Delay 1}
      end
   end

   Server = {New OPIServer init}
   Port   = thread Server.port end

end
