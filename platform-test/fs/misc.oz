fun {$ IMPORT}

   \insert '../lib/import.oz'

   MkFSetVar =
   proc {$ L U IN NIN V}
      {FS.var.new IN {FS.reflect.lowerBound {FS.compl {FS.value.new NIN}}} V}
      {FS.cardRange L U V}
   end

   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(entailed(proc {$} {T} = 1 end) keys: [fs])
   end

in
   fs([misc([{MiscTest 1
              fun {$}
                 if {FS.intersect
                     {FS.value.new [1]} {FS.value.new [2]}}
                    = FS.value.empty then 1 else 0 end
              end}

             {MiscTest 2
              fun {$}
                 FSVar1 = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
                 FSVar2 = {MkFSetVar 5 5 [5 7 9] [10 12 14]}
                 R
              in
                 R = thread
                        if FSVar1 = {FS.value.new [1 3 5 7 9]}
                        then 1 else {Show no} 0 end
                     end
                 FSVar1 = FSVar2
                 R
              end}

             {MiscTest 3
              fun {$}
                 FSVar1 = {MkFSetVar 6 6 [1 3 5] [10 12 14]}
                 FSVar2 = {MkFSetVar 6 6 [5 7 9] [10 12 14 15]}
                 R
              in
                 R = thread
                        if FSVar1 = {MkFSetVar 6 6 [1 3 5 7 9] [10 12 14 15]}
                        then 1 else 0 end
                     end
                 FSVar1 = FSVar2
                 R
              end}

             {MiscTest 4
              fun {$}
                 FSVar = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
                 R
              in
                 R = thread
                        if FSVal = {FS.value.new [1 3 5 7 9]} in FSVal = FSVar
                        then 1 else 0 end
                     end
                 FSVar = {FS.value.new [1 3 5 7 9]}
                 R
              end}

             {MiscTest 5
              fun {$}
                 if {FS.value.new [1 3 5 7 9]} = {FS.value.new [1 3 5 7 9]}
                 then 1 else 0 end
              end}

             {MiscTest 6
              fun {$} if {FS.value.new [1 3 5 7 9]} = 1
                      then 0 else 1 end
              end}

             {MiscTest 7
              fun {$}
                 FSVar1 = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
                 R
              in
                 R = thread
                        if FSVar2 = {MkFSetVar 5 5 [5 7 9] [10 12 14]}
                        in FSVar1 = FSVar2
                        then 1 else 0 end
                     end
                 FSVar1 = {FS.value.new [1 3 5 7 9]}
                 R
              end}

             {MiscTest 8
              fun {$}
                 FSVar1 = {MkFSetVar 7 7 [1 3 5] [10 12 14]}
                 R
              in
                 R = thread
                        if FSVar2 = {MkFSetVar 7 7 [5 7 9 11] [10 12 14]}
                        in FSVar1 = FSVar2
                        then 1 else 0 end
                     end
                 FSVar1 = {MkFSetVar 7 7 [1 3 5 7 9 11] nil}
                 R
              end}

             {MiscTest 9
              fun {$}
                 FSVar1 = {MkFSetVar 7 7 [1 3 5] [10 12 14]}
                 R
              in
                 R = thread
                        if FSVar2 = {MkFSetVar 7 7 [1 3 5] [14 16 18]}
                        in FSVar1 = FSVar2
                        then 1 else 0 end
                     end
                 FSVar1 = {MkFSetVar 7 7 nil [10 12 14 16 18]}
                 R
              end}

             {MiscTest 10
              fun {$}
                 if {MkFSetVar 2 2 nil [1]}={MkFSetVar 2 2 [1] nil}
                 then 0 else 1 end
              end}

             {MiscTest 11
              fun {$}
                 X = {FS.var.new [1#3] [1#7]}
                 R
              in
                 R = thread if {FS.reified.isIn 5 X 1} then 1 else 0 end end

                 X = {FS.var.new [1#5] [1#5]}
                 R
              end}

             {MiscTest 12
              fun {$}
                 X = {FS.var.new [1#3] [1#7]}
                 R
              in
                 R = thread if {FS.reified.isIn 6 X 0} then 1 else 0 end end

                 X = {FS.var.new [1#5] [1#5]}
                 R
              end}

             {MiscTest 13
              fun {$} X Y in
                 X = {FS.var.new [1#5] [1#7]}
                 Y = {FS.var.new [1#7] [1#7]}

                 if {FS.reflect.lowerBound X} = [1#5] then 1 else 0 end
              end}

             {MiscTest 14
              fun {$} X Y in
                 X = {FS.var.new [1#5] [1#7]}
                 Y = {FS.var.new [1#7] [1#7]}
                 if {FS.reflect.unknown X} = [6#7] then 1 else 0 end
              end}

             {MiscTest 15
              fun {$} X Y in
                 X = {FS.var.new [1#5] [1#7]}
                 Y = {FS.var.new [1#7] [1#7]}
                 if {FS.reflect.unknown Y} = nil then 1 else 0 end
              end}

             {MiscTest 16
              fun {$} X Y in
                 X = {FS.var.new [1#5] [1#7]}
                 Y = {FS.var.new [1#7] [1#7]}
                 if {FS.reflect.lowerBound Y} = [1#7] then 1 else 0 end
              end}

             {MiscTest 17
              fun {$} X R in
                 X = {FS.var.new [1#5] [1#7]}
                 R = thread if X = {FS.value.new [1#6]} then 1 else 0 end end
                 {FS.include 6 X}
                 {FS.exclude 7 X}
                 R
              end}

             {MiscTest 18
              fun {$} X R in
                 X = {FS.var.new [1#5] [1#7]}
                 R = thread if {FS.exclude 7 X} then 1 else 0 end end

                 {FS.include 6 X}
                 {FS.exclude 7 X}
                 R
              end}

             {MiscTest 19
              fun {$} X R
              in
                 X = {FS.var.new [1#5] [1#7]}
                 R = thread if {FS.include 6 X} then 1 else 0 end end

                 {FS.include 6 X}
                 {FS.exclude 7 X}
                 R
              end}

             {MiscTest 20
              fun {$}
                 fun {SetPart N}
                    proc {$ Root}
                       Root = {MakeList N}
                       {ForAll Root proc {$ E}
                                       {FS.var.new nil [1#N] E}
                                  %{FS.cardRange 1 1 E}
                                    end}

                       {FS.disjointN Root}

                       {FS.distribute naive Root}
                    end
                 end
                 Sol SolLen
              in
                 /*
                                                        N       / N \
                 the length of the list is: (N+1)^N = sigma N^I |   |
                                                      I = 1     \ I /
                 */
                 Sol = {SearchAll {SetPart 3}}
                 SolLen = {Length Sol}
                 case SolLen  == 64 then 1 else 0 end
              end}

             {MiscTest 21
              fun {$}
                 fun {SetPart N}
                    proc {$ Root}
                       Root = {MakeList N}
                       {ForAll Root proc {$ E}
                                       {FS.var.new nil [1#N] E}
                                       {FS.cardRange 1 1 E}
                                    end}

                       {FS.disjointN Root}

                       {FS.distribute naive Root}
                    end
                 end
                 Sol SolLen
              in
                 /*
                 the length of the list is: N!
                 */
                 Sol = {SearchAll {SetPart 5}}
                 SolLen = {Length Sol}
                 case SolLen  == 120 then 1 else 0 end
              end}

             {MiscTest 22
              fun {$}
                 if {FS.union {FS.var.upperBound [1#5]} FS.value.empty}
                    = {FS.var.upperBound [1#5]}
                 then 1 else 0 end
              end}

             {MiscTest 23
              fun {$}
                 if {FS.union FS.value.empty {FS.var.upperBound [1#5]}}
                    = {FS.var.upperBound [1#5]}
                 then 1 else 0 end
              end}

             {MiscTest 24
              fun {$}
                 if {FS.intersect FS.value.universal {FS.var.upperBound [1#5]}}
                    = {FS.var.upperBound [1#5]}
                 then 1 else 0 end
              end}

             {MiscTest 25
              fun {$}
                 if {FS.intersect {FS.var.upperBound [1#5]} FS.value.universal}
                    = {FS.var.upperBound [1#5]}
                 then 1 else 0 end
              end}

             {MiscTest 26
              fun {$}
                 X = {FS.var.decl} {FS.card X 3}
                 Y = {FS.var.decl} {FS.card Y 3}
                 Z = {FS.union X Y}
                 CX = {FS.card X}
                 CY = {FS.card Y}
                 CZ = {FS.card Z}
                 R
              in
                 R = case {FD.reflect.min CZ} ==
                        {Max {FD.reflect.min CX} {FD.reflect.min CY}}
                     then 1 else 0 end
                 {Wait R}
                 {ForAll [X Y] proc {$ E} {FS.value.new [1 2 3] E} end}
                 R
              end}

             {MiscTest 27
              fun {$}
                 X = {FS.var.decl} {FS.card X 3}
                 Y = {FS.var.decl} {FS.card Y 3}
                 Z = {FS.union X Y}
                 CX = {FS.card X}
                 CY = {FS.card Y}
                 CZ = {FS.card Z}
                 R
              in
                 R = case {FD.reflect.max CZ} ==
                        {FD.reflect.max CX}+{FD.reflect.max CY}
                     then 1 else 0 end

                 {Wait R}
                 {ForAll [X Y] proc {$ E} {FS.value.new [1 2 3] E} end}
                 R
              end}

             {MiscTest 28
              fun {$}
                 X = {FS.var.decl} {FS.card X 3}
                 Y = {FS.var.decl} {FS.card Y 3}
                 Z = {FS.intersect X Y}
                 CX = {FS.card X}
                 CY = {FS.card Y}
                 CZ = {FS.card Z}
                 R
              in
                 R = case {FD.reflect.max CZ} ==
                        {Min {FD.reflect.max CX} {FD.reflect.max CY}}
                     then 1 else 0 end
                 {Wait R}
                 {ForAll [X Y] proc {$ E} {FS.value.new [1 2 3] E} end}
                 R
              end}


             {MiscTest 29
              fun {$}  X Y R
              in
                 X = {FS.var.upperBound [1#10]} Y = {FS.var.upperBound [1#10]}
                 R = thread if {FS.distinct X Y} then 1 else 0 end end
                 {FS.include 1 X}
                 {FS.exclude 1 Y}
                 R
              end}

             {MiscTest 30
              fun {$} X Y R
              in
                 X = {FS.var.upperBound [1#10]} Y = {FS.var.upperBound [1#10]}
                 R = thread if {FS.distinct X Y} then 0 else 1 end end
                 X = {FS.value.new [1#10]} Y = {FS.value.new [1#10]}
                 R
              end}

             {MiscTest 31
              fun {$} X = {FS.var.decl} Y = {FS.var.decl} R
              in
                 R = thread if {FS.subset X Y} then 1 else 0 end end

                 {FS.include 1 Y}
                 {FS.include 2 Y}

                 X = {FS.value.new [1#2]}

                 R
              end}

             {MiscTest 32
              fun {$} S SV={FS.var.decl} E R
              in
                 R = thread if SV = {FS.value.new [1 2 3 4 5]}
                            then 1 else 0 end
                     end
                 {FS.monitorIn SV S}
                 S = 1|2|3|4|5|E
                 E = nil
                 R
              end}

             {MiscTest 33
              fun {$} S SV={FS.var.decl} R
              in
                 R = thread if S = [_ _ _ _ _] then 1 else 0 end end
                 {FS.monitorIn SV S}
                 {FS.include 1 SV}
                 {FS.include 2 SV}
                 {FS.include 3 SV}
                 {FS.include 4 SV}
                 {FS.include 5 SV}
                 {FS.card SV 5}
                 R
              end}

             {MiscTest 34
              fun {$} D={FD.decl}  S={FS.var.decl} R= {FD.int 0#1} R
              in
                 R = thread if R = 1 then 1 else 0 end end
                 {FS.reified.include D S R}

                 D :: 1#2
                 {FS.include 1 S}
                 {FS.include 2 S}
                 R
              end}

             {MiscTest 35
              fun {$} D={FD.decl}  S={FS.var.decl} C= {FD.int 0#1} R
              in
                 R = thread if C = 1 then 0 else 1 end end
                 {FS.reified.include D S C}

                 D :: 1#2
                 {FS.exclude 1 S}
                 {FS.exclude 2 S}
                 R
              end}

             {MiscTest 36
              fun {$} D={FD.decl}  S={FS.var.decl} R
              in
                 R = thread if {FS.include D S} then 1 else 0 end end

                 D :: 1#2
                 {FS.include 1 S}
                 {FS.include 2 S}
                 R
              end}


             {MiscTest 37
              fun {$}
                 D={FD.decl}  S={FS.var.decl} R
              in
                 R = thread if {FS.exclude D S} then 1 else 0 end end

                 D :: 1#2
                 {FS.exclude 1 S}
                 {FS.exclude 2 S}
                 R
              end}

             {MiscTest 38
              fun {$}
                 case {FS.int.min {FS.value.new [1 2 3]}} == 1 then 1 else 0 end
              end}

             {MiscTest 39
              fun {$}
                 case {FS.int.max {FS.value.new [1 2 3]}} == 3 then 1 else 0 end
              end}

             {MiscTest 40
              fun {$}
                 case {FS.int.min {FS.value.new [2]}} == 2 then 1 else 0 end
              end}

             {MiscTest 41
              fun {$}
                 case {FS.int.max {FS.value.new [2]}} == 2 then 1 else 0 end
              end}

             {MiscTest 42
              fun {$}
                 if {FS.int.convex {FS.value.new [1 2]}}  then 1 else 0 end
              end}

             {MiscTest 43
              fun {$}
                 if {FS.int.convex {FS.value.new [1 2 4]}} then 0 else 1 end
              end}

             {MiscTest 44
              fun {$}
                 if {FS.int.convex {FS.value.new nil}}  then 1 else 0 end
              end}

             {MiscTest 45
              fun {$}
                 if
                    S = {FS.var.upperBound [1#5]}
                 in
                    {FS.int.convex S} S = {FS.value.new nil}
                 then 1 else 0 end
              end}
            ])
      ])

end
