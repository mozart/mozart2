%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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

fun {Usage}
   'Usage: ozl [options] URL -o FILE\n' #
   '\n' #
   'Options:\n' #
   '--help, --usage, -h, -?\n' #
   '    Print this message.\n' #
   '--[no]verbose (default: false)\n' #
   '    Print messages on activities perfomed.\n' #
   '--[no]relative (default: true)\n' #
   '    Include functors referred by relative pathes.\n' #
   '--include=URL,..,URL (default: none)\n' #
   '    Include functors with these URL prefixes.\n' #
   '--exclude=URL,..,URL (default: none)\n' #
   '    Exclude functors with these URL prefixes (Priority over --include).\n' #
   '--[no]sequential (default: false)\n' #
   '    Assume that functor bodies can be executed sequentially.\n' #
   '--[no]executable, -x (default: false)\n' #
   '    Output the functor as executable.\n' #
   '--execheader=STR\n' #
   '    Use header STR for executables.\n' #
   '--execpath=STR\n' #
   '    Use path STR to ozengine in headers of executables.\n' #
   '--compress=N, -z N (N: 0..9, default 0)\n' #
   '    Use compression level N for created pickle.\n'
end

local
   Width = 80
   Ident = 3
   fun {Space N}
      if N==0 then nil else & |{Space N-1} end
   end

   Start = {VirtualString.toAtom {Space Ident}}

   fun {Break V|Vr N}
      L={VirtualString.length V}
   in
      if L+N+2>Width-Ident then
         '\n'#Start#V#if Vr==nil then '.\n'
                      else  ',\n' # Start # {Break Vr Ident}
                      end
      else
         V#if Vr==nil then '.'
           else ', '#{Break Vr N+L+2}
           end
      end
   end

in
   fun {CommaList Vs}
      case Vs of nil then
         Start#'.\n'
      [] V|Vr then
         Start#{Break V|Vr Ident}
      end
   end
end
