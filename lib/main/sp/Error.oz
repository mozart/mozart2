%%%
%%% Authors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
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
%%                          [loc: <location>]   % copied from exception
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
%%    <location> ::= [<location item>]
%%    <location item> ::= 'space' | 'cond' | 'dis'
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
%%    %** loc
%%    %** info
%%    %** stack
%%    %**
%%    %************************* (if footer)
%%

functor
import
   Debug(setRaiseOnBlock) at 'x-oz://boot/Debug'
   Property(get put condGet)
   System(printName printError onToplevel)
   Application(exit)
   ErrorRegistry(get exists)

export
   ExceptionToMessage
   MessageToVirtualString
   ExtendedVSToVS
   PrintException

prepare

   SKIP  = 0     % alignment spaces
   WIDTH = 65    % width of error message output

   BugReport = 'Please send bug report to oz@ps.uni-sb.de'

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
            elsecase {Atom.toString PrintName} of &`|Sr then
               &`|{FoldLTail Sr EscapeVariableChar $ nil}
            elsecase PrintName of nil then "nil"
            [] '#' then "#"
            else PrintName
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
      if {IsRecord Exc} then {CondSelect Exc 1 unit}
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
         if {IsRecord D} then {CondSelect D info unit}
         else unit
         end
      end
   in
      fun {GetExceptionLocation Exc}
         {CondSelect {DebugField Exc} loc unit}
      end

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

      fun {GetExceptionStack Exc} D in
         D = {DebugField Exc}
         if {HasFeature D stack} andthen {Property.get 'errors.thread'} > 0
         then D.stack
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
               Data = X.data
            in
               if {IsDet Data} then
                  PN = {System.printName Data}
               in
                  if {IsObject Data} then
                     if PN == '' then
                        'object application'
                     else
                        'object application of class \''#PN#'\''
                     end
                  else
                     if PN == '' then
                        'procedure'
                     else
                        'procedure \''#PN#'\''
                     end
                  end
               else
                  'procedure _'
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
         elseof Ts then
            if {Property.get 'errors.hints'} then {Lines Ts}
            else ""
            end
         end
      end

      fun {ErrorLoc Message}
         case {CondSelect Message loc unit} of unit then ""
         [] nil then ""
         elseof Ls then
            if {Property.get 'errors.location'} then
               EmptyLine#
               {StarLine 'Level: '#{FoldR Ls fun {$ I W} I#' '#W end ''}}
            else ""
            end
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
         {ErrorLoc Message}#
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
          error(loc: {GetExceptionLocation Exc}
                info: {GetExceptionInfo Exc}
                stack: {GetExceptionStack Exc}
                footer: true)}
      end

      fun {GenericFormatter Msg Exc}
         {Extend error(msg: Msg items: [line(oz(Exc))]) Exc}
      end
   in
      fun {ExceptionToMessage Exc}
         T = 'Error: unhandled exception'
      in
         if {IsRecord Exc} then LL Key in
            LL = {Label Exc}
            Key = if LL == error orelse LL == system then
                     {Label {GetExceptionDispatch Exc}}
                  else LL
                  end
            if {ErrorRegistry.exists Key} then Message in
               Message = {{ErrorRegistry.get Key} {GetExceptionDispatch Exc}}
               {Extend Message Exc}
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
         error(title: 'Unable to Print Error Message'
               items: [hint(l:'Initial exception' m:oz(Exc))
                       hint(l:'Format exception kind' m:{Label ExcExc})
                       hint(l:'Format exception'
                            m:oz({GetExceptionDispatch ExcExc}))
                       line(BugReport)]
               loc: {GetExceptionLocation Exc}
               stack: {GetExceptionStack Exc})
      end
   in
      proc {PrintException Exc}
         try
            {System.printError
             {MessageToVirtualString {ExceptionToMessage Exc}}}
         catch X then
            {System.printError
             {MessageToVirtualString {FormatReRaiseExc Exc X}}}
         end
      end
   end

   %%
   %% The Error Handler
   %%

   local
      proc {ExitError}
         {Application.exit 1}
      end
   in
      proc {ErrorHandler Exc}
         %% ignore thread termination exception
         case Exc of system(kernel(terminate) debug:_) then skip
         else
            {Thread.setThisPriority high}
            {Debug.setRaiseOnBlock {Thread.this} true}
            {PrintException Exc}
            {Debug.setRaiseOnBlock {Thread.this} false}
            %% terminate local computation
            if {System.onToplevel} then
               {{Property.condGet 'errors.toplevel' ExitError}}
            elsecase Exc of failure(...) then fail
            else
               {{Property.condGet 'errors.subordinate' ExitError}}
            end
         end
      end
   end

   {Property.put 'errors.handler' ErrorHandler}
end
