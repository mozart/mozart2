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
%%%                     {H REP ACTION ACTIONNAME MSG}
%%%
%%% REP is the parsed representation of a URL (see ParseURL), ACTION
%%% is a function which takes the transformed URL as a virtual string
%%% and either returns a value if it succeeded or raises an exception,
%%% ACTIONAME is an atom which identifies the ACTION.  MSG is a
%%% procedure that takes a virtual string as an argument and prints it
%%% out on standard output with an appropriate prefix (see [TITLE]
%%% below) if tracing is enabled.
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
%%% purposes.  TITLE is an atom that identifies the module for tracing
%%% purposes: all trace messages will be prefixed with [TITLE].  INIT
%%% indicates how to initialize the module and must have one of the
%%% following forms:
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
%%% windows, or, more precisely, separated by the value of system
%%% property file.separator which can be initialized with environment
%%% variable OZ_PATH_SEPARATOR (by default it is `:' on unix and `;'
%%% on windows).
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

local

URL_localize    = {`Builtin` 'URL.localize'      2}
URL_open        = {`Builtin` 'URL.open'          2}
URL_load        = {`Builtin` 'URL.load'          2}
PrintError      = {`Builtin` 'System.printError' 1}
Getpwnam        = {`Builtin` 'OS.getpwnam'       2}
GetCWD          = {`Builtin` 'OS.getCWD'         1}

Trace = {NewCell local
                    R=internal(browser:_ applet:_)
                 in
                    {{`Builtin` 'SystemGetInternal' 1} R}
                    case R.browser then false else true end
                 end}


proc {GetTrace B} {Access Trace B} end
proc {SetTrace B} {Assign Trace B} end

