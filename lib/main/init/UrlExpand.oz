%% TILDE and DOT NORMALIZATION: when `~' or `.' or `..' appear at the
%% front of a filename, they can be expanded expanded respectively
%% relative to a user directory of the current directory.

local
   %% Base is a url record where (at the moment) only the path field
   %% is of interest.  DIR is a list of parsed path components, to be
   %% interpreted relative to Base.  Rel is a url record whose path
   %% field must be replaced by the new interpreted DIR.  If, for some
   %% reason the interpretation is not applicable, Rel is returned.

   fun {Expand Base DIR Rel}
      %% Base should contain an absolute path
      case {CondSelect Base path unit} of abs(L) then
         N = {List.length L}
      in
         %% this path should be non-empty
         if L==0 then Rel else
            %% the last component of this path needs special treatment
            Front Last {List.takeDrop L N-1 Front [Last]}
            Path =
            case Last of C#false then
               if C==nil then
                  %% Base ends with a slash: drop the empty component
                  {Append Front DIR}
               else
                  %% last component C must now be followed by a slash
                  {Append Front (C#true)|DIR}
               end
            else raise urlbug end end
         in
            {AdjoinAt Rel path abs({URL.normalizePath Path})}
         end
      else Rel end
   end
in

   fun {URL_expand Url}
      U = {URL.make Url}
   in
      if {HasFeature U scheme   } orelse
         {HasFeature U authority} orelse
         {HasFeature U device   }
      then U else
         case {CondSelect U path unit}
         of rel((&~|USER)#Slash|DIR) then
            {Expand
             {URL.make
              if USER==nil then {GET 'user.home'}
              else {OS.getpwnam USER}.dir end}
             DIR U}
         elseof rel(DIR=((C#_)|_)) then
            if C=="." orelse C==".." then
               {Expand
                {URL.make {OS.getCWD}}
                DIR U}
            else U end
         else U end
      end
   end
end
