proc {NewAgenda ?Port ?Connect}
   Stream
in
   {NewPort Stream Port}
   proc {Connect P}
      thread
         {ForAll Stream proc {$ M} {Send P M} end}
      end
   end
end
