%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%   Leif Kornstaedt, 2001
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {Usage}
   'Usage: ozl [options] URL [options]\n' #
   '\n' #
   'Options:\n' #
   '--help, --usage, -h, -?\n' #
   '    Print this message.\n' #
   '--out=FILE, -o FILE\n' #
   '    Specify where to write the output functor.\n' #
   '    If omitted, do not produce any output.\n' #
   '--[no]verbose (default: false)\n' #
   '    Print messages on activities performed.\n' #
   '--[no]relative (default: true)\n' #
   '    Include functors referred to by relative paths.\n' #
   '    Import URLs in the resulting functor remain relative.\n' #
   '--include=URL,..,URL (default: none, see --relative)\n' #
   '    Include functors with these URL prefixes.\n' #
   '--exclude=URL,..,URL (default: "x-oz://")\n' #
   '    Exclude functors with these URL prefixes.\n' #
   '--[no]sequential (default: false)\n' #
   '    Assume that functor bodies can be executed sequentially.\n' #
   '--rewrite=RULE,...,RULE\n' #
   '    Specifies how to replace import URL prefixes in resulting functor,\n' #
   '    where a RULE is of the form FROM=TO.\n' #
   '--[no]executable, -x (default: false)\n' #
   '    Output the functor as executable.\n' #
   '--execheader=STR\n' #
   '    Use header STR for executables\n' #
   '    (Unix default: "#!/bin/sh\\nexec ozengine $0 "$@"\\n").\n' #
   '--execpath=STR\n' #
   '    Use above header, with ozengine replaced by STR.\n' #
   '--execfile=FILE\n' #
   '    Use contents of FILE as header\n' #
   '    (Windows default: <ozhome>/bin/ozwrapper.bin).\n' #
   '--execwrapper=FILE\n' #
   '    Use above header, with ozwrapper.bin replaced by STR.\n' #
   '--target=(unix|windows)\n' #
   '    When creating an executable functor,\n' #
   '    do it for this platform (default current).\n'#
   '--compress=N, -z N (N: 0..9, default 0)\n' #
   '    Use compression level N for created pickle.\n'
end

local
   Width = 80
   Ident = 3

   local
      fun {Space N}
         if N==0 then nil else & |{Space N-1} end
      end
   in
      Start = {VirtualString.toAtom {Space Ident}}
   end

   fun {Break V|Vr N}
      L = {VirtualString.length V}
      NewN = N + L + 2
   in
      if NewN > Width - Ident then
         if N == 0 then   % does not fit onto a single line at all
            V#if Vr == nil then ""
              else ',\n'#Start#{Break Vr 0}
              end
         else
            '\n'#Start#V#if Vr == nil then ""
                         else ', '#{Break Vr L + 2}
                         end
         end
      else
         V#if Vr == nil then ""
           else ', '#{Break Vr N + L + 2}
           end
      end
   end
in
   fun {CommaList Vs}
      case Vs of nil then
         Start#'.'
      [] _|_ then
         Start#{Break Vs 0}#'.'
      end
   end
end
