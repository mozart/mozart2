functor
import
   BootName(newNamed:NewNamedName) at 'x-oz://boot/Name'
export
   Compile
prepare
   RaiseError=Exception.raiseError
   FEATURES =
   ["break"   #break
    "continue"#continue
    "return"  #return
    "default" #default
    "minimize"#minimize
    "maximize"#maximize
    "count"   #count
    "add"     #sum
    "sum"     #sum
    "multiply"#multiply
    "collect" #collect
    "append"  #append
    "prepend" #prepend
    "while"   #while
    "until"   #until
    "yield"   #yield
    "yieldAppend"#yieldAppend
   ]
   ACCU_TYPE =
   ['return'    # ['return' 'default']
    'optimize'  # ['return' 'default' 'maximize' 'minimize']
    'sum'       # ['return' 'default' 'sum']
    'multiply'  # ['return' 'default' 'multiply']
    'count'     # ['return' 'default' 'count']
    'list'      # ['return' 'collect' 'append' 'prepend']
    'yield'     # ['yield' 'yieldAppend']]
   GENERAL_FEATURES = ['break' 'continue' 'while' 'until']
   fun {IsNotGeneral F} {Not {Member F GENERAL_FEATURES}} end
   fun {CoordNoDebug Coord}
      case {Label Coord} of pos then Coord
      else {Adjoin Coord pos}
      end
   end
define
   fun {MakeVar Name}
      fVar({NewNamedName Name} unit)
   end
   %%
   fun {LookupFeature F}
      FS = {Atom.toString F}
   in
      case {Filter FEATURES fun {$ S#_} {List.isPrefix FS S} end}
      of  nil  then {RaiseError 'for'(  unknownFeature(F))} unit
      [] [_#A] then A
      [] L     then FoundExact in
         {ForAll L
          proc {$ _#A}
             if A==F then
                if {IsDet FoundExact} then
                   {RaiseError 'for'(ambiguousFeature(F))}
                else FoundExact=unit end
             end
          end}
         F
      end
   end
   %%
   fun {Compile fFOR(DECLS BODY COORDS)}
      COORDS_NODEBUG={CoordNoDebug COORDS}
      D1 = {Record.toDictionary
            o('inners' : nil
              'outers' : nil
              'args'   : nil
              'inits'  : nil
              'tests'  : nil
              'nexts'  : nil)}
      proc {Push F V}
         {Dictionary.put D1 F V|{Dictionary.get D1 F}}
      end
      %%
      D2 = {NewDictionary}
      proc {PutF fAtom(F _) E}
         F2={LookupFeature F}
      in
         if {Dictionary.member D2 F2} then
            {RaiseError 'for'(repeatedFeature(F2))}
         else
            D2.F2 := E
         end
      end
      %%
      NeedBreak
      BreakExc
      {ForAll DECLS
       proc {$ DECL}
          case DECL
          of forFeature(F E) then {PutF F E}
          [] forPattern(X forGeneratorList(E)) then
             L = {MakeVar 'ForListVar'}
          in
             {Push 'inners' fEq(X fOpApply('.' [L fInt(1 unit)] unit) unit)}
             {Push 'args'   L}
             {Push 'inits'  E}
             {Push 'tests'  fOpApply('\\=' [L fAtom(nil unit)] unit)}
             {Push 'nexts'  fOpApply('.' [L fInt(2 unit)] unit)}
          [] forPattern(X forGeneratorInt(E1 E2 E3)) then
             Lo = {MakeVar 'ForIntVarLo'}
             Hi = {MakeVar 'ForIntVarHi'}
             XVar = case X of fWildcard(_) then {MakeVar 'ForIntVar'} else X end
             By
             Dir
          in
             {Push 'outers' fEq(Lo E1 unit)}
             {Push 'outers' fEq(Hi E2 unit)}
             if E3==unit then
                By = fInt(1 unit)
                Dir = up
             else
                case E3
                of fInt(V _) then
                   if V<0 then Dir=down else Dir=up end
                else
                   Dir=unknown
                end
                By = {MakeVar 'ForIntVarBy'}
                {Push 'outers' fEq(By E3 unit)}
             end
             {Push 'args'  XVar}
             {Push 'inits' Lo}
             case Dir
             of up   then {Push 'tests' fOpApply('=<' [XVar Hi] unit)}
             [] down then {Push 'tests' fOpApply('>=' [XVar Hi] unit)}
             [] unknown then B in
                B={MakeVar 'ForIntCountingUp'}
                {Push 'outers'
                 fEq(B fOpApply('>=' [By fInt(0 unit)] unit) unit)}
                {Push 'tests'
                 fBoolCase(
                    B
                    fOpApply('=<' [XVar Hi] unit)
                    fOpApply('>=' [XVar Hi] unit)
                    unit)}
             end
             {Push 'nexts' fOpApply('+'  [XVar By] unit)}
          [] forPattern(X forGeneratorC(E1 E2 unit)) then
             {Push 'args'  X}
             {Push 'inits' E1}
             {Push 'nexts' E2}
          [] forPattern(X forGeneratorC(E1 E2 E3)) then
             {Push 'args'  X}
             {Push 'inits' E1}
             case E2 of fAtom(true _) then skip else
                {Push 'tests' E2}
             end
             {Push 'nexts' E3}
          [] forFrom(X G) then
             GVar = {MakeVar 'ForGen'}
             GApp = fTry(
                       fApply(GVar nil unit)
                       fCatch(
                          [fCaseClause(fEq(fOpenRecord(fAtom(error unit) nil)
                                           fVar('E' unit) unit)
                                       fRaise(fVar('E' unit) unit))
                           fCaseClause(fEq(fOpenRecord(fAtom(failure unit) nil)
                                           fVar('E' unit) unit)
                                       fRaise(fVar('E' unit) unit))
                           fCaseClause(fWildcard(unit)
                                       fRaise(BreakExc unit))]
                          unit)
                       fNoFinally unit)
          in
             NeedBreak=unit
             {Push 'outers' fEq(GVar G unit)}
             {Push 'args' X}
             {Push 'inits' GApp}
             {Push 'nexts' GApp}
          end
       end}
      %%
      %% check that the combination of features actually makes sense
      %% and figure out the type of the hidden accumulator
      %%
      Feats = {Filter {Dictionary.keys D2} IsNotGeneral}
      AccuType =
      if Feats==nil then unit
      elsecase {Filter ACCU_TYPE
                fun {$ _#L}
                   {All Feats fun {$ F} {Member F L} end}
                end}
      of nil then {RaiseError 'for'(incompatibleFeatures(Feats))} unit
      [] ('return'#_)|_ then 'return'
      [] [T#_] then T
      else {RaiseError 'for'(ambiguousFeatures(Feats))} unit end
      %%
      VarD = {NewDictionary}
      VarAccu VarYieldStream
      if AccuType==unit orelse AccuType=='return'
      then VarAccu=unit
      else
         VarAccu={MakeVar 'ForAccu'}
         VarD.'accu' := VarAccu
         case AccuType
         of 'yield' then
            %% delay the creation and initialization of the yield accu
            %% until we wrap the thread around the main stuff
            VarYieldStream={MakeVar 'YieldStream'}
            {Push 'outers' VarAccu}
         else
            {Push 'outers' fEq(VarAccu
                               fOpApply(
                                  {VirtualString.toAtom 'For.mk'#AccuType}
                                  nil unit)
                               unit)}
         end
      end
      WHILE UNTIL
      {ForAll {Dictionary.entries D2}
       proc {$ F#E}
          case F
          of 'continue' then
             V = {MakeVar 'ForContinue'}
          in
             VarD.'continue' := V
             {Push 'outers' fEq(V fOpApply('Name.new' nil unit) unit)}
             {Push 'outers' fProc(E nil fRaise(V unit) nil unit)}
          [] 'break' then
             V = {MakeVar 'ForBreak'}
          in
             VarD.'break' := V
             {Push 'outers' fEq(V fOpApply('Name.new' nil unit) unit)}
             {Push 'outers' fProc(E nil fRaise(V unit) nil unit)}
          [] 'return' then
             V = {MakeVar 'ForReturn'}
             X = {MakeVar 'V'}
          in
             VarD.'return' := V
             {Push 'outers' fEq(V fOpApply('Name.new' nil unit) unit)}
             {Push 'outers' fProc(E [X]
                                  fRaise(fRecord(fAtom('|' unit) [V X]) unit)
                                  nil unit)}
          [] 'default' then
             V = {MakeVar 'ForDefault'}
          in
             VarD.'default' := V
             {Push 'outers' fEq(V E unit)}
          [] 'while' then
             WHILE=E NeedBreak=unit
          [] 'until' then
             UNTIL=E NeedBreak=unit
          else
             X = {MakeVar 'V'}
          in
             {Push 'outers' fProc(
                               E [X]
                               fOpApplyStatement(
                                  {VirtualString.toAtom 'For.'#F}
                                  [VarAccu X] unit)
                               nil unit)}
          end
       end}
      if {IsDet NeedBreak} then
         if {Not {Dictionary.member D2 break}} then
            E = {MakeVar 'ForBreak'}
         in
            VarD.'break' := E
            {Push 'outers' fEq(E fOpApply('Name.new' nil unit) unit)}
         end
         BreakExc = VarD.'break'
      end
      LoopProc = {MakeVar 'ForProc'}
      Loop1 = if {HasFeature D2 'continue'} then
                 fTry(BODY
                      fCatch(
                         [fCaseClause(
                             fEscape(VarD.'continue' unit)
                             fSkip(unit))]
                         unit)
                      fNoFinally unit)
              else BODY end
      Loop1b = if {IsDet WHILE}
               then fBoolCase(WHILE Loop1 fRaise(BreakExc unit) unit)
               else Loop1 end
      Loop1c = if {IsDet UNTIL}
               then fAnd(Loop1b fBoolCase(UNTIL fRaise(BreakExc unit) fSkip(unit) unit))
               else Loop1b end
      Loop2 = fAnd(Loop1c fApply(LoopProc {Reverse D1.'nexts'} unit))
      Loop2b= case D1.'inners'
              of nil then Loop2
              [] H|T then
                 fLocal(
                    {FoldL T fun {$ A D} fAnd(D A) end H}
                    Loop2 unit)
              end
      Loop3 = case D1.'tests'
              of nil then Loop2b
              [] H|T then
                 fBoolCase(
                    {FoldL T fun {$ C T} fAndThen(T C unit) end H}
                    Loop2b
                    fSkip(unit)
                    unit)
              end
      {Push 'outers' fProc(LoopProc {Reverse D1.'args'} Loop3 nil COORDS_NODEBUG)}
      Main1 = fApply(LoopProc {Reverse D1.'inits'} COORDS_NODEBUG)
      Main2 = if {HasFeature D2 'break'} orelse {IsDet NeedBreak} then
                 fTry(Main1
                      fCatch(
                         [fCaseClause(
                             fEscape(VarD.'break' unit)
                             fSkip(unit))]
                         unit)
                      fNoFinally COORDS_NODEBUG)
              else Main1 end
      Main3 = case AccuType
              of unit then Main2
              [] 'return' then
                 fAnd(Main2
                      if {HasFeature D2 'default'} then
                         VarD.'default'
                      else
                         fRaise(
                            fRecord(
                               fAtom('for' unit)
                               [fAtom('noDefaultValue' unit)])
                            COORDS_NODEBUG)
                      end)
              [] 'list' then
                 fAnd(Main2 fOpApply('For.retlist' [VarAccu] COORDS_NODEBUG))
              [] 'yield' then
                 fAnd(Main2 fOpApplyStatement('For.retyield' [VarAccu] COORDS_NODEBUG))
              elseif {HasFeature D2 'default'} then
                 fAnd(Main2
                      fOpApply('For.retintdefault' [VarAccu VarD.'default'] COORDS_NODEBUG))
              else
                 fAnd(Main2 fOpApply('For.retint' [VarAccu] COORDS_NODEBUG))
              end
      Main4 = if {HasFeature D2 'return'} then
                 V = {MakeVar 'V'}
              in
                 fTry(
                    Main3
                    fCatch(
                       [fCaseClause(
                           fRecord(
                              fAtom('|' unit)
                              [fEscape(VarD.'return' unit) V])
                           V)]
                       unit)
                    fNoFinally COORDS_NODEBUG)
              else Main3 end
      Main5 = if {IsDet VarYieldStream} then
                 fLocal(
                    VarYieldStream
                    fAnd(
                       fThread(
                          fAnd(
                             %% fortunately liveness analysis will discover that
                             %% the threads closure can forget about VarYieldStream
                             %% after this statement
                             fEq(VarYieldStream
                                 fOpApply(
                                    'For.mkyield'
                                    [VarAccu] unit)
                                 unit)
                             Main4)
                          COORDS_NODEBUG)
                       VarYieldStream)
                    COORDS_NODEBUG)
              else
                 Main4
              end
      Main6 = case D1.'outers'
              of nil then Main5
              [] H|T then
                 fLocal(
                    {FoldL T fun {$ A D} fAnd(D A) end H}
                    Main5
                    COORDS_NODEBUG)
              end
   in
      fStepPoint(Main6 'loop' COORDS)
   end
end
