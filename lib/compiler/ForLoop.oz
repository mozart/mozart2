functor
import
   CompilerSupport(newNamedName:NewNamedName) at 'x-oz://boot/CompilerSupport'
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
    "prepend" #prepend]
   ACCU_TYPE =
   ['return'    # ['return' 'default']
    'optimize'  # ['return' 'default' 'maximize' 'minimize']
    'sum'       # ['return' 'default' 'sum']
    'multiply'  # ['return' 'default' 'multiply']
    'count'     # ['return' 'default' 'count']
    'list'      # ['return' 'collect' 'append' 'prepend']]
   GENERAL_FEATURES = ['break' 'continue']
   fun {IsNotGeneral F} {Not {Member F GENERAL_FEATURES}} end
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
      else          {RaiseError 'for'(ambiguousFeature(F))} unit end
   end
   %%
   fun {Compile fFOR(DECLS BODY COORDS)}
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
             By
          in
             {Push 'outers' fEq(Lo E1 unit)}
             {Push 'outers' fEq(Hi E2 unit)}
             if E3==unit then
                By = fInt(1 unit)
             else
                By = {MakeVar 'ForIntVarBy'}
                {Push 'outers' fEq(By E3 unit)}
             end
             {Push 'args'  X}
             {Push 'inits' Lo}
             {Push 'tests' fOpApply('=<' [X Hi] unit)}
             {Push 'nexts' fOpApply('+'  [X By] unit)}
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
      VarAccu
      if AccuType==unit orelse AccuType=='return'
      then VarAccu=unit
      else
         VarAccu={MakeVar 'ForAccu'}
         VarD.'accu' := VarAccu
         {Push 'outers' fEq(VarAccu
                            fOpApply(
                               {VirtualString.toAtom 'For.mk'#AccuType}
                               nil unit)
                            unit)}
      end
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
      Loop2 = fAnd(Loop1 fApply(LoopProc {Reverse D1.'nexts'} unit))
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
      {Push 'outers' fProc(LoopProc {Reverse D1.'args'} Loop3 nil unit)}
      Main1 = fApply(LoopProc {Reverse D1.'inits'} COORDS)
      Main2 = if {HasFeature D2 'break'} then
                 fTry(Main1
                      fCatch(
                         [fCaseClause(
                             fEscape(VarD.'break' unit)
                             fSkip(unit))]
                         unit)
                      fNoFinally COORDS)
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
                            COORDS)
                      end)
              [] 'list' then
                 fAnd(Main2 fOpApply('For.retlist' [VarAccu] COORDS))
              elseif {HasFeature D2 'default'} then
                 fAnd(Main2
                      fOpApply('For.retintdefault' [VarAccu VarD.'default'] COORDS))
              else
                 fAnd(Main2 fOpApply('For.retint' [VarAccu] COORDS))
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
                    fNoFinally COORDS)
              else Main3 end
      Main5 = case D1.'outers'
              of nil then Main4
              [] H|T then
                 fLocal(
                    {FoldL T fun {$ A D} fAnd(D A) end H}
                    Main4
                    COORDS)
              end
   in
      Main5
   end
end
