local
   class TextSocket from Open.socket Open.text end

   GetMessage = {NewName}

   class IdentificationServer from TextSocket
      prop final
      attr ozPort

   % publish own address in the file $HOME/.netscape/OzFriend
   % and then waits for clients (Oz applets)
      meth init(OzPort)
         Open.socket,init
         Port     = Open.socket, bind(port:$)
         Host     = {OS.uName}.nodename
         FileName = {OS.getEnv 'HOME'}#'/.netscape/OzFriend'
         File     = {New Open.file init(name:  FileName
                                        flags: [write truncate create]
                                        mode:  mode(owner:[read write]))}
      in
         @ozPort = OzPort
         {File write(vs:Host#' '#Port#'\n')}
         {File close}
         {self listen}
         %don't block thread that executed {RunApplets}
         thread {self serveClients} end
      end

      meth serveClients
         Socket = {self accept(acceptClass:Communication accepted:$)}
      in
         {Socket GetMessage(@ozPort)}
         {self serveClients}
      end
   end

   local
      proc {BuildAttributesList Nr Socket AL}
         AttributeName
         Attribute
         M1
      in
         case Nr == 0 then
            AL = nil
         else
            AttributeName = {StringToAtom {Socket getS($)}}
            Attribute = {Socket getS($)}
            AL = AttributeName#Attribute|M1
            {BuildAttributesList (Nr-1) Socket M1}
         end
      end

   in

      class Communication from TextSocket
         prop final

         meth !GetMessage(OzPort)
            Tag = {StringToAtom {self getS($)}}
            ListOfAttributes
            NumberOfAttributes
            Attributes
         in
            case Tag of 'applet' then
               NumberOfAttributes = {String.toInt {self getS($)}}
               {BuildAttributesList NumberOfAttributes self ?ListOfAttributes}
               {List.toRecord 'attributes' ListOfAttributes ?Attributes}
               {Send OzPort applet(toUser:Attributes tk:self)}
            [] 'component' then
               {Send OzPort component({self getS($)})}
            end
         end
      end

   end

   class AppletServer from Server
      meth init
         {LinkToNetscape @port}
      end
      meth applet(...) = M
         URL = M.toUser.url
         MyTk = {NewTk M.tk}
         Applet
      in
         thread            % run applets concurrently
            Applet = {Load URL}
            case {ProcedureArity Applet $} of 2 then
               {Applet MyTk MyTk.applet} % for old applets - 2 arguments
            else
               {Applet MyTk MyTk.applet M.toUser}
            end
         end
      end
      meth component(...) = M
         {Show 'Sorry, cannot handle components'}
      end
   end
in

   proc {LinkToNetscape Port}
      {New IdentificationServer init(Port) _}
   end

   proc {RunApplets}
      {NewServer AppletServer init _}
   end

end
