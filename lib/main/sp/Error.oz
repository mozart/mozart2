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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\undef TYPE_DEBUG

local

   %% constants

   SKIP  = 0     % alignment spaces
   WIDTH = 65    % width of error message output

   %% shorthands

   S2A  = String.toAtom
   VS2S = VirtualString.toString
   VSL  = VirtualString.length
   VS2A = fun {$ X} {S2A {VS2S X}} end
   OnToplevel = {`Builtin` onToplevel 1}

   IsNotNL = fun {$ X} X \= &\n end
   ToLower = fun {$ Xs} {Map {VS2S Xs} Char.toLower} end

   %%
   %% PrintNameToVS: AlMostVS -> VS
   %% OzValueToVS:   OzValue  -> VS
   %% ListToVS:      list(AlMostVS) -> VS
   %%

   local
      proc {EscapeVariableChar Hd C|Cr Tl}
         case Cr of nil then Hd = C|Tl   % terminating quote
         elsecase C == &` orelse C == &\\ then Hd = &\\|C|Tl
         elsecase C < 10 then Hd = &\\|&x|&0|(&0 + C)|Tl
         elsecase C < 16 then Hd = &\\|&x|&0|(&A + C - 10)|Tl
         elsecase C < 26 then Hd = &\\|&x|&1|(&0 + C - 16)|Tl
         elsecase C < 32 then Hd = &\\|&x|&1|(&A + C - 26)|Tl
         else Hd = C|Tl
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

   fun {OzValueToVS X}
      P={System.get errors} in
      {System.valueToVirtualString X P.depth P.width}
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

   %%
   %% AlmostVSToVS: AlMostVS -> VS
   %%

   %%
   %% an almost virtual string is a virtual string
   %% which may contain embedded records:
   %%
   %% oz(X): some Oz value
   %% pn(P): variable print name
   %% list(Xs S): list of Oz values to be separated by VS S
   %%

   fun {AlmostVSToVS X}
      case {IsDet X}
         andthen {IsRecord X}
      then
         case X of oz(M) then
            {OzValueToVS M}
         [] pn(M) then
            {PrintNameToVS M}
         [] pos(F L C) then
            {PosToVS F L C unit}
         [] pos(F L C _ _ _) then
            {PosToVS F L C unit}
         [] posNoDebug(F L C) then
            {PosToVS F L C unit}
         [] list(Xs Sep) then
            {AlmostVSToVS {ListToVS Xs Sep}}
         elsecase
            {IsTuple X}
            andthen {Label X}=='#'
         then
            {Record.map X AlmostVSToVS}
         else X end
      else {OzValueToVS X} end
   end

   %%
   %% IsAlmostVSToVS: OzValue -> Bool
   %%

   fun {IsAlmostVirtualString X}
      case {IsInt X}
         orelse {IsFloat X}
         orelse {IsAtom X}
      then
         true
      elsecase {IsTuple X}
         andthen {Label X}=='#'
      then
         {Record.all X IsAlmostVirtualString}
      else
         false
      end
   end

   %%
   %% format position information
   %%

   fun {PosToVS F L C PC}
      Elems =
      {Filter
       [case F == '' orelse F == 'nofile' then "" else 'file "'#F#'"' end
        case L == unit then "" else 'line '#L end
        case C == unit then "" else 'column '#C end
        case PC == unit then "" else 'PC = '#PC end]
       fun {$ X} X \= "" end}
   in
      case Elems of E1|Er then
         {FoldL Er fun {$ In E} In#', '#E end E1}
      else ""
      end
   end

   %%
   %% current output: strings into emulator window
   %%

   Output   = proc {$ X} {System.printError {VS2A X}} end
   Alert    = proc {$} {System.printError ''} end

   %%
   %% parametrized output routines
   %%

   fun {StarLine X}
      '%** ' # X # '\n'
   end

   proc {LineOutput X}
      {Output {AlmostVSToVS X}}
   end

   proc {Repeat N C ?S}
      S = {MakeList N}
      {ForAll S fun {$} C end}
   end

   local
      DebugMode = {`Builtin` 'Debug.mode' 1}
   in
      fun {Spaces N}
         case {DebugMode}
         then [& ]
         else {Repeat N & }
         end
      end
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

   fun {MaxLeftSize Xs}
      {FoldL Xs fun {$ In L#_} {Max In L} end 0}
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
          [] pos(F L C _ _ _) then
             {Out {StarLine 'in ' # {PosToVS F L C unit}}}
          [] posNoDebug(F L C) then
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

   local
      fun {DoGiveHint S}
         case S of nil then nil
         else First Rest in
            {List.takeDropWhile S.2 IsNotNL First Rest}
            line(First) | {DoGiveHint Rest}
         end
      end
   in
      fun {GiveHint S}
         case {System.get errors}.hints
            andthen S \= nil
         then unit|{DoGiveHint &\n|{VS2S S}}
         else nil end
      end
   end

   fun {BugReport}
      'Please send bug report to oz@ps.uni-sb.de'
   end

   %%
   %% some formatting routines for arguments, applications, etc.
   %%

   fun {FormatAppl A Xs}
      P = {VS2A {OzValueToVS A}}
   in
      case Xs of nil then
         '{' # pn(P) # '}'
      else
         '{' # pn(P) # ' ' # list(Xs ' ') # '}'
      end
   end

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

   %%
   %% output list of spaces
   %%

   fun {Location Spaces}
      case Spaces ==  nil
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
            case N > 0 then
               Pos = {PosToVS
                      {CondSelect X file nofile}
                      {CondSelect X line unit}
                      {CondSelect X column unit}
                      {CondSelect X 'PC' unit}}
            in
               case {CondSelect X name unit} of unit then
                  case X.kind of call then
                     Data = {CondSelect X data unit}
                  in
                     case {IsDet Data} then
                        case Data == unit then
                           'procedure'
                        else
                           PN = {System.printName Data}
                        in
                           case {IsObject Data} then
                              case PN == '' then
                                 'object application'
                              else
                                 'object application of class \''#PN#'\''
                              end
                           else
                              case PN == '' then
                                 'procedure'
                              else
                                 'procedure \''#PN#'\''
                              end
                           end
                        end
                     else
                        'procedure _'
                     end
                  [] 'lock' then 'lock'
                  [] handler then 'exception handler'
                  [] cond then 'conditional'
                  elseof Kind then 'unknown task \''#Kind#'\''
                  end
               elseof Name then
                  case Name == '' then
                     'procedure'
                  else
                     'procedure \''#Name#'\''
                  end
               end#
               case Pos == "" then ""
               else ' in '#Pos
               end|{DoStack Xr N - 1}
            else ['...']
            end
         end
      end
   in
      fun {GetStack Xs N}
         case Xs==unit
         then nil
         elsecase N>0 then
            case {All Xs fun {$ X} X==toplevel end}
            then ['' 'On toplevel']
            else '' | 'CallStack: ' | {DoStack Xs N}
            end
         else nil end
      end
   end

\ifdef TYPE_DEBUG
   fun {IsBinaryProc P}
      {IsProcedure P} andthen {Procedure.arity P}==2
   end

   AskBinaryProc = {Type.ask.generic IsBinaryProc 'binary procedure'}
   AskChunkOrRec = {Type.ask.generic
                    fun {$ CR} {IsChunk CR} orelse {IsRecord CR} end
                    'chunk or record'}
   AskProcOrObject={Type.ask.generic
                    fun {$ P} {IsProcedure P} orelse {IsObject P} end
                    'procedure or object'}
\endif

   %%
   %% names of fd related builtins
   %%

   ArithOps = ['=:' '\\=:' '<:' '=<:' '>:' '>=:']

   BuiltinNames
   = bi(fdp_twice:         [fdp_twice           ['FD.plus' 'FD.minus']]
        fdp_square:        [fdp_square          ['FD.times']]
        fdp_plus:          ['FD.plus'           ['FD.distance']]
        fdp_plus_rel:      ['FD.plus'           ['FD.distance' '+']]
        fdp_minus:         ['FD.minus'          nil]
        fdp_times:         ['FD.times'          nil]
        fdp_times_rel:     ['FD.plus'           ['FD.distance' '*']]
        fdp_divD:          ['FD.divD'           nil]
        fdp_divI:          ['FD.divI'           nil]
        fdp_modD:          ['FD.modD'           nil]
        fdp_modI:          ['FD.modI'           nil]
        fdp_conj:          ['FD.conj'           nil]
        fdp_disj:          ['FD.disj'           nil]
        fdp_exor:          ['FD.exor'           nil]
        fdp_impl:          ['FD.impl'           nil]
        fdp_equi:          ['FD.equi'           nil]
        fdp_nega:          ['FD.nega'           ['FD.exor' 'FD.impl' 'FD.equi']]
        fdp_sumCR:         ['FD.reified.sumC'   ArithOps]
        fdp_intR:          ['FD.refied.int'     ['FD.reified.dom']]
        fdp_card:          ['FD.reified.card'   nil]
        fdp_exactly:       ['FD.exactly'        nil]
        fdp_atLeast:       ['FD.atLeast'        nil]
        fdp_atMost:        ['FD.atMost'         nil]
        fdp_element:       ['FD.element'        nil]
        fdp_disjoint:      ['FD.disjoint'       nil]
        fdp_disjointC:     ['FD.disjointC'      nil]
        fdp_distance:      ['FD.distance'       nil]
        fdp_notEqOff:      [fdp_notEqOff        ['FD.sumC' '\\=:']]
        fdp_lessEqOff:     ['FD.lesseq'         ['FD.sumC' '=<:' '<:' '>=:'
                                                 '>:' 'FD.min' 'FD.max'
                                                 'FD.modD'
                                                 'FD.modI' 'FD.disjoint'
                                                 'FD.disjointC' 'FD.distance'
                                                ]]
        fdp_minimum:        ['FD.min'                   nil]
        fdp_maximum:        ['FD.max'                   nil]
        fdp_inter:          ['FD.inter'                 nil]
        fdp_union:          ['FD.union'                 nil]
        fdp_distinct:       ['FD.distinct'              nil]
        fdp_distinctOffset: ['FD.distinctOffset'        nil]
        fdp_subset:         [fdp_subset         ['FD.union' 'FD.inter']]
        fdp_sumC:           ['FD.sumC'          'FD.sumCN'|'FD.reified.sumC'|ArithOps]
        fdp_sumCN:          ['FD.sumCN'         ArithOps]
        fdp_sumAC:          ['FD.sumAC'         nil]

        sched_disjoint_card:['FD.schedule.disjoint'             nil]
        sched_cpIterate:    ['FD.schedule.serialized'           nil]
        sched_disjunctive:  ['FD.schedule.serializedDisj'       nil]

        fdGetMin:           ['FD.reflect.min'   nil]
        fdGetMid:           ['FD.reflect.mid'   nil]
        fdGetMax:           ['FD.reflect.max'   nil]
        fdGetDom:           ['FD.reflect.dom'   ['FD.reflect.domList']]
        fdGetCard:          ['FD.reflect.size'  nil]
        fdGetNextSmaller:   ['FD.reflect.nextSmaller'   nil]
        fdGetNextLarger:    ['FD.reflect.nextLarger'    nil]

        fdWatchSize:        ['FD.watch.size'    nil]
        fdWatchMin:         ['FD.watch.min'     nil]
        fdWatchMax:         ['FD.watch.max'     nil]

        fdConstrDisjSetUp:  [fdConstrDisjSetUp  ['condis ... end']]
        fdConstrDisj:       [fdConstrDisj       ['condis ... end']]
        fd_sumCD:           [fdp_sumCD          ['condis ... end']]
        fd_sumCCD:          [fdp_sumCCD         ['condis ... end']]
        fd_sumCNCD:         [fdp_sumCNCD        ['condis ... end']]
       )

   fun {BIPrintName X}
      case {IsAtom X}
         andthen {HasFeature BuiltinNames X}
      then BuiltinNames.X.1
      else X end
   end

   fun {BIOrigin X}
      BuiltinNames.X.2.1
   end

   fun {FormatOrigin A}
      B = {BIPrintName A}
   in
      case {HasFeature BuiltinNames B}
         andthen {BIOrigin B}\=nil
      then
         [unit
          hint(l:'Possible Origin of Procedure' m:oz({BIPrintName B}))
          line(oz({BIOrigin B}))]
      else nil end
   end

   Stars  = '%***'
   Dashes = '%**' # {Repeat WIDTH - 3 &-} # '\n'
   NumStarsLeft = {VSL Stars}

in

   %%
   %% error messages have the following format
   %% (where all fields are optional)
   %%
   %%  <label>(kind:  AVS            % almost virtual string
   %%          msg:   AVS
   %%          items: <line>*
   %%          loc:                  % added by the emulator
   %%          stack:                % added by the emulator
   %%          footer:               % yes/no
   %%          alert:                % alert procedure
   %%         )
   %%  <line> ::= hint(l:AVS m:AVS)  % both fields optional
   %%             pos(A I I)
   %%             pos(A I I _ _ _)
   %%             posNoDebug(A I I)
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
   fun
      {NewError}

      fun {DebugLoc Exc}
         D = {DebugField Exc}
      in
         {CondSelect D loc unit}
      end

      fun {DebugStack Exc}
         E = {System.get errors}
         D = {DebugField Exc}
      in
         case {HasFeature D stack}
            andthen E.'thread'>0
         then D.stack else unit end
      end

      local
         proc {ErrorAlert Format}
            case {CondSelect Format alert unit}
            of unit then skip
            elseof Alert then
               {Alert}
            end
         end

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
               E = {System.get errors}
            in {ForAll
                {Map {GetStack S E.'thread'} StarLine}
                Out}
            end
         end

         proc {ErrorFooter Out Format}
            case {CondSelect Format footer false}
            then {Out Dashes}
            else skip end
         end

      in

         proc {ErrorMsg Out Format}
            case Format
            of none then skip
            else
               {Out '\n'}
               {ErrorAlert Format}
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
               {ErrorAlert Format}
               {ErrorTitle Out Format}
               {ErrorMsgLine Out Format}
               {ErrorItems Out Format}
               {ErrorLoc Out Format}
               {ErrorStack Out Format}
               {ErrorFooter Out Format}
            end
         end
      end

      %%
      %% register of error printers
      %%

      ErrorFormatter = {NewDictionary}

      fun {ExFormatter Key}
         {Dictionary.member ErrorFormatter Key}
      end

      proc {NewFormatter Key P}
\ifdef TYPE_DEBUG
         {Type.ask.feature Key}
         {AskBinaryProc P}
\endif
         case {ExFormatter Key}
         then {`RaiseError` system(reinstallFormatter Key)}
         else
            {Dictionary.put
             ErrorFormatter
             Key
             P}
         end
      end

      fun {GetFormatter Key}
         {Dictionary.get
          ErrorFormatter
          Key}
      end

      %%
      %% formatter for errors related to the kernel language
      %%

      fun {LayoutDot R F X Op}
         case {IsDet R}
            andthen {IsRecord R}
            andthen {Length {Arity R}}>5
         then
            [hint(l:'In statement' m:'R ' # Op # ' ' # oz(F) # ' = ' # oz(X))
             hint(l:'Expected fields' m:list({Arity R} ' '))
             hint(l:'Record value' m:oz(R))]
         else
            {LayoutBin R F X Op}
         end
      end

      fun {LayoutBin X Y Z Op}
         [hint(l:'In statement' m:oz(X) # ' ' # Op # ' ' # oz(Y) # ' = ' # oz(Z))]
      end

      %%
      %% returning the dispatching
      %% and the debugging info
      %%

      fun {DebugField Exc}
         case {IsRecord Exc}
            andthen {HasFeature Exc debug}
         then Exc.debug else unit end
      end

      fun {DispatchField Exc}
         case {IsRecord Exc}
            andthen {HasFeature Exc 1}
         then Exc.1 else unit end
      end

      fun {HasDispatchField Exc}
         {IsRecord Exc}
         andthen {HasFeature Exc 1}
         andthen {IsRecord Exc.1}
      end

      %%
      %% generic formatter for exceptions
      %%

      proc {FormatExc Kind Msg Bs Exc E}
         Fs = [items loc stack footer alert]
      in
         E = {Record.make error
              case Kind==unit then
                 case Msg==unit
                 then Fs
                 else msg|Fs end
              elsecase Msg==unit
              then kind|Fs
              else kind|msg|Fs
              end}

         case Kind \= unit
         then E.kind = Kind
         else skip end

         case Msg \= unit
         then E.msg = Msg
         else skip end

         E.items  = Bs
         E.loc    = {DebugLoc Exc}
         E.stack  = {DebugStack Exc}
         E.footer = true
         E.alert  = Alert
      end

      fun {GenericFormatter Msg Exc}
         {FormatExc unit Msg [line(oz(Exc))] Exc}
      end

      %%
      %% formatter for kernel related errors
      %%

      fun {KernelFormatter Exc}

         E = {DispatchField Exc}
      in

         case E
         of kernel(type A Xs T P S)
         then
            LayOut
         in
\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
            {Type.ask.atom T}
            {Type.ask.int P}
            {Type.ask.virtualString S}
\endif
            LayOut = case A # Xs
                     of '.' # [R F X] then
                        Ls = {LayoutDot R F X '.'}
                     in
                        {Append Ls {GiveHint S}}

                     elseof '^' # [R F X] then
                        Ls = {LayoutDot R F X '^'}
                     in
                        {Append Ls {GiveHint S}}

                     elseof '+1' # [X Y] then
                        Ls =
                        [hint(l:'In statement' m:oz(X) # ' + 1 = ' # oz(Y))
                         hint(l:'Possible origin' m:'1 + ' # oz(X) # ' = ' # oz(Y))]
                     in
                        {Append Ls {GiveHint S}}

                     elseof fdTellConstraint # [X Y] then
                        Ls = [hint(l:'In statement' m:oz(X) # ' :: ' # oz(Y))]
                     in
                        {Append Ls {GiveHint S}}

                     elsecase
                        {Member A ['+' '-' '*' '/' '<' '>' '=<' '>=' '\\=']}
                     then
                        Ls = case Xs of [X Y Z] then
                                {LayoutBin X Y Z A}
                             else
                                hint(l:'In statement' m:{FormatAppl A Xs})
                                | {FormatOrigin A}
                             end
                     in
                        {Append Ls {GiveHint S}}

                     else
                        Ls =
                        hint(l:'In statement' m:{FormatAppl A Xs})
                        | {FormatOrigin A}
                     in
                        {Append Ls {GiveHint S}}
                     end

            {FormatExc
             'type error'
             unit
             {Append
              {FormatTypes T}
              case P\=0 then
                 hint(l:'At argument' m:P) | LayOut
              else LayOut end}
             Exc}

         elseof kernel(instantiation A Xs T P S) then
            LayOut
         in
\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
            {Type.ask.atom T}
            {Type.ask.int P}
            {Type.ask.virtualString S}
\endif
            local
               Ls =
               hint(l:'In statement' m:{FormatAppl A Xs})
               | {FormatOrigin A}
            in
               LayOut = {Append Ls {GiveHint S}}

            end

            {FormatExc
             'instantiation error'
             unit
             {Append
              {FormatTypes T}
              case P\=0 then
                 hint(l:'At argument' m:P) | LayOut
              else LayOut end}
             Exc}

         elseof kernel(apply X Xs) then

\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
\endif

            {FormatExc
             'error in application'
             'Application of non-procedure and non-object'
             [hint(l:'In statement' m:{FormatAppl X Xs})]
             Exc}

         elseof kernel('.' R F) then

\ifdef TYPE_DEBUG
            {AskChunkOrRec R}
            {Type.ask.feature F}
\endif

            {FormatExc
             'Error: illegal field selection'
             unit
             {LayoutDot R F _ '.'}
             Exc}

         elseof kernel(recordConstruction L As) then

\ifdef TYPE_DEBUG
            {Type.ask.literal L}
            {Type.ask.list As}

            {ForAll As
             proc {$ A}
                {Type.ask.pair A}
                {Type.ask.feature A.1}
             end}
\endif

            {FormatExc
             'Error: duplicate fields'
             'Duplicate fields in record construction'
             [hint(l:'Label' m:oz(L))
              hint(l:'Feature-field Pairs' m:list(As ' '))]
             Exc}

         elseof kernel(arity P Xs) then

\ifdef TYPE_DEBUG
            {AskProcOrObject P}
            {Type.ask.list Xs}
\endif

            {FormatExc
             'Error: illegal number of arguments'
             unit
             [hint(l:'In statement' m:{FormatAppl P Xs})
              hint(l:'Expected'
                   m:case {IsProcedure P} then {Procedure.arity P} else 1 end
                     # ' argument(s)')
              hint(l:'Found' m:{Length Xs})]
             Exc}

         elseof kernel(noElse Pos) then

\ifdef TYPE_DEBUG
            {Type.ask.int Pos}
\endif
            {FormatExc
             'Error: conditional failed'
             'Missing else clause'
             [hint(l:'At line' m:Pos)]
             Exc}

         elseof kernel(noElse Pos A) then

\ifdef TYPE_DEBUG
            {Type.ask.int Pos}
\endif

            {FormatExc
             'Error: conditional failed'
             'Missing else clause'
             [hint(l:'At line' m:Pos)
              hint(l:'Matching' m:oz(A))]
             Exc}

         elseof kernel(boolCaseType Pos) then

\ifdef TYPE_DEBUG
            {Type.ask.int Pos}
\endif

            {FormatExc
             'Error: boolean conditional failed'
             'Non-boolean value found'
             [hint(l:'At line' m:Pos)]
             Exc}

            %%
            %% ARITHMETICS
            %%

         elseof kernel(div0 X) then

            {FormatExc
             'division by zero error'
             unit
             [hint(l:'In statement' m:oz(X) # ' div 0' # ' = _')]
             Exc}

         elseof kernel(mod0 X) then

            {FormatExc
             'division by zero error'
             unit
             [hint(l:'In statement' m:oz(X) # ' mod 0' # ' = _')]
             Exc}

            %%
            %% ARRAYS AND DICTIONARIES
            %%

         elseof kernel(dict D K) then

            Ks
         in
\ifdef TYPE_DEBUG
            {Type.ask.dictionary D}
            {Type.ask.feature K}
\endif

            Ks = {Dictionary.keys D}

            {FormatExc
             'Error: Dictionary'
             'Key not found'
             [hint(l:'Dictionary' m:oz(D))
              hint(l:'Key found'  m:oz(K))
              hint(l:'Legal keys' m:oz(Ks))]
             Exc}

         elseof kernel(array A I) then

\ifdef TYPE_DEBUG
            {Type.ask.array A}
            {Type.ask.int I}
\endif

            {FormatExc
             'Error: Array'
             'Index out of range'
             [hint(l:'Array' m:oz(A))
              hint(l:'Index Found' m:I)
              hint(l:'Legal Range' m:{Array.low A} # ' - ' # {Array.high A})]
             Exc}

            %%
            %% REPRESENTATION FAULT
            %%

         elseof kernel(stringNoFloat S) then

\ifdef TYPE_DEBUG
            {Type.ask.string S}
\endif

            {FormatExc
             'Error: representation fault'
             'Conversion to float failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoInt S) then

\ifdef TYPE_DEBUG
            {Type.ask.string S}
\endif

            {FormatExc
             'Error: representation fault'
             'Conversion to integer failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoAtom S) then

\ifdef TYPE_DEBUG
            {Type.ask.string S}
\endif
            {FormatExc
             'Error: representation fault'
             'Conversion to atom failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoValue S) then

\ifdef TYPE_DEBUG
            {Type.ask.string S}
\endif

            {FormatExc
             'Error: representation fault'
             'Conversion to Oz value failed'
             [hint(l:'String'  m:'\"' # S # '\"')]
             Exc}

         elseof kernel(globalState What) then

            Msg
         in
\ifdef TYPE_DEBUG
            {Type.ask.atom What}
\endif

            Msg  = case What
                   of     array  then 'Assignment to global array'
                   elseof dict   then 'Assignment to global dictionary'
                   elseof cell   then 'Assignment to global cell'
                   elseof io     then 'Input/Output'
                   elseof object then 'Assignment to global object'
                   elseof 'lock' then 'Request of global lock'
                   else What end

            {FormatExc
             'Error: space hierarchy'
             Msg # ' from local space'
             nil
             Exc}

         elseof kernel(spaceMerged S) then

\ifdef TYPE_DEBUG
            {Type.ask.space S}
\endif

            {FormatExc
             'Error: Space'
             'Space already merged'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceSuper S) then

\ifdef TYPE_DEBUG
            {Type.ask.space S}
\endif

            {FormatExc
             'Error: Space'
             'Merge of superordinated space'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceParent S) then

\ifdef TYPE_DEBUG
            {Type.ask.space S}
\endif

            {FormatExc
             'Error: Space'
             'Current space must be parent space'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceNoChoice S) then

\ifdef TYPE_DEBUG
            {Type.ask.space S}
\endif

            {FormatExc
             'Error: Space'
             'No choices left'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(portClosed P) then

\ifdef TYPE_DEBUG
            {Type.ask.port P}
\endif

            {FormatExc
             'Error: Port'
             'Port already closed'
             [hint(l:'Port' m:oz(P))]
             Exc}

         elseof kernel(terminate) then

            none

         elseof kernel(block T) then

\ifdef TYPE_DEBUG
            {Type.ask.'thread' T}
\endif

            {FormatExc
             'Error: Thread'
             'Purely sequential thread blocked'
             [hint(l:'Thread' m:oz(T))]
             Exc}

         else
            {GenericFormatter 'Kernel' Exc}
         end
      end


      %%
      %% failure formatter
      %%

      fun {FailureFormatter Exc}
         D = {DebugField Exc}
         T = 'failure'
      in

         case {Not {HasFeature D info}} then

            {GenericFormatter T Exc}

         elsecase D.info
         of 'fail' then

            {FormatExc
             T
             unit
             [hint(l:'Tell' m:'fail')]
             Exc}

         elseof apply(A Xs) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
            {Type.ask.list Xs}
\endif

            {FormatExc
             T
             unit
             case A # Xs
             of '^' # [R F] then
                [hint(l:'Tell' m:oz(R) # ' ^ ' # oz(F) # ' = _')]
             elseof '=' # [X Y] then
                [hint(l:'Tell' m:oz(X) # ' = ' # oz(Y))]
             elseof fdPutList # [X Y] then
                [hint(l:'Tell' m:oz(X) # ' :: ' # oz(Y))]
             elseof fdPutGe # [X Y] then
                [hint(l:'Tell' m:oz(X) # ' >: ' # oz(Y))]
             elseof fdPutLe # [X Y] then
                [hint(l:'Tell' m:oz(X) # ' <: ' # oz(Y))]
             elseof fdPutNot # [X Y] then
                [hint(l:'Tell' m:oz(X) # ' \\=: ' # oz(Y))]
             else
                hint(l:'In statement' m:{FormatAppl A Xs})
                | {FormatOrigin A}
             end
             Exc}

         elseof eq(X Y) then

            {FormatExc
             T unit
             [hint(l:'Tell' m:oz(X) # ' = ' # oz(Y))]
             Exc}

         elseof tell(X Y) then

            {FormatExc
             T unit
             [hint(l:'Tell' m:oz(X) # ' = ' # oz(Y))
              hint(l:'Store' m:oz(X))]
             Exc}

         else

            {FormatExc
             T unit
             [hint(l:'??? ' m:oz(D.info))]
             Exc}
         end
      end

      %%
      %% formatter for object-related errors
      %%

      fun {ObjectFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in object system'
      in

         case E
         of object('<-' State A V) then
            {FormatExc
             T unit
             [hint(l:'In statement' m:oz(A) # ' <- ' # oz(V))
              hint(l:'Attribute does not exist' m:oz(A))
              hint(l:'Expected Attribute(s)' m:list({Arity State} ' '))]
             Exc}

         elseof object('@' State A) then
            {FormatExc
             T unit
             [hint(l:'In statement' m:'@' # oz(A) # ' = _')
              hint(l:'Attribute does not exist' m:oz(A))
              hint(l:'Expected attribute(s)' m:list({Arity State} ' '))]
             Exc}
         elseof object(sharing C1 C2 A L) then
            {FormatExc T
             'Classes not ordered by inheritance'
             [hint(l:'Classes' m:C1 # ' and ' # C2)
              hint(l:'Shared ' # A m:oz(L) # ' (is not redefined)')]
             Exc}
         elseof object(order (A#B)|Xr) then
            fun {Rel A B} A # ' < ' # B end
         in
            {FormatExc T
             'Classes cannot be ordered'
             hint(l:'Relation found' m:{Rel A B})
             | {Map Xr fun {$ A#B} hint(m:{Rel A B}) end}
             Exc}
         elseof object(lookup C R) then
            L1 = hint(l:'Class'   m:oz(C))
            L2 = hint(l:'Message' m:oz(R))
            H  = {GiveHint 'Method undefined and no otherwise method given'}
         in
            {FormatExc T
             'Method lookup in message sending'
             L1|L2|H
             Exc}
         elseof object(final CParent CChild) then
            L2 = hint(l:'Final class used as parent' m:CParent)
            L3 = hint(l:'Class to be created' m:CChild)
            H  = {GiveHint 'remove prop final from parent class or change inheritance relation'}
         in
            {FormatExc T
             'Inheritance from final class'
             L2|L3|H
             Exc}
         elseof object(inheritanceFromNonClass
                       CParent CChild) then
            {FormatExc T
             'Inheritance from non-class'
             [hint(l:'Non-class used as parent' m:oz(CParent))
              hint(l:'Class to be created' m:CChild)]
             Exc}

         elseof object(arityMismatchDefaultMethod L)
         then
            {FormatExc T
             'Arity mismatch for method with defaults'
             [hint(l:'Unexpected feature' m:oz(L))]
             Exc}

         elseof object(slaveNotFree)
         then

            {FormatExc T
             'Method becomeSlave'
             [hint(l:'Slave is not free')]
             Exc}

         elseof object(slaveAlreadyFree) then

            {FormatExc T
             'Method free'
             [hint(l:'Slave is already free')]
             Exc}

         elseof object(locking O) then
            {FormatExc T
             'Attempt to lock unlockable object'
             [hint(l:'Object' m:oz(O))]
             Exc}

         elseof object(fromFinalClass C O) then
            {FormatExc T 'Final class not allowed'
             [hint(l:'Final class' m:C)
              hint(l:'Operation'   m:O)]
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      fun {OFSFormatter Exc}
         E = {DispatchField Exc}
         T = 'Error: records'
      in
         case E
         of record(width A Xs P S) then

\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
            {Type.ask.int P}
            {Type.ask.virtualString S}
\endif

            {FormatExc
             T unit
             hint(l:'At argument' m:P)
             | hint(l:'Statement' m:{FormatAppl A Xs})
             | {GiveHint S}
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for search errors
      %%

      fun {SearchFormatter Exc}
         T = 'Error: Search'
      in
         case {DispatchField Exc}
         of search(nyi) then
            {FormatExc T
             'Object not yet initialized'
             nil
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for finite domain related errors
      %%

      fun {FDFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in finite domain system'
      in

         case E
         of fd(scheduling A Xs T P S) then

\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
            {Type.ask.atom T}
            {Type.ask.int P}
            {Type.ask.virtualString S}
\endif

            {FormatExc
             T unit
             hint(l:'At argument' m:P)
             | {Append
                {FormatTypes T}
                hint(l:'In statement' m:{FormatAppl A Xs})
                | {Append {FormatOrigin A} {GiveHint S}}}
             Exc}

         elseof fd(noChoice A Xs P S) then

\ifdef TYPE_DEBUG
            {Type.ask.list Xs}
            {Type.ask.int P}
            {Type.ask.virtualString S}
\endif

            {FormatExc
             T unit
             hint(l:'At argument' m:P)
             | hint(l:'In statement' m:{FormatAppl A Xs})
             | {Append {FormatOrigin A} {GiveHint S}}
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for errors related to the foreign function interface
      %%

      fun {ForeignFormatter Exc}
         E = {DispatchField Exc}
         T = 'Error: Foreign'
      in

         case E
         of foreign(cannotFindFunction F A H) then
\ifdef TYPE_DEBUG
            {Type.ask.atom F}
            {Type.ask.int A}
            {Type.ask.int H}
\endif

            {FormatExc T
             'Cannot find foreign function'
             [hint(l:'Function name' m:F)
              hint(l:'Arity' m:A)
              hint(l:'Handle' m:H)]
             Exc}

         [] foreign(dlOpen F S) then
\ifdef TYPE_DEBUG
            {Type.ask.virtualString F}
\endif
            {FormatExc T
             'Cannot load foreign function file'
             [hint(l:'File name' m:F)
              hint(l:'Error number' m:S)]
             Exc}

         [] foreign(dlClose N) then

            {FormatExc T
             'Cannot unload foreign function file'
             [hint(l:'File handle' m:oz(N))]
             Exc}

         [] foreign(linkFiles As) then

            {FormatExc T
             'Cannot link object files'
             [hint(l:'File names' m:list(As ' '))]
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for system related errors
      %%

      fun {SystemFormatter Exc}

         E = {DispatchField Exc}
         T = 'system error'
      in

         case E
         of system(parameter P) then

            {FormatExc T
             unit
             [hint(l:'Illegal system parameter ' m:oz(P))]
              Exc}

         elseof system(limitInternal S) then

\ifdef TYPE_DEBUG
            {Type.ask.virtualString S}
\endif

            {FormatExc T
             unit
             [hint(l:'Internal System Limit' m:S)]
             Exc}

         elseof system(limitExternal S) then

\ifdef TYPE_DEBUG
            {Type.ask.virtualString S}
\endif

            {FormatExc T
             unit
             [hint(l:'External system limit' m:S)]
             Exc}

         elseof system(fallbackInstalledTwice A) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
\endif

            {FormatExc
             T unit
             [hint(l:'Fallback procedure installed twice' m:A)]
             Exc}

         elseof system(fallbackNotInstalled A) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
\endif

            {FormatExc
             T unit
             [hint(l:'Fallback procedure not installed' m:A)]
             Exc}

         elseof system(builtinUndefined A) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
\endif

            {FormatExc T
             'Undefined builtin'
             [hint(l:'Requested' m:A)]
             Exc}

         elseof system(builtinArity A F E) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
            {Type.ask.int F}
            {Type.ask.int E}
\endif

            {FormatExc T
             'Illegal arity in Oz-declaration'
             [hint(l:'Builtin' m:A)
              hint(l:'Found' m:F)
              hint(l:'Expected' m:E)]
             Exc}

         elseof system(inconsistentArity A F E) then

\ifdef TYPE_DEBUG
            {Type.ask.atom A}
            {Type.ask.int F}
            {Type.ask.int E}
\endif

            {FormatExc T
             'Illegal arity in emulator-declaration'
             [hint(l:'Builtin' m:A)
              hint(l:'Found' m:F)
              hint(l:'Expected' m:E)]
             Exc}

         elseof system(inconsistentFastcall) then

            {FormatExc T
             'Internal inconsistency'
             [hint(l:'Inconsistency in optimized application')
              hint(l:'Maybe due to previous toplevel failure')]
             Exc}

         elseof system(fatal S) then

\ifdef TYPE_DEBUG
            {Type.ask.virtualString S}
\endif

            {FormatExc
             T
             'Fatal exception'
             [line(S)
              line({BugReport})]
             Exc}

         elseof system(virtualStringToValue VS) then

            {FormatExc
             'Representation fault'
             'System.virtualStringToValue failed'
             [hint(l:'Virtual String' m:VS)]
             Exc}

         elseof system(reinstallFormatter Key) then

\ifdef TYPE_DEBUG
            {Type.ask.atom Key}
\endif

            {FormatExc
             T
             'Registration of error formatter failed'
             [hint(l:'Exception name already in use:' m:Key)]
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for tk related errors
      %%

      fun {TkFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in Tk module'
      in

         case E
         of tk(wrongParent O M) then
\ifdef TYPE_DEBUG
            {Type.ask.object O}
            {Type.ask.record M}
\endif
            {FormatExc T
             'Wrong Parent'
             [hint(l:'Object application' m:'{' # oz(O) # ' ' # oz(M) # '}')]
             Exc}

         elseof tk(alreadyInitialized O M) then
\ifdef TYPE_DEBUG
            {Type.ask.object O}
            {Type.ask.record M}
\endif
            {FormatExc T
             'Object already initialized'
             [hint(l:'Object application' m:'{' # oz(O) # ' ' # oz(M) # '}')]
             Exc}

         elseof tk(alreadyClosed O M) then
\ifdef TYPE_DEBUG
            {Type.ask.object O}
            {Type.ask.record M}
\endif
            {FormatExc T
             'Window already closed'
             [hint(l:'Object application' m:'{' # oz(O) # ' ' # oz(M) # '}')]
              Exc}

         elseof tk(alreadyClosed O) then
\ifdef TYPE_DEBUG
            {Type.ask.object O}
\endif
            {FormatExc T
             'Window already closed'
             [hint(l:'Object' m:oz(O))]
             Exc}

         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for open programming errors
      %%

      fun {OpenFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in Open module'
      in
         case E
         of open(What O M) then
\ifdef TYPE_DEBUG
            {Type.ask.atom What}
            {Type.ask.object O}
\endif
            {FormatExc T
             case What
             of alreadyClosed then
                'Object already closed'
             [] alreadyInitialized then
                'Object already initialized'
             [] illegalFlags then
                'Illegal value for flags'
             [] illegalModes then
                'Illegal value for mode'
             [] nameOrUrl then
                'Exactly one of \'name\' or \'url\' feature needed'
             [] urlIsReadOnly then
                'Only reading access to url-files allowed'
             else 'Unknown' end
             [hint(l:'Object Application'
                   m:'{' # oz(O) # ' ' # oz(M) # '}')]
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for operating system programming errors
      %%

      fun {OSFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in OS module'
      in
         case E
         of os(K N S) then
\ifdef TYPE_DEBUG
            {Type.ask.atom K}
            {Type.ask.int N}
            {Type.ask.virtualString S}
\endif

            case K
            of os then
               {FormatExc T
                'Operating system error'
                [hint(l:'Error number' m:N)
                 hint(l:'Description' m:S)]
                Exc}
            [] host then
               {FormatExc T
                'Network Error'
                [hint(l:'Error number' m:N)
                 hint(l:'Description' m:S)]
                Exc}
            else
               {GenericFormatter T Exc}
            end
         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% formatter for errors related to distributed programming
      %%

      fun {DPFormatter Exc}
         E = {DispatchField Exc}
         T = 'Error: distributed programming'
      in
         case E
         of dp(save(components:C found:F call:Call)) then
            {FormatExc
             T
             unit
             [hint(l:'In statement' m:'{'# list(Call ' ')#'}')
              hint(l:'Components authorized' m:oz(C))
              hint(l:'Components found' m:oz(F))]
             Exc}
         elseof dp(save(resources:R found:F call:Call)) then
            {FormatExc
             T
             unit
             [hint(l:'In statement' m:'{'#list(Call ' ')#'}')
              hint(l:'Resources authorized' m:oz(R))
              hint(l:'Resources found' m:oz(F))]
             Exc}
         elseof dp(save(badArg call:Call)) then
            {FormatExc
             'Wrong Type'
             unit
             [hint(l:'In statement' m:'{'#list(Call ' ')#'}')
              hint(l:'At 3rd argument' m:Call.2.2.2.1)
              hint(l:'Expected' m:'virtual string or record')]
             Exc}
         elseof dp(save(resources Filename Resources)) then
            {FormatExc
             'Resources found during save'
             unit
             [hint(l:'Filename'  m:Filename)
              hint(l:'Resources' m:oz(Resources))]
             Exc}
         elseof dp(save nogoods NoGoods) then
            {FormatExc
             'Non-distributables found during save'
             unit
             [hint(l:'Non-distributables' m:oz(NoGoods))]
             Exc}
         elseof dp('export' nogoods NoGoods) then
            {FormatExc
             'Non-distributables found during export'
             unit
             [hint(l:'Non-distributables' m:oz(NoGoods))]
             Exc}
         elseof dp(load versionMismatch ComponentName VerExpected VerGot) then
            {FormatExc
             'Version mismatch when loading of pickle'
             unit
             [hint(l:'Pickle name'      m:ComponentName)
              hint(l:'Version expected' m:VerExpected)
              hint(l:'Version got'      m:VerGot)]
             Exc}
         elseof dp(send nogoods NoGoods) then
            {FormatExc
             'Trying to send non-distributables to port'
             unit
             [hint(l:'Non-distributables' m:oz(NoGoods))]
             Exc}
         elseof dp(unify nogoods NoGoods) then
            {FormatExc
             'Trying to unify distributed variable with non-distributables'
             unit
             [hint(l:'Non-distributables' m:oz(NoGoods))]
             Exc}
         elseof dp(connection(illegalTicket V)) then
            {FormatExc
             'Illegal ticket for connection'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         elseof dp(connection(refusedTicket V)) then
            {FormatExc
             'Ticket refused for connection'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      fun {PanelFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in Oz Panel'
      in
         case E
         of panel(option OM) then
            {FormatExc T
             'Illegal option specification'
             [hint(l:'Message'
                   m:oz(OM))]
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      fun {ExplorerFormatter Exc}
         E = {DispatchField Exc}
         T = 'error in Oz Explorer'
      in
         case E
         of explorer(Kind OM) then
            {FormatExc T
             case Kind
             of actionAdd then 'Illegal action addition'
             [] actionDel then 'Illegal action deletion'
             [] option    then 'Illegal option specification'
             end
             [hint(l:'Message'
                   m:oz(OM))]
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      fun {GumpFormatter Exc}
         E = {DispatchField Exc}
         T = 'Gump Scanner error'
      in
         case E of gump(fileNotFound FileName) then
            {FormatExc T
             'Could not open file'
             [hint(l: 'File name' m: oz(FileName))]
             Exc}
         else
            {GenericFormatter T Exc}
         end
      end

      %%
      %% error print manager
      %%

      fun {FormatOzError Exc}
         T = 'Error: unhandled exception'
      in
         case {IsRecord Exc} then
            LL={Label Exc}
         in
            case LL==failure then
               {{GetFormatter failure} Exc}
            elsecase LL==error orelse LL==system then
               case {HasDispatchField Exc} then
                  Key = {Label {DispatchField Exc}}
               in
                  case {ExFormatter Key}
                  then {{GetFormatter Key} Exc}
                  else {GenericFormatter T Exc}
                  end
               else
                  {GenericFormatter T Exc}
               end
            else
               Key = {Label Exc}
            in
               case {ExFormatter Key}
               then {{GetFormatter Key} Exc}
               else {GenericFormatter T Exc}
               end
            end
         else
            {GenericFormatter T Exc}
         end
      end

      proc {ReRaise Exc ExcExc}
         {ErrorMsgDebug
          LineOutput
          error(title: 'Unable to Print Error Message'
                items:[hint(l:'Initial exception' m:oz(Exc))
                       hint(l:'Format exception Kind'  m:{Label ExcExc})
                       hint(l:'Format exception' m:oz({DispatchField ExcExc}))
                       line({BugReport})]
                loc:   {DebugLoc Exc}
                stack: {DebugStack Exc}
               )}
      end

      %%
      %% register procedure OzError as Handler in the emulator
      %% and initialize builtin error Formatters
      %%

      local
         proc {DefExHdl Exc}
            try
               {Thread.setThisPriority high}
               {ErrorMsgDebug LineOutput {FormatOzError Exc}}
            catch X then
               {ReRaise Exc X}
            end
            %% terminate local computation
            case {OnToplevel} then skip else fail end
         end
      in
         {{`Builtin` setDefaultExceptionHandler 1} DefExHdl}
      end

      OzError = {{`Builtin` getDefaultExceptionHandler 1}}

      %%
      %% register formatters
      %%

      {NewFormatter failure     FailureFormatter}
      {NewFormatter kernel      KernelFormatter}
      {NewFormatter object      ObjectFormatter}
      {NewFormatter fd          FDFormatter}
      {NewFormatter record      OFSFormatter}
      {NewFormatter search      SearchFormatter}
      {NewFormatter tk          TkFormatter}
      {NewFormatter os          OSFormatter}
      {NewFormatter open        OpenFormatter}
      {NewFormatter system      SystemFormatter}
      {NewFormatter foreign     ForeignFormatter}
      {NewFormatter dp          DPFormatter}
      {NewFormatter panel       PanelFormatter}
      {NewFormatter explorer    ExplorerFormatter}
      {NewFormatter gump        GumpFormatter}

   in

      error(formatter: p(put:     NewFormatter
                         get:     GetFormatter
                         exists:  ExFormatter
                         generic: GenericFormatter)

            formatExc: FormatOzError
            formatLine:AlmostVSToVS
            formatPos: PosToVS

            printExc:  OzError

            msg:       ErrorMsg
            msgDebug:  ErrorMsgDebug
           )
   end

end
