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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%% ==================================================================
%%% A URL denotes a networked resource, typically a file of data.
%%% Normally, one would retrieve the data from the networked location
%%% represented by the URL itself.  However, it is sometimes desirable
%%% to retrieve the data from a different location instead.  For
%%% example: (1) to access a local cache (faster than downloading from
%%% the net, (2) to override one implementation with another without
%%% changing the URL.  Also, we want this capability for file paths,
%%% relative or not.  This package implements a mechanism that
%%% generalizes the concept of `search path': instead of having
%%% several alternative directories, we have several alternative
%%% `methods'.
%%%
%%% Each `method' or `handler' H is a procedure.  It is called as
%%% follows:
%%%                     {H URL ACTION ACTIONNAME MSG}
%%%
%%% URL is guaranteed to be a string, ACTION is a function which takes
%%% the transformed URL as a virtual string and either returns a value
%%% if it succeeded or raises an exception, ACTIONAME is an atom which
%%% identifies the ACTION.  MSG is a procedure that takes a virtual
%%% string as an argument and prints it out with an appropriate prefix
%%% (see [TITLE] below) if tracing is enabled.
%%%
%%% Currently there are only 3 builtin actions which can be performed
%%% on a URL: localize, open, and load.
%%%
%%% The handler H either (1) raises the exception found(V) if ACTION
%%% returned the value V, or (2) skips if it raised an acceptable
%%% exception indicating that the resource was not found.  There are
%%% two reasons for doing it this way: (a) we can just loop through
%%% the handlers and the first one that succeeds will escape the loop
%%% by raising the exception found(V), (b) only the handler itself
%%% knows which exceptions simply indicate that the resource was not
%%% found and which ones indicate problems that should be reported by
%%% letting the exception through.
%%%
%%% {URL.makeResolver +TITLE +INIT ?M}
%%%
%%% Creates a new module M that has its own set of handlers.  This may
%%% be useful to create different ways of resolving urls for different
%%% purposes.  TITLE is an atom that identifies the modules for
%%% tracing purposes: all trace messages will be prefixed with [TITLE].
%%% INIT indicates how to initialize the module and must have one of
%%% the following forms:
%%%
%%% unit
%%%     in which case only the default handler is in effect.
%%% init(L)
%%%     where L is a list of handlers.
%%% env(S)
%%%     where S names an environment variable: the methods decribed by
%%%     S will be created and the default handler added at the end. If
%%%     S doesn't exist, only the default handlers is present.
%%% env(S D)
%%%     same as above except that if S doesn't exist, virtual string D
%%%     is used as its missing value.
%%% vs(S)
%%%     S is a virtual string that will be treated just like the value
%%%     of the environment variable of the previous case.
%%%
%%% When using an environment variable or a virtual string to create
%%% the initial list of handlers, the corresponding string should be
%%% of the form:
%%%                     meth1:meth2:...:methN   (unix)
%%%                     meth1;meth2;...;methN   (windows)
%%%
%%% i.e. description of methods separated by `:' on unix and by `;' on
%%% windows, or, more precisely, separated by the value of environment
%%% variable OZ_SEPARATOR whose default is `:' on unix and `;' under
%%% windows.
%%%
%%% Each method descriptor is of the form KIND=VALUE.
%%%
%%% all=DIR             .../FILE ==> DIR/FILE
%%% root=DIR            PATH ==> DIR/PATH       (if PATH is relative)
%%% cache=DIR           PROTO://HOST/PATH ==> DIR/PROTO/HOST/PATH
%%% prefix=PREFIX=SUBST (PREFIX)PATH ==> (SUBST)PATH
%%% DIR                 PATH ==> DIR/PATH       (if PATH is relative)
%%%
%%% When the method is just DIR, it means root=DIR, and thus emulates
%%% the usual search path mechanism.

%declare
local

URL_localize    = {`Builtin` 'URL.localize'      2}
URL_open        = {`Builtin` 'URL.open'          2}
URL_load        = {`Builtin` 'URL.load'          2}
PrintError      = {`Builtin` 'System.printError' 1}
GetEnv          = {`Builtin` 'OS.getEnv'         2}
GetHome         = {`Builtin` 'SystemGetHome'     1}
GetPlatform     = {`Builtin` 'SystemGetPlatform' 1}

WINDOWS         = case {GetPlatform} of win32#_  then true else false end

Separator       = case {GetEnv 'OZ_SEPARATOR'} of [C] then C
                  elsecase WINDOWS then &; else &: end

Trace           = {NewCell false}

proc {GetTrace B} {Access Trace B} end
proc {SetTrace B} {Assign Trace B} end

%% the default way of applying a handler to a URL: all system exceptions
%% are considered to indicate that the data was not available at this
%% location, and ignored. all other exceptions are passed through.  If
%% a value V is obtained, exception found(V) is raised.

proc {HApply URL Meth} V OK in
   try {Meth URL V} OK=true catch system(...) then OK=false end
   case OK then raise found(V) end else skip end
end

local
   fun {Gather L TO}
      fun {Loop L Accu}
         case L of nil  then {Reverse Accu}#nil
         elseof &\\|C|T then {Loop T C|Accu}
         elseof  !TO|T  then {Reverse Accu}#T
         elseof    H|T  then {Loop T H|Accu} end
      end
   in {Loop L nil} end
in
   fun {StringToHandlers L}
      case L of
         nil then [DefaultHandler]
      [] &a|&l|&l|&=|T then
         URL#REST = {Gather T Separator}
      in
         {MakeAllHandler URL}|{StringToHandlers REST}
      [] &r|&o|&o|&t|&=|T then
         URL#REST = {Gather T Separator}
      in
         {MakeRootHandler URL}|{StringToHandlers REST}
      [] &c|&a|&c|&h|&e|&=|T then
         URL#REST = {Gather T Separator}
      in
         {MakeCacheHandler URL}|{StringToHandlers REST}
      [] &p|&r|&e|&f|&i|&x|&=|T then
         PREFIX#TMP = {Gather T &=}
         SUBST#REST = {Gather TMP Separator}
      in
         {MakePrefixHandler PREFIX SUBST}|{StringToHandlers REST}
      else
         URL#REST = {Gather L Separator}
      in
         {MakeRootHandler URL}|{StringToHandlers REST}
      end
   end
end

fun {MakeResolver Title Init}
   proc {MSG S}
      case {Access Trace}
      then {PrintError '['#Title#'] '#S#'\n'}
      else skip end
   end
   Handlers = {NewCell [ DefaultHandler ]}
   proc {GetHandlers L} {Access Handlers L} end
   proc {SetHandlers L} {Assign Handlers L} end
   proc {AddHandler H}
      case H
      of front(H) then L in {Exchange Handlers L H|L}
      [] back( H) then O N in
         {Exchange Handlers O N}
         {Append O [H] N}
      else L in {Exchange Handlers L H|L} end
   end
   proc {Get URL VAL Meth MethName}
      {MSG MethName#' request: '#URL}
      try STR={VirtualString.toString URL} in
         {ForAll {Access Handlers}
          proc {$ H} {H STR Meth MethName MSG} end}
         {MSG '...all handlers failed'}
         raise error(url(MethName URL) debug:debug) with debug end
      catch found(V) then
         {MSG '...'#MethName#' succeeded'}
         V=VAL
      end
   end
   proc {Localize URL VAL} {Get URL VAL URL_localize localize} end
   proc {Open     URL VAL} {Get URL VAL URL_open     open    } end
   proc {Load     URL VAL} {Get URL VAL URL_load     load    } end
in
   case Init of
      unit    then skip
   [] init(L) then {SetHandlers L}
   [] env( L) then S={GetEnv L} in
      case S==false then skip else
         {SetHandlers {StringToHandlers S}}
      end
   [] env( L D) then S={GetEnv L} in
      {SetHandlers {StringToHandlers
                    case S==false then {VirtualString.toString D}
                    else S end}}
   [] vs(  L) then
      {SetHandlers {StringToHandlers {VirtualString.toString L}}}
   end
   url(getHandlers: GetHandlers
       setHandlers: SetHandlers
       addHandler : AddHandler
       localize   : Localize
       open       : Open
       load       : Load
       get        : Get
       msg        : MSG)
end

%% default handler

proc {DefaultHandler URL Meth MethName MSG}
   {MSG '...['#URL#'] (default)'}
   {HApply URL Meth}
end

%% all handler

fun {MakeAllHandler DIR}
   proc {$ URL Meth MethName MSG}
      PATH = DIR#'/'#{SkipSlashes URL URL}
   in
      {MSG '...['#PATH#'] (all)'}
      {HApply PATH Meth}
   end
end

fun {SkipSlashes L Was}
   case L of nil then Was
   [] H|T then case H==&/ then {SkipSlashes T T}
               else {SkipSlashes T Was} end
   end
end

%% root handler

fun {MakeRootHandler DIR}
   proc {$ URL Meth MethName MSG}
      case WINDOWS then
         case URL of C|&:|L then
            {MSG '...[not applicable] (root '#DIR#')'}
         else
            PATH = DIR#'/'#URL
         in
            {MSG '...['#PATH#'] (root)'}
            {HApply PATH Meth}
         end
      else
         case URL of &/|_ then
            {MSG '...[not applicable] (root '#DIR#')'}
         else
            PATH = DIR#'/'#URL
         in
            {MSG '...['#PATH#'] (root)'}
            {HApply PATH Meth}
         end
      end
   end
end

%% cache handler

fun {MakeCacheHandler DIR}
   proc {$ URL Meth MethName MSG}
      case {ParseProto URL nil}
      of PROTO#REST then
         PATH = DIR#'/'#PROTO#'/'#REST
      in
         {MSG '...['#PATH#'] (cache)'}
         {HApply PATH Meth}
      else
         {MSG '...[not applicable] (cache '#DIR#')'}
      end
   end
end

fun {ParseProto URL PROTO}
   case URL of &:|&/|&/|T then {Reverse PROTO}#T
   elseof H|T then {ParseProto T H|PROTO}
   else unit end
end

%% prefix handler

fun {MakePrefixHandler PREFIX SUBST}
   proc {$ URL Meth MethName MSG}
      case {StripPrefix PREFIX URL}
      of ok(REST) then
         PATH = SUBST#REST
      in
         {MSG '...['#PATH#'] (prefix)'}
         {HApply PATH Meth}
      else
         {MSG '...[not applicable] (prefix '#PREFIX#' '#SUBST#')'}
      end
   end
end

fun {StripPrefix Prefix URL}
   case Prefix of nil then ok(URL)
   elseof H|Prefix then
      case URL of !H|URL then {StripPrefix Prefix URL}
      else unit end
   end
end

%% create a resolver for loading

LoadResolver = {MakeResolver url
                env('OZ_LOAD' 'cache='#{GetHome}#'/cache')}
in

   URL = {Adjoin
          url(builtin  : builtin(localize : URL_localize
                                 open     : URL_open
                                 load     : URL_load)
              getTrace : GetTrace
              setTrace : SetTrace
              handler  : handler(default:DefaultHandler
                                 all    :MakeAllHandler
                                 root   :MakeRootHandler
                                 cache  :MakeCacheHandler
                                 prefix :MakePrefixHandler)
              makeResolver : MakeResolver)
          LoadResolver}
end
