\define OldServer
\ifndef OldServer

local
   InitServer = {NewName}
   class Server
      attr
         port close serve

      meth !InitServer(?Port)
         proc {Serve X|Xs}
            {@serve X}
            {Serve Xs}
         end
         Stream
         CloseException = {NewName}
      in
         proc {@close}
            raise CloseException end
         end
         {NewPort Stream Port}
         @port  = Port
         @serve = self
         thread
            try
               {Serve Stream}
            catch
               !CloseException then skip
            end
         end
      end
   end
in
   fun {NewServer Class Init}
      Port
      Object = {New class $ from Server Class end InitServer(Port)}
   in
      {Object Init}
      Port
   end
end

\else

local
   InitServer = {NewName}
in
   class Server
      attr
         port close serve

      meth !InitServer(?Port)
         proc {Serve X|Xs}
            {@serve X}
            {Serve Xs}
         end
         Stream
         CloseException = {NewName}
      in
         proc {@close}
            raise CloseException end
         end
         {NewPort Stream Port}
         @port  = Port
         @serve = self
         thread
            try
               {Serve Stream}
            catch
               !CloseException then skip
            end
         end
      end
   end

   fun {NewServer Class Init}
      Port
      Object = {New Class InitServer(Port)}
   in
      {Object Init}
      Port
   end

end

\endif
