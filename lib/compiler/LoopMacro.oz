functor
import
   Macro(
      makeNamedVar      : NewNamedVar
      macroExpand       : MacroExpand
      )
export
   LoopExpander
define
   LEAVE_EXCEPTION = {NewNamedVar 'Loop_Leave'}
   NEXT_EXCEPTION  = {NewNamedVar 'Loop_Next'}
   ACCUMULATOR     = {NewNamedVar 'Loop_Accu'}
   CALL_NEWNAME    = fOpApply('Name.new' nil unit)
   LOOP            = {NewNamedVar 'Loop_Proc'}
   fun {LoopExpander fLoop(Body Coord)=Form Env}
      Fors = {NewCell nil}
      Type = {NewCell unit}
      Named= {NewCell unit}
      proc {DeclType T}
         if {Access Type}\=unit then
            {Exception.raiseError
             'loop'(conflictingAccumulation(Form))}
         else
            {Assign Type T}
         end
      end
      fun {ForExpander Form Env}
         T in {Exchange Fors T Form|T}
         <<'`' skip>>
      end
      fun {LeaveExpander fMacro(_|L _) _}
         case L of nil then
            <<'`' raise <<',' LEAVE_EXCEPTION>> end>>
         [] [V] then
            <<'`' case <<',' V>> of
                     'loop'(leave:L next:_)
                  then raise L end end>>
         end
      end
      fun {NextExpander fMacro(_|L _) _}
         case L of nil then
            <<'`' raise <<',' NEXT_EXCEPTION>> end>>
         [] [V] then
            <<'`' case <<',' V>> of
                     'loop'(leave:_ next:L)
                  then raise L end end>>
         end
      end
      fun {CollectExpander fMacro([_ E] _) _}
         {DeclType 'list'}
         H  = {NewNamedVar 'H'}
         T1 = {NewNamedVar 'T1'}
         T2 = {NewNamedVar 'T2'}
      in
         <<'`' local <<',' H>> <<',' T1>> <<',' T2>>
               in
                  <<',' fOpApplyStatement(
                           'Cell.exchange'
                           [ACCUMULATOR
                            <<'`' <<',' H>>#<<',' T1>> >>
                            <<'`' <<',' H>>#<<',' T2>> >>]
                           unit) >>
                  <<',' T1>> = (<<',' E>> | <<',' T2>>)
                  skip
               end >>
      end
      fun {AppendExpander fMacro([_ E] _) _}
         {DeclType 'list'}
         H  = {NewNamedVar 'H'}
         T1 = {NewNamedVar 'T1'}
         T2 = {NewNamedVar 'T2'}
      in
         <<'`' local <<',' H>> <<',' T1>> <<',' T2>>
               in
                  <<',' fOpApplyStatement(
                           'Cell.exchange'
                           [ACCUMULATOR
                            <<'`' <<',' H>>#<<',' T1>> >>
                            <<'`' <<',' H>>#<<',' T2>> >>]
                           unit) >>
                  <<',' fOpApplyStatement(
                           'List.append'
                           [E T2 T1]
                           unit) >>
               end >>
      end
      fun {CountExpander fMacro([_ E] _) _}
         {DeclType 'counter'}
         <<'`' if <<',' E>> then N M in
                  <<',' fOpApplyStatement(
                           'Cell.exchange'
                           [ACCUMULATOR <<'`' N>> <<'`' M>>]
                           unit) >>
                  M = N+1
               end >>
      end
      fun {SumExpander fMacro([_ E] _) _}
         {DeclType 'counter'}
         K = {NewNamedVar 'N'}
      in
         <<'`' local <<',' K>> = <<',' E>> in
                  local N M in
                     <<',' fOpApplyStatement(
                              'Cell.exchange'
                              [ACCUMULATOR <<'`' N>> <<'`' M>>]
                              unit) >>
                     M = N + <<',' K>>
                  end
               end >>
      end
      fun {MaximizeExpander fMacro([_ E] _) _}
         {DeclType 'maximizer'}
         K = {NewNamedVar 'N'}
      in
         <<'`' local <<',' K>> = <<',' E>> in
                  local N M in
                     <<',' fOpApplyStatement(
                              'Cell.exchange'
                              [ACCUMULATOR <<'`' N>> <<'`' M>>]
                              unit) >>
                     if N==unit then M = <<',' K>>
                     elseif N < <<',' K>> then M = <<',' K>>
                     else M = N end
                  end
               end >>
      end
      fun {MinimizeExpander fMacro([_ E] _) _}
         {DeclType 'minimizer'}
         K = {NewNamedVar 'N'}
      in
         <<'`' local <<',' K>> = <<',' E>> in
                  local N M in
                     <<',' fOpApplyStatement(
                              'Cell.exchange'
                              [ACCUMULATOR <<'`' N>> <<'`' M>>]
                              unit) >>
                     if N==unit then M = <<',' K>>
                     elseif N > <<',' K>> then M = <<',' K>>
                     else M = N end
                  end
               end >>
      end
      fun {NamedExpander fMacro([_ E] _) _}
         if {Access Named}\=unit then
            {Exception.raiseError
             'loop'(multipleNamedClauses)}
         elsecase E of fVar(_ _) then
            {Assign Named E}
         else
            {Exception.raiseError
             'loop'(badNamedClause)}
         end
         SKIP
      end
      fun {WhileExpander fMacro([_ E] _) _}
         <<'`' if <<',' E>> then skip else
                  raise <<',' LEAVE_EXCEPTION>> end
               end>>
      end
      fun {UntilExpander fMacro([_ E] _) _}
         <<'`' if <<',' E>> then
                  raise <<',' LEAVE_EXCEPTION>> end
               end>>
      end
      LocalEnv =
      o('for'    : ForExpander
        leave    : LeaveExpander
        next     : NextExpander
        collect  : CollectExpander
        append   : AppendExpander
        count    : CountExpander
        sum      : SumExpander
        maximize : MaximizeExpander
        minimize : MinimizeExpander
        named    : NamedExpander
        while    : WhileExpander
        until    : UntilExpander
       )
      %%
      fun {ForToBasic fMacro(_|L _)}
         case L
         of fEq(X E _)|T then {ForWhileToBasic X|fAtom('=' unit)|E|T}
         [] _|fAtom('from'     _)|_ then {ForCountToBasic   L}
         [] _|fAtom('to'       _)|_ then {ForCountToBasic   L}
         [] _|fAtom('by'       _)|_ then {ForCountToBasic   L}
         [] _|fATom('downfrom' _)|_ then {ForCountToBasic   L}
         [] _|fAtom('in'       _)|_ then {ForElementToBasic L}
         end
      end
      TRUE = <<'`' true>>
      SKIP = <<'`' skip>>
      ONE  = <<'`' 1>>
      VarsForInitValues = {NewCell SKIP}
      proc {RegisterInit Var Val}
         Vs
      in
         {Exchange VarsForInitValues Vs fAnd(fEq(Var Val unit) Vs)}
      end
      fun {ForWhileToBasic X|fAtom('=' _)|E|L}
         case
            case L
            of nil then
               'for'(X init:E while:TRUE next:X)
            [] [fAtom('while' _) W fAtom('next' _) N] then
               'for'(X init:E while:W next:N)
            [] [fAtom('while' _) W] then
               'for'(X init:E while:W next:X)
            [] [fAtom('next' _) N] then
               'for'(X init:E while:TRUE next:N)
            end
         of 'for'(X init:Init while:While next:Next) then
            iterator(
               var:X init:Init while:While next:Next lvars:SKIP)
         end
      end
      fun {ForCountToBasic X|L}
         case
            case L
            of [fAtom('from' _) I fAtom('to' _) J fAtom('by' _) K] then
               'for'(X 'from':I to:J by:K)
            [] [fAtom('from' _) I fAtom('by' _) K] then
               'for'(X 'from':I to:SKIP by:K)
            [] [fAtom('from' _) I fAtom('to' _) J] then
               'for'(X 'from':I to:J by:ONE)
            [] [fAtom('from' _) I] then
               'for'(X 'from':I to:SKIP by:ONE)
            [] [fAtom('to' _) J fAtom('by' _) K] then
               'for'(X 'from':ONE to:J by:K)
            [] [fAtom('to' _) J] then
               'for'(X 'from':ONE to:J by:ONE)
               %%
            [] [fAtom('from' _) I fAtom('downto' _) J fAtom('by' _) K] then
               'for'(X 'from':I downto:J by:K)
            [] [fAtom('downfrom' _) I fAtom('to' _) J fAtom('by' _) K] then
               'for'(X 'from':I downto:J by:K)
            [] [fAtom('downfrom' _) I fAtom('downto' _) J fAtom('by' _) K] then
               'for'(X 'from':I downto:J by:K)
            [] [fAtom('downfrom' _) I fAtom('by' _) K] then
               'for'(X 'from':I downto:SKIP by:K)
            [] [fAtom('downfrom' _) I fAtom('to' _) J] then
               'for'(X 'from':I downto:J by:ONE)
            [] [fAtom('downfrom' _) I fAtom('downto' _) J] then
               'for'(X 'from':I downto:J by:ONE)
            [] [fAtom('downfrom' _) I] then
               'for'(X 'from':I downto:SKIP by:ONE)
            end
         of 'for'(X 'from':I to:J by:K) then
            II = {NewNamedVar 'I'}
            JJ = {NewNamedVar 'J'}
            KK = {NewNamedVar 'K'}
         in
            {RegisterInit II I}
            {RegisterInit JJ J}
            {RegisterInit KK K}
            iterator(
               var      : X
               init     : II
               while    : if J==SKIP then TRUE else <<'`' <<',' X>> =< <<',' JJ>>>> end
               next     : <<'`' <<',' X>> + <<',' KK>>>>
               lvars    : SKIP
               )
         [] 'for'(X 'from':I downto:J by:K) then
            II = {NewNamedVar 'I'}
            JJ = {NewNamedVar 'J'}
            KK = {NewNamedVar 'K'}
         in
            {RegisterInit II I}
            {RegisterInit JJ J}
            {RegisterInit KK K}
            iterator(
               var      : X
               init     : II
               while    : if J==SKIP then TRUE else <<'`' <<',' X>> >= <<',' JJ>>>> end
               next     : <<'`' <<',' X>> - <<',' KK>>>>
               lvars    : SKIP
               )
         end
      end
      fun {ForElementToBasic [X fAtom('in' _) L]}
         LL = {NewNamedVar 'L'}
      in
         iterator(
            var         : LL
            init        : L
            while       : <<'`' <<',' LL>>\=nil>>
            next        : <<'`' <<',' LL>>.2>>
            lvars       : <<'`' <<',' X>> = <<',' LL>>.1>>
            )
      end
      %% the expansion of the body will result in side effects
      %% to the cells introduced earlier
      XBody = {MacroExpand fMacrolet(LocalEnv Body) Env}
      %%
      Basics = {Map {Reverse {Access Fors}} ForToBasic}
   in
      <<'`' local
               <<',' {Access VarsForInitValues}>>
               <<',' LEAVE_EXCEPTION>> = <<',' CALL_NEWNAME>>
               <<','  NEXT_EXCEPTION>> = <<',' CALL_NEWNAME>>
               <<',' if {Access Named}\=unit then
                        <<'`' <<',' {Access Named}>>
                           = 'loop'(leave:<<',' LEAVE_EXCEPTION>>
                                    next :<<','  NEXT_EXCEPTION>>)>>
                     else
                        <<'`' skip>>
                     end >>
               <<',' case {Access Type}
                     of unit then SKIP
                     [] 'list' then H = {NewNamedVar 'H'} in
                        <<'`' local <<',' H>> in
                                 <<',' fEq(ACCUMULATOR
                                           fOpApply('Cell.new' [<<'`' <<',' H>>#<<',' H>>>>] unit)
                                           unit) >>
                              end >>
                     [] 'counter' then
                        fEq(ACCUMULATOR
                            fOpApply('Cell.new' [<<'`' 0>>] unit)
                            unit)
                     else
                        fEq(ACCUMULATOR
                            fOpApply('Cell.new' [<<'`' unit>>] unit)
                            unit)
                     end >>
               <<',' fProc(
                        LOOP {Map Basics fun {$ I} I.var end}
                        local
                           Cond = {FoldR Basics
                                   fun {$ I B}
                                      W = I.while
                                   in
                                      if W==TRUE then B
                                      elseif B==TRUE then W
                                      else <<'`' <<',' W>> andthen <<',' B>>>> end
                                   end TRUE}
                           Lvars = {FoldR Basics fun {$ I Vs} fAnd(I.lvars Vs) end SKIP}
                           Inner = <<'`' local
                                            <<',' Lvars>>
                                         in
                                            try <<',' XBody>>
                                            catch <<',' fEscape(NEXT_EXCEPTION unit)>> then skip end
                                            <<',' fApply(
                                                     LOOP
                                                     {Map Basics fun {$ I} I.next end}
                                                     Coord) >>
                                         end >>
                        in
                           if Cond==TRUE then Inner else
                              <<'`' if <<',' Cond>> then <<',' Inner>> end>>
                           end
                        end
                        nil Coord) >>
            in
               try <<',' fApply(
                            LOOP {Map Basics fun {$ I} I.init end} Coord) >>
               catch <<',' fEscape(LEAVE_EXCEPTION unit)>> then skip end
               <<',' case {Access Type}
                     of unit then SKIP
                     [] 'list' then
                        <<'`' local X in
                                 <<',' fOpApplyStatement(
                                          'Cell.exchange'
                                          [ACCUMULATOR <<'`' X#nil>> <<'`' unit>>] Coord) >>
                                 X
                              end >>
                     else
                        <<'`' local X in
                                 <<',' fOpApplyStatement(
                                          'Cell.exchange'
                                          [ACCUMULATOR <<'`' X>> <<'`' unit>>] Coord) >>
                                 X
                              end >>
                     end>>
            end >>
   end
end
