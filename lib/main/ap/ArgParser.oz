%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
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

   %%
   %% Some closure avoidance accesses, to keep Denys happy
   %%
   CharToLower   = Char.toLower
   CharIsUpper   = Char.isUpper
   CharIsLower   = Char.isLower

   AtomToString  = Atom.toString

   StringIsInt   = String.isInt
   StringToAtom  = String.toAtom
   StringToInt   = String.toInt
   StringToFloat = String.toFloat
   StringToken   = String.token
   StringTokens  = String.tokens

   %%
   %% Access to Serlvet parameters following CGI spec
   %%
   fun {MakeGetServletArgs Open OS}
      GetEnv        = OS.getEnv

      class StdIn from Open.file
         prop final
         meth init
            StdIn,dOpen(0 1)
         end
         meth get(N ?Is)
            Ir M=StdIn,read(list:?Is tail:?Ir size:N len:$)
         in
            Ir = case M<N then StdIn,get(N-M $) else nil end
         end
      end

      fun {CgiRawGet}
         case {StringToAtom {GetEnv 'REQUEST_METHOD'}}
         of 'GET'  then {GetEnv 'QUERY_STRING'}
         [] 'POST' then F in
            try
               F={New StdIn init}
               {F get({StringToInt {GetEnv 'CONTENT_LENGTH'}} $)}
            finally
               {F close}
            end
         end
      end
   in
      fun {$}
         {Map {StringTokens {CgiRawGet} &&}
          fun {$ S}
             S1 S2 in {StringToken S &= ?S1 ?S2} S1#S2
          end}
      end
   end


   %%
   %% Access to commandline arguments
   %%
   fun {GetCmdArgs}
      {Map {{`Builtin` 'GetProperty' 2} argv} AtomToString}
   end


   %%
   %% Preprocessing of CGI or Applet arguments
   %%
   local
      fun {HexToInt D}
         case {CharIsUpper D} then D-&A+10
         elsecase {CharIsLower D} then D-&a+10
         else D-&0
         end
      end

      fun {Unquote Is}
         case Is of nil then nil
         [] I|Ir then
            case I
            of &% then
               case Ir of D1|I1r then
                  case I1r of D2|I2r then
                     {HexToInt D1}*16+{HexToInt D2}|{Unquote I2r}
                  else Ir
                  end
               else Ir
               end
            [] &+ then & |{Unquote Ir}
            else I|{Unquote Ir}
            end
         end
      end

   in
      fun {WebPreProc SSs}
         %% Takes a list of pairs of strings
         case SSs of nil then nil
         [] SS|SSr then S1#S2=SS in
            ({StringToAtom {Unquote S1}}#{Unquote S2})|{WebPreProc SSr}
         end
      end
   end

   %%
   %% Preprocessing of commandlines
   %%

   local
      fun {IsOption Is ?Ir}
         case Is of I1|I1r then
            case I1==&- then
               case I1r of I2|I2r then
                  case I2==&- then
                     case I2r==nil then false else Ir=I2r true end
                  else Ir=I1r true
                  end
               else false
               end
            else false
            end
         else false
         end
      end
   in
      fun {CmdPreProc Ss ?RSs}
         %% RSs is a list of string that are unprocessed
         case Ss of nil then
            RSs=nil nil
         [] S|Sr then SO in
            case {IsOption S ?SO} then S1 S2 in
               {StringToken SO &= S1 S2}
               {StringToAtom S1}#S2|{CmdPreProc Sr RSs}
            else
               RSs=Ss nil
            end
         end
      end
   end


   %%
   %% Normalization of argument specifications
   %%

   local
      proc {Normalize AS D}
         S = {Map {AtomToString {Label AS}} CharToLower}
         A = {StringToAtom S}
         N = case {IsAtom AS} then
                A(type:bool optional:false default:false)
             else
                TA={Adjoin
                    {Adjoin o(type:bool optional:false) AS} A}
             in
                {Adjoin o(default:case TA.type
                                  of float  then 0.0
                                  [] int    then 0
                                  [] string then ""
                                  [] atom   then ''
                                  [] bool   then false
                                  else
                                     {`RaiseError` argParser(type(TA.type))} _
                                  end) TA}
             end
      in
         case N.type of bool then
            NoA={StringToAtom &n|&o|S}
         in
            {Dictionary.put D A   {Adjoin N A(real:A   value:true)}}
            {Dictionary.put D NoA {Adjoin N NoA(real:A value:false)}}
         else
            {Dictionary.put D A
             {Adjoin case N.optional then o(real:A value:N.default)
                     else o(real:A)
                     end N}}
         end
      end
   in
      fun {NormArgSpec DefSpec ArgSpec}
         D={Dictionary.new}
      in
         {Record.forAll DefSpec proc {$ AS}
                                   {Normalize AS D}
                                end}
         {Record.forAll ArgSpec proc {$ AS}
                                   {Normalize AS D}
                                end}
         {Dictionary.toRecord m D}
      end
   end


   local
      fun {TidyMinus Is}
         case Is of nil then nil
         [] I|Ir then case I of &- then &~ else I end|{TidyMinus Ir}
         end
      end

      fun {ExtractValue S O}
         try
            case S of nil then O.value
            elsecase O.type
            of float  then TS={TidyMinus S} in
               case {StringIsInt TS} then {IntToFloat {StringToInt TS}}
               else {StringToFloat TS}
               end
            [] int    then {StringToInt {TidyMinus S}}
            [] atom   then {StringToAtom S}
            [] string then S
            end
         catch _ then
            {`RaiseError` argParser(value(O.real S))} _
         end
      end

   in
      fun {EnterValues ASs OS D}
         case ASs of nil then nil
         [] AS|ASr then A#S=AS in
            case {HasFeature OS A} then OSA=OS.A in
               {Dictionary.put D OSA.real
                {ExtractValue S OSA}|{Dictionary.get D OSA.real}}
               {EnterValues ASr OS D}
            else AS|{EnterValues ASr OS D}
            end
         end
      end
   end

   local
      fun {LowerLabel R}
         {StringToAtom {Map {AtomToString {Label R}} CharToLower}}
      end

      proc {MakeDefaultDict Args FAS ?D}
         D = {Dictionary.new}
         {ForAll Args proc {$ A}
                         {Dictionary.put D A [FAS.A.default]}
                      end}
      end
   in
      fun {GetPostProc DefSpec ArgSpec}
         FAS  = {NormArgSpec DefSpec ArgSpec}
         Args = {Record.foldL ArgSpec fun {$ As S}
                                         {LowerLabel S}|As
                                      end
                 {Record.foldL DefSpec fun {$ As S}
                                          {Label S}|As
                                       end nil}}
      in
         case {Label ArgSpec}
         of list then
            fun {$ OVs Rs}
               args(OVs Rs)
            end
         [] single then
            fun {$ OVs Rs}
               D    = {MakeDefaultDict Args FAS}
               ROVs = {EnterValues OVs FAS D}
            in
               {ForAll {Dictionary.keys D}
                proc {$ K}
                   {Dictionary.put D K {Dictionary.get D K}.1}
                end}
               {Dictionary.put D 1 ROVs}
               {Dictionary.put D 2 Rs}
               {Dictionary.toRecord args D}
            end
         [] multiple then
            fun {$ OVs Rs}
               D    = {MakeDefaultDict Args FAS}
               ROVs = {EnterValues OVs FAS D}
            in
               {Dictionary.put D 1 ROVs}
               {Dictionary.put D 2 Rs}
               {Dictionary.toRecord args D}
            end
         end
      end
   end

in

   Parser = parser(cmd:     fun {$ ArgSpec}
                               case ArgSpec==plain then
                                  GetCmdArgs
                               else
                                  PostProc = {GetPostProc plain ArgSpec}
                               in
                                  fun {$}
                                     OVs Rs
                                  in
                                     {CmdPreProc {GetCmdArgs} ?Rs ?OVs}
                                     {PostProc OVs Rs}
                                  end
                               end
                            end
                   applet:  fun {$ ArgSpec}
                               PostProc = {GetPostProc
                                           plain(width(type:     int
                                                       optional: false
                                                       default:  ~1)
                                                 height(type:     int
                                                        optional: false
                                                        default:  ~1)
                                                 title(type:      string
                                                       optional:  false
                                                       default:   "Oz Applet"))
                                           ArgSpec}
                            in
                               fun {$}
                                  OVs Rs
                               in
                                  {CmdPreProc {GetCmdArgs} ?Rs ?OVs}
                                  {PostProc OVs Rs}
                               end
                            end
                   servlet: fun {$ ArgSpec}
                               PostProc = {GetPostProc plain ArgSpec}
                            in
                               fun {$ Open OS}
                                  GetArgs = {MakeGetServletArgs Open OS}
                               in
                                  {PostProc {WebPreProc {GetArgs}} nil}
                               end
                            end)

end
