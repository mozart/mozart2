functor
import
   Remote
   Connection
   Pickle
   System(show:Show)
   OS(tmpnam unlink)
export
   Return
define
   fun{CreateTest Config Check}
      proc{$}
          M={New Remote.manager Config}
      in
         {Wait {M apply(Check $)}}
         {M close}
      end
   end

   % Check that firewall option is false with no specific initialization
   Plain =
   {CreateTest init
    functor
    import
       DPInit
    define
       {DPInit.getSettings}.firewall=false
    end}

   FireWall =
   {CreateTest init(firewall:true)
    functor
    import
       DPInit
    define
       {DPInit.getSettings}.firewall=true
    end}

   Port =
   local
      C={NewCell 10101}
      fun {MakePortNumber} N1 N2 in
         {Exchange C N1 N2}
         N2 = 1+N1
         N1
      end
   in
      proc{$}
         TempFile = {OS.tmpnam}
         PortNum  = {MakePortNumber}
         Pid
      in
         try
            thread
               {{CreateTest init(port:PortNum)
                 functor
                 import
                    DPInit
                    Connection
                    Pickle
                    OS
                 define
                    {DPInit.getSettings}.port=PortNum
                    local N={OS.getPID} in
                       {Pickle.save {Connection.offer N} TempFile}
                       !Pid=N
                    end
                 end}}
            end
            {Wait Pid}
            {Connection.take {Pickle.load TempFile}}=Pid
         finally
            try {OS.unlink TempFile} catch _ then skip end
         end
      end
   end

   LoopbackIp =
   {CreateTest init(ip:"127.0.0.1")
    functor
    import
       Remote
    define
       M={New Remote.manager init}
    in
       {M apply(functor
                define
                   skip
                end)}
       {M close}
    end}

   Return = dp([init_settings_plain(Plain keys:[remote])
                init_settings_firewall(FireWall keys:[remote])
                init_settings_port(Port keys:[remote])
                init_settings_loopback_ip(LoopbackIp keys:[remote])
               ])
end
