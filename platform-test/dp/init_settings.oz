functor
import
   Remote
   Connection
   Pickle
export
   Return
define
   fun{CreateTest Config Check}
      proc{$}
          M={New Remote.manager Config}
      in
         {M apply(Check)}
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
           {{CreateTest init(port:10101) functor
                                         import
                                            DPInit
                                            Connection
                                            Pickle
                                         define
                                            {DPInit.getSettings}.port=10101
                                            {Pickle.save
                                             {Connection.offer testatom}
                                             '/tmp/afd'}
                                         end}}
           {Connection.take {Pickle.load '/tmp/afd'}}=testatom
        end

   Return = dp([init_settings_plain(Plain keys:[remote])
                init_settings_firewall(FireWall keys:[remote])
                init_settings_port(Port keys:[remote])
               ])
end
