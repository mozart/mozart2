%%%
%%% Author:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%% ==================================================================
%%%                          URL LIBRARY
%%% ==================================================================
%%%
%%% This library provides facilities for the manipultion of URLs and
%%% filenames.  It supports both Unix and Windows syntax where they do
%%% not conflict.  There are no plans to ever support VMS's strange
%%% filename syntax.
%%%
%%% HISTORY
%%%
%%% The first implementation of such a library was written by
%%% Christian Schulte for his `Module Manager' facility.  It has been
%%% entorely rewritten by Denys Duchier to add various extensions such
%%% as support for Windows-style filenames.  The new implementation
%%% also improves the theoretical complexity, although not necessarily
%%% the performance.
%%%
%%% What is definitely improved is the correctness: the library now
%%% fully conforms to URI syntax as defined in IETF draft "Uniform
%%% Resource Identifiers (URI): Generic Syntax" by T. Berners-Lee,
%%% R. Fielding, and L. Masinter, of June 4, 1998, available at
%%% http://search.ietf.org/internet-drafts/draft-fielding-uri-syntax-03.txt
%%% and passes all 5 test suites published by Roy Fielding.
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
%%% There is additionally a further experimental extension: all urls
%%% may be suffixed by a string of the form "{foo=a,bar=b}".  This
%%% adds an info record to the parsed representation of the url.  This
%%% record is here info(foo:a bar:b).  Thus properties can be attached
%%% to urls.  For example, we may indicate that a url denotes a native
%%% functor thus: file:/foo/bar/baz.so{native}.  Here {native} is
%%% equivalent to {native=}, i.e. info record is info(native:'').
%%%
%%% INTERFACE
%%%
%%% {URL.make LOC}
%%%     parses virtual string LOC according to the proposed URI syntax
%%% modulo Windows-motivated derogations (see above).  Local filename
%%% syntax is a special case of schemeless uri.  The parsed
%%% representation of a url is a non-empty record whose features hold
%%% the various parts or the url.  We speak of url records and url
%%% vstrings: the former being the parsed representation of the latter.
%%% A url record must be non-empty to distibguish it from the url
%%% vstring consisting of the atom 'url'. The empty url record can be
%%% written e.g. url(unit).  LOC may also be a url record, in which
%%% case it is simply returned.
%%%
%%% {URL.is X}
%%%     returns true iff X is a non-empty record labeled with 'url'.
%%%
%%% {URL.toVs X}
%%%     X may be a url record or vstring.  The corresponding normalized
%%% vstring representation is returned. #FRAGMENT and {INFO} segments
%%% are not included (see below).  This is appropriate for retrieval
%%% since fragment and info sections are meant for client-side usage.
%%%
%%% {URL.toVsExtended X HOW}
%%%     Similar to the above, but HOW is a record with optional boolean
%%% features `full' and `cache'.  `full:true' indicates that #FRAGMENT
%%% and {INFO} sections should be included if present. `cache:true'
%%% requests that cache-style syntax be used: the `:' following the
%%% scheme and the `//' preceding the authority are both replaced by
%%% single `/'.
%%%
%%% {URL.toString X}
%%%     calls URL.toVs and transforms the result to a string
%%%
%%% {URL.toAtom X}
%%%     calls URL.toVs and transforms the result to an atom
%%%
%%% {URL.resolve BASE REL}
%%%     BASE and REL are url records or vstrings.  REL is resolved
%%% relative to BASE and a new url record is returned with the
%%% approprate fields filled in.
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
%%% segment is allowed to contain occurrences of `;'.  Is the parameter
%%% parsing semantics as usual or not?.  Roy Fielding provided a
%%% clarification by email: it's business as usual.  The apparent
%%% difference was intended to emphacize that the parameter is to be
%%% treated like the rest of the segment when resolving relative uris.
%%% ... in my opiniion, this makes things less clear rather than
%%% clearer.
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

