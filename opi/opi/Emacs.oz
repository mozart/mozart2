%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt and Benjamin Lorenz, 1997-1999
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL WARRANTIES.
%%%

functor
import
   Parser(expandFileName) at 'x-oz://boot/Parser'
   Property(get condGet)
   System(printInfo showInfo showError)
   Error(messageToVirtualString)
   OS(tmpnam)
   Open(socket text file)
   Listener('class')
   OPIServer(port)
export
   getOPI:    GetOPI
   condSend:  CondSend
   interface: CompilerInterfaceEmacs
define
   TimeoutToConfigBar = 200
   TimeoutToUpdateBar = TimeoutToConfigBar

   local
      MSG_ERROR = [17]

      class TextSocket from Open.socket Open.text
         prop final
         meth readQuery($) S in
            Open.text, getS(?S)
            case S of false then ""
            elseof [4] then ""   % ^D
            elseof [4 13] then ""   % ^D^M
            else {Coders.decode S [utf8]}#'\n'#TextSocket, readQuery($)
            end
         end
      end
   in
      class CompilerInterfaceEmacs from Listener.'class'
         prop final
         attr
            Socket: unit BarSync: _ BarLock: {NewLock} Topped: false
            lastFile: unit lastLine: unit lastColumn: unit
         meth init(CompilerObject Host <= unit Print <= System.printInfo)
            lock Sock Port in
               thread
                  Sock = {New TextSocket server(port: ?Port)}
               end
               {Wait Port}
               {Wait OPIServer.port}
               Socket <- Sock
               {Print '\'oz-socket '#case Host of unit then ""
                                     else '"'#Host#'" '
                                     end#Port#' '#OPIServer.port#'\''}
               {System.showInfo ''}
               Listener.'class', init(CompilerObject Serve)
            end
         end
         meth close()
            Listener.'class', close()
            case @Socket of unit then skip
            elseof S then {S close()}
            end
         end
         meth Write(VS)
            case @Socket of unit then skip
            elseof S then
               try
                  {S write(vs: {Coders.encode VS [utf8]})}
               catch system(os(os _ 32 ...) ...) then
                  Socket <- unit
               end
            end
         end

         meth readQueries()
            case @Socket of unit then skip
            elseof S then VS0 VS in
               {S readQuery(?VS0)}
               VS = case VS0 of ""#'\n'#VS1 then VS1 else VS0 end
               {Listener.'class', getNarrator($)
                enqueue(feedVirtualString(VS))}
               CompilerInterfaceEmacs, readQueries()
            end
         end

         meth Serve(Ms)
            case Ms of M|Mr then
               case M of info(VS) then
                  CompilerInterfaceEmacs, Write(VS)
               [] info(VS _) then
                  CompilerInterfaceEmacs, Write(VS)
               [] message(Record _) then
                  case {Label Record} of error then
                     CompilerInterfaceEmacs, ToTop()
                  else skip
                  end
                  CompilerInterfaceEmacs,
                  Write({Error.messageToVirtualString Record})
               [] displaySource(_ Ext VS) then Name File in
                  Name = {OS.tmpnam}#Ext
                  File = {New Open.file
                          init(name: Name
                               flags: [write create truncate])}
                  {File write(vs: {Coders.encode VS [utf8]})}
                  {File close()}
                  CompilerInterfaceEmacs, Write({VirtualString.toAtom
                                                 '\'oz-show-temp '#Name#'\''})
               [] runQuery(_ _) then
                  Topped <- false
               [] attention() then
                  CompilerInterfaceEmacs, ToTop()
               else skip
               end
               CompilerInterfaceEmacs, Serve(Mr)
            end
         end
         meth ToTop()
            if {Property.get 'oz.standalone'} then skip
            elseif @Topped then skip
            else
               CompilerInterfaceEmacs, Write(MSG_ERROR)
               Topped <- true
            end
         end

         meth bar(file:F line:L column:C state:S)
            BarSync <- _ = unit
            if F == '' orelse L == unit then
               CompilerInterfaceEmacs, removeBar()
            else NewF in
               NewF = case {Parser.expandFileName F} of false then F
                      elseof X then X
                      end
               CompilerInterfaceEmacs, MakeOzBar(NewF L C S)
            end
         end
         meth delayedBar(file:F line:L column:C state:S<=unchanged) New in
            BarSync <- New = unit
            thread
               {WaitOr New {Alarm TimeoutToUpdateBar}}
               if {IsDet New} then skip else
                  CompilerInterfaceEmacs, bar(file:F line:L column:C state:S)
               end
            end
         end
         meth configureBar(State) New in
            BarSync <- New = unit
            thread
               {WaitOr New {Alarm TimeoutToConfigBar}}
               if {IsDet New} orelse @lastFile == unit then skip else
                  CompilerInterfaceEmacs,
                  MakeOzBar(@lastFile @lastLine @lastColumn State)
               end
            end
         end
         meth removeBar()
            BarSync <- _ = unit
            CompilerInterfaceEmacs, MakeOzBar('' 0 0 hide)
         end
         meth exit()
            BarSync <- _ = unit
            CompilerInterfaceEmacs, MakeOzBar('' 0 0 exit)
         end
         meth MakeOzBar(File Line Column State)
            lock @BarLock then
               S = 'oz-bar ' # File # ' ' # Line # ' ' # Column # ' ' # State
            in
               CompilerInterfaceEmacs, Write('\'' # S # '\'')
               lastFile <- File
               lastLine <- Line
               lastColumn <- Column
               {Delay 1}   % this is needed for Emacs
            end
         end
      end
   end

   fun {GetOPI}
      {Property.condGet 'opi.compiler' false}
   end

   CondSend = condSend(interface:
                          proc {$ M}
                             case {GetOPI} of false then skip
                             elseof OPI then
                                {OPI M}
                             end
                          end
                       compiler:
                          proc {$ M}
                             case {GetOPI} of false then skip
                             elseof OPI then
                                {{OPI getNarrator($)} M}
                             end
                          end)

end
