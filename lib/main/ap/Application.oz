%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%   Christian Schulte, 1998
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

%%
%% Specification Format:
%%
%%    Spec ::= plain
%%          |  list([mode: Mode] Option ... Option)
%%          |  record([mode: Mode] Option ... Option)
%%    Mode ::= start | anywhere   % default: anywhere
%%    Option ::= LongOpt(['char': Char] [type: Type]
%%                       [1: Occ] [default: value] [optional: bool])
%%            |  LongOpt(['char': Char] alias: Alias)
%%    LongOpt ::= atom
%%    Occ ::= single | multiple | leftmost | rightmost
%%         |  accumulate(procedure/2)
%%    Type ::= 'bool'
%%          |  PrimType
%%          |  list(PrimType)
%%    PrimType ::= 'int'([min: int] [max: int])
%%              |  'float'([min: float] [max: float])
%%              |  'atom'([atom ... atom])
%%              |  'string'
%%              |  procedure   % transformation procedure {P +S X}
%%    Char ::= char | [char]
%%    Alias ::= LongOpt   % specs copied from LongOpt's spec
%%           |  LongOpt#value | [LongOpt#value]
%%
%% Parsing of CGI arguments:
%%
%% A boolean option `opt' may be given as `opt=yes' or `opt=no'.
%% Option names may be abbreviated, as long as they match a single
%% Option.  The `mode' and `char' specifications are ignored.
%%
%% Parsing of Command Lines:
%%
%% A boolean option `opt' may be given as `--opt' (meaning `true') or
%% `--noopt' (meaning `false').  Option names (LongOpt) may be abbreviated,
%% as long as they match a single Option.  Single-character options may be
%% combined.  The argument to a single-character option may be attached to
%% the option character.  A single hyphen `-' is returned in the RestArgs.
%% Parsing stops at a double hyphen `--' not followed by an option name;
%% the double hyphen does not appear in the RestArgs.
%%
%% General Information:
%%
%% If the input does not conform to the specification, an error exception
%% of the form `ap(usage VS)' is raised (VS being a virtual string describing
%% the error).
%%
%% When using `list', the `Occ', `default' and `optional' specifications
%% are ignored.  An OptionList are returned:
%%
%%    OptionList ::= [ArgOrOption]
%%    ArgOrOption ::= string   % unparsed argument
%%                 |  LongOpt#value   % parsed option
%%
%% When using `record', an option record OptRec is returned.  If Occ
%% is given, the option will appear in the option record, else in the
%% OptionList, which is stored under feature 1 of the option record.
%% If the `optional' feature is not given, options are optional.
%% Optional options only appear in the option record if they were
%% actually given on the command line.  If a default is given, the
%% option will always appear in the option record.
%%
%%    OptRec ::= optRec(1: OptionList
%%                      LongOpt: value ... LongOpt: value)
%%

functor
import
   BootApplication(exit: Exit) at 'x-oz://boot/Application'
   OS(getEnv)
   Open(file)
   Property(get condGet)
   Gui(getGuiCmdArgs:GetGuiArgs) at 'x-oz://contrib/ap/OptionSheet.ozf'
export
   Exit
   GetCgiArgs
   GetCmdArgs
   GetGuiArgs
   GetArgs
   PostProcess
