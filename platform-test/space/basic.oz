%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {$ IMPORT}
   \insert '../lib/import.oz'
in

   space({Map
          [failure(equal(fun {$}
                            {Space.ask {Space.new proc {$ X} fail end}}
                         end
                         failed)
                   keys: [space failure])

          entailment(equal(fun {$}
                              S={Space.new proc {$ X} X = 1 end}
                           in
                              [{Space.askVerbose S}
                               {Space.merge {Space.clone S}}
                               {Space.merge {Space.clone S}}
                               {Space.merge {Space.clone S}}
                               {Space.merge {Space.clone S}}
                               {Space.merge S}]
                           end
                           [succeeded(entailed) 1 1 1 1 1])
                     keys: [space entailment clone merge])

          commit(equal(fun {$}
                          S1 = {Space.new proc {$ X}
                                             choice X = 1 [] X = 2 end
                                          end}
                          S2 = {Space.new proc {$ X}
                                             choice X = 1 [] X = 2 end
                                          end}
                       in
                          [{Space.ask S1} {Space.ask S2}
                           ({Space.commit S1 1} {Space.ask S1})
                           ({Space.commit S2 2} {Space.ask S2})
                           {Space.merge S1} {Space.merge S2}]
                       end
                       [alternatives(2) alternatives(2)
                        succeeded succeeded
                        1 2])
                 keys: [space ask commit merge new])

           suspension(entailed(proc {$}
                                  U
                                  S = thread
                                         {Space.new
                                          proc {$ X}
                                             if X = 1 then U = 1 end
                                          end}
                                      end
                               in
                                  case {Space.askVerbose S}
                                  of succeeded(suspended) then
                                     thread {Space.merge S 1} end
                                     %% Ho!
                                     {Thread.setThisPriority low}
                                     case U==1 then skip end
                                     %% and back;
                                     {Thread.setThisPriority medium}
                                  end
                               end)
                      keys: [space 'thread'])

           unstable(entailed(proc {$}
                                Z
                                S1 = {Space.new proc {$ X}
                                                   case Z==1 then X=1
                                                   else X=2 end
                                                end}
                                S2 = {Space.new proc {$ X}
                                                   case Z==1 then X=1
                                                   else X=2 end
                                                end}
                                A2 = thread {Space.askVerbose S2} end
                                A1 = thread {Space.ask        S1} end
                             in
                                {IsFree A1 true}
                                ({Label A2}==blocked) = true
                                {IsFree A2.1 true}
                                Z = 1
                                {Thread.setThisPriority low}
                                case A1 of succeeded then
                                   {Loop.for 1 10 1
                                    proc {$ _}
                                       thread
                                          {Space.merge {Space.clone S1}} = 1
                                       end
                                    end}
                                end
                                case A2 of blocked(succeeded(entailed)) then
                                   {Loop.for 1 10 1
                                    proc {$ _}
                                       thread
                                          {Space.merge {Space.clone S2}} = 1
                                       end
                                    end}
                                end
                                {Thread.setThisPriority medium}
                             end)
                    keys: [space 'thread'])

           blocking(entailed(proc {$}
                                X
                                S1 = {Space.new
                                      proc {$ Y}
                                         {Space.ask {Space.new
                                                     proc {$ Z}
                                                        X=Y
                                                     end} _}
                                      end}
                                S2 = {Space.new
                                      proc {$ Y}
                                         dis X=Y [] Y=X end
                                      end}
                             in
                                {Space.askVerbose S1}=succeeded(suspended)
                                {Space.askVerbose S2}=alternatives(2)
                             end)
                    keys: [space 'dis'])

           propagation(entailed(proc {$}
                                   D
                                   S = {Space.new
                                        proc {$ X} Y Z F in
                                           thread
                                              dis Z = 1 then Y = 1
                                              [] Z = 2 then Y = 2
                                              end
                                           end
                                           if Y = 1 D = 1 then F = 1
                                           [] Y = 2 D = 1 then F = 2
                                           else fail
                                           end
                                           X = Z#Y#F#D
                                        end}
                                   A = thread {Space.ask S} end
                                in
                                   {IsFree A true}
                                   D = 1
                                   {Thread.setThisPriority low}
                                   case A of alternatives(2) then
                                      S2 = {Space.clone S}
                                   in
                                      {Space.commit S2 1}
                                      {Space.commit S 2}
                                      {Space.ask S2 succeeded}
                                      {Space.ask S succeeded}
                                      {Thread.setThisPriority low}
                                      {Space.merge S2  1#1#1#1}
                                      {Space.merge S   2#2#2#1}
                                   end
                                   {Thread.setThisPriority medium}
                                end)
                       keys: [space 'dis' 'thread'])

           alternatives(entailed(proc {$}
                                    S1 = {Space.new
                                          proc {$ X}
                                             choice X=1 [] X=2 [] X=3 end
                                          end}
                                    S2 = {Space.clone S1}
                                    S3 = {Space.clone S2}
                                 in
                                    {Space.ask S1 alternatives(3)}
                                    {Space.ask S2 alternatives(3)}
                                    {Space.ask S3 alternatives(3)}
                                    {Space.commit S1 1}
                                    {Space.commit S2 2}
                                    {Space.commit S3 3}
                                    {Space.askVerbose S1 succeeded(entailed)}
                                    {Space.askVerbose S2 succeeded(entailed)}
                                    {Space.askVerbose S3 succeeded(entailed)}
                                    {Space.merge S1 1}
                                    {Space.merge S2 2}
                                    {Space.merge S3 3}
                                 end)
                        keys: [space clone commit merge ask 'choice'])

           deep(equal(fun {$}
                         {SearchAll proc {$ X}
                                       dis X = 1
                                       []
                                          dis X = 3
                                          [] dis X = a [] X = b end
                                          [] X = 4
                                          end
                                       [] X = 5
                                       end
                                    end}
                      end
                      [1 3 a b 4 5])
                keys: [space 'dis'])

           unstable_dis(entailed(proc {$}
                                    U in
                                    thread
                                       {SearchAll
                                        proc {$ X}
                                           U=1
                                           if U=1 then skip end
                                           thread
                                              dis X = 1
                                              []
                                                 dis X = 3
                                                 [] dis X = a [] X = b end
                                                 [] X = 4
                                                 end
                                              [] X = 5
                                              end
                                           end
                                        end} = [1 3 a b 4 5]
                                    end
                                    U=1
                                 end)
                        keys: [space stability 'thread' 'dis'])

           unstable_deep(entailed(proc {$}
                                     U1 V1 U2 V2
                                  in
                                     thread
                                        {SearchAll proc {$ X} H in
                                                      dis X=1
                                                      [] dis X=a
                                                            if U1=1 then H=1
                                                            else fail
                                                            end
                                                            dis H=1 [] V1=2 end
                                                         [] X=b
                                                         end
                                                      [] X=2
                                                      end
                                                   end} = [1 a b 2]
                                     end
                                     thread
                                        {SearchAll proc {$ X} H in
                                                      dis X=1
                                                      [] dis X=a
                                                            if U2=1 then H=1
                                                            else fail
                                                            end
                                                            dis H=1 [] V2=2 end
                                                         [] X=b
                                                         end
                                                      [] X=2
                                                      end
                                                   end} = [1 b 2]
                                     end
                                     U1=1 V1=2
                                     U2=2 V2=1
                                  end)
                         keys: [space stability 'dis'])

           clone([vars(entailed(proc {$}
                                   proc {MakeVars ?V}
                                      UVAR  = {fun {$} _ end}
                                      SVAR  = {fun {$} _ end}
                                      CVAR  = {fun {$} _ end}
                                      !V    = vars(uvar:UVAR duvar:_
                                                   svar:SVAR dsvar:_
                                                   cvar:CVAR dcvar:_)
                                      DSVAR = V.dsvar
                                      DCVAR = V.dcvar
                                      SYNC DSYNC
                                   in
                                      CVAR  = {FD.decl}
                                      DCVAR = {FD.decl}
                                      thread SYNC=1  {Wait SVAR}  end
                                      thread DSYNC=1 {Wait DSVAR} end
                                      {Wait SYNC}
                                      {Wait DSYNC}
                                   end

                                   GV = {MakeVars}

                                   S1 = {Space.new proc {$ X}
                                                      X = GV # {MakeVars}
                                                   end}

                                   S2 = {Space.clone S1}
                                   G1#L1 = {Space.merge S1}
                                   G2#L2 = {Space.merge S2}
                                in
                                   G1.uvar=1 G1.duvar=1
                                   G1.svar=1 G1.dsvar=1
                                   G1.cvar=1 G1.dcvar=1
                                   {IsDet G2.uvar}=true  {IsDet G2.duvar}=true
                                   {IsDet G2.svar}=true  {IsDet G2.dsvar}=true
                                   {IsDet G2.cvar}=true  {IsDet G2.dcvar}=true
                                   L1.uvar=1 L1.duvar=1
                                   L1.svar=1 L1.dsvar=1
                                   L1.cvar=1 L1.dcvar=1
                                   {IsDet L2.uvar}=false {IsDet L2.duvar}=false
                                   {IsDet L2.svar}=false {IsDet L2.dsvar}=false
                                   {IsDet L2.cvar}=false {IsDet L2.dcvar}=false
                                   L2.svar=1 L2.dsvar=1
                                end)
                       keys: [variable clone space])
                  name(entailed(local
                                   PreName = {NewName}
                                in
                                   proc {$}
                                      LocalName = {NewName}
                                      S1={Space.new
                                          proc {$ X}
                                             X = LocalName # PreName # {NewName}
                                          end}
                                      S2 = {Space.clone S1}
                                      X1 = {Space.merge S1}
                                      X2 = {Space.merge S2}
                                   in
                                      X1.1=X2.1=LocalName
                                      X1.2=X2.2=PreName
                                      not X1.3=X2.3 end
                                   end
                                end)
                       keys: [name clone space])

                  procedure(entailed(local
                                        proc {PreProc} skip end
                                     in
                                        proc {$}
                                           LocalProc = proc {$} skip end
                                           S1 = {Space.new
                                                 proc {$ X}
                                                    X = LocalProc # PreProc #
                                                    proc {$} skip end
                                                 end}
                                           S2 = {Space.clone S1}
                                           X1 = {Space.merge S1}
                                           X2 = {Space.merge S2}
                                        in
                                           X1.1=X2.1=LocalProc
                                           X1.2=X2.2=PreProc
                                           not X1.3=X2.3 end
                                        end
                                     end)
                            keys: [procedure clone space])
                  cell(entailed(proc {$}
                                   LocalCell = {NewCell _}
                                   S1 = {Space.new proc {$ X}
                                                      X = LocalCell #
                                                      {NewCell _}
                                                   end}
                                   S2 = {Space.clone S1}
                                   X1 = {Space.merge S1}
                                   X2 = {Space.merge S2}
                                in
                                   X1.1=X2.1=LocalCell
                                   not X1.2=X2.2 end
                                end)
                       keys: [cell clone space])

                  space(entailed(proc {$}
                                    LocalSpace = {Space.new
                                                  proc {$ X} skip end}
                                    S1 = {Space.new
                                          proc {$ X}
                                             X = LocalSpace #
                                             {Space.new proc {$ X} skip end}
                                          end}
                                    S2 = {Space.clone S1}
                                    X1 = {Space.merge S1}
                                    X2 = {Space.merge S2}
                                 in
                                    X1.1=X2.1=LocalSpace
                                    not X1.2=X2.2 end
                                 end)
                        keys: [space clone])])

           nested(entailed(proc {$}
                              U
                           in
                              thread {SearchAll
                                      proc {$ X}
                                         Y in
                                         X = {SearchAll
                                              proc {$ X}
                                                 thread
                                                    dis X = 1
                                                    [] X = 2
                                                    [] X = 3
                                                    end
                                                 end
                                                 if U = 1 then skip end
                                              end} # Y
                                         dis Y=a [] Y=b end
                                      end}
                              end = [[1 2 3]#a [1 2 3]#b]
                              U=1
                           end)
                  keys: [space])

           unblock(entailed(proc {$}
                               Z
                               S = {Space.new proc {$ X}
                                                 X = local _ in
                                                        {Wait Z}
                                                        {Wait _}
                                                        unit
                                                     end
                                              end}
                            in
                               case thread {Space.askVerbose S} end
                               of blocked(_) then
                                  Z=unit
                               end
                               {Space.ask S}=succeeded
                            end)
                   keys: [stability space])

           inject(entailed(proc {$}
                              SFF={Space.new proc {$ X} fail end}
                              SSF={Space.new proc {$ X} skip  end}
                              SAF={Space.new proc {$ X} dis X=1 [] X=2 end end}
                              SFS={Space.clone SFF} SFA={Space.clone SFF}
                              SSS={Space.clone SSF} SSA={Space.clone SSF}
                              SAS={Space.clone SAF} SAA={Space.clone SAF}
                           in
                              {Space.inject SFF proc {$ X} fail end}
                              {Space.inject SSF proc {$ X} fail end}
                              {Space.inject SAF proc {$ X} fail end}
                              {Space.ask SFF failed}
                              {Space.ask SSF failed}
                              {Space.ask SAF failed}
                              {Space.inject SFS proc {$ X} X=1 end}
                              {Space.inject SSS proc {$ X} X=1 end}
                              {Space.inject SAS proc {$ X} X=1 end}
                              {Space.ask SFS failed}
                              {Space.ask SSS succeeded}
                              {Space.ask SAS succeeded}
                              {Space.inject SFA
                               proc {$ X} dis X=1 [] X=2 [] X=3 end end}
                              {Space.inject SSA
                               proc {$ X} dis X=1 [] X=2 [] X=3 end end}
                              {Space.inject SAA
                               proc {$ X} dis X=1 [] X=2 [] X=3 end end}
                              {Space.ask SFA failed}
                              {Space.ask SSA alternatives(3)}
                              {Space.ask SAA alternatives(3)}
                           end)
                  keys: ['choice' 'dis' inject space clone])

           merge([failed(entailed(proc {$}
                                     SIF={Space.new proc {$ X} fail end}
                                     SOF={Space.new proc {$ X} skip end}
                                  in
                                     {Space.ask SIF failed}
                                     {Space.ask SOF succeeded}
                                     {Space.inject SOF proc {$ X}
                                                          {Space.merge SIF X}
                                                       end}
                                     {Space.ask SOF failed}
                                  end)
                         keys: [merge space])

                  blocked(entailed(proc {$}
                                      Y Z
                                      S={Space.new proc {$ X} Y=a Y=X end}
                                   in
                                      {IsFree Y true}
                                      {Space.merge S Z}
                                      {Wait Z} Z=a
                                      {Wait Y} Y=a
                                   end)
                          keys: [merge space])

                  sibling(entailed(proc {$}
                                      proc {Loop X}
                                         case {IsDet X} then skip
                                         else {Loop X} end
                                      end
                                      proc {Waste N}
                                         case N>0 then {Waste N-1}
                                         else skip end
                                      end
                                      S1 = {Space.new Loop}
                                      S2 = {Space.new Loop}
                                      S3 = {Space.new proc {$ X}
                                                         _#_#C=X in {Loop C}
                                                      end}
                                   in
                                      {Space.inject S3 proc {$ X}
                                                          X.1={Space.merge S1}
                                                       end}
                                      {Space.inject S3 proc {$ X}
                                                          X.2={Space.merge S2}
                                                       end}
                                      {Waste 5000}
                                      {Space.inject S3 proc {$ X}
                                                          X = unit#_#_
                                                       end}
                                      {Space.inject S3 proc {$ X}
                                                          X = _#unit#_
                                                       end}
                                      {Space.inject S3 proc {$ X}
                                                          X = _#_#unit
                                                       end}
                                      {Space.ask S1 merged}
                                      {Space.ask S2 merged}
                                      {Space.askVerbose S3 succeeded(entailed)}
                                   end)
                          keys: [merge space])

                  parent(entailed(proc {$}
                                     proc {Loop X}
                                        case {IsDet X} then skip
                                        else {Loop X} end
                                     end
                                     proc {Waste N}
                                        case N>0 then {Waste N-1}
                                        else skip end
                                     end
                                     S = {Space.new
                                          proc {$ X}
                                             S1 = {Space.new Loop}
                                             S2 = {Space.new Loop}
                                          in
                                             X = thread {Loop} end#S1#_#S2#_
                                          end}
                                  in
                                     {Space.inject S proc {$ X}
                                                        X.3={Space.merge X.2}
                                                     end}
                                     {Space.inject S proc {$ X}
                                                        X.5={Space.merge X.4}
                                                     end}
                                     {Waste 5000}
                                     {Space.inject S proc {$ X}
                                                        X.3 = unit
                                                     end}
                                     {Space.inject S proc {$ X}
                                                        X.1 = unit
                                                     end}
                                     {Space.inject S proc {$ X}
                                                        X.5 = unit
                                                     end}
                                     {Space.askVerbose S succeeded(entailed)}
                                  end)
                         keys: [merge space])

                  hierarchy(entailed(proc {$}
                                        proc {Skip _} skip end
                                     in
                                        try
                                           S = {Space.new Skip}
                                        in
                                           {Space.inject S
                                            proc {$ X}
                                               try
                                                  {Space.merge S _}
                                                  fail
                                               catch error(kernel(spaceSuper _) ...) then skip
                                               end
                                            end}
                                           {Space.ask S succeeded}
                                        catch error(kernel(spaceSuper _) ...) then fail
                                        end
                                        try
                                           S = {Space.new proc {$ X}
                                                             X = {Space.new Skip}
                                                          end}
                                        in
                                           {Space.inject S
                                            proc {$ X}
                                               {Space.inject X
                                                proc {$ _}
                                                   try
                                                      {Space.merge S _}
                                                      fail
                                                   catch error(kernel(spaceSuper _) ...) then skip
                                                   end
                                                end}
                                               {Space.ask X succeeded}
                                            end}
                                           {Space.ask S succeeded}
                                        catch error(kernel(spaceSuper _) ...) then fail
                                        end
                                        try
                                           S = {Space.new proc {$ X}
                                                             X = {Space.new Skip}
                                                          end}
                                        in
                                           {Space.inject S proc {$ X}
                                                              {Space.merge X _}
                                                           end}
                                           {Space.ask S succeeded}
                                        catch error(kernel(spaceSuper _) ...) then fail
                                        end
                                        try
                                           S1 = {Space.new Skip}
                                           S2 = {Space.new Skip}
                                        in
                                           {Space.inject S1 proc {$ X} {Space.merge S2 X} end}
                                           {Space.ask S1 succeeded}
                                           {Space.ask S2 merged}
                                        catch error(kernel(spaceSuper _) ...) then fail
                                        end
                                     end)
                            keys: [merge space])

                  inject(entailed(proc {$}
                                     proc {Skip _} skip end
                                  in
                                     try
                                        S = {Space.new Skip}
                                     in
                                        {Space.inject S Skip}
                                        {Space.ask S succeeded}
                                     catch error(kernel(spaceParent _) ...) then fail
                                     end
                                     try
                                        S = {Space.new Skip}
                                     in
                                        {Space.inject S
                                         proc {$ X}
                                            try
                                               {Space.inject S Skip}
                                               fail
                                            catch error(kernel(spaceParent _) ...) then skip
                                            end
                                         end}
                                        {Space.ask S succeeded}
                                     catch error(kernel(spaceParent _) ...) then fail
                                     end
                                     try
                                        S = {Space.new proc {$ X}
                                                          X = {Space.new Skip}
                                                       end}
                                     in
                                        {Space.inject S
                                         proc {$ X}
                                            {Space.inject X
                                             proc {$ _}
                                                try
                                                   {Space.inject S Skip}
                                                   fail
                                                catch error(kernel(spaceParent _) ...) then skip
                                                end
                                             end}
                                         end}
                                     catch error(kernel(spaceParent _) ...) then fail
                                     end
                                     try
                                        S1 = {Space.new Skip}
                                        S2 = {Space.new Skip}
                                     in
                                        {Space.inject S1
                                         proc {$ X}
                                            try
                                               {Space.inject S2 Skip}
                                               fail
                                            catch error(kernel(spaceParent _) ...) then skip
                                            end
                                         end}
                                        {Space.ask S1 succeeded}
                                     catch error(kernel(spaceParent _) ...) then fail
                                     end
                                  end)
                         keys: [merge space])
                 ])


           'unit'(entailed(proc {$}
                              proc {AssumeDet X}
                                 case {IsDet X} then skip else fail end
                              end
                              S1={Space.new proc {$ X}
                                               A#B#C#D = X
                                            in
                                               thread
                                                  choice A=1 end
                                               end
                                               thread
                                                  choice
                                                     D=1
                                                  then
                                                     {AssumeDet A} A=1
                                                     {AssumeDet B} B=2
                                                     {AssumeDet C} C=3
                                                  []
                                                     D=2
                                                  then
                                                     {AssumeDet A} A=1
                                                     {AssumeDet B} B=2
                                                     {AssumeDet C} C=3
                                                  end
                                               end
                                               thread
                                                  choice
                                                     thread choice B=2 end end
                                                  end
                                               end
                                               choice
                                                  thread
                                                     {Wait A}
                                                     choice thread C=3 end end
                                                  end
                                               end
                                            end}
                              A  = {Space.ask S1}
                              S2 = {Space.clone S1}
                           in
                              case {IsDet A} then
                                 A=alternatives(2)
                                 {Space.commit S1 1}
                                 {Space.commit S2 2}
                                 local
                                    {Space.ask S1} = succeeded
                                    A#B#C#D        = {Space.merge S1}
                                 in
                                    {Wait A} {Wait B} {Wait C} {Wait D}
                                    A=1 B=2 C=3 D=1
                                 end
                                 local
                                    {Space.ask S2} = succeeded
                                    A#B#C#D={Space.merge S2}
                                 in
                                    {Wait A} {Wait B} {Wait C} {Wait D}
                                    A=1 B=2 C=3 D=2
                                 end
                              else fail
                              end
                           end)
                  keys: [det 'choice' space])

           'lock'(entailed(proc {$}
                              S = {Space.new
                                   proc {$ X}
                                      L={NewLock}
                                   in
                                      thread lock L then {Wait X} end end
                                      thread lock L then {Wait X} end end
                                      thread X=unit end
                                   end}
                           in
                              {Space.askVerbose S}=succeeded(entailed)
                              case {IsDet {Space.merge S}} then skip
                              else fail end
                           end)
                  keys: ['lock' space])

           commit_merge(entailed(proc {$}
                                    S = {Space.new
                                         proc {$ X}
                                            choice X=1 [] X=2 end
                                         end}
                                 in
                                    {Space.commit S 1}
                                    {Space.merge  S _}
                                 end)
                        keys: [commit merge space 'choice'])
          ]
          fun {$ T}
             T
          end})
end
