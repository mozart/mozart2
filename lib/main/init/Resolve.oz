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

%%% ==================================================================
%%% A URL denotes a networked resource, typically a file of data.
%%% Normally, one would retrieve the data from the networked location
%%% represented by the URL itself.  However, it is sometimes desirable
%%% to retrieve the data from a different location instead.  For
%%% example: (1) to access a local cache (faster than downloading from
%%% the net, (2) to override one implementation with another without
%%% changing the URL, (3) to bootstrap a system.  Also, we want this
%%% capability for file paths, relative or not.  This package
%%% implements a mechanism that generalizes the concept of `search
%%% path': instead of having several alternative directories, we have
%%% several alternative `methods'.
%%%
%%% Each `method' or `handler' H is a procedure, called as follows:
%%%
%%%                     {H URL METH MSG}
%%%
%%% where URL is the parsed representation of a URL. METH is a
%%% a procedure which takes as an argument the URL transformed by the
%%% handler and either raises found(V), if it successfully retrieved
%%% value V from the location, or returns if it failed. MSG is a
%%% procedure that takes 5 arguments, each is either a virtual string
%%% or a URL, which are printed as a 1 line message if tracing is
%%% enabled.
%%% ==================================================================

local
   BURL_localize        = BURL.localize
   BURL_open            = BURL.open
   BURL_load            = BURL.load
   Native_load          = fun {$ FN}
                             {ObtainNative false FN}
                          end
   \insert UrlExpand.oz

   %% the default way of applying a method to a parsed URL: all system
   %% exceptions are considered to indicate that the data was not
   %% available at this location and are ignored; all other exceptions
   %% are passed through.  If a value V is obtained, exception
   %% found(V) is raised.

   proc {Do_Method M U} V OK in
      try {M {UrlToString
              if {UrlIsRelative U} then
                 {URL_expand {UrlResolve DotUrl U}}
              else U end} V} OK=true
      catch system(...) then     OK=false
      [] error(dp(generic 'URLhandler' _ _) ...)
      then                       OK=false
      end
      if OK then raise found(V) end else skip end
   end

   Methods = m(localize : proc {$ U} {Do_Method BURL_localize U} end
               open     : proc {$ U} {Do_Method BURL_open     U} end
               load     : proc {$ U} {Do_Method BURL_load     U} end
               native   : proc {$ U} {Do_Method Native_load   U} end)

   %% ----------------------------------------------------------------
   %% Tracing
   %% ----------------------------------------------------------------

   Trace = {NewCell {GET 'oz.trace.load'}}
   proc {GetTrace B} {Access Trace B} end
   proc {SetTrace B} {Assign Trace B} end

   Full_Url = o(full:true)
   fun {ToVS A}
      if {UrlIs A} then {UrlToVsExtended A Full_Url} else A end
   end

   proc {TraceMsg A B C D E F}
      %% the 1st arg is the resolver's title
      %% the other 5 args are the MSG procedure's arguments
      {System.printError
       '['#{ToVS A}#'] '
       #{ToVS B}#{ToVS C}#{ToVS D}#{ToVS E}#{ToVS F}#'\n'}
   end

   %% ----------------------------------------------------------------
   %% Handler Constructors
   %% ----------------------------------------------------------------

   %% default

   proc {Default_Handler Url Meth Msg}
      NewUrl = {URL_expand Url}
   in
      {Msg '...[' NewUrl '] (default)' nil nil}
      {Meth NewUrl}
   end

   %% all

      fun {Make_All_Handler DIR}
      Base = {UrlToBase DIR}
   in
      proc {$ Url Meth Msg}
         Path = {CondSelect Url path unit}
      in
         if Path==unit orelse Path.1==nil then
            {Msg '...[not applicable] (all ' Base ')' nil nil}
         else
            Rel=url(path:rel([{List.last Path.1}]))
            NewUrl = {URL_expand {UrlResolve Base Rel}}
         in
            {Msg '...[' NewUrl '] (all)' nil nil}
            {Meth NewUrl}
         end
      end
   end

   %% root

   fun {Make_Root_Handler DIR}
      Base = {UrlToBase DIR}
   in
      proc {$ Url Meth Msg}
         if {UrlIsRelative Url} then
            NewUrl = {URL_expand {UrlResolve Base Url}}
         in
            {Msg '...[' NewUrl '] (root)' nil nil}
            {Meth NewUrl}
         else
            {Msg '...[not applicable] (root ' Base ')' nil nil}
         end
      end
   end

   %% cache

   fun {Make_Cache_Handler DIR}
      Base = {UrlToBase DIR}
   in
      proc {$ Url Meth Msg}
         if {HasFeature Url scheme} then
            Rel = {UrlMake {UrlToVsExtended Url x(cache:true)}}
            NewUrl = {URL_expand {UrlResolve Base Rel}}
         in
            {Msg '...[' NewUrl '] (cache)' nil nil}
            {Meth NewUrl}
         else
            {Msg '...[not applicable] (cache ' Base ')' nil nil}
         end
      end
   end

   %% pattern

   fun {Make_Pattern_Handler LSpec RSpec}
      LPat = {Pattern_Parse LSpec}
      RPat = {Pattern_Parse RSpec}
   in
      proc {$ Url Meth Msg}
         try
            Alist  = {Pattern_Match LPat {UrlToString Url}}
            Arec   = {List.toRecord alist Alist}
            NewPat = {Pattern_Instantiate RPat Arec}
            NewUrl = {URL_expand {UrlMake NewPat}}
         in
            {Msg '...[' NewUrl '] (pattern)' nil nil}
            {Meth NewUrl}
         catch no then
            {Msg '...[not applicable] (pattern ' LSpec ' -> ' RSpec ')'}
         end
      end
   end

   %% prefix

   fun {Make_Prefix_Handler Prefix Subst}
      {Make_Pattern_Handler
       {Append Prefix "?{x}"}
       {Append Subst  "?{x}"}}
   end

   %% pattern utils

   %% returns true if S1 is a prefix of S2 and binds S3 to the
   %% remaining suffix

   fun {IsPrefix S1 S2 S3}
      case S1
      of nil then S3=S2 true
      [] H1|T1 then
         case S2 of H2|T2 then
            H1==H2 andthen {IsPrefix T1 T2 S3}
         else false
         end
      end
   end

   %% Splits Input at the first occurrence of string Str
   %% binds Prefix to what occurred before and Suffix
   %% to what is left after

   proc {SplitAtString Str Input Prefix Suffix}
      if {IsPrefix Str Input Suffix} then
         Prefix=nil
      else
         case Input of H|T then
            PrefixTail
         in
            Prefix=H|PrefixTail
            {SplitAtString Str T PrefixTail Suffix}
         else raise no end
         end
      end
   end

   %% returns a list of element of the form str(S) or var(V S) where S
   %% is a string and V a symbol. str(S) can only occur at the front
   %% of the pattern: it is the string that precedes the 1st pattern
   %% variable.  var(V S) represents  a pattern variable that extends
   %% to the first occurrence of string S.

   fun {Pattern_Parse Input}
      Prefix Suffix
   in
      try
         if try {SplitAtString "?{" Input Prefix Suffix} true
            catch no then false end
         then str(Prefix)|{Pattern_Parse_aux Suffix}
         else [str(Input)] end
      catch badPattern then
         raise resolve(patternParse Input) end
      end
   end

   fun {Pattern_Parse_aux Input}
      Prefix1 Suffix1 Prefix2 Suffix2
   in
      {SplitAtString "}" Input Prefix1 Suffix1}
      if try {SplitAtString "?{" Suffix1 Prefix2 Suffix2} true
         catch no then false end
      then var({String.toAtom Prefix1} Prefix2)
         | {Pattern_Parse_aux Suffix2}
      else
         [ var({String.toAtom Prefix1} Suffix1) ]
      end
   end

   fun {Pattern_Match Specs Input}
      case Specs
      of nil then case Input of nil then nil else raise no end end
      [] H|T then
         case H
         of var(V Sep) then
            case Sep of nil then (V#Input)|{Pattern_Match T nil}
            else Prefix Suffix in
               {SplitAtString Sep Input Prefix Suffix}
               (V#Prefix)|{Pattern_Match T Suffix}
            end
         [] str(Str) then Suffix in
            if {IsPrefix Str Input Suffix} then
               {Pattern_Match T Suffix}
            else raise no end end
         end
      end
   end

   fun {Pattern_Instantiate Pat Arec}
      case Pat
      of nil then nil
      [] H|T then
         case H
         of str(Str) then Str#{Pattern_Instantiate T Arec}
         [] var(V Sep) then Arec.V#Sep#{Pattern_Instantiate T Arec}
         end
      end
   end

   %% convert a string to a list of handlers

   fun {StringToHandlers L}
      SEP       = {GET 'path.separator'} % usually `:'
      ESC       = {GET 'path.escape'   } % usually `\'

      fun {Parse L}
         case L
         of nil then [Default_Handler]
         elseof "=" then nil
         elseof &a|&l|&l|&=|T then
            DIR#Rest = {Gather T SEP ESC}
         in {Make_All_Handler DIR}|{Parse Rest}
         elseof &r|&o|&o|&t|&=|T then
            DIR#Rest = {Gather T SEP ESC}
         in {Make_Root_Handler DIR}|{Parse Rest}
         elseof &c|&a|&c|&h|&e|&=|T then
            DIR#Rest = {Gather T SEP ESC}
         in {Make_Cache_Handler DIR}|{Parse Rest}
         elseof &p|&r|&e|&f|&i|&x|&=|T then
            PREFIX#Tmp  = {Gather T   &=  ESC}
            SUBST #Rest = {Gather Tmp SEP ESC}
         in {Make_Prefix_Handler PREFIX SUBST}|{Parse Rest}
         elseof &p|&a|&t|&t|&e|&r|&n|&=|T then
            LEFT #Tmp  = {Gather T   &=  ESC}
            RIGHT#Rest = {Gather Tmp SEP ESC}
         in {Make_Pattern_Handler LEFT RIGHT}|{Parse Rest}
         else URL#Rest = {Gather L SEP ESC}
         in {Make_Root_Handler URL}|{Parse Rest} end
      end
   in
      {Parse L}
   end

   %% {Gather L SEP ESC} ==> PREFIX#SUFFIX
   %% Splits string L at the first non-escaped occurrence of character
   %% SEP.  Any character can be escaped by preceding it with
   %% character ESC.  The ESC character is stripped off.  A pair is
   %% returned: PREFIX is what occurred before SEP, and SUFFIX is what
   %% is left after it.

   fun {Gather L SEP ESC}
      fun {Loop L Accu}
         case L
         of nil then {Reverse Accu}#nil
         [] H|T then
            if H==ESC then
               case T
               of nil then {Reverse H|Accu}#nil
               [] H|T then {Loop T  H|Accu}
               end
            elseif H==SEP then {Reverse Accu}#T
            else {Loop T H|Accu} end
         end
      end
   in {Loop L nil} end

   %% creating a resolver

   proc {NoMSG _ _ _ _ _} skip end

   fun {MakeResolver TITLE Init}
      Title = {VirtualString.toAtom TITLE}
      proc {MSG S1 S2 S3 S4 S5}
         {TraceMsg Title S1 S2 S3 S4 S5}
      end
      Handlers = {NewCell [Default_Handler]}
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
      proc {Get Loc Value MethodName}
         Msg  = if {Access Trace} then MSG else NoMSG end
         Url  = {UrlMake Loc}
         Meth = Methods.MethodName
      in
         {Msg MethodName ' request: ' Url nil nil}
         try
            {ForAll {Access Handlers}
              proc {$ H} {H Url Meth Msg} end}
            {Msg '...all handlers failed' nil nil nil nil}
            {Exception.raiseError
             url(MethodName
                 {VirtualString.toAtom {UrlToVsExtended Url o(full:true)}})}
         catch found(V) then
            {Msg '...' MethodName ' succeeded' nil nil}
            Value=V
         end
      end
      proc {Localize Url Value} {Get Url Value localize} end
      proc {Open     Url Value} {Get Url Value open    } end
      proc {Load     Url Value} {Get Url Value load    } end
      proc {Native   Url Value} {Get Url Value native  } end
   in
      case Init
      of unit then skip
      [] init(L) then {SetHandlers L}
      [] env( L) then S={OS.getEnv L} in
         if S==false then skip else
            {SetHandlers {StringToHandlers S}}
         end
      [] env( L D) then S={OS.getEnv L} in
         {SetHandlers
          {StringToHandlers
           if S==false then {VirtualString.toString D} else S end}}
      [] vs(  L) then
         {SetHandlers {StringToHandlers {VirtualString.toString L}}}
      end
      Title(getHandlers : GetHandlers
            setHandlers : SetHandlers
            addHandler  : AddHandler
            localize    : Localize
            open        : Open
            load        : Load
            native      : Native)
   end

   %% create a resolver for loading

   LoadResolver   = {MakeResolver load vs(OZ_SEARCH_LOAD)}
   NativeResolver = {MakeResolver native vs(OZ_SEARCH_LOAD)}

in
   Resolve = {Adjoin LoadResolver
              resolve(
                 trace          :
                    trace(set   : SetTrace
                          get   : GetTrace)
                 handler        :
                 handler(
                    default     : Default_Handler
                    all         : Make_All_Handler
                    root        : Make_Root_Handler
                    cache       : Make_Cache_Handler
                    prefix      : Make_Prefix_Handler
                    pattern     : Make_Pattern_Handler
                    )
                 makeResolver   : MakeResolver
                 make           : MakeResolver
                 expand         : URL_expand
                 pickle         : LoadResolver
                 native         : NativeResolver
                 )}
end