%%% {ParseURL +URL ?REP}
%%%
%%% Parse the input url and return a description of it to be used by
%%% the various handlers.  The description has the following form:
%%%
%%% url(string:STRING type:TYPE last:LAST path:PATH)
%%%
%%% where STRING is URL as a string, TYPE is either url(http),
%%% url(ftp), url(file), or file(abs) for an absolute pathname, or
%%% file(rel) for a relative pathname.  LAST is the last component of
%%% the pathname obtained by skipping all slashes and backslashes.
%%% PATH is the non PROTO[:[//]] suffix of STRING.

fun {ParseURL URL}
   L = {VirtualString.toString URL}
in
   case L
   of     &h|&t|&t|&p|&:|&/|&/|T then
      url(string:L type:url(http) last:{GetLAST T T} path:T)
   elseof &f|&t|&p   |&:|&/|&/|T then
      url(string:L type:url(ftp ) last:{GetLAST T T} path:T)
   elseof &f|&i|&l|&e|&:      |T then
      url(string:L type:url(file) last:{GetLAST T T} path:T)
   elseof &/                  |T then
      url(string:L type:file(abs) last:{GetLAST T T} path:L)
   elseof &\\                 |T then
      url(string:L type:file(abs) last:{GetLAST T T} path:L)
   elseof &~                  |_ then
      url(string:L type:file(abs) last:{GetLAST L L} path:L)
   elseof C|&:|T then
      case {GET 'os.name'}==win32 andthen {Char.isAlpha C} then
         url(string:L type:file(abs) last:{GetLAST T T} path:L)
      else url(string:L type:file(rel) last:{GetLAST L L} path:L) end
   else url(string:L type:file(rel) last:{GetLAST L L} path:L)
   end
end

fun {GetLAST L Was}
   case L of &/|T then {GetLAST T T}
   elseof   &\\|T then {GetLAST T T}
   elseof     H|T then {GetLAST T Was}
   elseof     nil then Was
   end
end

%% the default way of applying a handler to a parsed URL: all system
%% exceptions are considered to indicate that the data was not
%% available at this location, and ignored. all other exceptions are
%% passed through.  If a value V is obtained, exception found(V) is
%% raised.

proc {HApply URL Meth} V OK in
   try {Meth URL V} OK=true catch system(...) then OK=false end
   case OK then raise found(V) end else skip end
end

%% {Gather L TO ESC} ==> PREFIX#SUFFIX
%% where PREFIX is the beginning of L before the first occurrence of TO
%% and SUFFIX is everything after TO.  ESC is the escape character: it
%% can be used to include an occurrence of TO in the PREFIX.  If TO doesn't
%% occur in L: the PREFIX is all of L and SUFFIX is nil.

fun {Gather L TO ESC}
   fun {Loop L Accu}
      case L of nil then {Reverse Accu}#nil
      elseof H|T then
         case H==ESC then
            case T of C|T then {Loop T C|Accu}
            elseof    nil then {Reverse H|Accu}#nil
            end
         elsecase H==TO then {Reverse Accu}#T
         else {Loop T H|Accu}
         end
      end
   end
in {Loop L nil} end

fun {StringToHandlers L}
   SEPARATOR = {GET 'path.separator'}
   ESCAPE    = {GET 'path.escape'   }

   fun {Parse L}
      case L of
         nil then [DefaultHandler]
      [] &a|&l|&l|&=|T then
         URL#REST = {Gather T SEPARATOR ESCAPE}
      in
         {MakeAllHandler URL}|{Parse REST}
      [] &r|&o|&o|&t|&=|T then
         URL#REST = {Gather T SEPARATOR ESCAPE}
      in
         {MakeRootHandler URL}|{Parse REST}
      [] &c|&a|&c|&h|&e|&=|T then
         URL#REST = {Gather T SEPARATOR ESCAPE}
      in
         {MakeCacheHandler URL}|{Parse REST}
      [] &p|&r|&e|&f|&i|&x|&=|T then
         PREFIX#TMP = {Gather T &= ESCAPE}
         SUBST#REST = {Gather TMP SEPARATOR ESCAPE}
      in
         {MakePrefixHandler PREFIX SUBST}|{Parse REST}
      else
         URL#REST = {Gather L SEPARATOR ESCAPE}
      in
         {MakeRootHandler URL}|{Parse REST}
      end
   end
in
   {Parse L}
end

%%% Normalizing a pathname.  A pathname is in normal form if it contains
%%% no doubling of the file separators (/ and \), does not begin with
%%% a tilde (~) or a period (.).
local
   fun {NoDoubling L Path}
      case L of H|T then
         case H==&/ orelse H==&\\ then
            case T of H|R then
               case H==&/ orelse H==&\\ orelse H==&~
               then {NoDoubling T T}
               else {NoDoubling R Path} end
            else Path end
         else {NoDoubling T Path} end
      else Path end
   end
   %% this should look up system property 'user.home' instead
   fun {NoTildeOrDot Path}
      case Path of H|T then
         case H==&~ then
            case T of &/|_ then {GET 'user.home'}#T
            else
               USER#DIR = {Gather T &/ unit}
               PATH = case DIR==nil then nil else &/|DIR end
            in
               try R={Getpwnam USER} in R.dir#PATH
               catch _ then Path end
            end
         elsecase H==&. then CWD = {GetCWD} in
            case T of &/|_ then CWD#T
            else CWD #(&/|Path) end
         else Path end
      else Path end
   end
in
   fun {NormalizePath Path} L = {VirtualString.toString Path} in
      {NoTildeOrDot {NoDoubling  L L}}
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
      try REP={ParseURL URL} in
         {ForAll {Access Handlers}
          proc {$ H} {H REP Meth MethName MSG} end}
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
   [] env( L) then S={Getenv L} in
      case S==false then skip else
         {SetHandlers {StringToHandlers S}}
      end
   [] env( L D) then S={Getenv L} in
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

proc {DefaultHandler REP Meth MethName MSG}
   PATH = {NormalizePath REP.string}
in
   {MSG '...['#PATH#'] (default)'}
   {HApply PATH Meth}
end

%% all handler

fun {MakeAllHandler DIR}
   proc {$ REP Meth MethName MSG}
      case REP.last of nil then
         {MSG '...[not applicable] (all '#DIR#')'}
      elseof Path then
         PATH = {NormalizePath DIR#'/'#Path}
      in
         {MSG '...['#PATH#'] (all)'}
         {HApply PATH Meth}
      end
   end
end

%% root handler

fun {MakeRootHandler DIR}
   proc {$ REP Meth MethName MSG}
      case REP.type of file(rel) then
         PATH = {NormalizePath DIR#'/'#REP.string}
      in
         {MSG '...['#PATH#'] (root)'}
         {HApply PATH Meth}
      else
         {MSG '...[not applicable] (root '#DIR#')'}
      end
   end
end

%% cache handler

fun {MakeCacheHandler DIR}
   proc {$ REP Meth MethName MSG}
      case REP.type of url(PROTO) then
         PATH = {NormalizePath DIR#'/'#PROTO#'/'#REP.path}
      in
         {MSG '...['#PATH#'] (cache)'}
         {HApply PATH Meth}
      else
         {MSG '...[not applicable] (cache '#DIR#')'}
      end
   end
end

%% prefix handler

fun {MakePrefixHandler PREFIX SUBST}
   proc {$ REP Meth MethName MSG}
      case {StripPrefix PREFIX REP.string}
      of ok(REST) then
         PATH = {NormalizePath SUBST#REST}
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
      case URL of HH|URL then
         case H==HH then {StripPrefix Prefix URL}
         else unit end
      else unit end
   end
end

%% create a resolver for loading

LoadResolver = {MakeResolver url vs(OZ_SEARCH_LOAD)}

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
              makeResolver : MakeResolver
              normalizePath: NormalizePath)
          LoadResolver}
end
