functor

require
   Boot_OS at 'x-oz://boot/OS'

prepare

   local
      fun {FlagsToMode Flags}
         if {Member 'O_WRONLY' Flags} then
            if {Member 'O_APPEND' Flags} then
               "ab"
            else
               "wb"
            end
         elseif {Member 'O_RDWR' Flags} then
            if {Not {Member 'O_CREAT' Flags}} then
               "r+b"
            elseif {Member 'O_APPEND' Flags} then
               "a+b"
            else
               "w+b"
            end
         else
            "rb"
         end
      end

      fun {Open FileName Flags CreateMode}
         {Boot_OS.fopen FileName {FlagsToMode Flags}}
      end

      fun {FileDesc DescName}
         case DescName
         of 'STDIN_FILENO'  then {Boot_OS.stdin}
         [] 'STDOUT_FILENO' then {Boot_OS.stdout}
         [] 'STDERR_FILENO' then {Boot_OS.stderr}
         end
      end

      proc {Read FD Max ?Head Tail ?Count}
         {Boot_OS.fread FD Max Tail Count Head}
      end

      fun {Write FD Data}
         {Boot_OS.fwrite FD Data}
      end

      proc {LSeek FD Whence Offset ?Where}
         {Boot_OS.fseek FD Offset Whence Where}
      end

      proc {Close FD}
         {Boot_OS.fclose FD}
      end
   in
      OS = os(rand:       Boot_OS.rand
              srand:      Boot_OS.srand
              randLimits: Boot_OS.randLimits

              fopen:      Boot_OS.fopen
              fread:      Read
              fwrite:     Boot_OS.fwrite
              fseek:      Boot_OS.fseek
              fclose:     Boot_OS.fclose

              stdin:      Boot_OS.stdin
              stdout:     Boot_OS.stdout
              stderr:     Boot_OS.stderr

              % compatibility
              open:       Open
              fileDesc:   FileDesc
              read:       Read
              write:      Write
              lSeek:      LSeek
              close:      Close)
   end

end
