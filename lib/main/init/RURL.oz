%%%
%%% Author:
%%%   Christian Schulte <schulte@dfki.de>
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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   local
      Here = "."
      Up   = ".."

      fun {Normalize Cs RCs}
         case Cs of nil then {Reverse RCs}
         [] C|Cr then
            case C==Here then {Normalize Cr RCs}
            elsecase C==Up then
               case RCs==nil then Up|{Normalize Cr nil}
               else {Normalize Cr RCs.2}
               end
            else {Normalize Cr C|RCs}
            end
         end
      end
   in
      fun {NormalizePath Cs}
         {Normalize Cs nil}
      end
   end

   local
      fun {StripLast X|Xs ?Y}
         case Xs of nil then Y=X nil
         [] _|Xr then X|{StripLast Xs ?Y}
         end
      end
   in
      fun {PathResolve Base Embed}
         %% Mode of Embed must be rel and both pathes must be normalized!
         M  = {Label Base}
         BP = Base.1
         EP = Embed.1
      in
         M({NormalizePath
            case BP==nil then EP
            else
               {Append {StripLast BP _} case EP==nil then [nil] else EP end}
            end})
      end
   end

   local

      local
         fun {Split Is Js}
            case Is of nil then Js=nil
            [] I|Ir then
               case I==&/ then NewJs in Js=nil NewJs|{Split Ir NewJs}
               else Jr in Js=I|Jr {Split Ir Jr}
               end
            end
         end
      in
         fun {SplitPath S}
            Js in Js|{Split S Js}
         end
      end

   in
      fun {StringToUrl UrlS}
         try
            %% Parsing according to RFC 1808
            case UrlS=="" then
               url
            else
               %% <scheme>://<net>/<path>;<params>?<query>#<fragment>
               %% 1. Fragment
               R1
               Fragment  = case {Member &# UrlS} then
                              o(fragment:{String.token UrlS &# ?R1 $})
                           else R1=UrlS o
                           end
               %% 2. Scheme
               R2
               Scheme    = case R1\=nil andthen {Member &: R1.2} then
                              o(scheme:{Map {String.token R1 &: $ ?R2}
                                        Char.toLower})
                           else R2=R1 o
                           end
               %% 3. Net location
               R3
               Netloc    = case {List.isPrefix "//" R2} then S=R2.2.2 in
                              case {Member &/ S} then R in
                                 R3=&/|R
                                 o(netloc:{Map {String.token S &/ $ ?R}
                                           Char.toLower})
                              else R3=nil o(netloc:{Map S Char.toLower})
                              end
                           else R3=R2 o
                           end
               %% 4. Query information
               R4
               Query     = case {Member &? R3} then
                              o(query: {String.token R3 &? ?R4 $})
                           else R4=R3 o
                           end
               %% 5. Parameters
               R5
               Parameter = case {Member &; R4} then
                              o(parameter:{String.token R4 &; ?R5 $})
                           else R5=R4 o
                           end

               Path      = case R5 of nil then o
                           [] H|R then
                              o(path: case H==&/ then
                                         abs({NormalizePath {SplitPath R}})
                                      else
                                         rel({NormalizePath {SplitPath R5}})
                                      end)
                           end
            in
               {Record.foldR Scheme#Fragment#Netloc#Query#Parameter#Path
                Adjoin url}
            end
         catch _ then
            raise illegalUrl(UrlS) end
         end
      end
   end

   fun {UrlIsAbs Url}
      {HasFeature Url scheme} orelse
      ({HasFeature Url path} andthen {Label Url.path}==abs)
   end

   local
      proc {Copy As R1 R2}
         case As of nil then skip
         [] A|Ar then R1.A=R2.A {Copy Ar R1 R2}
         end
      end

      proc {Project R1 As ?R2}
         Fs={Filter As fun {$ A}
                          {HasFeature R1 A}
                       end}
      in
         R2={MakeRecord {Label R1} Fs}
         {Copy Fs R1 R2}
      end
   in
      fun {UrlResolve Base Embed}
         case Base==url then Embed
         elsecase Embed==url then Base
         elsecase {HasFeature Embed scheme} then Embed
         else
            %% Inherit [scheme]
            case {HasFeature Embed netloc} then
               {Adjoin Embed {Project Base [scheme]}}
               %% Inherit [scheme netloc]
            elsecase {HasFeature Embed path} then
               case {Label Embed.path}==abs then
                  {Adjoin Embed {Project Base [scheme netloc]}}
               else
                  {AdjoinAt
                   {Adjoin Embed {Project Base [scheme netloc]}}
                   path {PathResolve
                         {CondSelect Base path abs(nil)}
                         Embed.path}}
               end
            else
               %% Inherit [parameter query], query only if no parameter
               {Adjoin
                {Project Base
                 scheme|netloc|path|parameter|
                 case {HasFeature Embed parameter} then nil else [query] end}
                Embed}
            end
         end
      end
   end

   fun {UrlToVs Url}
      %% <scheme>://<net>/<path>;<params>?<query>#<fragment>
      case {HasFeature Url scheme} then Url.scheme#'://' else '' end #
      {CondSelect Url netloc ''} #
      case {HasFeature Url path} then P=Url.path in
         case {Label P}==abs then '/' else '' end #
         case P.1==nil then '' else
            {FoldL P.1.2 fun {$ P C} P#'/'#C end P.1.1}
         end
      else ''
      end #
      case {HasFeature Url parameter} then ';'#Url.parameter else '' end #
      case {HasFeature Url query}     then '?'#Url.query     else '' end #
      case {HasFeature Url fragment}  then "#"#Url.fragment  else '' end
   end

in

   RURL = rurl(vsToUrl:  fun {$ V}
                            {StringToUrl {VirtualString.toString V}}
                         end
               isAbsUrl: UrlIsAbs
               resolve:  UrlResolve
               urlToVs:  UrlToVs
               urlToKey: fun {$ U}
                            {VirtualString.toAtom {UrlToVs U}}
                         end)

end

/*

declare U1={RURL.vsToUrl "http://www.ps.uni-sb.de/mozart/../gaga/./"}
{Browse U1#{RURL.urlToKey U1}}

declare U2={RURL.vsToUrl "//gaga/mozart"}
{Browse U2#{RURL.urlToKey U2}}

declare U3={RURL.vsToUrl "file://mozart"}
{Browse U3}
{Browse U3#{RURL.urlToKey U3}}

declare U3={RURL.vsToUrl "../mozart/"}
{Browse U3}
{Browse U3#{RURL.urlToKey U3}}

{Save a '/home/schulte/gaga.ozc'}
{Load 'file:///home/schulte/gaga.ozc'}

{Browse {RURL.urlToKey {RURL.resolve U1 U3}}}

% Testexamples from RFC

{Browse {RURL.vsToUrl "g"}}

declare B = {RURL.vsToUrl "http://a/b/c/d;p?q#f"}
{Browse B}
{ForAll ["g"#"http://a/b/c/g"
         "./g"#"http://a/b/c/g"
         "g/"#"http://a/b/c/g/"
         "/g"#"http://a/g"
         "//g"#"http://g"
         "?y"#"http://a/b/c/d;p?y"
         "g?y"#"http://a/b/c/g?y"
         "g?y/./x"#"http://a/b/c/g?y/./x"
         "#s"#"http://a/b/c/d;p?q#s"
         "g#s"#"http://a/b/c/g#s"
         "g#s/./x"#"http://a/b/c/g#s/./x"
         "g?y#s"#"http://a/b/c/g?y#s"
         ";x"#"http://a/b/c/d;x"
         "g;x"#"http://a/b/c/g;x"
         "g;x?y#s"#"http://a/b/c/g;x?y#s"
         "."#"http://a/b/c/"
         "./"#"http://a/b/c/"
         ".."#"http://a/b/"
         "../"#"http://a/b/"
         "../g"#"http://a/b/g"
         "../.."#"http://a/"
         "../../"#"http://a/"
         "../../g"#"http://a/g"]
 proc {$ E#R}
    U1={RURL.vsToUrl E}
    U2={RURL.resolve B U1}
 in
    case {RURL.urlToKey U2}=={String.toAtom R} then skip else
       {Browse U1#B#U2#{RURL.urlToKey U2}#{String.toAtom R}}
    end
 end}

{Browse a}

{ForAll [""#"http://a/b/c/d;p?q#f"
         "../../../g"#"http://a/../g"
         "../../../../g"#"http://a/../../g"
%        "/./g"#"http://a/./g"
%        "/../g"#"http://a/../g"
         "g."#"http://a/b/c/g."
         ".g"#"http://a/b/c/.g"
         "g.."#"http://a/b/c/g.."
         "..g"#"http://a/b/c/..g"
         "./../g"#"http://a/b/g"
         "./g/."#"http://a/b/c/g/"
         "g/./h"#"http://a/b/g/h"
         "g/../h"#"http://a/b/c/h"]
 proc {$ E#R}
    U1={RURL.vsToUrl E}
    U2={RURL.resolve B U1}
 in
    case {RURL.urlToKey U2}=={String.toAtom R} then skip else
       {Browse U1#U2#{RURL.urlToKey U2}#{String.toAtom R}}
    end
 end}

*/
