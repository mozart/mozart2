declare

local
   proc {Find X Y|Yr}
      if {System.eq X Y} then skip else {Find X Yr} end
   end
   proc {CheckSame Xs Ys}
      case Xs
      of nil then skip
      [] X|Xr then {Find X Ys} {CheckSame Xr Ys}
      end
   end
in
   proc {Check X Cs}
      case
         try
            {Space.checkSit X} nil
         catch error(kernel(spaceSituatedness Xs) ...) then Xs
         end
      of nil then skip
      [] Xs then
         {CheckSame Xs Cs}
      end
   end
end

S={Space.new proc {$ X}
                proc {P} skip end
                proc {Q} skip end
             in
                {Check a(b c|d) nil}
                {Check FD nil}
                {Check a(X X P) [X P]}
                {Check a(X X P Q P Q) [X P Q]}
                {Check a(X X) [X]}
                local Z in
                   Z=a(X X P Q Z Z|Z)
                   {Check Z [X P Q]}
                end
                local Z in
                   Z=a(a(a:Z) Z Z|Z)
                   {Check Z nil}
                end
                local Z in
                   Z=a(a(a:Z) Z Z|Z Append Object.base)
                   {Check Z nil}
                end
                local Z F in
                   F={fun lazy {$ X} X end 1}
                   Z=a(a(a:Z) Z Z|Z F Append Object.base)
                   {Check Z nil}
                end
                local Z F in
                   F={fun lazy {$ X} X end 1}
                   Z=a(a(a:Z) Z Z|Z F P Append Object.base)
                   {Check Z [P]}
                end
                local Z F in
                   F={fun lazy {$ X} X end 1}
                   Z=a(a(a:Z) Z Z|Z F P Q X Append Object.base)
                   {Check Z [P Q X]}
                end
             end}
