fun {$ IMPORT}

   \insert '../lib/import.oz'

   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fd])
   end


   CDSU = FD.cd.header
   CD   = FD.cd.'body'

   SRD = 1
   SEA =
   fun {$ P}
      Ss={Search.allS P SRD _}

   in
      {Map Ss fun {$ S}
                 A = {Space.askVerbose S}
              in
                 {Space.merge S} # A.1
              end}
   end

in
   fd([constrdisj([
                   {MiscTest 1
                    fun {$} Xs [X Y] = Xs C
                    in Xs = {FD.dom 0#10}
                       C::0#1

                       condis X + 8 =<: Y C=:0
                       [] Y + 6 =<: X C=:1
                       end

                       X >:2 % unit-commit of second clause X in 6..10
                               % Y in 0..4
                       Y>:2    % X in 9..10
                       if C=1 then 1 else 0 end
                    end}

                   {MiscTest 2
                    fun {$}
                       if Xs [X Y Z] = Xs
                       in Xs = {FD.dom 0#10}

                          condis X+4=<:Y
                          [] Y+2=<:Z
                          end

                          Z::9#10 Y::5#6  % top-commit of second clause

                       then 1 else 0end
                       end}

                   {MiscTest 3
                    fun {$}
                       Xs [X Y Z V] = Xs C
                    in Xs = {FD.dom 0#10}
                       C::0#1

                       condis X=<:Y Z=<:V C=:0
                       [] X+12=<:Y+Z Z=<:V C=:1
                       end


                       %% unit-commit:
                       Y::5#10 Z::1#5
                       X=5
                       Z>:2
                       if C=0 then 1 else 0 end
                    end}

                   {MiscTest 4
                    fun {$}
                       if Xs [X Y Z V]=Xs
                          C
                       in Xs = {FD.dom 0#10}
                          C::0#1

                          condis X=<:Y Z=<:V C=:0
                          [] X+12=<:Y+Z Z=<:V C=:1
                          end

                          %% top-commit:
                          X::0#5 Y::5#10 Z::1#5 V=10
                          X=5
                          %% this results in no failure.
                       then 1 else 0 end
                    end}

                   {MiscTest 5
                    fun {$} CDProb S
                    in
                       proc {CDProb S}
                          L
                          [P1#P2#P3 B1#B2#B3 X#Y
                           (XP1#YP1)#(XP2#YP2)#(XP3#YP3)] = L
                       in
                          S = [X Y]
                          S = {FD.dom  0#20}

                          condis X+6 <: Y
                          [] Y + 8 =<: X
                          [] X =<: Y  Y =<: X
                          end

                          {FD.distribute ff S}
                       end

                       S = {SEA CDProb}
                       if {ForAll S proc{$ X} X.2 = entailed end} then
                          1
                       else
                          0
                       end
                    end}

                   {MiscTest 6
                    fun {$} CDProb S in
                       proc {CDProb S}
                          L [P1#P2 B1#B2 X#Y#Z
                             (XP1#YP1#ZP1)#(XP2#YP2#ZP2)]=L in
                          S = [X Y Z]
                          S = {FD.dom 0#20}

                          condis Z=<:X
                          [] Z =<: Y
                          end

                          X + Y =: 5

                          {FD.distribute ff S}
                       end
                       S = {SEA CDProb}
                       if {ForAll S proc{$ X} X.2 = entailed end} then
                          1
                       else
                          0
                       end
                    end}

                   %% or Y=1 [] Z=1 end und X=Y X=Z geht zu Y=X=Z=1
                   {MiscTest 7
                    fun {$}
                       X Y Z Ls [P1#P2 B1#B2 (Y1#Z1)#(Y2#Z2)]=Ls in
                       condis Y=:1 [] Z=:1 end

                       [Y Z X] = {FD.dom  0#FD.sup}

                       X=Y X=Z
                       if X=1 Y=1 Z=1 then
                          1
                       else
                          0
                       end
                    end}

                   {MiscTest 8
                    fun {$}
                       proc {CDproc X Y XD YD}
                          condis X+XD =<: Y
                          [] Y+YD =<: X
                          end
                       end
                    in
                       local L1 L2 R in [L1 L2] = {FD.dom 0#10}
                          R = thread
                                 if B in B :: 0#1  or B=1 L1+3>:L2
                                                      L2+4>:L1
                                                   [] B=0 {CDproc L1 L2 3 4}
                                                   end
                                 then 1 else 0 end
                              end
                          L1::0#3
                          L2::7#10
                          R
                       end
                    end}

% if Abs(X+1) = 1 then ...
                   {MiscTest 9
                    fun {$}
                       proc {Abs X Y D}
                          condis X-Y =: D
                          [] Y-X =: D
                          end
                       end
                       X Y R
                    in
                       [X Y] = {FD.dom 1#5}
                       R = thread if {Abs X Y 1}
                                  then 1 else 0 end
                           end
                       X=1 Y=2
                       R
                    end}

% if Abs(X+1) = 1 then ...
                   {MiscTest 10
                    fun {$}
                       proc {Abs X Y D}
                          condis X-Y =: D
                          [] Y-X =: D
                          end
                       end
                       X Y R
                    in
                       [X Y] = {FD.dom 1#5}
                       R = thread if {Abs X Y 1} then 1 else 0 end end
                       X=4 Y=3
                       R
                    end}

                   {MiscTest 11
                    fun {$}
                       N = 5
                       OutOfBounds = N*N+2
                       Board = {FD.list N*N 1#N*N} = {FD.distinct}

                       fun {Num I J}
                          case I>=1 andthen I=<N andthen J>=1 andthen J=<N
                          then {Nth Board (I-1)*N + J} else OutOfBounds end
                       end
                    in
                       if

                          Choices
                          = thread
                               {Loop.forThread 1 N 1
                                fun {$ InI I}
                                   {Loop.forThread 1 N 1
                                    fun {$ InJ J}
                                       C = {FD.int 1#8}
                                       condis C=:1  {Num I J}+1 =: {Num I+1 J+2}
                                       []  C=:2  {Num I J}+1 =: {Num I+1 J-2}
                                       []  C=:3  {Num I J}+1 =: {Num I-1 J+2}
                                       []  C=:4  {Num I J}+1 =: {Num I-1 J-2}
                                       []  C=:5  {Num I J}+1 =: {Num I+2 J+1}
                                       []  C=:6  {Num I J}+1 =: {Num I+2 J-1}
                                       []  C=:7  {Num I J}+1 =: {Num I-2 J+1}
                                       []  C=:8  {Num I J}+1 =: {Num I-2 J-1}
                                       end
                                    in
                                       C|InJ
                                    end
                                    InI}
                                end
                                nil}
                            end
                       in
                          Board =
                          [1 10 15 20 23 16 5 22 9 14 11 2 19
                           24 21 6 17 4 13 8 3 12 7 18 25]
                       then 0
                       else 1 end
                    end}

                   {MiscTest 12
                    fun {$}
                       if condis 7=:9 [] 0=:1 end then 0 else 1 end
                    end}

                   {MiscTest 13
                    fun {$}
                       if condis 7=:7 [] 1=:1 end then 1 else 0 end
                    end}

                  ])
      ])

end
