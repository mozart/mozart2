%%% ==================================================================
%%%                           URL LIBRARY
%%% ==================================================================
%%%
%%% This library provides facilities for the manipulation of URLs and
%%% filenames.  It supports both Unix and Windows syntax where they do
%%% not conflict.  There are no plans to ever support VMS's strange
%%% filename syntax.
%%%
%%% HISTORY
%%%
%%% * 1ST IMPLEMENTATION
%%% The 1st implementation of such a library was written by Christian
%%% Schulte for his `Module Manager' facility.
%%% * 2nd IMPLEMENTATION
%%% It was entirely rewritten by Denys Duchier to add various
%%% extensions such as support for Windows-style filenames.  That 2nd
%%% implementation also improved the theoretical complexity, although
%%% not necessarily the performance.  What was definitely improved was
%%% the correctness: the library now conforms to URI syntax as defined
%%% in the IETF draft (see below).
%%% * 3rd IMPLEMENTATION
%%% The 3rd implementation is a clean-up of the 2nd one.  The
%%% representation is rationalized and simplified.  Minor problems are
%%% fixed.  The performance is improved measurably.
%%%
%%% The library fully conforms to URI syntax as defined in RFC 2396
%%% "Uniform Resource Identifiers (URI): Generic Syntax" by T.
%%% Berners-Lee, R. Fielding, and L. Masinter, of August 1998,
%%% available at: ftp://ftp.isi.edu/in-notes/rfc2396.txt
%%% and passes all 5 test suites published by Roy Fielding (see
%%% http://www.ics.uci.edu/~fielding/url/test{1,2,3,4,5}.html)
%%%
%%% The only derogations to said specification are made to accommodate
%%% Windows-style filenames: (1) a prefix of the form "C:" where C is
%%% a single character is interpreted as Windows-style device notation
%%% rather than as a uri scheme - in practice, this is a compatible
%%% extension since there are no legal single character schemes, (2)
%%% path segments may indifferently be separated by "/" or "\" - this
%%% too is compatible since non-separator forward and backward slashes
%%% ought to be otherwise `escape encoded'.
%%%
%%% There is additionally a further expereimental extension: all urls
%%% may be suffixed by a string of the form "{foo=a,bar=b}".  This
%%% adds an info record to the parsed representation or the url.  This
%%% record is here info(foo:a bar:b).  Thus properties can be attached
%%% to urls.  For example, we may indicate that a url denotes a native
%%% functor thus: file:/foo/bar/baz.so{native}.  Here {native} is
%%% equivalent to {native=}, i.e. the info record is info(native:'').
%%%
%%% API
%%%
%%% {URL.make LOC}
%%%     parses virtual string LOC according to the proposed URI syntax
%%% modulo Windows-motivated derogations (see above).  Local filename
%%% syntax is a special case of schemeless uri.  The parsed
%%% representation of a url is a record whose features hold the
%%% various parts of the url.  We speak of url `records' and url
%%% `vstrings': to former being the parsed representation of the
%%% latter.  A url record has label 'url' and must be non-empty to
%%% distinguish it from the the url vstring consisting of the atom
%%% 'url'.  The empty url record can be written e.g. url(unit).  LOC
%%% may also be a url record, in which case it is simply returned.
%%%
%%% {URL.is X}
%%%     returns true iff X is a non-empty record with label 'url'.
%%%
%%% {URL.toVirtualString X}
%%%     X may be a url record or vstring.  The corresponding
%%% normalized vstring representation is returned.  #FRAGMENT and
%%% {INFO} sections are not included (see below).  This is appropriate
%%% for retrieval since fragment and info sections are meant for
%%% client-side usage.
%%%
%%% {URL.toVirtualStringExtended X HOW}
%%%     Similar to the above, but HOW is a record with optional
%%% features to parametrize the conversion process.
%%% `full:true'
%%%     indicates that full information is desired, including
%%%     #FRAGMENT and {INFO} sections.
%%% `cache:true'
%%%     indicates that a syntax appropriate for cache lookup is
%%%     desired.  the `:' after the scheme and the '//' before the
%%%     authority are in both cases replaced by a single `/'.
%%% `raw:true'
%%%     indicates that no encoding should take place, i.e. special
%%%     url characters are not escaped
%%%
%%% {URL.toString X}
%%%     transforms the result of URL.toVirtualString to a string
%%%
%%% {URL.toAtom X}
%%%     transforms the result of URL.toVirtualString to an atom
%%%
%%% {URL.resolve BASE REL}
%%%     BASE and REL are url records or vstrings.  REL is resolved
%%% relative to BASE and a new url record is returned with the
%%% appropriate fields filled in.  If REL is not a relative url, it
%%% is simply returned unchanged.  Otherwise, the full path is
%%% computed by dropping the last component of BASE's path and
%%% appending REL's path.
%%%
%%% BUGS AND LIMITATIONS
%%%
%%% Each path component may have the form `COMP;PARM': that is each
%%% path component may have its own parameter section.  Parameters
%%% are currently not parsed and simply remain attached to the path
%%% component.  This has the problem that the distinction between
%%% encoded occurrences of `;' in COMP and naked occurrences of `;'
%%% in PARM is not preserved.
%%%
%%% CLARIFICATIONS
%%%
%%% The draft standard is ambiguous: in a relative uri, the leading
%%% segment is allowed to contain occurrences of `;'.  Is the
%%% parameter parsing semantics as usual or not?.  Roy Fielding
%%% provided a clarification by email: it's business as usual.  The
%%% apparent difference was intended to emphacize that the parameter
%%% is to be treated like the rest of the segment when resolving
%%% relative uris.  ... in my opiniion, this makes things less clear
%%% rather than clearer.
%%%
%%% MISCELLANEOUS
%%%
%%% A URL string has at most the following fields:
%%%
%%%          SCHEME://AUTHORITY/PATH?QUERY#FRAGMENT{INFO}
%%%
%%% A Windows-style pathname is similar:
%%%
%%%          DEVICE:PATH?QUERY#FRAGMENT{INFO}
%%%
%%% ==================================================================
functor
export
   is                           : URL_is
   make                         : URL_make
   toVirtualString              : URL_toVS
   toVirtualStringExtended      : URL_vs
   toString                     : URL_toString
   toAtom                       : URL_toAtom
   resolve                      : URL_resolve
   normalizePath                : NormalizePath
   isAbsolute                   : URL_isAbsolute
   isRelative                   : URL_isRelative
   toBase                       : URL_toBase
prepare
   ToLower = Char.toLower
   ToRecord = List.toRecord
   Tokens = String.tokens
   Token  = String.token
   ToAtom = VirtualString.toAtom
   ToString = VirtualString.toString
   ToTuple = List.toTuple
   fun {INFO_ELT S}
      Prop Value
   in
      {Token S &= Prop Value}
      {ToAtom Prop}#{ToAtom Value}
   end

   fun {URL_is X}
      %% a url record has label 'url' and must be non-empty to
      %% distinguish it from the url vstring consisting of the
      %% atom 'url'.  an empty url record can be written e.g.
      %% url(unit)
      X\=url andthen {IsRecord X} andthen {Label X}==url
   end

   LEVEL_START     = 4
   LEVEL_AUTHORITY = 3
   LEVEL_PATH      = 3
   LEVEL_QUERY     = 2
   LEVEL_FRAGMENT  = 1

   CharIsAlNum = Char.isAlNum

define

   %% a url may contain occurrences of %XY escape sequences
   %% Here is how to decode them

   local
      D = x(&0:0 &1:1 &2:2 &3:3 &4:4 &5:5 &6:6 &7:7 &8:8 &9:9
            &a:10 &b:11 &c:12 &d:13 &e:14 &f:15
            &A:10 &B:11 &C:12 &D:13 &E:14 &F:15)
   in
      fun {Decode L}
         case L of nil then nil
         [] H|T then
            if H==&% then
               case T of X1|X2|T then
                  (D.X1*16)+D.X2 | {Decode T}
               else H | {Decode T} end
            else H | {Decode T} end
         end
      end
   end

   proc {SPLIT S Level Prefix Sep Suffix}
      case S
      of nil      then Prefix=Suffix=nil Sep=unit
      [] &{ |T    then Prefix=nil Sep=&{ Suffix=T
      [] &# |T andthen Level>1 then Prefix=nil Sep=&#  Suffix=T
      [] &? |T andthen Level>2 then Prefix=nil Sep=&?  Suffix=T
      [] &\\|T andthen Level>2 then Prefix=nil Sep=&\\ Suffix=T
      [] &/ |T andthen Level>2 then Prefix=nil Sep=&/  Suffix=T
      [] &: |T andthen Level>3 then Prefix=nil Sep=&:  Suffix=T
      [] H  |T    then More in
         Prefix=H|More
         {SPLIT T Level More Sep Suffix}
      end
   end

   fun {PARSE S}
      URL = {START {ToString S}
             url(scheme    : unit
                 authority : unit
                 device    : unit
                 absolute  : false
                 path      : nil
                 query     : unit
                 fragment  : unit
                 info      : unit)}
   in
      {AdjoinAt URL path {NormalizePath {Reverse URL.path}}}
   end

   fun {URL_make X}
      if {URL_is X} then X else {PARSE X} end
   end

   fun {START L URL}
      Prefix Sep Suffix
   in
      {SPLIT L LEVEL_START Prefix Sep Suffix}
      case Sep
      of unit then
         %% we hit then end without finding a separator
         {AdjoinAt URL path [{Decode Prefix}]}
      [] &: then
         %% we found the scheme or device separator
         case Prefix of [C] then
            %% this is a device (1 char)
            URL2 = {AdjoinAt URL device {ToLower C}}
         in
            %% does the path begin with a slash?
            case Suffix of H|T then
               if H==&/ orelse H==&\\ then
                  {PATH T {AdjoinAt URL2 absolute true}}
               else
                  {PATHDEV Suffix URL2}
               end
            else URL2 end
         else
            %% it is a scheme: downcase it
            URL2 = {AdjoinAt URL scheme {Map Prefix ToLower}}
         in
            %% check for authority
            case Suffix
            of &/|&/|T then {AUTHORITY T URL2}
            [] &/   |T then
               {PATH T {AdjoinAt URL2 absolute true}}
            else {PATHDEV Suffix URL2} end
         end
      [] &/ then
         %% unix path separator
         case Prefix of nil then
            %% slash at start: check for //authority
            case Suffix
            of &/|T then {AUTHORITY T URL}
            else
               {PATH Suffix {AdjoinAt URL absolute true}}
            end
         else
            %% Prefix is 1st relative component
            {PATH Suffix {AdjoinAt URL path [{Decode Prefix}]}}
         end
      [] &\\ then
         %% windows path separator
         case Prefix of nil then
            %% slash at front
            {PATH Suffix {AdjoinAt URL absolute true}}
         else
            %% Prefix is 1st relative component
            {PATH Suffix {AdjoinAt URL path [{Decode Prefix}]}}
         end
      [] &? then
         {QUERY Suffix
          if Prefix\=nil
          then {AdjoinAt URL path [{Decode Prefix}]} else URL end}
      [] &# then
         {FRAGMENT Suffix
          if Prefix==nil then URL
          else {AdjoinAt URL path {Decode Prefix}|URL.path} end}
      [] &{ then
         {INFO Suffix
          if Prefix\=nil
          then {AdjoinAt URL path [{Decode Prefix}]} else URL end}
      end
   end

   fun {AUTHORITY L URL}
      Prefix Sep Suffix
      {SPLIT L LEVEL_AUTHORITY Prefix Sep Suffix}
      URL2 = {AdjoinAt URL authority Prefix}
   in
      case Sep
      of unit then URL2
      [] &/   then {PATH Suffix {AdjoinAt URL2 absolute true}}
      [] &\\  then {PATH Suffix {AdjoinAt URL2 absolute true}}
      [] &?   then {QUERY Suffix URL2}
      [] &#   then {FRAGMENT Suffix URL2}
      [] &{   then {INFO Suffix URL2}
      else raise urlbug end
      end
   end

   fun {PATHDEV L URL}
      case L of C|&:|T then
         {PATH T {AdjoinAt URL device {ToLower C}}}
      else
         {PATH L URL}
      end
   end

   fun {PATH L URL}
      Prefix Sep Suffix
      {SPLIT L LEVEL_PATH Prefix Sep Suffix}
      URL2 = {AdjoinAt URL path {Decode Prefix}|URL.path}
   in
      case Sep
      of unit then URL2
      [] &/   then {PATH Suffix URL2}
      [] &\\  then {PATH Suffix URL2}
      [] &?   then {QUERY Suffix URL2}
      [] &#   then {FRAGMENT Suffix URL2}
      [] &{   then {INFO Suffix URL2}
      else raise urlbug end
      end
   end

   fun {QUERY L URL}
      Prefix Sep Suffix
      {SPLIT L LEVEL_QUERY Prefix Sep Suffix}
      URL2 = {AdjoinAt URL query Prefix}
   in
      case Sep
      of unit then URL2
      [] &# then {FRAGMENT Suffix URL2}
      [] &{ then {INFO Suffix URL2}
      else raise urlbug end
      end
   end

   fun {FRAGMENT L URL}
      Prefix Sep Suffix
      {SPLIT L LEVEL_FRAGMENT Prefix Sep Suffix}
      URL2 = {AdjoinAt URL fragment Prefix}
   in
      if Sep\=unit then {INFO Suffix URL2} else URL2 end
   end

   fun {INFO L URL}
      case {Reverse L} of &}|L then
         {AdjoinAt URL info
          {ToRecord info
           {Map {Tokens {Reverse L} &,} INFO_ELT}}}
      else raise urlbad end end
   end

   %% a path is represented by a list of strings.  normalizing a path
   %% is the process of eliminating occurrences of path components
   %% "." and ".." by interpreting them relative to the stack of path
   %% components.  This algorithm is due to Christian Schulte.  I
   %% modified it to not throw out a leading "." because ./foo and foo
   %% should be treated differently: ./foo is an absolute path, whereas
   %% foo is a relative path.

   fun {NormalizePath Path}
      case Path
      of nil then nil
      [] ("."=H)|T then H|{NormalizeStack T nil}
      else {NormalizeStack Path nil} end
   end
   fun {NormalizeStack Path Stack}
      case Path
      of nil then {Reverse Stack}
      [] H|T then
         if     H=="."  then
            if T==nil then
               if Stack==nil then nil else {Reverse nil|Stack} end
            else {NormalizeStack T Stack} end
         elseif H==".." then
            if T==nil then
               case Stack
               of nil then [H]
               [] [_] then [nil]
               [] _|Stack then {Reverse nil|Stack}
               end
            elsecase Stack
            of nil then H|{NormalizeStack T nil}
            [] _|Stack then {NormalizeStack T Stack} end
         else {NormalizeStack T H|Stack} end
      end
   end

   %% URL_vs converts a url to a virtual string.  The 2nd argument is
   %% a record whose features parametrize the conversion process.
   %% `full:true'
   %%   indicates that full information is desired, including #FRAGMENT
   %%   and {INFO} sections.  Normally, the #FRAGMENT indicator is
   %%   intended only for client-side usage.  Similarly, but even more
   %%   so, the {INFO} section is a Mozart extension, where, for
   %%   example, it is indicated whether the url denotes a native
   %%   functor or not.  Thus, neither should be included when
   %%   constructing a url for retrieval.
   %% `cache:true'
   %%   indicates that a syntax appropriate for cache lookup is desired.
   %%   the `:' after the scheme and the '//' before the authority are
   %%   in both cases replaced by a single `/'.
   %% `raw:true'
   %%   indicates that no encoding should take place, i.e. special url
   %%   characters are not escaped.

   fun {URL_vs Url How}
      U         = {URL_make Url}
      Full      = {CondSelect How full  false}
      Cache     = {CondSelect How cache false}
      Raw       = {CondSelect How raw   false}
      CompAdd   =
      if Cache then
         if Raw then CompAdd_c_raw else CompAdd_c_enc end
      else
         if Raw then CompAdd_raw else CompAdd_enc end
      end
      Scheme    = {CondSelect U scheme unit}
      Device    = {CondSelect U device unit}
      Authority = {CondSelect U authority unit}
      Absolute  = {CondSelect U absolute false}
      Path      = {CondSelect U path      nil}
      Query     = {CondSelect U query unit}
      Fragment  = if Full then {CondSelect U fragment unit} else unit end
      Info      = if Full then {CondSelect U info unit} else unit end
      %%
      V1        = if Full andthen Info\=unit then
                     {InfoPropsAdd {Record.toListInd Info} ['}'] true}
                  else nil end
      V2        = if Full andthen Fragment\=unit then
                     "#"|Fragment|V1
                  else V1 end
      V3        = if Query==unit then V2 else '?'|Query|V2 end
      V4        = {Append
                   %% yes we want the nil here otherwise
                   %%Slashit adds an erroneous slash
                   {FoldR Path CompAdd nil} V3}
      V5        = if Absolute then {Slashit V4} else V4 end
      V6        = if Device==unit then V5
                  else
                     [Device]
                     |if Cache then {Slashit V5} else ':'|V5 end
                  end
      V7        = if Authority==unit then V6
                  elseif Cache then
                     if Authority==nil then V6
                     else Authority|{Slashit V6} end
                  else
                     '/'|'/'|Authority|{Slashit V6}
                  end
      V8        = if Scheme==unit then V7
                  elseif Cache then Scheme|{Slashit V7}
                  else Scheme|':'|V7 end
   in
      {ToTuple '#' V8}
   end

   fun {Slashit L}
      case L of nil then nil
      [] '/'|_ then L
      else '/'|L end
   end

   fun {InfoPropsAdd L Rest First}
      case L of nil then '{'|Rest
      [] (K#V)|T then
         {InfoPropsAdd T
          K|'='|V|if First then Rest else ','|Rest end
          false}
      end
   end

   fun {CompAdd_raw H L}
      H|{Slashit L}
   end

   fun {CompAdd_enc H L}
      {Encode H}|{Slashit L}
   end

   fun {CompAdd_c_raw H L}
      if H==nil then L else H|{Slashit L} end
   end

   fun {CompAdd_c_enc H L}
      if H==nil then L else {Encode H}|{Slashit L} end
   end

   fun {URL_toVS     U} {URL_vs U true} end
   fun {URL_toString U} {ToString {URL_toVS U}} end
   fun {URL_toAtom   U} {ToAtom   {URL_toVS U}} end

   fun {URL_isAbsolute U}
      U2 = {URL_make U}
   in
      {CondSelect U2 scheme unit}\=unit orelse
      {CondSelect U2 device unit}\=unit orelse
      {CondSelect U2 absolute false} orelse
      case {CondSelect U2 path nil}
      of (&~|_)|_ then true
      [] "."   |_ then true
      [] ".."  |_ then true
      else false end
   end

   fun {URL_isRelative U} {Not {URL_isAbsolute U}} end

   %% resolving a relative url with respect to a base url

   fun {URL_resolve BASE REL}
      Rel = {URL_make REL}
   in
      if {CondSelect Rel scheme unit}\=unit then Rel
      else
         Base = {URL_make BASE}
         Scheme = {CondSelect Base scheme unit}
         Rel2 = if Scheme==unit then Rel
                else {AdjoinAt Rel scheme Scheme} end
      in
         if {CondSelect Rel2 authority unit}\=unit then Rel2
         else
            Authority = {CondSelect Base authority unit}
            Rel3 = if Authority==unit then Rel2
                   else {AdjoinAt Rel2 authority Authority} end
         in
            if {CondSelect Rel3 device unit}\=unit then Rel3
            else
               Device = {CondSelect Base device unit}
               Rel4 = if Device==unit then Rel3
                      else {AdjoinAt Rel3 device Device} end
               BPath = {CondSelect Base path unit}
               RAbs  = {CondSelect Rel4 absolute false}
            in
               if RAbs orelse BPath==unit then Rel4
               else
                  Rel5 = if {CondSelect Base absolute false}
                         then {AdjoinAt Rel4 absolute true}
                         else Rel4 end
                  RPath = {CondSelect Rel path nil}
               in
                  {AdjoinAt Rel5 path
                   {NormalizePath
                    {AtLast BPath
                     if RPath==unit orelse RPath==nil
                     then [nil] else RPath end}}}
               end
            end
         end
      end
   end

   fun {AtLast L1 L2}
      case L1
      of nil then L2
      [] H|T then
         case T of nil then L2
         else H|{AtLast T L2} end
      end
   end

   %% turn a url into one that can safely be used as a base without
   %% loosing its last component.  we just add an empty component if
   % the last one is not already empty.

   fun {URL_toBase U}
      U2 = {URL_make U}
   in
      case {CondSelect U2 path nil}
      of unit then U2
      [] nil  then U2
      [] L then
         case {Reverse L}
         of nil|_ then U2
         else {AdjoinAt U2 path {Append L [nil]}} end
      end
   end

   %% for producing really normalized url vstrings, we need to encode
   %% its components.  Encode performs the `escape encoding' of a
   %% string (e.g. a single path component).

   local
      D = x(0:&0 1:&1 2:&2 3:&3 4:&4 5:&5 6:&6 7:&7 8:&8 9:&9
            10:&a 11:&b 12:&c 13:&d 14:&e 15:&f)
   in
      fun {Encode S}
         case S of nil then nil
         [] H|T then
            %% check that it is an `ascii' alphanum
            if H<128 andthen {CharIsAlNum H} orelse
               H==&; orelse
               H==&- orelse
               H==&_ orelse
               H==&. orelse
               H==&! orelse
               H==&~ orelse
               H==&* orelse
               H==&' orelse
               H==&( orelse
               H==&) orelse
               H==&: orelse
               H==&@ orelse
               H==&& orelse
               H==&= orelse
               H==&+ orelse
               H==&$ orelse
               H==&,
            then H|{Encode T} else
               X1 = H div 16
               X2 = H mod 16
            in &%|D.X1|D.X2|{Encode T} end
         end
      end
   end

end
