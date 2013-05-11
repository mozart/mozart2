%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%   Martin Mueller, 1997
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
%% Error messages have the following format
%% (where all fields are optional):
%%
%%    <message> ::=
%%          <message label>([kind: <extended virtual string>]
%%                          [msg: <extended virtual string>]
%%                          [items: [<line>]]
%%                          [info: <info>]      % copied from exception
%%                          [stack: <stack>]    % copied from exception
%%                          [footer: bool])
%%
%%    <message label> ::= error | warn   % no special meaning
%%
%%    <extended virtual string> ::=
%%          atom | int | float | string
%%       |  '#'(<extended virtual string> ... <extended virtual string>)
%%       |  oz(value)
%%       |  pn(atom)
%%       |  <coordinates>
%%       |  apply(<procedure or print name> [value])
%%       |  list([value] <extended virtual string>)
%%
%%    <coordinates> ::= pos(atom   % file name; '' if not known
%%                          int    % line number; required
%%                          int)   % column number; ~1 if not known
%%
%%    <line> ::= hint([l: <extended virtual string>]
%%                    [m: <extended virtual string>])
%%            |  <coordinates>
%%            |  line(<extended virtual string>)     % full line
%%            |  unit                                % empty line
%%
%%    <info> ::= [<info item>]
%%    <info item> ::= apply(<procedure or print name> [value])
%%                 |  fapply(<procedure or print name> [value] int)
%%                 |  'fail'
%%                 |  eq(value value)
%%                 |  tell(value value)
%%    <procedure or print name> ::= procedure | atom
%%
%%    <stack> ::= [<frame>]
%%    <frame> ::= <entry exit>(kind: atom
%%                             [file: atom]
%%                             [line: int]
%%                             [column: int]
%%                             ['PC': int]
%%                             [data: value]
%%                             ...)
%%    <entry exit> ::= 'entry' | 'exit'
%%
%% Output format is approximately:
%%
%%    %*********** kind ********
%%    %**
%%    %** msg
%%    %**
%%    %** line
%%    %** ...
%%    %**
%%    %** info
%%    %** stack
%%    %**
%%    %************************* (if footer)
%%

functor
import
   Property(get)
   System(printName printError)
   ErrorFormatters(kernel:  KernelFormatter
                   object:  ObjectFormatter
                   failure: FailureFormatter
                   recordC: RecordCFormatter
                   system:  SystemFormatter
                   ap:      APFormatter
                   dp:      DPFormatter
                   os:      OSFormatter
                   foreign: ForeignFormatter
                   url:     URLFormatter
                   module:  ModuleFormatter)

export
   ExceptionToMessage
   MessageToVirtualString
   ExtendedVSToVS
   PrintException
   RegisterFormatter

