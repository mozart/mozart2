functor
import
   Remote
   Connection
   Pickle
   System(show:Show)
export
   Return
define
   fun{CreateTest Config Check}
      proc{$}
          M={New Remote.manager Config}
      in
         {M apply(Check)}
         {Delay 2000}
         {M close}
      end
   end

   % Check that firewall option is false with no specific initialization
   Plain={CreateTest init functor
                          import
                             DPInit
                          define
                             {DPInit.getSettings}.firewall=false
                          end}

   FireWall={CreateTest init(firewall:true)
             functor
             import
                DPInit
             define
                {DPInit.getSettings}.firewall=true
             end}

   Port=proc{$}
           thread
              {{CreateTest init(port:10101) functor
                                            import
                                               DPInit
                                               Connection
                                               Pickle
                                               OS
                                            define
                                               {DPInit.getSettings}.port=10101
                                               {Pickle.save
                                                {Connection.offer {OS.getPID}}
                                                '/tmp/afd'}
                                            end}}
           end
           {Delay 1000}
           {Connection.take {Pickle.load '/tmp/afd'}}=_
        end

   LoopbackIp={CreateTest init(ip:"127.0.0.1")
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