prepare
   %%
   %% Closure avoidance access
   %%

   AtomToString  = Atom.toString

   %%
   %% Preprocessing of CGI arguments
   %%

   local
      fun {HexToInt D}
         if {Char.isUpper D} then D-&A+10
         elseif {Char.isLower D} then D-&a+10
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
      fun {CgiPreProcessArgs SSs}
         %% Takes a list of pairs of strings
         case SSs of nil then nil
         [] SS|SSr then S1#S2=SS in
            {Unquote S1}#{Unquote S2}|{CgiPreProcessArgs SSr}
         end
      end
   end

   %%
   %% Preprocessing the Specification
   %%
   %% The results are of the following formats:
   %%
   %%    CgiSpecs ::= [LongOpt'#CgiOption]   % sorted list
   %%    LongOpt' ::= string
   %%    CgiOption ::= LongOpt(type: Type)
   %%
   %%    LongOptSpecs ::= [LongOpt'#CmdOption]   % sorted list
   %%    CharSpecRec ::= charSpecRec(char: CmdOption ... char: CmdOption)
   %%    CmdOption ::= LongOpt(type: CmdType)
   %%               |  LongOpt(alias: Alias')
   %%    CmdType ::= PrimType
   %%             |  list(PrimType)
   %%    Alias' ::= LongOpt#value | [LongOpt#value]
   %%
   %%    OptRecSpec ::= optRecSpec(LongOpt: OneOptRecSpec ...)
   %%    OneOptRecSpec ::= x(occ: Occ' default: Default)
   %%                   |  x(occ: Occ' required: bool)
   %%    Occ' ::= Occ | multilist
   %%

   local
      proc {AddOpt Option Chars Os Or Ls Lr}
         Os = {Label Option}#Option|Or
         Ls = case Chars of nil then Lr
              [] _|_ then
                 {FoldR Chars fun {$ C In} C#Option|In end Lr}
              [] Char then
                 Char#Option|Lr
              end
      end

      proc {BuildMaps Spec I IsCgi ?LongOptSpecs ?CharSpecs}
         case {CondSelect Spec I unit} of unit then
            LongOptSpecs = nil
            CharSpecs = nil
         [] Option then LongOpt Chars Lr Cr in
            LongOpt = {Label Option}
            Chars = {CondSelect Option char nil}
            case {CondSelect Option alias unit} of unit then
               if IsCgi then
                  case {CondSelect Option type unit} of unit then
                     {AddOpt LongOpt(type: bool)
                      Chars LongOptSpecs Lr CharSpecs Cr}
                  [] Type then
                     {AddOpt LongOpt(type: Type)
                      Chars LongOptSpecs Lr CharSpecs Cr}
                  end
               else
                  case {CondSelect Option type unit} of unit then
                     {AddOpt LongOpt(alias: LongOpt#true)
                      Chars LongOptSpecs Lr CharSpecs Cr}
                  [] bool then Li Ci NoLongOpt in
                     {AddOpt LongOpt(alias: LongOpt#true)
                      Chars LongOptSpecs Li CharSpecs Ci}
                     NoLongOpt = {String.toAtom
                                  &n|&o|{AtomToString {Label Option}}}
                     {AddOpt NoLongOpt(alias: LongOpt#false) nil Li Lr Ci Cr}
                  [] Type then
                     {AddOpt LongOpt(type: Type)
                      Chars LongOptSpecs Lr CharSpecs Cr}
                  end
               end
            [] A then
               {AddOpt LongOpt(alias: A)
                Chars LongOptSpecs Lr CharSpecs Cr}
            end
            {BuildMaps Spec I + 1 IsCgi ?Lr ?Cr}
         end
      end

      fun {DerefAliases Specs SpecRec}
         case Specs of Spec|Specr then LongOpt in
            LongOpt = {CondSelect Spec.2 alias unit}
            if {IsAtom LongOpt} then Spec.1#SpecRec.LongOpt else Spec end|
            {DerefAliases Specr SpecRec}
         [] nil then nil
         end
      end
   in
      fun {CgiPreProcess Spec}
         {Record.foldRInd
          {List.toRecord cgiSpecRec {BuildMaps Spec 1 true $ _}}
          fun {$ LongOpt Spec In}
             {Atom.toString LongOpt}#Spec|In
          end nil}
      end

      proc {CmdPreProcess Spec ?LongOptSpecs ?CharSpecRec}
         LongOptSpecs0 CharSpecs SpecRec
      in
         {BuildMaps Spec 1 false ?LongOptSpecs0 ?CharSpecs}
         SpecRec = {List.toRecord specRec LongOptSpecs0}
         LongOptSpecs = {Record.foldRInd SpecRec
                         fun {$ LongOpt Spec In}
                            {Atom.toString LongOpt}#Spec|In
                         end nil}
         CharSpecRec = {List.toRecord charSpecRec
                        {DerefAliases CharSpecs SpecRec}}
      end
   end

   local
      fun {GetOptRecSpecSub Spec I}
         case {CondSelect Spec I unit} of unit then nil
         [] OneSpec then
            case {CondSelect OneSpec 1 unit} of unit then
               {GetOptRecSpecSub Spec I + 1}
            [] Occ0 then Occ X in
               Occ = case Occ0 of multiple then
                        case OneSpec.type of list(_) then multilist
                        [] list(_)#_ then multilist
                        else multiple
                        end
                     else Occ0
                     end
               X = if {HasFeature OneSpec validate} then
                      if {HasFeature OneSpec default} then
                         x(occ      : Occ
                           validate : OneSpec.validate
                           default  : OneSpec.default)
                      else
                         x(occ      : Occ
                           validate : OneSpec.validate)
                      end
                   elseif {HasFeature OneSpec default} then
                      x(occ         : Occ
                        default     : OneSpec.default)
                   else
                      x(occ         : Occ
                        required    : {Not {CondSelect OneSpec optional true}})
                   end
               {Label OneSpec}#X|{GetOptRecSpecSub Spec I + 1}
            end
         end
      end
   in
      fun {GetOptRecSpec Spec}
         {List.toRecord optRecSpec {GetOptRecSpecSub Spec 1}}
      end
   end

   %%
   %% Parse the Arguments into an OptionList
   %%
   %% CgiParse, used for CGI:
   %%    Takes a list of pairs atom#string
   %% CmdParse, used for command lines:
   %%    Takes a list of strings
   %%

   local
      fun {SignConvert S}
         case S of C|Cr then
            case C of &- then &~ else C end|{SignConvert Cr}
         [] nil then nil
         end
      end

      proc {MinMax Value Type LongOpt}
         case {CondSelect Type min unit} of unit then skip
         [] X then
            if Value < X then
               {Exception.raiseError
                ap(usage 'argument to option `'#LongOpt#'\' out of range')}
            end
         end
         case {CondSelect Type max unit} of unit then skip
         [] X then
            if Value > X then
               {Exception.raiseError
                ap(usage 'argument to option `'#LongOpt#'\' out of range')}
            end
         end
      end

      proc {CheckTokens Type I Value LongOpt}
         case {CondSelect Type I unit} of unit then
            {Exception.raiseError
             ap(usage 'illegal argument to option `'#LongOpt#'\'')}
         [] T then
            if Value == T then skip
            else {CheckTokens Type I + 1 Value LongOpt}
            end
         end
      end

      proc {StringToArgPrimType Arg LongOpt Type ?Value}
         if {IsProcedure Type} then
            Value = {Type Arg}
         else
            case {Label Type} of int then S = {SignConvert Arg} in
               if {String.isInt S} then
                  Value = {String.toInt S}
               else
                  {Exception.raiseError
                   ap(usage
                      'option `'#LongOpt#'\' expects an integer argument')}
               end
               {MinMax Value Type LongOpt}
            [] float then S = {SignConvert Arg} in
               if {String.isFloat S} then
                  Value = {String.toFloat S}
               else
                  {Exception.raiseError
                   ap(usage 'option `'#LongOpt#'\' expects a float argument')}
               end
               {MinMax Value Type LongOpt}
            [] atom then
               Value = {String.toAtom Arg}
               if {IsLiteral Type} then skip
               else {CheckTokens Type 1 Value LongOpt}
               end
            [] string then
               Value = Arg
            [] bool then   % (only used for CGI)
               case Arg of "yes" then
                  Value = true
               [] "no" then
                  Value = false
               else
                  {Exception.raiseError
                   ap(usage
                      'option `'#LongOpt#'\' expects a boolean argument')}
               end
            end
         end
      end

      proc {StringToArgType Arg LongOpt Type ?Value}
         case Type of list(PrimType) then
            Value = {Map {String.tokens Arg &,}
                     fun {$ S}
                        {StringToArgPrimType S LongOpt PrimType}
                     end}
         else
            {StringToArgPrimType Arg LongOpt Type ?Value}
         end
      end

      proc {ParseOptArg Spec Args ?Opt ?Rest}
         case {CondSelect Spec alias unit} of unit then
            case Args of Arg1|Argr then
               Opt = {Label Spec}#{StringToArgType Arg1 {Label Spec} Spec.type}
               Rest = Argr
            [] nil then
               {Exception.raiseError
                ap(usage 'option `'#{Label Spec}#'\' expects an argument')}
            end
         [] A then
            Opt = A
            Rest = Args
         end
      end

      fun {CondAppend Opt Rest}
         case Opt of _|_ then {Append Opt Rest}
         [] _#_ then Opt|Rest
         end
      end
   in
      fun {CgiParse Args Spec}
         CgiSpecs

         proc {GetOptSpec LongOpt ?Spec} Rest in
            Rest = {List.dropWhile CgiSpecs
                    fun {$ ThisLongOpt#_}
                       {Not {List.isPrefix LongOpt ThisLongOpt}}
                    end}
            case Rest of S|Sr then
               case Sr of S2|_ then
                  if {List.isPrefix LongOpt S2.1} andthen LongOpt \= S.1 then
                     {Exception.raiseError
                      ap(usage 'ambiguous option prefix `'#LongOpt#'\'')}
                  end
               [] nil then skip
               end
               Spec = S.2
            [] nil then
               {Exception.raiseError
                ap(usage 'unknown option `'#LongOpt#'\'')}
            end
         end
      in
         CgiSpecs = {CgiPreProcess Spec}
         {Map Args
          fun {$ LongOpt#Arg}
             Spec = {GetOptSpec LongOpt}
          in
             {Label Spec}#{StringToArgPrimType Arg LongOpt Spec.type}
          end}
      end

      fun {CmdParse Argv Spec}
         Mode LongOptSpecs CharSpecRec

         fun {GetOptSpec OptChar}
            case {CondSelect CharSpecRec OptChar unit} of unit then
               {Exception.raiseError
                ap(usage 'unknown option character `'#[OptChar]#'\'')} unit
            [] Spec then Spec
            end
         end

         proc {ParseOpt OptChar Arg1r Args ?Opt ?Rest} Spec in
            Spec = {GetOptSpec OptChar}
            case Arg1r of nil then
               {ParseOptArg Spec Args ?Opt ?Rest}
            else
               case {CondSelect Spec alias unit} of unit then
                  {ParseOptArg Spec Arg1r|Args ?Opt ?Rest}
               [] A then
                  Opt = A
                  Rest = (&-|Arg1r)|Args
               end
            end
         end

         proc {GetLongOptSpec Arg ?Spec ?Value} LongOpt ArgRest Rest in
            LongOpt = {List.takeDropWhile Arg fun {$ C} C \= &= end $ ?ArgRest}
            Rest = {List.dropWhile LongOptSpecs
                    fun {$ ThisLongOpt#_}
                       {Not {List.isPrefix LongOpt ThisLongOpt}}
                    end}
            case Rest of S|Sr then
               case Sr of S2|_ then
                  if {List.isPrefix LongOpt S2.1} andthen LongOpt \= S.1 then
                     {Exception.raiseError
                      ap(usage 'ambiguous option prefix `'#LongOpt#'\'')}
                  end
               [] nil then skip
               end
               Spec = S.2
               Value = case ArgRest of &=|S then S
                       [] nil then unit
                       end
            [] nil then
               {Exception.raiseError ap(usage 'unknown option `'#LongOpt#'\'')}
            end
         end

         proc {ParseLongOpt LongOpt Args ?Opt ?Rest} Spec Value NewArgs in
            {GetLongOptSpec LongOpt ?Spec ?Value}
            case Value of unit then
               case Args of (&-|_)|_ andthen {HasFeature Spec type} then
                  {Exception.raiseError
                   ap(usage 'option `'#{Label Spec}#'\' expects an argument')}
               else skip
               end
               NewArgs = Args
            else
               if {HasFeature Spec alias} then
                  {Exception.raiseError
                   ap(usage ('option `'#{Label Spec}#
                             '\' does not expect an argument'))}
               end
               NewArgs = Value|Args
            end
            {ParseOptArg Spec NewArgs ?Opt ?Rest}
         end

         fun {ParseOptions Argv}
            case Argv of Arg1|Argr then
               case Arg1 of &-|Opt then
                  case Opt of &-|LongOpt then
                     case LongOpt of nil then
                        Argr
                     else Opt1 NewArgr in
                        {ParseLongOpt LongOpt Argr ?Opt1 ?NewArgr}
                        {CondAppend Opt1 {ParseOptions NewArgr}}
                     end
                  [] OptChar|Arg1r then Opt1 NewArgr in
                     {ParseOpt OptChar Arg1r Argr ?Opt1 ?NewArgr}
                     {CondAppend Opt1 {ParseOptions NewArgr}}
                  [] nil then
                     Arg1|{ParseOptions Argr}
                  end
               elsecase Mode of start then
                  Argv
               [] anywhere then
                  Arg1|{ParseOptions Argr}
               end
            [] nil then
               nil
            end
         end
      in
         Mode = {CondSelect Spec mode anywhere}
         {CmdPreProcess Spec ?LongOptSpecs ?CharSpecRec}
         {ParseOptions Argv}
      end
   end

   %%
   %% Postprocess the Parsed Option List
   %%
   %% Takes an OptionList, returns an OptRec (see above).
   %%

   fun {PostProcess Options Spec} OptRecSpec Dict in
      OptRecSpec = {GetOptRecSpec Spec}
      Dict = {NewDictionary}
      {Dictionary.put Dict 1
       {Filter Options
        fun {$ O}
           case O of LongOpt#Value then
              case {CondSelect OptRecSpec LongOpt unit} of unit then true
              [] X then
                 case X.occ of single then
                    if {Dictionary.member Dict LongOpt} then
                       {Exception.raiseError
                        ap(usage
                           'option `'#LongOpt#'\' may be given at most once')}
                    end
                    {Dictionary.put Dict LongOpt Value}
                 [] multiple then
                    {Dictionary.put Dict LongOpt
                     {Append {Dictionary.condGet Dict LongOpt nil}
                      [Value]}}
                 [] multilist then
                    {Dictionary.put Dict LongOpt
                     {Append {Dictionary.condGet Dict LongOpt nil}
                      Value}}
                 [] leftmost then
                    if {Dictionary.member Dict LongOpt} then skip
                    else {Dictionary.put Dict LongOpt Value}
                    end
                 [] rightmost then
                    {Dictionary.put Dict LongOpt Value}
                 [] accumulate(P) then
                    {P LongOpt Value}
                 end
                 false
              end
           else true
           end
        end}}
      {Record.forAllInd OptRecSpec
       proc {$ LongOpt X}
          if {HasFeature X validate} then
             case {Validate X.validate Dict}
             of true then
                if {Dictionary.member Dict LongOpt} then skip
                elseif {HasFeature X default} then
                   {Dictionary.put Dict LongOpt X.default}
                else {Exception.raiseError
                      ap(usage 'option `'#LongOpt
                         #'\' required in this context')}
                end
             [] false then
                if {Dictionary.member Dict LongOpt} then
                   {Exception.raiseError
                    ap(usage 'option `'#LongOpt
                       #'\' illegal in this context')}
                end
             [] optional then
                if {HasFeature X default} andthen
                   {Not {Dictionary.member Dict LongOpt}}
                then
                   {Dictionary.put Dict LongOpt X.default}
                end
             end
          elseif {Dictionary.member Dict LongOpt} then skip
          elseif {HasFeature X default} then
             {Dictionary.put Dict LongOpt X.default}
          elseif X.required then
             {Exception.raiseError
              ap(usage 'required option `'#LongOpt#'\' not given')}
          end
       end}
      {Dictionary.toRecord optRec Dict}
   end

   %%
   %% E ::= true | false | optional | alt(A1 ... An)
   %% A ::= when(C E)
   %% C ::= true | false
   %%     | conj(C1 ... Cn)
   %%     | disj(C1 ... Cn)
   %%     | nega(C)
   %%     | <option name>
   %%

   fun {Validate E Dict}
      try {ValidateExpr E Dict} optional
      catch return(E) then E end
   end

   proc {ValidateExpr E Dict}
      case E
      of     true     then raise return(true)     end
      [] false    then raise return(false)    end
      [] optional then raise return(optional) end
      elsecase {Label E} of alt then
         {Record.forAll E
          proc {$ Alt}
             case Alt of when(C E) then
                if {ValidateCond C Dict} then
                   {ValidateExpr E Dict}
                end
             end
          end}
         raise return(optional) end
      end
   end

   fun {ValidateCond C Dict}
      case C of true then true
      [] false then false
      else
         if {IsAtom C} then {Dictionary.member Dict C}
         else
            case C of nega(C) then {Not {ValidateCond C Dict}}
            elsecase {Label C}
            of     conj then
               {Record.all  C fun {$ C} {ValidateCond C Dict} end}
            [] disj then
               {Record.some C fun {$ C} {ValidateCond C Dict} end}
            end
         end
      end
   end

define

   %%
   %% Access to Servlet parameters following CGI spec
   %%

   local
      local
         fun {CgiRawGet}
            class StdIn from Open.file
               prop final
               meth init
                  StdIn,dOpen(0 1)
               end
               meth get(N ?Is)
                  Ir M=StdIn,read(list:?Is tail:?Ir size:N len:$)
               in
                  Ir = if M<N then StdIn,get(N-M $) else nil end
               end
            end
         in
            case {OS.getEnv 'REQUEST_METHOD'} of false then
               {Exception.raiseError ap(spec env 'REQUEST_METHOD')} unit
            [] S then
               case {String.toAtom S}
               of 'GET'  then
                  case {OS.getEnv 'QUERY_STRING'} of false then
                     {Exception.raiseError ap(spec env 'QUERY_STRING')} unit
                  [] S then S
                  end
               [] 'POST' then
                  case {OS.getEnv 'CONTENT_LENGTH'} of false then
                     {Exception.raiseError ap(spec env 'CONTENT_LENGTH')} unit
                  [] S then F in
                     F = {New StdIn init()}
                     {F get({String.toInt S} $)}
                     %% NEVER ATTEMPT TO CLOSE!
                  end
               end
            end
         end
      in
         fun {GetRawCgiArgs}
            {Map {String.tokens {CgiRawGet} &&}
             fun {$ S} S1 S2 in
                {String.token S &= ?S1 ?S2} S1#S2
             end}
         end
      end
   in
      fun {GetCgiArgs Spec}
         Args = {CgiPreProcessArgs {GetRawCgiArgs}}
      in
         case {Label Spec}
         of plain  then Args
         [] list   then {CgiParse Args Spec}
         [] record then {PostProcess {CgiParse Args Spec} Spec}
         end
      end
   end

   %%
   %% Access to commandline arguments
   %%

   fun {GetCmdArgs Spec} Argv in
      Argv = case {Property.condGet 'ozd.args' unit} of unit then
                {Map {Property.get 'application.args'} AtomToString}
             [] X then X
             end
      case {Label Spec} of plain then Argv
      [] list then
         {CmdParse Argv Spec}
      [] record then
         {PostProcess {CmdParse Argv Spec} Spec}
      end
   end

   fun {GetArgs Spec}
      if {Property.get 'application.gui'} then
         {GetGuiArgs Spec}
      else {GetCmdArgs Spec} end
   end
end