%declare
local

   CharToLower          = Char.toLower

   %% a URL value is simply a record with label 'url' and at least one
   %% feature: this is to distinguish the empty URL value and the
   %% URL notation consisting of the single symbol url (i.e. to denote
   %% a relative file named 'url').  For example, the empty URL value
   %% can be written url(unit).

   fun {URL_is X}
      {IsRecord X}      andthen
      {Label    X}==url andthen
      {Width    X} >0
   end

   %% split a string at the 1st occurrence of a separator character.
   %% return the 2 halves as Prefix and Suffix and the separator
   %% character itself as Sep.  The set of admissible separator
   %% characters is specified with a bitString.  If the input is
   %% exhausted without finding a separator character, Prefix contains
   %% the whole string, Suffix is nil, and Sep is unit.

   proc {Split S Charset Prefix Suffix Sep}
      case S of nil then Prefix=Suffix=nil Sep=unit
      [] H|T then
         if {BitString.get Charset H} then
            Sep=H Prefix=nil Suffix=T
         else More in
            Prefix=H|More
            {Split T Charset More Suffix Sep}
         end
      end
   end

   %% Christian's original parser used String.token repeatedly and
   %% thus ended up traversing and copying the string several times.
   %% This new parser traverses the string only once and uses character
   %% sets represented as bit strings to recognize the crucial
   %% characters that determine the breaking points in a url.

   %% This parser is a state machine, with 6 states, each of which is
   %% implemented by a procedure:
   %%
   %% START             the initial state: what is at the front of the
   %%                   url is disambiguated by the 1st separator we
   %%                   find or the eos
   %% AUTHORITY         entered when we encounter the // thing
   %% PATH              recognize the next path component
   %% QUERY             after `?'
   %% FRAGMENT          after `#'
   %% INFO              after `{'

   Charset_START        = {BitString.make 256 "/\\:?#{"}
   Charset_PATH         = {BitString.make 256  "/\\?#{"}
   Charset_QUERY        = {BitString.make 256      "#{"}
   Charset_FRAGMENT     = {BitString.make 256       "{"}


   fun {URL_make LOC}
      if {URL_is LOC} then LOC else

         Data = {Dictionary.new}
         %% Absolute indicates whether the path section of the url
         %% begins with a slash
         Absolute

         proc {PUT Prop Value}
            {Dictionary.put Data Prop Value}
         end

         proc {PUSHPath Value}
            {Dictionary.put Data path
             Value|{Dictionary.condGet Data path nil}}
         end

         proc {START L}
            Prefix Suffix
         in
            case {Split L Charset_START Prefix Suffix}
            of unit then
               %% -- we hit the end without finding a separator
               Absolute=false
               {PUT path [{Decode Prefix}#false]}
            [] &: then
               %% -- we found the scheme or device separator
               case Prefix of [C] then
                  %% -- this is a device (1 char): downcase it
                  {PUT device [{Char.toLower C}]}
                  %% -- does the path begin with a slash?
                  case Suffix of H|T then
                     if H==&/ orelse H==&\\ then
                        Absolute=true
                        {PATH T}
                     else
                        Absolute=false
                        {PATH Suffix}
                     end
                  else skip end
               else
                  %% -- it is a scheme: downcase it
                  {PUT scheme {Map Prefix CharToLower}}
                  %% -- check for //authority
                  case Suffix of H1|T1 then
                     if H1==&/ then
                        case T1 of H2|T2 then
                           if H2==&/ then
                              %% -- found //, expect authority
                              {AUTHORITY T2}
                           else
                              %% -- absolute path
                              Absolute=true
                              {PATH T1}
                           end
                        else
                           %% -- empty path ends with a slash
                           Absolute=true
                        end
                     else
                        %% -- path does not begin with a slash
                        Absolute=false
                        {PATH Suffix}
                     end
                  else skip end %% nothing left
               end
            [] &/ then
               %% -- Unix path separator
               case Prefix of nil then
                  %% -- slash at start: check for //authority
                  case Suffix of H|T then
                     if H==&/ then
                        {AUTHORITY T}
                     else
                        Absolute=true
                        {PATH Suffix}
                     end
                  else
                     Absolute=true
                  end
               else
                  %% -- prefix is 1st relative component
                  Absolute=false
                  {PUSHPath {Decode Prefix}#true}
                  {PATH Suffix}
               end
            [] &\\ then
               %% -- Windows path separator
               case Prefix of nil then
                  %% -- slash at front
                  Absolute=true
                  {PATH Suffix}
               else
                  %% -- prefix is 1st relative component
                  Absolute=false
                  {PUSHPath {Decode Prefix}#true}
                  {PATH Suffix}
               end
            [] &? then
               case Prefix of nil then skip else
                  Absolute=false
                  {PUSHPath {Decode Prefix}#false}
               end
               {QUERY Suffix}
            [] &# then
               case Prefix of nil then skip else
                  Absolute=false
                  {PUSHPath {Decode Prefix}#false}
               end
               {FRAGMENT Suffix}
            [] &{ then
               case Prefix of nil then skip else
                  Absolute=false
                  {PUSHPath {Decode Prefix}#false}
               end
               {INFO Suffix}
            end
         end

         proc {AUTHORITY L}
            Prefix Suffix Sep
         in
            {Split L Charset_PATH Prefix Suffix Sep}
            {PUT authority {Map Prefix CharToLower}}
            case Sep
            of unit then skip
            [] &/  then Absolute=true {PATH Suffix}
            [] &\\ then Absolute=true {PATH Suffix}
            [] &?  then {QUERY    Suffix}
            [] &#  then {FRAGMENT Suffix}
            [] &{  then {INFO     Suffix}
            else raise urlbug end
            end
         end

         proc {PATH L}
            Prefix Suffix Sep Slash
         in
            {Split L Charset_PATH Prefix Suffix Sep}
            {PUSHPath {Decode Prefix}#Slash}
            case Sep
            of unit then Slash=false
            [] &/   then Slash=true  {PATH     Suffix}
            [] &\\  then Slash=true  {PATH     Suffix}
            [] &?   then Slash=false {QUERY    Suffix}
            [] &#   then Slash=false {FRAGMENT Suffix}
            [] &{   then Slash=false {INFO     Suffix}
            else raise urlbug end
            end
         end

         proc {QUERY L}
            Prefix Suffix Sep
         in
            {Split L Charset_QUERY Prefix Suffix Sep}
            {PUT query Prefix}
            case Sep
            of unit then skip
            [] &#   then {FRAGMENT Suffix}
            [] &{   then {INFO     Suffix}
            else raise urlbug end
            end
         end

         proc {FRAGMENT L}
            Prefix Suffix Sep
         in
            {Split L Charset_FRAGMENT Prefix Suffix Sep}
            {PUT fragment Prefix}
            case Sep of unit then skip else
               {INFO Suffix}
            end
         end

         proc {INFO L}
            case {Reverse L} of &}|L then
               {PUT info
                {List.toRecord info
                 {Map {String.tokens {Reverse L} &,} INFO_elt}}}
            else raise urlbad end end
         end

         fun {INFO_elt S}
            Prop Value
         in
            {String.token S &= Prop Value}
            {String.toAtom Prop}#{String.toAtom Value}
         end

         %% parse

         {START {VirtualString.toString LOC}}

         %% now normalize the results
         if {IsDet Absolute} then
            Path = {Dictionary.condGet Data path nil}
            Lab  = if Absolute then abs else rel end
         in
            %% -- path was accumulated in reverse order
            %% -- it also needs to be normalized with
            %% -- respect to `.' and `..'
            {Dictionary.put Data path
                Lab({NormalizePath {Reverse Path}})}
         end

         URLValue = {Dictionary.toRecord url Data}

      in
         if URLValue==url then url(unit) else URLValue end
      end
   end

   %% for truly normalizing a url, we need to `decode' the components
   %% of its path

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

   %% a path is represented by a sequence of COMP#SLASH where COMP is
   %% a string and SLASH is a boolean indicating whether it was
   %% followed by a slash.  Normalizing a path is the proce of
   %% eliminating occurrences of path components "." and ".." by
   %% interpreting them relative to the stack of path components.
   %% This algorithm is due to Christian.  I modified it to handle
   %% pairs COMP#SLASH and to not throw out a leading "." because
   %% ./foo and foo should be treated differently: the first one
   %% is really an absolute path, whereas the second one is relative.

   fun {NormalizePath Path}
      case Path
      of nil then nil
      [] H|T then
         if H.1=="."  then H|{NormalizeStack T nil}
         else {NormalizeStack Path nil} end
      end
   end

   fun {NormalizeStack Path Stack}
      case Path
      of nil then {Reverse Stack}
      [] H|T then C=H.1 in
         if     C=="."  then {NormalizeStack T Stack}
         elseif C==".." then
            case Stack of nil then
               H|{NormalizeStack T nil}
            [] _|Stack then {NormalizeStack T Stack} end
         else {NormalizeStack T H|Stack} end
      end
   end

   %% for producing really normalized url strings, we need to encode
   %% its components.  Encode performs the `escape encoding' of a
   %% string (e.g. a single path component).  It uses a bitString,
   %% supplied as an argument, to recognize the characters that don't
   %% need to be escape encoded.

   local
      D = x(0:&0 1:&1 2:&2 3:&3 4:&4 5:&5 6:&6 7:&7 8:&8 9:&9
            10:&a 11:&b 12:&c 13:&d 14:&e 15:&f)
   in
      fun {Encode L Charset}
         case L
         of nil then nil
         [] H|T then
            if {BitString.get Charset H} then H|{Encode T Charset}
            else
               X1 = H div 16
               X2 = H mod 16
            in
               &%|D.X1|D.X2|{Encode T Charset}
            end
         end
      end
   end

   %% Here is the charset for encoding path segments.  It contains all
   %% characters that don't need to be encoded.  BUGLET: ";" should
   %% not be in there in principle; however, I am currently not parsing
   %% parameters (note that there can be a parameter section for each
   %% path component) but instead I leave them with the path component.
   %% This means that it _must_ not be encoded.  The bug is that I
   %% cannot distinguish between a semi-colon that was previously
   %% encoded and one that actually delimited a parameter section.

   Comp_Charset =
   {BitString.make 256
    ";abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.!~*'():@&=+$,"}

   %% CompToVS converts a parsed path component to a virtual string.
   %% Slash indicates whether or not the path component should be
   %% suffixed with a slash.  The string itself must be escape encoded
   %% to produce a conforming url.  The result is prepended to the
   %% Rest of the converted path.

   fun {CompToVS Seg Rest}
      case Seg of Comp#Slash then
         {Encode Comp Comp_Charset}
         # if Slash then '/' else nil end # Rest
      else raise urlbug end end
   end

   %% URL_VS converts a url to a virtual string.  The second
   %% argument is a record with optional boolean features `full' and
   %% `cache'.  `full:true' indicates that a string with full
   %% information is desired: including #FRAGMENT and {INFO} sections.
   %% The #FRAGMENT indicator is intended for client-side usage.
   %% Similarly, but even more so, for the experimental {INFO}
   %% section.  Thus, neither should be included when constructing a
   %% url string for retrieval. `cache:true' indicates that a syntax
   %% appropriate for cache look up is desired: the `:' after the
   %% scheme and the `//' before the authority are both replaced by
   %% single `/'.

   fun {URL_VS Url How}
      U         = {URL_make Url}
      Full      = {CondSelect How full  false}
      Cache     = {CondSelect How cache false}
      ScheSep   = if Cache then '/' else ':'  end
      AuthSep   = if Cache then nil else '//' end
      Scheme    = {CondSelect U scheme    unit}
      Device    = {CondSelect U device    unit}
      Authority = {CondSelect U authority unit}
      Path      = {CondSelect U path      unit}
      Query     = {CondSelect U query     unit}
      Fragment  = {CondSelect U fragment  unit}
      Info      = {CondSelect U info      unit}
   in
      case Scheme    of unit then nil else Scheme #ScheSep   end #
      case Device    of unit then nil else Device #':'       end #
      case Authority of unit then nil else AuthSep#Authority end #
      case Path      of unit then nil else
         case {Label Path} of abs then '/' else nil end          #
         {List.foldR Path.1 CompToVS nil}
      end                                                        #
      case Query     of unit then nil else '?'#Query      end    #
      if Full then
         case Fragment of unit then nil else "#"#Fragment end    #
         case Info     of unit then nil else
            '{'#{FoldR {Record.toListInd Info} InfoPropToVS nil}#'}'
         end
      else nil end
   end

   fun {InfoPropToVS P#V Rest} P#'='#V#Rest end

   fun {URL_toVS         U} {URL_VS U true } end
   fun {URL_toString     U} {VirtualString.toString {URL_VS U true }} end
   fun {URL_toAtom       U} {VirtualString.toAtom   {URL_VS U true }} end

   %% resolving a relative url with respect to a base url

   fun {URL_resolve BASE REL}
      Base = {URL_make BASE}
      Rel  = {URL_make REL}
   in
      if {CondSelect Rel scheme unit}\=unit then Rel % already absolute
      else
         Fields = {Record.toDictionary Rel}
      in
         try
            Scheme = {CondSelect Base scheme unit}
            case Scheme of unit then skip else
               {Dictionary.put Fields scheme Scheme}
            end
            if {Dictionary.condGet Fields authority unit}\=unit
            then raise done end end
            Authority = {CondSelect Base authority unit}
            case Authority of unit then skip else
               {Dictionary.put Fields authority Authority}
            end
            if {Dictionary.condGet Fields device unit}\=unit
            then raise done end end
            Device = {CondSelect Base device unit}
            case Device of unit then skip else
               {Dictionary.put Fields device Device}
            end
            Path = {CondSelect Base path unit}
            if Path==unit then raise done end else
               Lab   = {Label Path}
               RPath = {Dictionary.condGet Fields path unit}
            in
               case RPath
               of unit then
                  {Dictionary.put Fields path
                   Lab({AtLast Path.1 [nil#false]})}
               [] rel(L) then
                  {Dictionary.put Fields path
                   Lab({NormalizePath
                        {AtLast Path.1
                         case L of nil then [nil#false] else L end}})}
               else skip end
            end
         in skip catch done then skip end
         {Dictionary.toRecord url Fields}
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

   fun {URL_isAbsolute Url}
      U = {URL_make Url}
   in
      {HasFeature U scheme} orelse
      {HasFeature U device} orelse
      case {CondSelect U path unit}
      of abs(_) then true
      [] rel(L) then
         case L of H|T then
            case H.1
            of &~|_ then true
            [] "."  then true
            [] ".." then true
            else false end
         else false end
      else false end
   end

   fun {URL_isRelative Url}
      {Not {URL_isAbsolute Url}}
   end

   %% turn a url into one that can safely be used as a base without
   %% loosing its last component

   fun {URL_toBase Url}
      U = {URL_make Url}
      Path = {CondSelect U path unit}
   in
      if Path==unit orelse Path.1==nil then U else
         case {List.last Path.1} of nil#false then U
         elseof _#true then L = {Label Path} in
            %% should not happen, but let's be robust
            {AdjoinAt U path L({Append Path.1 [nil#false]})}
         elseof C#false then L = {Label Path} in
            %% C must now be followed by a slash and an empty component
            {AdjoinAt U path L({AtLast Path.1 [C#true nil#false]})}
         else raise urlbug end end
      end
   end

in
   functor
   export
      is                : URL_is
      make              : URL_make
      toVs              : URL_toVS
      toVsExtended      : URL_VS
      toString          : URL_toString
      toAtom            : URL_toAtom
      resolve           : URL_resolve
      normalizePath     : NormalizePath
      isAbsolute        : URL_isAbsolute
      isRelative        : URL_isRelative
      toBase            : URL_toBase
   define
      skip
   end
end