prepare

   SKIP  = 0     % alignment spaces
   WIDTH = 65    % width of error message output

   BugReport = 'Please send bug report to bugs@mozart-oz.org'

   %% some formatting routines

   fun {Repeat N C}
      {ForThread 1 N 1 fun {$ In _} C|In end nil}
   end

   fun {StarLine X}
      '%** '#X#'\n'
   end

   Stars  = '%***'
   NumStarsLeft = {VirtualString.length Stars}
   EmptyLine = '%**\n'
   Footer = '%**'#{Repeat WIDTH - 3 &-}#'\n'

   fun {PosToVS F L C PC} Elems in
      Elems = {Filter
               [case F of '' then "" else 'file "'#F#'"' end
                case L of unit then "" else 'line '#L end
                case C of ~1 then "" [] unit then "" else 'column '#C end
                case PC of unit then "" else 'PC = '#PC end]
               fun {$ X} X \= "" end}
      case Elems of E1|Er then
         {FoldL Er fun {$ In E} In#', '#E end E1}
      else ""
      end
   end

   fun {FormatPartialAppl A Xs N}
      '{'#if {IsAtom A} then pn(A) else oz(A) end#
      case Xs of nil then ""
      else ' '#list(Xs ' ')
      end#
      case N of 0 then ""
      else {Loop.forThread 1 N 1 fun {$ In I} & |&_|In end nil}
      end#'}'
   end

   fun {FormatAppl A Xs}
      {FormatPartialAppl A Xs 0}
   end

define

   %%
   %% Translation of Extended Virtual Strings to Virtual Strings
   %%

   local
      fun {OzValueToVS X} P in
         P = {Property.get errors}
         {Value.toVirtualString X P.depth P.width}
      end

      local
         proc {EscapeVariableChar Hd C|Cr Tl}
            case Cr of nil then Hd = C|Tl   % terminating quote
            else
               if C == &` orelse C == &\\ then Hd = &\\|C|Tl
               elseif C < 10 then Hd = &\\|&x|&0|(&0 + C)|Tl
               elseif C < 16 then Hd = &\\|&x|&0|(&A + C - 10)|Tl
               elseif C < 26 then Hd = &\\|&x|&1|(&0 + C - 16)|Tl
               elseif C < 32 then Hd = &\\|&x|&1|(&A + C - 26)|Tl
               else Hd = C|Tl
               end
            end
         end
      in
         fun {PrintNameToVS PrintName}
            case PrintName of unit then '_'
            elsecase {Atom.toString {System.printName PrintName}} of &`|Sr then
               &`|{FoldLTail Sr EscapeVariableChar $ nil}
            elsecase PrintName of nil then "nil"
            [] '#' then "#"
            else {System.printName PrintName}
            end
         end
      end

      fun {ListToVS Xs Sep}
         case Xs of nil then ""
         elseof [X] then oz(X)
         elseof X1|Xr then oz(X1)#Sep#{ListToVS Xr Sep}
         end
      end
   in
      fun {ExtendedVSToVS X}
         if {IsDet X} then
            case X of oz(M) then
               {OzValueToVS M}
            [] pn(M) then
               {PrintNameToVS M}
            [] pos(F L C) then
               {PosToVS F L C unit}
            [] apply(A Xs) then
               {ExtendedVSToVS {FormatAppl A Xs}}
            [] list(Xs Sep) then
               {ExtendedVSToVS {ListToVS Xs Sep}}
            [] '#'(...) andthen {IsTuple X} then
               {Record.map X ExtendedVSToVS}
            else X
            end
         else {OzValueToVS X}
         end
      end
   end

   %%
   %% Accessing Exception Components
   %%

   fun {GetExceptionDispatch Exc}
      case Exc of error(DispatchField ...) then DispatchField
      [] system(DispatchField ...) then DispatchField
      elseif {IsRecord Exc} then Exc
      else unit
      end
   end

   local
      fun {DebugField Exc}
         if {IsRecord Exc} then {CondSelect Exc debug unit}
         else unit
         end
      end

      fun {InfoField Exc} D in
         D = {DebugField Exc}
         case {Value.status D}
         of det(record) then {CondSelect D info unit}
         [] future then {CondSelect D info unit}
         else unit
         end
      end
   in
      fun {GetExceptionInfo Exc}
         case {InfoField Exc} of unit then nil
         elseof Is then
            {Map Is
             fun {$ I}
                case I of apply(X Xs) then
                   hint(l:'In statement' m:{FormatAppl X Xs})
                [] fapply(X Xs N) then
                   hint(l:'In statement' m:{FormatPartialAppl X Xs N})
                [] 'fail' then
                   hint(l:'Tell' m:'fail')
                [] eq(X Y) then
                   hint(l:'Tell' m:oz(X)#' = '#oz(Y))
                [] tell(X Y) then
                   hint(l:'Tell' m:oz(X)#' = '#oz(Y))
                else
                   hint(l:'Info' m:oz(I))
                end
             end}
         end
      end

      fun {GetExceptionStack Exc}
         D = {DebugField Exc}
         Dstatus = {Value.status D}
      in
         if Dstatus == det(record) orelse Dstatus == future then
            if {HasFeature D stack} andthen {Property.get 'errors.thread'} > 0
            then D.stack
            else unit
            end
         else unit
         end
      end
   end

   %%
   %% output call stack
   %%

   fun {GetStack Xs N}
      case Xs of nil then ""
      [] X|Xr then
         if N > 0 then
            Pos = {PosToVS
                   {CondSelect X file ''}
                   {CondSelect X line unit}
                   {CondSelect X column ~1}
                   {CondSelect X 'PC' unit}}
            Kind = case X.kind of 'call/c' then 'call'
                   [] 'call/f' then 'call'
                   [] 'lock/c' then 'lock'
                   [] 'lock/f' then 'lock'
                   [] 'exception handler/c' then 'exception handler'
                   [] 'exception handler/f' then 'exception handler'
                   [] 'conditional/c' then 'conditional'
                   [] 'conditional/f' then 'conditional'
                   [] 'definition/c' then 'definition'
                   [] 'definition/f' then 'definition'
                   [] 'skip/c' then 'skip'
                   [] 'skip/f' then 'skip'
                   [] 'fail/c' then 'fail'
                   [] 'fail/f' then 'fail'
                   [] 'thread/c' then 'thread'
                   [] 'thread/f' then 'thread'
                   elseof K then K
                   end
         in
            case Kind of call then
               if {HasFeature X data} then Data in
                  Data = X.data
                  if {IsDet Data} then
                     PN = {System.printName Data}
                  in
                     if {IsObject Data} then
                        case PN of '' then
                           'object application'
                        else
                           'object application of class \''#PN#'\''
                        end
                     else
                        case PN of '' then
                           'procedure'
                        [] 'Toplevel abstraction' then
                           'toplevel abstraction'
                        else
                           'procedure \''#PN#'\''
                        end
                     end
                  else 'procedure _'
                  end
               else 'procedure'
               end
            else Kind
            end#
            if Pos == "" then ""
            else ' in '#Pos
            end|{GetStack Xr N - 1}
         else ['...']
         end
      end
   end

   %%
   %% Converting a Message to a Virtual String
   %%

   local
      local
         fun {AttachLeftSizes Xs}
            {Map Xs
             fun {$ X}
                case X
                of hint(l:L) then
                   {VirtualString.length {ExtendedVSToVS L}} # X
                [] hint(l:L m:_) then
                   {VirtualString.length {ExtendedVSToVS L}} # X
                else
                   0 # X
                end
             end}
         end

         fun {MaxLeftSize Xs}
            {FoldL Xs fun {$ In L#_} {Max In L} end 0}
         end

         fun {Spaces N}
            {Repeat N & }
         end
      in
         fun {Lines Xs}
            Ys    = {AttachLeftSizes Xs}
            Align = {MaxLeftSize Ys} + SKIP
         in
            {FoldR Ys
             fun {$ L#X In}
                case X
                of unit then
                   EmptyLine
                [] line(H) then
                   {StarLine {ExtendedVSToVS H}}
                [] pos(_ _ _) then
                   {StarLine 'in '#{ExtendedVSToVS X}}
                [] hint then
                   EmptyLine
                [] hint(l:Left) then
                   {StarLine {ExtendedVSToVS Left}}
                [] hint(m:Mid) then
                   {StarLine {Spaces Align - L + 2}#{ExtendedVSToVS Mid}}
                [] hint(l:Left m:Mid) then
                   {StarLine
                    {ExtendedVSToVS Left}#':'#{Spaces Align - L + 1}#
                    {ExtendedVSToVS Mid}}
                end#In
             end ""}
         end
      end

      fun {ErrorKind Message}
         Kind = case {CondSelect Message kind unit} of unit then ''
                elseof X then ' '#{ExtendedVSToVS X}#' '
                end
         NumStars = WIDTH - {VirtualString.length Kind} - NumStarsLeft
         NumStars1 = NumStars div 2
         NumStars2 = (NumStars + 1) div 2
      in
         Stars#{Repeat NumStars1 &*}#Kind#{Repeat NumStars2 &*}#'\n'#
         EmptyLine
      end

      fun {ErrorMsg Message}
         case {CondSelect Message msg unit} of unit then ""
         elseof Msg then
            {StarLine {ExtendedVSToVS Msg}}#
            EmptyLine
         end
      end

      fun {ErrorItems Message}
         case {CondSelect Message items unit} of unit then ""
         elseof Ts then {Lines Ts}
         end
      end

      fun {ErrorInfo Message}
         case {CondSelect Message info unit} of unit then ""
         elseof Ts then
            {Lines Ts}
         end
      end

      fun {ErrorStack Message}
         case {CondSelect Message stack unit} of unit then ""
         elseof Frames then N in
            N = {Property.get 'errors.thread'}
            if N > 0 then
               EmptyLine#
               {StarLine 'Call Stack:'}#
               {FoldR {GetStack Frames N}
                fun {$ Frame In} {StarLine Frame}#In end ""}
            else ""
            end
         end
      end

      fun {ErrorFooter Message}
         if {CondSelect Message footer false} then Footer
         else ""
         end
      end
   in
      fun {MessageToVirtualString Message}
         '\n'#
         {ErrorKind Message}#
         {ErrorMsg Message}#
         {ErrorItems Message}#
         {ErrorInfo Message}#
         {ErrorStack Message}#
         {ErrorFooter Message}
      end
   end

   %%
   %% Converting an Exception to a Message
   %%

   local
      fun {Extend Message Exc}
         {Adjoin Message
          error(info: {GetExceptionInfo Exc}
                stack: {GetExceptionStack Exc})}
      end

      fun {GenericFormatter Msg Exc}
         {Extend error(msg: Msg items: [line(oz(Exc))]) Exc}
      end
   in
      fun {ExceptionToMessage Exc}
         T = 'Error: unhandled exception'
         E = {GetExceptionDispatch Exc}
      in
         if E \= unit andthen {IsRecord E} then Key in
            Key = {Label E}
            if {Dictionary.member ErrorRegistry Key} then
               {Extend {{Dictionary.get ErrorRegistry Key} E} Exc}
            else
               {GenericFormatter T Exc}
            end
         else
            {GenericFormatter T Exc}
         end
      end
   end

   %%
   %% Printing an Exception
   %%

   local
      fun {FormatReRaiseExc Exc ExcExc}
         error(kind: 'exception formatter error'
               msg: 'unable to print error message'
               items: [hint(l:'Initial exception'
                            m:oz({GetExceptionDispatch Exc}))
                       hint(l:'Format exception'
                            m:oz({GetExceptionDispatch ExcExc}))
                       unit
                       line(BugReport)]
               stack: {GetExceptionStack Exc}
               footer: true)
      end
   in
      proc {PrintException Exc}
         try M in
            M = {AdjoinAt {ExceptionToMessage Exc} footer true}
            {System.printError {MessageToVirtualString M}}
         catch X then
            {System.printError
             {MessageToVirtualString {FormatReRaiseExc Exc X}}}
         end
      end
   end

   %%
   %% The Registry
   %%

   ErrorRegistry = {NewDictionary}

   proc {RegisterFormatter Key Formatter}
      {Dictionary.put ErrorRegistry Key Formatter}
   end

   {RegisterFormatter kernel  KernelFormatter}
   {RegisterFormatter object  ObjectFormatter}
   {RegisterFormatter failure FailureFormatter}
   {RegisterFormatter recordC RecordCFormatter}
   {RegisterFormatter system  SystemFormatter}
   {RegisterFormatter ap      APFormatter}
   {RegisterFormatter dp      DPFormatter}
   {RegisterFormatter os      OSFormatter}
   {RegisterFormatter foreign ForeignFormatter}
   {RegisterFormatter url     URLFormatter}
   {RegisterFormatter module  ModuleFormatter}
end
