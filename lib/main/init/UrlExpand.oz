%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

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
      Path = {CondSelect Base path nil}
   in
      if {CondSelect Base absolute false} andthen Path\=unit
      then
         N = {List.length Path}
         D={CondSelect Base device unit}
         RelB
      in
         %% if a device is specified in Base it must be carried on to Rel
         if D\=unit then
            RelB={AdjoinAt Rel device D}
         else
            RelB=Rel
         end
         %% this path should usually be non-empty
         if N==0 then
            %% if empty, then Base dir is just "/"
            {AdjoinAt RelB absolute true}
         else
            %% the last component of this path needs special treatment
            Front Last {List.takeDrop Path N-1 Front [Last]}
            PATH = {Append Front
                    %% if Base ends with a slash: drop the empty component
                    if Last==nil then DIR else Last|DIR end}
         in
            {Adjoin RelB url(absolute:true path:{URL.normalizePath PATH})}
         end
      else Rel end
   end
in

   fun {URL_expand Url}
      U = {UrlMake Url}
   in
      if {CondSelect U scheme    unit}\=unit orelse
         {CondSelect U authority unit}\=unit orelse
         {CondSelect U device    unit}\=unit
      then U else
         case {CondSelect U path unit}
         of (&~|USER)|DIR then
            {Expand {UrlMake
                     if USER==nil then {GET 'user.home'}
                     else {OS.getpwnam USER}.dir end}
             DIR U}
         [] DIR=(H|_) andthen (H=="." orelse H=="..") then
            {Expand {UrlMake {OS.getCWD}} DIR U}
         else U end
      end
   end
end
