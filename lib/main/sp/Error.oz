%%%
%%% Authors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
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

local

   SKIP  = 0     % alignment spaces
   WIDTH = 65    % width of error message output

   %% shorthands

   VSL  = VirtualString.length
   VS2S    = VirtualString.toString
   IsNotNL = fun {$ X} X \= &\n end
   ToLower = fun {$ Xs} {Map {VS2S Xs} Char.toLower} end
   BugReport = 'Please send bug report to oz@ps.uni-sb.de'

   %% some formatting routines for arguments, applications, etc.

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
         case {Atom.toString PrintName} of &`|Sr then
            &`|{FoldLTail Sr EscapeVariableChar $ nil}
         elsecase PrintName of nil then "nil"
         [] '#' then "#"
         else PrintName
         end
      end
   end

   fun {ListToVS Xs Sep}
      case Xs
      of nil then
         ''
      elseof [X] then
         oz(X)
      elseof X1|X2|Xr then
         oz(X1) # Sep # {ListToVS X2|Xr Sep}
      end
   end

   fun {PosToVS F L C PC}
      Elems =
      {Filter
       [if F == '' then "" else 'file "'#F#'"' end
        if L == unit then "" else 'line '#L end
        case C of unit then "" [] ~1 then "" else 'column '#C end
        if PC == unit then "" else 'PC = '#PC end]
       fun {$ X} X \= "" end}
   in
      case Elems of E1|Er then
         {FoldL Er fun {$ In E} In#', '#E end E1}
      else ""
      end
   end

   fun {StarLine X}
      '%** ' # X # '\n'
   end

   proc {Repeat N C ?S}
      S = {MakeList N}
      {ForAll S fun {$} C end}
   end

   fun {MaxLeftSize Xs}
      {FoldL Xs fun {$ In L#_} {Max In L} end 0}
   end

   Stars  = '%***'
   Dashes = '%**' # {Repeat WIDTH - 3 &-} # '\n'
   NumStarsLeft = {VSL Stars}

in

   functor

   import
      Property(get put condGet)

      System(printName
             printError
             onToplevel)

      Application(exit)

      ErrorRegistry(get
                    exists)

   export
      formatGeneric: GenericFormatter

      formatExc:     FormatOzError
      formatLine:    AlmostVSToVS
      formatPos:     PosToVS
      formatAppl:    FormatAppl
      formatTypes:   FormatTypes
      formatHint:    FormatHint
      format:        Format

      dispatch:      DispatchField
      info:          InfoField

      printExc:      OzError

      msg:           ErrorMsg
      msgDebug:      ErrorMsgDebug

   define

      %% current output: strings into emulator window

      Output = System.printError

      proc {ExitError}
         {Application.exit 1}
      end

      %% some formatting routines

      local
         fun {DoFormatTypes Text S}
            case S
            of nil then nil
            else
               First Rest
            in
               {List.takeDropWhile S.2 IsNotNL First Rest}
               case Text of '' then
                  hint(m:{ToLower First})
               else
                  hint(l:Text m:{ToLower First})
               end | {DoFormatTypes '' Rest}
            end
         end
      in
         fun {FormatTypes T}
            {DoFormatTypes 'Expected type' &\n|{Atom.toString T}}
         end
      end

      fun {FormatPartialAppl A Xs N}
         '{' # oz(A) #
         case Xs of nil then '' else ' ' # list(Xs ' ') end #
         if N==0 then "}"
         else {Loop.forThread 1 N 1
               fun {$ In I} & |&_|In end nil} # '}'
         end
      end

      fun {FormatAppl A Xs}
         {FormatPartialAppl A Xs 0}
      end

      local
         fun {DoFormatHint S}
            case S of nil then nil
            else First Rest in
               {List.takeDropWhile S.2 IsNotNL First Rest}
               line(First) | {DoFormatHint Rest}
            end
         end
      in
         fun {FormatHint S}
            if {Property.get errors}.hints
               andthen S \= nil
            then unit|{DoFormatHint &\n|{VS2S S}}
            else nil end
         end
      end

      %% inspect exception record

      fun {InfoField Exc}
         D = {DebugField Exc}
      in
         if {IsRecord D}
            andthen {HasFeature D info}
         then D.info else unit end
      end

      fun {DebugField Exc}
         if {IsRecord Exc}
            andthen {HasFeature Exc debug}
         then Exc.debug else unit end
      end

      fun {DispatchField Exc}
         if {IsRecord Exc}
            andthen {HasFeature Exc 1}
         then Exc.1 else unit end
      end

      fun {HasDispatchField Exc}
         {IsRecord Exc}
         andthen {HasFeature Exc 1}
         andthen {IsRecord Exc.1}
      end

      fun {DebugInfo Exc}
         Is = {InfoField Exc}
      in
         case Is
         of unit then nil
         [] nil then nil
         [] I|Ir then
            case I
            of apply(X Xs) then
               hint(l:'In statement' m:{FormatAppl X Xs})
            [] fapply(X Xs N) then
               hint(l:'In statement' m:{FormatPartialAppl X Xs N})
            [] vs(V) then hint(l:V)
            end
            | {DebugInfo Ir}
         else
            nil
         end
      end

      fun {DebugLoc Exc}
         D = {DebugField Exc}
      in
         {CondSelect D loc unit}
      end

      fun {DebugStack Exc}
         E = {Property.get errors}
         D = {DebugField Exc}
      in
         if {HasFeature D stack}
            andthen E.'thread'>0
         then D.stack else unit end
      end

      %%
      %% AlmostVSToVS: AlMostVS -> VS
      %%
      %% an almost virtual string is a virtual string
      %% which may contain embedded records:
      %%
      %% oz(X): some Oz value
      %% pn(P): variable print name
      %% list(Xs S): list of Oz values to be separated by VS S
      %%

      fun {OzValueToVS X}
         P={Property.get errors} in
         {Value.toVirtualString X P.depth P.width}
      end

      fun {AlmostVSToVS X}
         if {IsDet X}
            andthen {IsRecord X}
         then
            case X of oz(M) then
               {OzValueToVS M}
            [] pn(M) then
               {PrintNameToVS M}
            [] pos(F L C) then
               {PosToVS F L C unit}
            [] list(Xs Sep) then
               {AlmostVSToVS {ListToVS Xs Sep}}
            else
               if
                  {IsTuple X}
                  andthen {Label X}=='#'
               then
                  {Record.map X AlmostVSToVS}
               else X end
            end
         else {OzValueToVS X} end
      end

      fun {AttachLeftSizes Xs}
         {Map Xs
          fun {$ X}
             case X
             of hint(l:L) then
                {VSL {AlmostVSToVS L}} # X
             [] hint(l:L m:M) then
                {VSL {AlmostVSToVS L}} # X
             else
                0 # X
             end
          end}
      end

      %% parametrized output routines

      proc {LineOutput ErrorMsg Format} VSCell in
         %% We have to call output a single time and not once per line
         %% so that the alarm character to raise the buffer if running
         %% under Emacs is only output once.
         case Format of none then skip
         else
            VSCell = {NewCell ""}
            {ErrorMsg
             proc {$ X}
                {Assign VSCell {Access VSCell}#{AlmostVSToVS X}}
             end
             Format}
            {Output {Access VSCell}}
         end
      end

      fun {Spaces N}
         {Repeat N & }
      end

      proc {Lines Out Xs}
         Ys    = {AttachLeftSizes Xs}
         Align = {MaxLeftSize Ys} + SKIP
      in
         {ForAll Ys
          proc {$ L#X}
             case X
             of unit then
                {Out {StarLine ''}}
             [] line(H) then
                {Out {StarLine H}}
             [] pos(F L C) then
                {Out {StarLine 'in ' # {PosToVS F L C unit}}}
             [] hint then
                {Out {StarLine ''}}
             [] hint(l:Left) then
                {Out {StarLine Left}}
             [] hint(m:Mid) then
                {Out {StarLine {Spaces Align - L + 2} # Mid}}
             [] hint(l:Left m:Mid) then
                {Out {StarLine Left # ':' # {Spaces Align - L + 1} # Mid}}
             else
                skip % more to be added
             end
          end}
      end

      %%
      %% output list of spaces
      %%

      fun {Location Spaces}
         if Spaces ==  nil
            orelse Spaces == unit
         then nil else
            [ ''
              'Level: ' # {FoldR Spaces fun {$ I W} I # ' ' # W end ''} ]
         end
      end

      %%
      %% output call stack
      %%

      local
         fun {DoStack Xs N}
            case Xs of nil then ""
            [] X|Xr then
               if N > 0 then
                  Pos = {PosToVS
                         {CondSelect X file ''}
                         {CondSelect X line unit}
                         {CondSelect X column unit}
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
                  end|{DoStack Xr N - 1}
               else ['...']
               end
            end
         end
      in
         fun {GetStack Xs N}
            if Xs==unit
            then nil
            elseif N>0 then
               if {All Xs fun {$ X} X==toplevel end}
               then ['' 'On toplevel']
               else '' | 'CallStack: ' | {DoStack Xs N}
               end
            else nil end
         end
      end

      %% error messages have the following format
      %% (where all fields are optional)
      %%
      %%  <label>(kind:  AVS            % almost virtual string
      %%          msg:   AVS
      %%          items: <line>*
      %%          loc:                  % added by the emulator
      %%          stack:                % added by the emulator
      %%          footer:               % yes/no
      %%         )
      %%  <line> ::= hint(l:AVS m:AVS)  % both fields optional
      %%             pos(A I I)
      %%             line(AVS)          % full line
      %%             unit               % empty line
      %%
      %% format is approximately
      %%
      %% %********** <kind> ********
      %% %**
      %% %** <title>
      %% %**
      %% %** <line>
      %% %** ...
      %% %**
      %% %** <stack>
      %% %** <loc>
      %% %**
      %% %************************** if <footer>

      %%
      %% return stack/location/info components
      %%

      local
         proc {ErrorTitle Out Format}
            Kind = case {CondSelect Format kind unit}
                   of unit then ''
                   elseof Msg then ' ' # Msg # ' '
                   end
            NumStars = WIDTH - {VSL Kind} - NumStarsLeft
            NumStars1 = NumStars div 2
            NumStars2 = (NumStars + 1) div 2
         in
            {Out
             Stars # {Repeat NumStars1 &*} #
             Kind # {Repeat NumStars2 &*} # '\n'}
            {Out {StarLine ''}}
         end

         proc {ErrorMsgLine Out Format}
            case {CondSelect Format msg unit}
            of unit then skip
            elseof Msg then
               {Out {StarLine Msg}}
               {Out {StarLine ''}}
            end
         end

         proc {ErrorItems Out Format}
            case {CondSelect Format items unit}
            of unit then
               skip
            elseof Ts then
               {Lines Out Ts}
            end
         end

         proc {ErrorLoc Out Format}
            case {CondSelect Format loc unit}
            of unit then
               skip
            elseof L then
               {ForAll
                {Map {Location L} StarLine}
                Out}
            end
         end

         proc {ErrorStack Out Format}
            case {CondSelect Format stack unit}
            of unit then
               skip
            elseof S then
               E = {Property.get errors}
            in {ForAll
                {Map {GetStack S E.'thread'} StarLine}
                Out}
            end
         end

         proc {ErrorFooter Out Format}
            if {CondSelect Format footer false}
            then {Out Dashes}
            end
         end

         proc {ErrorInfo Out Format}
            case {CondSelect Format info unit}
            of unit then
               skip
            elseof Ts then
               {Lines Out Ts}
            end
         end
      in
         proc {ErrorMsg Out Format}
            case Format
            of none then skip
            else
               {Out '\n'}
               {ErrorTitle Out Format}
               {ErrorMsgLine Out Format}
               {ErrorItems Out Format}
               {ErrorFooter Out Format}
            end
         end

         proc {ErrorMsgDebug Out Format}
            case Format
            of none then skip
            else
               {Out '\n'}
               {ErrorTitle Out Format}
               {ErrorMsgLine Out Format}
               {ErrorItems Out Format}
               {ErrorLoc Out Format}
               {ErrorInfo Out Format}
               {ErrorStack Out Format}
               {ErrorFooter Out Format}
            end
         end
      end

      %%
      %% build error format record
      %%

      proc {Format Kind Msg Bs Exc E}
         Fs = [items loc stack footer info]
      in
         E = {Record.make error
              if Kind==unit then
                 if Msg==unit
                 then Fs
                 else msg|Fs end
              elseif Msg==unit
              then kind|Fs
              else kind|msg|Fs
              end}

         if Kind \= unit
         then E.kind = Kind
         end

         if Msg \= unit
         then E.msg = Msg
         end

         E.items  = Bs
         E.loc    = {DebugLoc Exc}
         E.stack  = {DebugStack Exc}
         E.footer = true
         E.info   = {DebugInfo Exc}
      end

      fun {FormatReRaiseExc Exc ExcExc}
         error(title: 'Unable to Print Error Message'
               items:[hint(l:'Initial exception' m:oz(Exc))
                      hint(l:'Format exception Kind'  m:{Label ExcExc})
                      hint(l:'Format exception' m:oz({DispatchField ExcExc}))
                      line(BugReport)]
               loc:   {DebugLoc Exc}
               stack: {DebugStack Exc}
              )
      end


      %%
      %% generic formatter for exceptions
      %%

      fun {GenericFormatter Msg Exc}
         {Format unit Msg [line(oz(Exc))] Exc}
      end

      %%
      %% error print manager
      %%

      fun {FormatOzError Exc}
         T = 'Error: unhandled exception'
      in
         if {IsRecord Exc} then
            LL={Label Exc}
         in
            if LL==failure then
               {{ErrorRegistry.get failure} Exc}
            elseif LL==error orelse LL==system then
               if {HasDispatchField Exc} then
                  Key = {Label {DispatchField Exc}}
               in
                  if {ErrorRegistry.exists Key}
                  then {{ErrorRegistry.get Key} Exc}
                  else {GenericFormatter T Exc}
                  end
               else
                  {GenericFormatter T Exc}
               end
            else
               Key = {Label Exc}
            in
               if {ErrorRegistry.exists Key}
               then {{ErrorRegistry.get Key} Exc}
               else {GenericFormatter T Exc}
               end
            end
         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% register procedure OzError as Handler in the emulator
      %% and initialize builtin error formatters
      %%

      local
         proc {DefExHdl Exc}
            try
               {Thread.setThisPriority high}
               {LineOutput ErrorMsgDebug {FormatOzError Exc}}
            catch X then
               {LineOutput ErrorMsgDebug {FormatReRaiseExc Exc X}}
            end
            %% terminate local computation
            if {System.onToplevel} then
               {{Property.condGet 'errors.toplevel' ExitError}}
            elseif {Label Exc}==failure then fail else
               {{Property.condGet 'errors.subordinate' ExitError}}
            end
         end
      in
         {Property.put 'errors.handler' DefExHdl}
      end

      OzError = {Property.get 'errors.handler'}

   end

end
