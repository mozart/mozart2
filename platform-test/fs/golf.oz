functor $ prop once

import

   FS

   Search

export
   Return
body

   fun {Golf NbOfWeeks NbOfFourSomes}
      NbOfPlayers = 4*NbOfFourSomes

      fun {Flatten Ls}
         {FoldL Ls fun {$ L R}
                      case R==nil then L else {Append L R} end
                   end nil}
      end

      proc {DistrPlayers AllWeeks Player Weeks}
         choice
            case Weeks
            of FourSome|Rest then
               dis {FS.include Player FourSome} then
                  {DistrPlayers AllWeeks Player Rest}
               [] {FS.exclude Player FourSome} then
                  {DistrPlayers AllWeeks Player Rest}
               end
            else
               case Player < NbOfPlayers then
                  {DistrPlayers AllWeeks Player+1 AllWeeks}
               else skip end
            end
         end
      end
   in
      proc {$ Weeks}
         FlattenedWeeks
      in
         Weeks = {MakeList NbOfWeeks}

         {ForAll Weeks
          proc {$ Week}
             Week = {FS.var.list.upperBound NbOfFourSomes [1#NbOfPlayers]}
             {ForAll Week proc {$ FourSome} {FS.card FourSome 4} end}
             {FS.disjointN Week}
             {FS.unionN Week {FS.var.upperBound [1#NbOfPlayers]}}
          end}

         {ForAllTail Weeks
          proc {$ WTails}
             case WTails
             of Week|RestWeeks then
                {ForAll Week
                 proc {$ FourSome}
                    {ForAll {Flatten RestWeeks}
                     proc {$ RestFourSome}
                        {FS.cardRange 0 1
                         {FS.intersect FourSome RestFourSome}}
                     end}
                 end}
             else skip end
          end}

         FlattenedWeeks = {Flatten Weeks}
         {DistrPlayers FlattenedWeeks 1 FlattenedWeeks}
      end
   end

   GolfSol =
   [[[ {FS.value.new [1#4]} {FS.value.new [5#8]} {FS.value.new [9#12]} {FS.value.new [13#16]} {FS.value.new [17#20]} {FS.value.new [21#24]} {FS.value.new [25#28]} {FS.value.new [29#32]} ]
[ {FS.value.new [1 5 9 13]} {FS.value.new [2 6 10 14]} {FS.value.new [3 7 11 15]} {FS.value.new [4 8 12 16]} {FS.value.new [17 21 25 29]} {FS.value.new [18 22 26 30]} {FS.value.new [19 23 27 31]} {FS.value.new [20 24 28 32]} ]
[ {FS.value.new [1 6 11 16]} {FS.value.new [2 5 12 15]} {FS.value.new [3 8#9 14]} {FS.value.new [4 7 10 13]} {FS.value.new [17 22 27 32]} {FS.value.new [18 21 28 31]} {FS.value.new [19 24#25 30]} {FS.value.new [20 23 26 29]} ]
[ {FS.value.new [1 7 17 23]} {FS.value.new [2 8 18 24]} {FS.value.new [3 5 19 21]} {FS.value.new [4 6 20 22]} {FS.value.new [9 15 25 31]} {FS.value.new [10 16 26 32]} {FS.value.new [11 13 27 29]} {FS.value.new [12 14 28 30]} ]
[ {FS.value.new [1 8 19 22]} {FS.value.new [2 7 20#21]} {FS.value.new [3 6 17 24]} {FS.value.new [4#5 18 23]} {FS.value.new [9 16 27 30]} {FS.value.new [10 15 28#29]} {FS.value.new [11 14 25 32]} {FS.value.new [12#13 26 31]} ]
[ {FS.value.new [1 10 18 25]} {FS.value.new [2 9 17 26]} {FS.value.new [3 12 20 27]} {FS.value.new [4 11 19 28]} {FS.value.new [5 14 22 29]} {FS.value.new [6 13 21 30]} {FS.value.new [7 16 24 31]} {FS.value.new [8 15 23 32]} ]
[ {FS.value.new [1 12 21 32]} {FS.value.new [2 11 22 31]} {FS.value.new [3 10 23 30]} {FS.value.new [4 9 24 29]} {FS.value.new [5 16#17 28]} {FS.value.new [6 15 18 27]} {FS.value.new [7 14 19 26]} {FS.value.new [8 13 20 25]} ]
[ {FS.value.new [1 14 20 31]} {FS.value.new [2 13 19 32]} {FS.value.new [3 16 18 29]} {FS.value.new [4 15 17 30]} {FS.value.new [5 10 24 27]} {FS.value.new [6 9 23 28]} {FS.value.new [7 12 22 25]} {FS.value.new [8 11 21 26]} ]
[ {FS.value.new [1 15 24 26]} {FS.value.new [2 16 23 25]} {FS.value.new [3 13 22 28]} {FS.value.new [4 14 21 27]} {FS.value.new [5 11 20 30]} {FS.value.new [6 12 19 29]} {FS.value.new [7 9 18 32]} {FS.value.new [8 10 17 31]} ]
    ]]


   Return=
   fs([golf([
             one(equal(fun {$} {Search.base.one {Golf 9 8}} end GolfSol)
                 keys: [fs])
             one_entailed(entailed(proc {$} {Search.base.one {Golf 9 8} _} end)
                          keys: [fs entailed])
            ]
           )
      ]
     )
end
