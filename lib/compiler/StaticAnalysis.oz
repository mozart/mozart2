%%%
%%% Author:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
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

\define ANALYSEINHERITANCE


/*
\define DEBUGSA
\define LOOP
\define INHERITANCE
\define DEBUGPOS
\define REMINDER
\define DEBUG_SAVESUBST
*/

functor prop once
import
   BootName at 'x-oz://boot/Name'
   CompilerSupport(newNamedName newCopyableName isCopyableName
                   newPredicateRef newCopyablePredicateRef
                   nameVariable isBuiltin) at 'x-oz://boot/CompilerSupport'
   FD(int is less distinct distribute)
   FS(include var subset value reflect isIn)
   System(eq valueToVirtualString printName)
   Type(is)
   Core
   Builtins(getInfo)
   RunTime(tokens)
export
   ImAConstruction
   ImAValueNode
   ImAVariableOccurrence
   ImAToken

   statement: SAStatement
   typeOf: SATypeOf
   stepPoint: SAStepPoint
   declaration: SADeclaration
   equation: SAEquation
   construction: SAConstruction
   definition: SADefinition
   application: SAApplication
   boolCase: SABoolCase
   boolClause: SABoolClause
   patternCase: SAPatternCase
   patternClause: SAPatternClause
   recordPattern: SARecordPattern
   equationPattern: SAEquationPattern
   elseNode: SAElseNode
   noElse: SANoElse
   threadNode: SAThreadNode
   tryNode: SATryNode
   lockNode: SALockNode
   classNode: SAClassNode
   method: SAMethod
   methodWithDesignator: SAMethodWithDesignator
   methFormal: SAMethFormal
   methFormalOptional: SAMethFormalOptional
   methFormalWithDefault: SAMethFormalWithDefault
   objectLockNode: SAObjectLockNode
   getSelf: SAGetSelf
   ifNode: SAIfNode
   choicesAndDisjunctions: SAChoicesAndDisjunctions
   clause: SAClause
   valueNode: SAValueNode
   variable: SAVariable
   variableOccurrence: SAVariableOccurrence
   token: SAToken
   nameToken: SANameToken
define
   \insert POTypes

%-----------------------------------------------------------------------
% Some constants and shorthands

   SAGenError    = 'static analysis error'
   SAFatalError  = 'static analysis fatal error'
   SAGenWarn     = 'static analysis warning'
   SATypeError   = 'type error'

   AnalysisDepth = 3 % analysis of current environment
   PrintDepth    = 3 % output of analysed structure

   VS2S = VirtualString.toString
   IsVS = IsVirtualString
   Partition = List.partition

   fun {NormalizeCoord Coord}
      case Coord of unit then Coord
      else pos(Coord.1 Coord.2 Coord.2)
      end
   end

   fun {IsMinimalType T}
      {BitArray.card T} == 1
   end

   TypeClone = BitArray.clone

   fun {FirstOrId X}
      case X of F#_ then F else X end
   end

   fun {LabelToVS X}
      case {IsDet X} then {System.valueToVirtualString X 0 0} else '_' end
   end

   fun {Bool2Token B}
      case B then RunTime.tokens.'true' else RunTime.tokens.'false' end
   end

% assumes privacy of the following feature names used in Core:

   ImAVariableOccurrence = {NewName}
   ImAValueNode          = {NewName}
   ImAConstruction       = {NewName}
   ImAToken              = {NewName}

%-----------------------------------------------------------------------
% kinded records

   fun {CurrentArity R}
      case {IsFree R} then
         nil
      else
         {Record.reflectArity R}
      end
   end

   fun {HasFeatureNow R F}
      {Member F {CurrentArity R}}
   end

%-----------------------------------------------------------------------

% GetClassData: T -> <value>
% given a T node, assumes a class value and
% returns an associated class token or unit

   fun {GetClassData X}
      XV = {X getValue($)}
   in
      case {IsDet XV}
         andthen {IsObject XV}
      then
         case XV == X
         then
            unit % variable
         elsecase {HasFeature XV ImAToken}
            andthen XV.kind == 'class'
         then
            XV
         elsecase {HasFeature XV ImAVariableOccurrence}
         then
            {GetClassData XV}
         else
            unit % type checking elsewhere
         end
      else
         unit    % variable
      end
   end

% GetClassOfObjectData: T -> <value>
% given a T node, assumes an object value and
% returns an associated class token or unit

   fun {GetClassOfObjectData X}
      XV = {X getValue($)}
   in
      case {IsDet XV}
         andthen {IsObject XV}
      then
         case XV==X
         then
            unit % variable
         elsecase {HasFeature XV ImAToken}
            andthen XV.kind == 'object'
         then
            {XV getClassNode($)}
         elsecase {HasFeature XV ImAVariableOccurrence}
         then
            {GetClassOfObjectData XV}
         else
            unit % type checking elsewhere
         end
      else
         unit % variable
      end
   end

% GetValue: T -> <value>
% given a T node, returns the associated value
% ie, an integer/float/atom/construction, or a token;
% constructions may contain embedded T nodes

   fun {GetDataObject X}
      {X getData(true $)}
   end

% GetData: T -> <value>
% given a T node, returns the associated value
% ie, an integer/float/atom/construction; or the
% value associated with a token (proc/builtin/class etc.)
% constructions may contain embedded T nodes

   fun {GetData X}
      {X getData(false $)}
   end

% GetFullData: T -> <oz-term>
% given a T node, returns the associated value
% ie, an integer/float/atom/construction; or the
% value associated with a token (proc/builtin/class etc.)
% constructions are expanded recursively up to limited depth

   fun {GetFullData X}
      {X getFullData(PrintDepth true $)}
   end

   fun {GetPrintData X}
      {X getFullData(PrintDepth false $)}
   end

%-----------------------------------------------------------------------
% Type predicates

   fun {IsToken X}
      {IsObject X} andthen {HasFeature X ImAToken}
   end

   TypeTests = {AdjoinAt Type.is object
                fun {$ X}
                   {IsObject X} andthen
                   {Not {HasFeature X ImAConstruction}
                    orelse {HasFeature X ImAValueNode}
                    orelse {HasFeature X ImAToken}}
                end}

%-----------------------------------------------------------------------
% Determination predicates

   DetTests
   = dt(any:    fun {$ X}
                   true
                end
        det:    fun {$ X} XD = {GetData X} in
                   {IsDet XD} andthen
                   case {IsObject XD} then
                      {Not {HasFeature XD ImAVariableOccurrence}}
                   else true end
                end
        detOrKinded:
                fun {$ X} XD = {GetData X} in
                   case {IsDet XD} then
                      case {IsObject XD} then
                         {Not {HasFeature XD ImAVariableOccurrence}}
                      else true end
                   else {IsKinded XD} end
                end)

   %
   % three valued tests for recursive data structures
   %

   fun {IsListNow S}
      case {IsDet S} then
         case S
         of nil then true
         elseof _|Sr then
            {IsListNow Sr}
         else false end
      else unit end
   end

   fun {IsStringNow S}
      case {IsDet S} then
         case S
         of nil then true
         elseof I|Sr then
            {IsDet I}
            andthen {IsChar I}
            andthen {IsStringNow Sr}
         else false end
      else unit end
   end

   % approximation of isVirtualString

   fun {IsVirtualStringNow S}
      case {IsDet S} then
         case {IsAtom S}
            orelse {IsInt S}
            orelse {IsFloat S}
            orelse {IsStringNow S}
         then true
         elsecase {IsTuple S}
            andthen {Label S} == '#'
         then unit
         else false end
      else unit end
   end

%-----------------------------------------------------------------------
% Determination & type predicates

   local
      fun {Maybe Type}
         fun {$ X}
            XX = {GetData X}
         in
            case {IsDet XX} then
               case {IsObject XX}
                  andthen {HasFeature XX ImAVariableOccurrence}
               then true
               else {Type XX} end
            else true
            end
         end
      end
      fun {MaybePairOf L R X}
         XX = {GetData X}
      in
         case {IsDet XX} then
            case {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            elsecase XX
            of A#B then
               {DetTypeTest L A}
               andthen {DetTypeTest R B}
            else false end
         else true end
      end
      fun {MaybeListOf T X}
         XX = {GetData X}
      in
         case {IsDet XX} then
            case {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            elsecase XX
            of X|XXr then
               {DetTypeTest T X}
               andthen {MaybeListOf T XXr}
            [] nil then true
            else false end
         else true end
      end
      fun {MaybeList X}
         {MaybeListOf value X}
      end
      fun {MaybeString X}
         {MaybeListOf char X}
      end
      fun {MaybeVirtualString X}
         XX = {GetData X}
      in
         case {IsDet XX} then
            case {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            elsecase {IsAtom XX}
               orelse {IsInt XX}
               orelse {IsFloat XX}
               orelse {MaybeString X}
            then true
            elsecase {IsTuple XX} andthen {Label XX}=='#'
            then {Record.all XX MaybeVirtualString}
            else false end
         else true end
      end
      DetTypeTests2
      = dtt(list: MaybeList
            listOf: MaybeListOf
            pairOf: MaybePairOf
            string: MaybeString
            virtualString:MaybeVirtualString)

   in
      % flat type tests generalize to "isdet then type"
      % complex ones must be recursively checked

      DetTypeTests
      = {Adjoin {Record.map TypeTests Maybe} DetTypeTests2}

      fun {DetTypeTest T X}
         case
            {Width T} == 0
         then
            {DetTypeTests.{Label T} X}

         elsecase T
         of list(T1) then
            {DetTypeTests.listOf T1 X}
         [] pair(T1 T2) then
            {DetTypeTests.pairOf T1 T2 X}
         else
            {Exception.raiseError compiler(internal illegalTypeDeclaration(T))}
            unit
         end
      end
   end

%-----------------------------------------------------------------------

   BINameToMethod
   = bi(    'Name.new'          : doNewName
            'Name.newUnique'    : doNewUniqueName
            'Cell.new'          : doNewCell
            'Lock.new'          : doNewLock
            'Port.new'          : doNewPort
            'Array.new'         : doNewArray
            'Dictionary.new'    : doNewDictionary
            'Chunk.new'         : doNewChunk
            'Space.new'         : doNewSpace
            'Object.new'        : doNew
            'Array.is'          : doCheckType(det IsArray)
            'Atom.is'           : doCheckType(det IsAtom)
            'Bool.is'           : doCheckType(det IsBool)
            'Cell.is'           : doCheckType(det IsCell)
            'Char.is'           : doCheckType(det IsChar)
            'Chunk.is'          : doCheckType(det IsChunk)
            'Value.isDet'       : doCheckType(det IsDet)
            'Dictionary.is'     : doCheckType(det IsDictionary)
            'Float.is'          : doCheckType(det IsFloat)
            'Int.is'            : doCheckType(det IsInt)
            'List.is'           : doCheckType(rec IsList)
            'Literal.is'        : doCheckType(det IsLiteral)
            'Lock.is'           : doCheckType(det IsLock)
            'Name.is'           : doCheckType(det IsName)
            'Number.is'         : doCheckType(det IsNumber)
            'Object.is'         : doCheckType(det IsObject)
            'Port.is'           : doCheckType(det IsPort)
            'Procedure.is'      : doCheckType(det IsProcedure)
            'Record.is'         : doCheckType(det IsRecord)
            'Record.isC'        : doCheckType(kind IsRecordC)
            'Space.is'          : doCheckType(det IsSpace)
            'String.is'         : doCheckType(rec IsStringNow)
            'Tuple.is'          : doCheckType(det IsTuple)
            'Unit.is'           : doCheckType(det IsUnit)
            'VirtualString.is'  : doCheckType(rec IsVirtualStringNow)
            'Record.label'      : doLabel
            'Record.width'      : doWidth
            'Procedure.arity'   : doProcedureArity
            '=\'Value.\'=\''    : doEq
            'Record.\'.\''      : doDot
            'Record.\'^\''      : doHat
            'Object.\',\''      : doComma
            'Object.\'<-\''     : doAssignAccess
            'Object.\'@\''      : doAssignAccess
            'Bool.and'          : doAnd
            'Bool.or'           : doOr
            'Bool.not'          : doNot
       )

%-----------------------------------------------------------------------
%

   fun {GetReachable V}
      L = {V getLastValue($)}
      T = {V getType($)}
   in
      % L == unit if V is uninitialized
      % eg, first use within conditional;
      % atomic data need not be saved

      case
         L==unit
      then

         case {IsMinimalType T}
         then env(var:V last:L)
         else
            % copy non-minimal types
            {V setType({TypeClone T})}
            env(var:V last:L type:T)
         end

      elsecase
         {L isVariableOccurrence($)}
      then
\ifdef DEBUGSA
         {System.show env(var:V last:L data:{GetDataObject L} type:T)}
\endif
         case {IsMinimalType T}
         then env(var:V last:L data:{GetDataObject L})
         else
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L data:{GetDataObject L} type:T)
         end

      elsecase
         {L isConstruction($)}
      then
\ifdef DEBUGSA
         {System.show env(var:V last:L data:{GetDataObject L} type:T)}
\endif
         case {IsMinimalType T}
         then env(var:V last:L data:{GetDataObject L})
         else
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L data:{GetDataObject L} type:T)
         end

      else
         % L is atomic: int, float, atom, token
         % has constant type
         case {IsMinimalType T}
         then env(var:V last:L)
         else
\ifdef DEBUGSA
            {System.show weird(L T)}
\endif
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L type:T)
         end
      end
   end

   fun {AppendReachable In V}
      {V reachable(In $)}
   end

   proc {InstallEntry E}
      V = E.var
      L = E.last
   in
\ifdef DEBUGSA
      {System.show install({V getPrintName($)} L {V getLastValue($)})}
\endif
      {V setLastValue(L)}

      case {HasFeature E data}
      then {L setValue(E.data)}
      else skip end

      case {HasFeature E type}
      then {V setType(E.type)}
      else skip end
   end

   fun {GetGlobalEnv Vs}
      ReachableVs = {FoldL Vs AppendReachable nil}
   in
\ifdef DEBUGSA
      {System.show v(Vs {Map Vs fun {$ V} {V getPrintName($)} end})}
      {System.show r(ReachableVs {Map ReachableVs fun {$ V} {V getPrintName($)} end})}
\endif

      {Map ReachableVs GetReachable}
   end

   proc {InstallGlobalEnv Env}
      {ForAll Env InstallEntry}
   end

%-----------------------------------------------------------------------
% type equality assertions

   TypeClash = BitArray.disjoint

%
% ValueToErrorLine: VS x Oz-Value -> <error line>
%

   fun {ValueToErrorLine Text X}
      case
         X == unit
      then
         nil
      else
         XD = {GetPrintData X}
      in
         case {X isVariableOccurrence($)}
         then [hint(l:Text m:pn({X getPrintName($)}) # ' = ' # oz(XD))]
         else [hint(l:Text m:oz(XD))] end
      end
   end

%
% IssueTypeError: BitArray x BitArray x Oz-Value x Oz-Value
%

   proc {IssueTypeError TX TY X Y Ctrl Coord}
\ifdef DEBUGSA
      {System.show issuetypeerror(TX TY X Y)}
\endif

      ErrMsg UnifLeft UnifRight Msgs Items
   in

      ErrMsg = {Ctrl getErrorMsg($)}
      {Ctrl getUnifier(UnifLeft UnifRight)}

      Msgs   = [ [hint(l:'First type' m:{TypeToVS TX})
                  hint(l:'Second type' m:{TypeToVS TY})]
                 {ValueToErrorLine 'First value' X}
                 {ValueToErrorLine 'Second value' Y}
                 case UnifLeft \= unit
                    andthen UnifRight \= unit
                 then
                    [hint(l:'Original assertion'
                          m:oz({GetPrintData UnifLeft}) # ' = ' #
                          oz({GetPrintData UnifRight}))]
                 else nil end
               ]
      Items  = {FoldR Msgs Append nil}

      case {Ctrl getNeeded($)} then
         {Ctrl.rep
          error(coord:Coord kind:SATypeError msg:ErrMsg items:Items)}
      else
         {Ctrl.rep
          warn(coord:Coord kind:SAGenWarn msg:ErrMsg items:Items)}
      end
   end

%
% UnifyTypesOf: Oz-Value x Oz-Value
%

   fun {UnifyTypesOf X Y Ctrl Coord}
      TX = {X getType($)}
      TY = {Y getType($)}
   in
      case
         {TypeClash TX TY}
      then
         {IssueTypeError TX TY X Y Ctrl Coord}
         false
      else
         {BitArray.and TX TY}
         {BitArray.and TY TX}
         true
      end
   end

%
% ConstrainTypes: BitArray x BitArray
%

   fun {ConstrainTypes TX TY}
\ifdef DEBUGSA
      {System.show constrainTypes({BitArray.toList TX} {BitArray.toList TY})}
\endif
      case
         {TypeClash TX TY}
      then
         false
      else
         {BitArray.and TX TY}
         true
      end
   end

%-----------------------------------------------------------------------
% type representation conversion

   fun {OptimizeTypeRepr X}
      case X of type(Ns) then
         case Ns of [N] then N
         else {List.toTuple '#' Ns}
         end
      [] value(V) then
         {OptimizeTypeRepr type({OzTypes.decode {OzValueToType V}})}
      [] record(Rec) then
         record({Record.map Rec OptimizeTypeRepr})
      end
   end

%-----------------------------------------------------------------------
% equality assertions

   proc {IssueUnificationFailure Ctrl Coord Msgs}
      ErrMsg Origin Offend UnifLeft UnifRight Text1 Text2
   in
      Origin = {Ctrl getCoord($)}
      ErrMsg = {Ctrl getErrorMsg($)}

      {Ctrl getUnifier(UnifLeft UnifRight)}

      Offend = hint(l:'Offending expression in' m:{NormalizeCoord Coord})

      Text1 = case UnifLeft \= unit
                 andthen UnifRight \= unit
              then
                 {Append Msgs
                  [hint(l:'Original assertion'
                        m:oz({GetPrintData UnifLeft}) # ' = '
                        # oz({GetPrintData UnifRight}))]}
              else
                 Msgs
              end

      Text2 = case Origin==Coord orelse Coord==unit then Text1
              else {Append Text1 [Offend]} end

      case {Ctrl getNeeded($)} then
         {Ctrl.rep error(coord: Origin
                         kind:  SAGenError
                         msg:   case ErrMsg of unit then
                                   'unification error in needed statement'
                                else ErrMsg end
                         items: Text2)}
      else
         {Ctrl.rep warn(coord: Origin
                        kind:  SAGenWarn
                        msg:   case ErrMsg of unit then
                                  'unification error in possibly unneeded statement'
                               else ErrMsg end
                        items: Text2)}
      end
   end

%-----------------------------------------------------------------------
%

   fun {MakeDummyProcedure N PN}
      case N
      of 0 then  proc {$} skip end
      [] 1 then  proc {$ _} skip end
      [] 2 then  proc {$ _ _} skip end
      [] 3 then  proc {$ _ _ _} skip end
      [] 4 then  proc {$ _ _ _ _} skip end
      [] 5 then  proc {$ _ _ _ _ _} skip end
      [] 6 then  proc {$ _ _ _ _ _ _} skip end
      [] 7 then  proc {$ _ _ _ _ _ _ _} skip end
      [] 8 then  proc {$ _ _ _ _ _ _ _ _} skip end
      [] 9 then  proc {$ _ _ _ _ _ _ _ _ _} skip end
      [] 10 then proc {$ _ _ _ _ _ _ _ _ _ _} skip end
      [] 11 then proc {$ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 12 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 13 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 14 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 15 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 16 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 17 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 18 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 19 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      [] 20 then proc {$ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _} skip end
      else
         _ % weaker analysis for procedures with arity > 20
      end
   end

   fun {MakeDummyObject PN}
      {New {Object.'class' [BaseObject] '#' 'attr' 'feat' nil PN} noop}
   end

   fun {MakeDummyClass PN}
      {Object.'class' nil '#' 'attr' 'feat' nil PN}
   end

%-----------------------------------------------------------------------
% some formatting

   fun {ListToVS Xs L Sep R}
      case Xs
      of nil then
         L # R
      elseof [X] then
         L # X # R
      elseof X1|(Xr=(_|_)) then
         L # X1 #
         {FoldR Xr
          fun {$ X In} Sep # X # In end
          R}
      end
   end

   fun {SetToVS Xs}
      {ListToVS Xs '{' ', ' '}'}
   end

   fun {ProdToVS Xs}
      {ListToVS Xs '' ' x ' ''}
   end

   fun {ApplToVS Xs}
      {ListToVS Xs '{' ' ' '}'}
   end

   fun {FormatArity Xs}
      {Map {Arity Xs}
       fun {$ X} case {IsLiteral X} then oz(X) else X end end}
   end

   fun {Ozify Xs}
      {Map Xs
       fun {$ X} case {IsVS X} then X else oz(X) end end}
   end

   fun {TypeToVS T}
      X = {ListToVS {OzTypes.decode T} '' ' ++ ' ''}
   in
      X
   end

%-----------------------------------------------------------------------
% some set routines

% {AllUpTo Xs P Ill} is defined like {All Xs P}
% but in addition, it returns the first element
% Ill in Xs such that {P Ill} does not hold
% (if such an Ill exists)

   local
      fun {AllUpToAux Xs P N Ill}
         case Xs
         of nil then
            Ill = N   % avoid free variables
            true
         [] X|Xr then
            case {P X}
            then {AllUpToAux Xr P N+1 Ill}
            else Ill = X false end
         end
      end
   in
      fun {AllUpTo Xs P ?Ill}
         {AllUpToAux Xs P 1 Ill}
      end
   end

% {SomeUpTo Xs P Ill} is defined like {Some Xs P}
% but in addition, it returns the index Idx of the first
% element Wit in Xs such that {P Wit} holds (if such a
% Wit exists)

   local
      fun {SomeUpToNAux Xs P N Idx}
         case Xs
         of nil then
            Idx = N   % avoid free variables
            false
         [] X|Xr then
            case {P X} then Idx = N true
            else {SomeUpToNAux Xr P N+1 Idx}
            end
         end
      end
   in
      fun {SomeUpToN Xs P ?Wit}
         {SomeUpToNAux Xs P 1 Wit}
      end
   end

   fun {AllDistinct Xs}
      case Xs of nil then true
      elseof X|Xr then
         {Not {Member X Xr}} andthen {AllDistinct Xr}
      end
   end

   fun {Add X Ys}
      case {Member X Ys}
      then Ys else X|Ys end
   end

   fun {Union Xs Ys}
      case Xs of nil then Ys
      elseof X|Xr then
         case {Member X Ys}
         then {Union Xr Ys}
         else X|{Union Xr Ys}
         end
      end
   end

   fun {UnionAll XXs}
      case XXs of nil then nil
      elseof X|XXr then {FoldR XXr Union X}
      end
   end

%-----------------------------------------------------------------------
% property list dot access

   fun {PLDotEQ X Ys}
      case Ys
      of nil then unit
      [] YC|Yr then
         Y#C = YC
      in
         case
            {System.eq X Y}
         then
            C
         else
            {PLDotEQ X Yr}
         end
      end
   end

%-----------------------------------------------------------------------
% ApproxInheritance: list(record) x list(record) -> record(pair(<req> <opt>))
%
% the features of the returned record are the available method labels
% per label, the fields of the returned record are the
%     list of labels required for calls/messages of this method (or nil)
%     list of labels optional for calls/messages of this method
%     (nil = none is optional; unit = all may be optional)
% overriding in parenst is approximated by throwing away all information
% about the message format (required/optional features); this avoids the
% need to carry around the inheritance hierarchy completely

   fun {ApproxInheritance PMet PNew}
      {Adjoin
       {FoldL PMet
        fun {$ I1 M}
           {FoldL {Arity M}
            fun {$ I2 F}
               case {HasFeature I2 F}
               then {AdjoinAt I2 F (nil#unit)}
               else {AdjoinAt I2 F M.F}
               end
            end I1}
        end m} % combine parents methods
       PNew}   % and then adjoin new information
   end

%-----------------------------------------------------------------------
%  global control information

   class Control
      prop final
      feat
         rep                 % the reporter object
         switches            % interface switch control
      attr
         'self': nil         % currently active class context
         coord: unit         % current coordinates
         top: true           % top-level expression
                             % (immediate execution) yes/no?
                             % if no: static analysis branches
         needed: true        % analysing needed expression
                             % (eventual execution) yes/no?
                             % if yes: more errors
         toCopy: unit        % list of things to copy in a virtual toplevel
         savedToCopy: nil    % for managing nested virtual toplevels
         errorMsg: unit      % currently active error message
         unifierLeft: unit   % last unification requested
         unifierRight: unit  %

      meth init(Rep Switches)
         self.rep = Rep
         self.switches = Switches
         'self'        <- nil
         coord         <- unit
         top           <- true
         needed        <- true
         toCopy        <- unit
         savedToCopy   <- nil
         errorMsg      <- unit
         unifierLeft   <- unit
         unifierRight  <- unit
      end

      meth pushSelf(S)
         'self' <- S|@'self'
      end
      meth popSelf
         case @'self'
         of _|S then 'self' <- S
         else
            {Exception.raiseError compiler(internal popEmptyStack)}
         end
      end
      meth getSelf($)
         case @'self' of Self|_ then Self
         [] nil then unit
         end
      end

      meth setCoord(C)
         coord <- C
      end
      meth getCoord($)
         @coord
      end

      meth getTop($)
         @top
      end
      meth setTop(T)
         top <- T
      end

      meth getNeeded($)
         @needed
      end
      meth setNeeded(N)
         needed <- N
      end

      meth getTopNeeded(T N)
         T = @top
         N = @needed
      end
      meth setTopNeeded(T N)
         Control, setTop(T)
         Control, setNeeded(N)
      end
      meth notTopNotNeeded
         Control, setTopNeeded(false false)
      end
      meth notTopButNeeded
         Control, setTopNeeded(false true)
      end

      meth beginVirtualToplevel(Coord)
         case @toCopy of unit then skip
         elseof Xs then
            savedToCopy <- Xs|@savedToCopy
         end
         toCopy <- nil
      end
      meth declareToplevelName(PrintName ?N)
         case @toCopy of unit then
            N = {CompilerSupport.newNamedName PrintName}
         elseof Xs then
            N = {CompilerSupport.newCopyableName PrintName}
            toCopy <- N|Xs
         end
      end
      meth declareToplevelProcedure(?PredicateRef)
         case @toCopy of unit then
            PredicateRef = {CompilerSupport.newPredicateRef}
         elseof Xs then
            PredicateRef = {CompilerSupport.newCopyablePredicateRef}
            toCopy <- PredicateRef|Xs
         end
      end
      meth endVirtualToplevel(?Xs)
         Xs = @toCopy
         case @savedToCopy of Ys1|Ysr then
            toCopy <- Ys1
            savedToCopy <- Ysr
         [] nil then
            toCopy <- unit
         end
      end

      meth setErrorMsg(E)
         errorMsg <- E
      end
      meth resetErrorMsg
         errorMsg <- unit
      end
      meth getErrorMsg($)
         @errorMsg
      end

      meth setUnifier(L R)
         unifierLeft  <- L
         unifierRight <- R
      end
      meth resetUnifier
         unifierLeft  <- unit
         unifierRight <- unit
      end
      meth getUnifier(L R)
         L = @unifierLeft
         R = @unifierRight
      end
   end

%-----------------------------------------------------------------------
%  static analysis mix-ins

   class SAStatement

      % a complex statement is one which may do more than suspend immediately
      % or bind a variable; _not_ complex in this sense are constraints,
      % declarations, definitions, class nodes, etc.
      % (a class with isComplex = false must provide an saSimple method)
      %
      % we only deal with definitions and class nodes at this point

      feat
         isComplex:true

      %%
      %% static analysis iteration
      %%

      meth staticAnalysis(Rep Switches Ss)
         Ctrl = {New Control init(Rep Switches)}
      in
         {self SaDo(Ctrl true)}          % initiate first lookahead
      end
      meth SaDo(Ctrl Cpx)
         if
            Cpx                          % if last statement was complex
         then
            {self SaLookahead(Ctrl)}     % then do lookahead
         end

         {Ctrl setCoord(@coord)}         % save coordinates for error messages
         {self applyEnvSubst(Ctrl)}      % apply old substitutions
         {self sa(Ctrl)}
         {self saDescend(Ctrl)}

         if
            @next\=self
         then
            {@next SaDo(Ctrl self.isComplex)}
         end
      end
      meth SaLookahead(Ctrl)
         if
            self.isComplex               % if this statement is complex
         then
            skip                         % then terminate
         else
            {self saSimple(Ctrl)}

            if
               @next\=self               % if there is another one
            then
               {@next SaLookahead(Ctrl)}
            end
         end
      end

      meth saBody(Ctrl Ss)
         case
            Ss
         of
            S|Sr
         then
            {S SaDo(Ctrl true)}          % new lookahead in bodies
         end
      end

      meth sa(Ctrl)
         skip
\ifdef DEBUGSA
         {System.show saStatement(@coord)}
\endif
      end
      meth saDescend(Ctrl)
         skip
      end
      meth applyEnvSubst(Ctrl)
         skip
      end
   end

   class SATypeOf
      meth sa(Ctrl) T in
         {@arg reflectType(AnalysisDepth ?T)}
         value <- {OptimizeTypeRepr T}
         %--** the new information about res is not propagated
      end
   end

   class SAStepPoint
      meth saDescend(Ctrl)
         SAStatement, saBody(Ctrl @statements)
      end
   end

   class SADeclaration
      meth sa(Ctrl)
\ifdef DEBUGSA
         {System.show declaration({Map @localVars
                                   fun {$ V} {V getPrintName($)} end})}
\endif

         if {Ctrl getTop($)} then
            {ForAll @localVars proc {$ V} {V setToplevel(true)} end}
         end
      end
      meth saDescend(Ctrl)
         % descend with same environment
         SAStatement, saBody(Ctrl @statements)
      end
   end

   class SAEquation
      meth sa(Ctrl)
\ifdef DEBUGSA
         {System.show saEQ(@left @right)}
\endif
         {@right sa(Ctrl)}                            % analyse right hand side

         {Ctrl setErrorMsg('equality constraint failed')}
         {Ctrl setUnifier(@left @right)}

         {@left unify(Ctrl @right)}                   % l -> r

         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}
      end
      meth applyEnvSubst(Ctrl)
         {@left applyEnvSubst(Ctrl)}
         {@right applyEnvSubst(Ctrl)}
      end
   end

   class SAConstructionOrPattern
      attr
         type: unit
         lastValue : unit
         value

      meth init()
         type <- {OzTypes.encode record nil}
      end
      meth getValue($)
         @value
      end
      meth setValue(Val)
         value <- Val
      end
      meth getLastValue($)
         @lastValue
      end
      meth setLastValue(O)
         lastValue <- O
      end
      meth getLabel($)
         @label
      end
      meth getArgs($)
         @args
      end
      meth isOpen($)
         @isOpen
      end
      meth getType($)
         @type
      end
      meth getPrintType(D $)
         case
            D =< 0
         then
            {TypeToVS @type}
         else
            {self deref(self)}
            case
               {IsDet @value}
            then
               case {IsTuple @value} then
                  {ListToVS
                   '(' | {Map {Record.toList @value}
                          fun {$ X} {X getPrintType(D-1 $)} end}
                   {LabelToVS {Label @value}} ' ' ' )'}
               else
                  {ListToVS
                   '(' | {Map {Record.toListInd @value}
                          fun {$ F#X}
                             {System.valueToVirtualString F 0 0} # ': ' #
                             {X getPrintType(D-1 $)}
                          end}
                   {LabelToVS {Label @value}} ' ' ' )'}
               end
            elsecase
               {IsFree @value}
            then
               {TypeToVS @type}
            else
               Lab = case {Record.hasLabel @value} then {Label @value} else _ end
            in
               {ListToVS
                '(' | {Map {CurrentArity @value}
                       fun {$ F}
                          {System.valueToVirtualString F 0 0} # ': ' #
                          {@value^F getPrintType(D-1 $)}
                       end}
                {LabelToVS Lab}  ' ' '...)'}
            end
         end
      end
      meth reflectType(Depth $)
         try Lab Args Rec in
            if Depth =< 0 orelse @isOpen then fail end
            Lab = case {@label reflectType(Depth $)} of value(V) then V
                  else fail unit
                  end
            Args = {List.mapInd @args
                    fun {$ I Arg}
                       case Arg of F#X then
                          case {F reflectType(Depth $)} of value(V) then
                             V#{X reflectType(Depth - 1 $)}
                          else fail unit
                          end
                       else
                          I#{Arg reflectType(Depth - 1 $)}
                       end
                    end}
            Rec = {List.toRecord Lab Args}
            record(Rec)
         catch failure(...) then
            type({OzTypes.decode @type})
         end
      end
      meth setType(T)
         type <- T
      end
      meth getData(IsObj $)
         {self deref(self)}
         @value
      end
      meth getFullData(D IsData $)
         case
            D =< 0
         then
            _
         else
            {self deref(self)}
            case
               {IsDet @value}
            then
               {Record.map @value fun {$ X} {X getFullData(D-1 IsData $)} end}
            elsecase
               {IsFree @value}
            then
               @value
            else
               Rec
               Lab = case {Record.hasLabel @value} then {Label @value} else _ end
            in
               case {IsDet Lab} then
                  Rec = {TellRecord Lab}
               else skip end
               {ForAll {CurrentArity @value}
                proc {$ F}
                   Rec^F = {@value^F getFullData(D-1 IsData $)}
                end}
               Rec
            end
         end
      end
      meth deref(VO)
         case
            @lastValue == unit                          % is "free"
         then
            SAConstructionOrPattern, setLastValue(VO)   % initialize with self
         elsecase
            {@lastValue isConstruction($)}
         then
            NewVal = {@lastValue getLastValue($)}
         in
            case
               @lastValue == NewVal
            then
               skip                                     % self reference
            elsecase
               NewVal == unit
            then
               {@lastValue setLastValue(@lastValue)}    % non initialised
            else
               SAConstructionOrPattern, setLastValue(NewVal) % constr path compr
               SAConstructionOrPattern, deref(VO)
            end
         else
            skip % atom
         end
      end
      meth reachable(Vs $)
\ifdef LOOP
         {System.show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
\endif
         {FoldL @args
          fun {$ VsIn Arg}
             case Arg of F#T then
                {T reachable({F reachable(VsIn $)} $)}
             else
                {Arg reachable(VsIn $)}
             end
          end
          {@label reachable(Vs $)}}
      end

      meth makeType
         type <- {OzValueToType @value}
      end

      meth MakeConstruction(Ctrl)
         Coord= {@label getCoord($)}
         Args = {FoldL @args
                 fun {$ In Arg}
                    case Arg of F#_ then F|In else In end
                 end nil}
      in
         case
            {DetTypeTests.literal @label}
         then
            IllFeat TestFeats
         in
            {AllUpTo Args DetTypeTests.feature ?IllFeat ?TestFeats}

            case
               TestFeats
            then
               LData = {GetData @label}
               FData = {List.mapInd @args
                        fun {$ I Arg}
                           case Arg of F#T then {GetData F}#T else I#Arg end
                        end}
               Fields= {Map FData fun {$ F#_} F end}
            in
\ifdef DEBUGSA
               {System.show makeConstruction(LData FData Fields)}
\endif
               case
                  {AllDistinct Fields}
               then
                  case
                     {All @label|Args DetTests.det}
                  then
                     case
                        @isOpen
                     then
                        value <- {TellRecord LData}
                        {ForAll FData proc {$ F#V} @value^F=V end}
                     else
                        value <- {List.toRecord LData FData}
                     end
                  else
\ifdef DEBUGSA
                     {System.show noRecordConstructed}
\endif
                     value <- _ % no record constructed
                  end
               else
                  {Ctrl.rep
                   error(coord: Coord
                         kind:  SAGenError
                         msg:   'duplicate features in record construction'
                         items: [hint(l:'Features found' m:{SetToVS Fields})])}
               end
            else
               {Ctrl.rep error(coord: Coord
                               kind:  SAGenError
                               msg:   'illegal record feature '
                               items: [hint(l:'Feature found' m:oz({GetPrintData IllFeat}))])}
            end
         else
            {Ctrl.rep error(coord: Coord
                            kind:  SAGenError
                            msg:   'illegal record label '
                            items: [hint(l:'Label found' m:oz({GetPrintData @label}))])}
         end
\ifdef DEBUGSA
         {System.show madeConstruction(@value)}
\endif
      end

      %% Bind: _ x Construction

      meth bind(Ctrl RHS)
\ifdef DEBUGSA
         {System.show bindConstruction(self {RHS getValue($)})}
\endif
         case
            {UnifyTypesOf self RHS Ctrl {@label getCoord($)}}
         then
            % set new value for following occurrences
            SAConstructionOrPattern, setLastValue(RHS)
         else
            skip % not continue on type error
         end
      end

      % unify: _ x Token U Construction U ValueNode

      meth unify(Ctrl RHS)
\ifdef LOOP
         {System.show unifyC(RHS)}
\endif
         Coord = {@label getCoord($)}
      in
         case
            {Not {UnifyTypesOf self RHS Ctrl Coord}}
         then
            skip % do not continue on type error
         elsecase
            {RHS isConstruction($)}
         then
            RLab  = {RHS getLabel($)}
            RArgs = {RHS getArgs($)}
            ROpen = {RHS isOpen($)}
            RVal  = {GetData RHS}
         in
            case
               {@label isVariableOccurrence($)}
            then
               {@label unify(Ctrl RLab)}               % unify labels
            elsecase
               {RLab isVariableOccurrence($)}
            then
               {RLab unify(Ctrl @label)}
            else                                % both labels must be known
\ifdef DEBUGSA
               {System.show label({GetData @label} {GetData RLab})}
\endif
               case
                  {GetData @label}=={GetData RLab}
               then
                  skip
               else
                  {IssueUnificationFailure Ctrl Coord
                   [hint(l:'Incompatible labels'
                         m:oz({GetData @label}) # ' and ' # oz({GetData RLab}))
                    hint(l:'First value' m:oz(@value))
                    hint(l:'Second value' m:oz(RVal))]}
               end
            end

            case
               {Not @isOpen}
               andthen
               {Not ROpen}
               andthen
               {Length @args} \= {Length RArgs}
            then
               {IssueUnificationFailure Ctrl Coord
                [hint(l:'Incompatible widths'
                      m:{Length @args} # ' and ' # {Length RArgs})
                 hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz(RVal))]}
            else skip end

            case
               {IsDet @value} andthen {IsDet RVal}
            then
               {ForAll {Arity @value}
                proc {$ F}
                   VF = @value.F
                   RF = RVal.F
                in
                   case
                      {RF isVariableOccurrence($)}
                   then
                      {RF unify(Ctrl VF)}
                   else
                      {VF unify(Ctrl RF)}
                   end
                end}
            else
               LArity = {CurrentArity @value}
               RArity = {CurrentArity RVal}
            in
               {ForAll RArity
                proc {$ F}
                   case
                      {Member F LArity}
                   then
                      VF = @value^F
                      RF = RVal^F
                   in
                      case
                         {RF isVariableOccurrence($)}
                      then
                         {RF unify(Ctrl VF)}
                      else
                         {VF unify(Ctrl RF)}
                      end
                   else
                      %--** incomplete ft unification
                      skip
                   end
                end}
            end

         elsecase
            {IsToken RHS}
            orelse
            {IsAtom {RHS getValue($)}}
         then

            case
               @isOpen
            then
               {@label unify(Ctrl RHS)}
            elsecase
               {Length @args}\=0
            then
               {IssueUnificationFailure Ctrl Coord
                [hint(l:'Incompatible widths'
                      m:{Length @args} # ' and ' # 0)
                 hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz({RHS getValue($)}))]}
            else
               {@label unify(Ctrl RHS)}
            end

         else
            {IssueUnificationFailure Ctrl Coord
             [line('record = number')
              hint(l:'First value' oz(@value))
              hint(l:'Second value' oz({RHS getValue($)}))]}
         end
      end
      meth sa(Ctrl)

\ifdef DEBUGSA
         {System.show saConstruction}
\endif

         {ForAll @args
          proc {$ Arg}
             case Arg of _#T then
                {T sa(Ctrl)}
             else
                {Arg sa(Ctrl)}
             end
          end}
         SAConstructionOrPattern, MakeConstruction(Ctrl)
         SAConstructionOrPattern, makeType
      end
      meth applyEnvSubst(Ctrl)
         {@label applyEnvSubst(Ctrl)}
         {ForAll @args
          proc {$ Arg}
             case Arg of F#T then
                {F applyEnvSubst(Ctrl)}
                {T applyEnvSubst(Ctrl)}
             else
                {Arg applyEnvSubst(Ctrl)}
             end
          end}
      end
   end

   class SAConstruction
      from SAConstructionOrPattern
   end

   class SADefinition
      feat
         isComplex:false
      meth saSimple(Ctrl)
         DummyProc = {MakeDummyProcedure
                      {Length @formalArgs}
                      {@designator getPrintName($)}}
         Value
      in
         % prepare some feature values for the code generator:
         case {self isClauseBody($)} then
            Value = {New Core.clauseBodyToken init(DummyProc)}
            Value.clauseBodyStatements = @statements
         else
            Value = {New Core.procedureToken init(DummyProc)}
            if {Ctrl getTop($)} then PredicateRef in
               {Ctrl declareToplevelProcedure(?PredicateRef)}
               Value.predicateRef = PredicateRef
               predicateRef <- PredicateRef
            end
         end

         {@designator unifyVal(Ctrl Value)}

\ifdef DEBUGSA
         {System.show lookedAhead({@designator getPrintName($)} Value)}
\endif
      end
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         case {Member 'instantiate' @procFlags} then
            {Ctrl beginVirtualToplevel(@coord)}
            {Ctrl setTopNeeded(true false)}
            SAStatement, saBody(Ctrl @statements)
            toCopy <- {Ctrl endVirtualToplevel($)}
         else
            {Ctrl notTopNotNeeded}
            SAStatement, saBody(Ctrl @statements)
         end
         {Ctrl setTopNeeded(T N)}
         {InstallGlobalEnv Env}
      end
      meth applyEnvSubst(Ctrl)
         {@designator applyEnvSubst(Ctrl)}
      end
   end

   class SABuiltinApplication

      meth typeCheckN(Ctrl N VOs Ts $)
         case VOs of nil then
            case Ts\=nil then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAFatalError
                      msg:   'builtin arity does not match declaration')}
               {Exception.raiseError compiler(internal typeCheckN)}
            else skip end
            0
         [] VO|VOr then
            case Ts
            of T|Tr then
               case
                  {DetTypeTest T VO}
               then
                  SABuiltinApplication, typeCheckN(Ctrl N+1 VOr Tr $)
               else N end
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAFatalError
                      msg:   'builtin arity does not match declaration')}
               {Exception.raiseError compiler(internal typeCheckN)} unit
            end
         end
      end

      meth typeCheck(Ctrl VOs Ts $)
         SABuiltinApplication, typeCheckN(Ctrl 1 VOs Ts $)
      end

      meth detCheck(Ctrl VOs Ds $)
         case VOs of nil then
            case Ds\=nil then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAFatalError
                      msg:   'builtin arity does not match declaration')}
               {Exception.raiseError compiler(internal detCheck)}
            else skip end
            true
         [] VO|VOr then
            case Ds
            of D|Dr then
               {DetTests.{Label D} VO}
               andthen
               SAApplication, detCheck(Ctrl VOr Dr $)
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAFatalError
                      msg:   'builtin arity does not match declaration')}
               {Exception.raiseError compiler(internal detCheck)} unit
            end
         end
      end

      meth AssertTypes(Ctrl N Args Types Det)
\ifdef DEBUGSA
         {System.show 'AssertTypes'(Args Types Det)}
\endif
         case Args
         of nil then skip
         elseof A|Ar then
            case Types # Det
            of (T|Tr) # (D|Dr)
            then
\ifdef DEBUG
               {System.show asserting(A T D)}
\endif
               case
                  {ConstrainTypes
                   {A getType($)}
                   {OzTypes.encode {Label T} nil}}
               then
                  SABuiltinApplication, AssertTypes(Ctrl N+1 Ar Tr Dr)
               else
                  PN  = pn({@designator getPrintName($)})
                  PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
                  Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
                  Ts  = {Map @actualArgs fun {$ A} {TypeToVS {A getType($)}} end}
               in
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SATypeError
                         msg:   'ill-typed application'
                         items: [hint(l:'Procedure' m:PN)
                                 hint(l:'At argument' m:N)
                                 hint(l:'Expected' m:oz(T))
                                 hint(l:'Found' m:{TypeToVS {A getType($)}})
                                 hint(l:'Application (names)'
                                      m:{ApplToVS PN|PNs})
                                 hint(l:'Application (values)'
                                      m:{ApplToVS PN|Vals})
                                 hint(l:'Application (types)'
                                      m:{ApplToVS PN|Ts})])}
               end
            else
               skip % number of arguments has been checked earlier
            end
         end
      end

      meth assertTypes(Ctrl BIName)
\ifdef DEBUGSA
         {System.show assertTypes(BIName)}
\endif
         I = {Builtins.getInfo BIName}
      in
         case I of noInformation then skip
         else
            Types = I.types
            Det   = I.det
         in
\ifdef DEBUGSA
            {System.show assert(BIName I @actualArgs)}
\endif
            SABuiltinApplication, AssertTypes(Ctrl 1 @actualArgs Types Det)
         end
      end

      meth checkMessage(Ctrl MsgArg Meth Type PN)
         Msg     = {GetData MsgArg}
         MsgData = {GetPrintData MsgArg}   %--** memory leak with named vars!
\ifdef DEBUG
         {System.show checkingMsg(pn:PN arg:MsgArg msg:Msg met:Meth)}
\endif
         What Where
      in

         case Type
         of object then
            What  = 'Object'
            Where = 'object application'
         elseof new then
            What  = 'Object'
            Where = 'object creation'
         elseof 'class' then
            What  = 'Class'
            Where = 'class application'
         else
            What  = '???'
            Where = '???'
         end

         case Meth==unit
         then
            skip
         elsecase
            {IsDet Msg} andthen {IsRecord Msg}
         then
            case
               {HasFeature Meth {Label Msg}}
            then
               Req # Opt = Meth.{Label Msg}
            in

               {ForAll Req
                proc {$ R}
                   case {HasFeature Msg R}
                   then skip else
                      {Ctrl.rep
                       error(coord: @coord
                             kind:  SAGenError
                             msg:   'missing message feature in ' # Where
                             items: [hint(l:What m:pn(PN))
                                     hint(l:'Required feature' m:R)
                                     hint(l:'Message found'
                                          m:oz(MsgData))])}
                   end
                end}

               case
                  Opt \= unit
               then
                  {ForAll {Arity Msg}
                   proc {$ F}
                      case {Member F Req}
                         orelse {Member F Opt}
                      then skip else
                         {Ctrl.rep
                          error(coord: @coord
                                kind:  SAGenError
                                msg:   'illegal message feature in ' # Where
                                items: [hint(l:What m:pn(PN))
                                        hint(l:'Required features'
                                             m:{SetToVS Req})
                                        hint(l:'Optional features'
                                             m:{SetToVS Opt})
                                        hint(l:'Message found'
                                             m:oz(MsgData))])}
                      end
                   end}
               else skip end

            elsecase
               {HasFeature Meth otherwise}
            then skip else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal message label in ' # Where
                      items: [hint(l:What m:pn(PN))
                              hint(l:'Expected' m:{SetToVS {FormatArity Meth}})
                              hint(l:'Message found' m:oz(MsgData))])}
            end
         else
            skip
         end
      end

      % Det:     flag whether to check determination
      % Returns: success flag depending on whether
      %          the arguments have been tested

      meth checkArguments(Ctrl Det $)
         N         = {System.printName {GetData @designator}}
         BIInfo    = {Builtins.getInfo N}
         NumArgs   = {Length @actualArgs}
         BIData    = {GetData @designator}
         ProcArity = {Procedure.arity BIData}
      in
\ifdef DEBUGSA
         {System.show checkArguments}
\endif
         if
            BIInfo==noInformation
         then
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
         in
            {Ctrl.rep error(coord: @coord
                            kind:  SAGenError
                            msg:   'application of unknown builtin'
                            items: [hint(l:'Builtin' m:N)
                                    hint(l:'Argument names'
                                         m:{ApplToVS pn(N)|PNs})
                                    hint(l:'Argument values'
                                         m:{ApplToVS pn(N)|Vals})])}
            false
         elseif
            NumArgs==ProcArity
         then
            case
               SABuiltinApplication, typeCheck(Ctrl @actualArgs BIInfo.types $)
            of
               0 % no type error
            then
\ifdef DEBUGSA
               {System.show det(N Det {Map @actualArgs GetData})}
\endif
               {Not Det} orelse
               SABuiltinApplication, detCheck(Ctrl @actualArgs BIInfo.det $)
            elseof
               Pos
            then
               PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
               Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
               Ts  = {Map BIInfo.types fun {$ T} oz(T) end}
            in
               {Ctrl.rep error(coord: @coord
                               kind:  SATypeError
                               msg:   'ill-typed application'
                               items: [hint(l:'Builtin' m:pn(N))
                                       hint(l:'At argument' m:Pos)
                                       hint(l:'Expected types' m:{ProdToVS Ts})
                                       hint(l:'Argument names' m:{ApplToVS pn(N)|PNs})
                                       hint(l:'Argument values' m:{ApplToVS pn(N)|Vals})])}
               false
            end
         else
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
         in
            {Ctrl.rep error(coord: @coord
                            kind:  SAGenError
                            msg:   'illegal arity in application'
                            items: [hint(l:'Builtin' m:N)
                                    hint(l:'Expected' m:ProcArity)
                                    hint(l:'Found' m:NumArgs)
                                    hint(l:'Argument names'
                                         m:{ApplToVS pn(N)|PNs})
                                    hint(l:'Argument values'
                                         m:{ApplToVS pn(N)|Vals})])}
            false
         end
      end

      meth doNewName(Ctrl)
         BndVO BndV PrintName TheName Token
      in
         BndVO = {Nth @actualArgs 1}
         {BndVO getVariable(?BndV)}
         {BndV getPrintName(?PrintName)}
         case {Ctrl getTop($)} andthen {BndV getOrigin($)} \= generated then
            {Ctrl declareToplevelName(PrintName ?TheName)}
         else
            TheName = {CompilerSupport.newNamedName PrintName}
         end
         Token = {New Core.nameToken init(TheName {Ctrl getTop($)})}
         {BndVO unifyVal(Ctrl Token)}
         case {Ctrl getTop($)} then self.codeGenMakeEquateLiteral = TheName
         else skip end
      end

      meth doNewUniqueName(Ctrl)
         NName = {GetData {Nth @actualArgs 1}}
         Value = {BootName.newUnique NName}   % always succeeds
         Token = {New Core.nameToken init(Value true)}
         BndVO = {Nth @actualArgs 2}
      in
\ifdef DEBUGSA
         {System.show newUniqueName(NName Token)}
\endif
         {BndVO unifyVal(Ctrl Token)}
         self.codeGenMakeEquateLiteral = Value
      end

      meth doNewLock(Ctrl)
         Token = {New Core.lockToken init({NewLock})}
         BndVO = {Nth @actualArgs 1}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewPort(Ctrl)
         Token = {New Core.portToken init({NewPort _})}
         BndVO = {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewCell(Ctrl)
         Token = {New Core.cellToken init({NewCell _})}
         BndVO = {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewArray(Ctrl)
         Low  = {GetData {Nth @actualArgs 1}}
         High = {GetData {Nth @actualArgs 2}}
         Token= {New Core.arrayToken init({Array.new Low High _})}
         BndVO= {Nth @actualArgs 4}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewDictionary(Ctrl)
         Token= {New Core.dictionaryToken init({Dictionary.new})}
         BndVO= {Nth @actualArgs 1}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewChunk(Ctrl)
         Rec  = {GetData {Nth @actualArgs 1}}
         Token= {New Core.chunkToken init({NewChunk Rec})}
         BndVO= {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewSpace(Ctrl)
         Token= {New Core.spaceToken init({Space.new proc {$ _} skip end})}
         BndVO= {Nth @actualArgs 2}
\ifdef DEBUGSA
         Pred = {GetData {Nth @actualArgs 1}}
         {System.show space({{Nth @actualArgs 2} getPrintName($)} Pred)}
\endif
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNew(Ctrl)
         DummyObj = {MakeDummyObject {@designator getPrintName($)}}
         Cls      = {GetClassData {Nth @actualArgs 1}}
         Msg      = {Nth @actualArgs 2}
         Token    = {New Core.objectToken init(DummyObj Cls)}
         BndVO    = {Nth @actualArgs 3}
         PN       = {BndVO getPrintName($)}
\ifdef DEBUGSA
         {System.show doNew(Token)}
\endif
      in
         {BndVO unifyVal(Ctrl Token)}

         case Cls == unit
         then skip else
            Meth = {Cls getMethods($)}
         in
            SABuiltinApplication, checkMessage(Ctrl Msg Meth new PN)
         end
      end

      meth doEq(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
      in
         {Ctrl setErrorMsg('equation failed')}
         {Ctrl setUnifier(BVO1 BVO2)}

         {BVO1 unify(Ctrl BVO2)}

         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}
      end

      meth doDot(Ctrl)
\ifdef DEBUGSA
         {System.show dot(@actualArgs {Map @actualArgs GetData})}
\endif
         FirstArg = {Nth @actualArgs 1}
         RecOrCh  = {GetData FirstArg}
         F        = {GetData {Nth @actualArgs 2}}
      in
\ifdef DEBUGSA
         {System.show dot(FirstArg RecOrCh F)}
\endif
         case
            {IsDet RecOrCh}
            andthen {TypeTests.object RecOrCh}
         then
\ifdef DEBUGSA
            {System.show dotobj}
\endif
            case {GetClassOfObjectData FirstArg}
            of unit then
               skip
            elseof Cls then
               Fs  = {Cls getFeatures($)}
            in
               case
                  Fs == unit orelse {Member F Fs}
               then
                  skip
               else
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SAGenError
                         msg:   'illegal feature selection from object'
                         items: [hint(l:'Expected' m:{SetToVS {Ozify Fs}})
                                 hint(l:'Found' m:oz(F))])}
               end
            end

         elsecase
            {IsDet RecOrCh}
            andthen {TypeTests.'class' RecOrCh}
         then
            case {GetClassData FirstArg}
            of unit then
               skip
            elseof Cls then
               Fs  = {Cls getFeatures($)}
            in
               case Fs == unit
                  orelse {Member F Fs}
               then skip else
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SAGenError
                         msg:   'illegal feature selection from class'
                         items: [hint(l:'Expected' m:{SetToVS {Ozify Fs}})
                                 hint(l:'Found' m:oz(F))])}
               end
            end

         elsecase
            {IsDet RecOrCh}
            andthen {TypeTests.record RecOrCh}
         then
            case {HasFeature RecOrCh F}
            then
               BndVO = {Nth @actualArgs 3}
            in
               {Ctrl setErrorMsg('feature selection (.) failed')}
               {Ctrl setUnifier(BndVO RecOrCh.F)}

               {BndVO unify(Ctrl RecOrCh.F)}

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal feature selection from record'
                      items: [hint(l:'Expected' m:{SetToVS {FormatArity RecOrCh}})
                              hint(l:'Found' m:oz(F))])}
            end
         elsecase
            {TypeTests.recordC RecOrCh}
            andthen {HasFeatureNow RecOrCh F}
         then
            BndVO = {Nth @actualArgs 3}
         in
            {Ctrl setErrorMsg('feature selection (.) failed')}
            {Ctrl setUnifier(BndVO RecOrCh.F)}

            {BndVO unify(Ctrl RecOrCh^F)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else
            skip
         end
      end

      meth doHat(Ctrl)
\ifdef DEBUGSA
         {System.show hat(@actualArgs {Map @actualArgs GetData})}
\endif
         Rec = {GetData {Nth @actualArgs 1}}
         Fea = {GetData {Nth @actualArgs 2}}
      in
\ifdef DEBUGSA
         {System.show hat(Rec Fea)}
\endif
         case
            {HasFeatureNow Rec Fea}
         then
            BndVO = {Nth @actualArgs 3}
         in
            {Ctrl setErrorMsg('feature selection (^) failed')}
            {Ctrl setUnifier(BndVO Rec^Fea)}

            {BndVO unify(Ctrl Rec^Fea)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         elsecase
            {IsDet Rec}
         then
            {Ctrl.rep
             error(coord: @coord
                   kind:  SAGenError
                   msg:   'illegal feature selection from record'
                   items: [hint(l:'Expected' m:{SetToVS {FormatArity Rec}})
                           hint(l:'Found' m:oz(Fea))])}
         else
            skip
         end
      end

      meth doComma(Ctrl)
         Cls  = {GetClassData {Nth @actualArgs 1}}
         Msg  = {Nth @actualArgs 2}
         PN   = {{Nth @actualArgs 1} getPrintName($)}
      in
         case Cls == unit
         then skip else
            Meth = {Cls getMethods($)}
         in
            SABuiltinApplication, checkMessage(Ctrl Msg Meth 'class' PN)
         end
      end

      meth doAssignAccess(Ctrl)
         Self = {Ctrl getSelf($)}
         FeaV = {Nth @actualArgs 1}
         Fea  = {GetData FeaV}
         Attrs= case Self of unit then unit
                else {Self getAttributes($)}
                end
         Props= case Self of unit then unit
                else {Self getProperties($)}
                end
      in
         case
            Attrs==unit
            orelse {Not {DetTests.det FeaV}}
            orelse {Member Fea Attrs}
         then
            skip
         else
            Val  = {GetData {Nth @actualArgs 2}}
            Expr = case {System.printName {GetData @designator}}
                   of 'Object.\'<-\'' then oz(Fea) # ' <- ' # oz(Val)
                   elseof 'Object.\'@\'' then '@' # oz(Fea) # ' = ' # oz(Val)
                   end
            Final = (Props\=unit andthen {Member final Props})
            Hint = case Final
                   then '(correct use requires method application)'
                   else '(may be a correct forward declaration)'
                   end
            Cls  = case Final
                   then 'In final class'
                   else 'In class'
                   end
         in
            case
               Final orelse
               {Ctrl.switches getSwitch(warnforward $)}
            then
               {Ctrl.rep
                warn(coord: @coord
                     kind:  SAGenWarn
                     msg:   'applying ' #
                     {System.printName {GetData @designator}} #
                     ' to unavailable attribute'
                     items: [hint(l:'Expression' m:Expr)
                             hint(l:Cls
                                  m:pn({System.printName {Self getValue($)}}))
                             hint(l:'Expected' m:{SetToVS {Ozify Attrs}})
                             line(Hint)])}
            else skip end
         end
      end

      meth doAnd(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         BVO3 = {Nth @actualArgs 3}
         Val1 = {GetData BVO1}
         Val2 = {GetData BVO2}
      in
         case
            {IsDet Val1} andthen {IsDet Val2}
         then
            Token = {Bool2Token {And Val1 Val2}}
         in
            {Ctrl setErrorMsg('boolean and failed')}
            {Ctrl setUnifier(BVO3 Token)}

            {BVO3 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else
            skip
         end
      end

      meth doOr(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         BVO3 = {Nth @actualArgs 3}
         Val1 = {GetData BVO1}
         Val2 = {GetData BVO2}
      in
         case
            {IsDet Val1} andthen {IsDet Val2}
         then
            Token = {Bool2Token {Or Val1 Val2}}
         in
            {Ctrl setErrorMsg('boolean and failed')}
            {Ctrl setUnifier(BVO3 Token)}

            {BVO3 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else
            skip
         end
      end

      meth doNot(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         Val1 = {GetData BVO1}
      in
         case
            {IsDet Val1}
         then
            Token = {Bool2Token {Not Val1}}
         in
            {Ctrl setErrorMsg('boolean not failed')}
            {Ctrl setUnifier(BVO2 Token)}

            {BVO2 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else skip end
      end

      meth doLabel(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         Val  = {BVO1 getValue($)}
      in
         case
            {HasFeature Val ImAConstruction}
         then
            Lab = {Val getLabel($)}
         in
            {Ctrl setErrorMsg('label assertion failed')}
            {Ctrl setUnifier(BVO2 Lab)}

            {BVO2 unify(Ctrl Lab)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else skip end
      end

      meth doWidth(Ctrl)
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
         Data  = {GetData BVO1}
      in
         case
            {IsDet Data}
         then
            IntVal= {New Core.intNode init({Width Data} @coord)}
         in
            {Ctrl setErrorMsg('width assertion failed')}
            {Ctrl setUnifier(BVO2 IntVal)}

            {BVO2 unifyVal(Ctrl IntVal)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else skip end
      end

      meth doProcedureArity(Ctrl)
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
         Data  = {GetData BVO1}
      in
         case
            {IsDet Data}
         then
            IntVal = {New Core.intNode init({Procedure.arity Data} @coord)}
         in
            {Ctrl setErrorMsg('assertion of procedure arity failed')}
            {Ctrl setUnifier(BVO2 IntVal)}

            {BVO2 unifyVal(Ctrl IntVal)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else skip end
      end

      meth doCheckType(TestType Test Ctrl)
\ifdef DEBUGSA
         {System.show doCheckType(TestType Test)}
\endif
         case TestType
         of det  then SABuiltinApplication, DoDetType(Test Ctrl)
         [] rec  then SABuiltinApplication, DoRecDetType(Test Ctrl)
         [] kind then SABuiltinApplication, DoKindedType(Test Ctrl)
         end
      end

      meth DoDetType(Test Ctrl)
\ifdef DEBUGSA
         {System.show doDetType(Test @actualArgs)}
\endif
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
      in
         case {DetTests.det BVO1} then
            {Ctrl setErrorMsg('type test failed')}

            case {Test {GetData BVO1}} then
               {Ctrl setUnifier(BVO2 RunTime.tokens.'true')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'true')}
            else
               {Ctrl setUnifier(BVO2 RunTime.tokens.'false')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'false')}
            end

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         else skip end
      end

      meth DoRecDetType(ThreeValuedTest Ctrl)
\ifdef DEBUGSA
         {System.show doRecDetType(ThreeValuedTest)}
\endif
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
\ifdef DEBUGSA
         {System.show doRecDetType({GetFullData BVO1})}
\endif
      in
         {Ctrl setErrorMsg('type test failed')}

         case {ThreeValuedTest {GetFullData BVO1}}
         of true then
            {Ctrl setUnifier(BVO2 RunTime.tokens.'true')}
            {BVO2 unifyVal(Ctrl RunTime.tokens.'true')}
         elseof false then
            {Ctrl setUnifier(BVO2 RunTime.tokens.'false')}
            {BVO2 unifyVal(Ctrl RunTime.tokens.'false')}
         elseof unit then
            skip
         end
         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}
      end

      meth DoKindedType(Test Ctrl)
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
      in
         {Ctrl setErrorMsg('type test failed')}

         case {DetTests.detOrKinded BVO1} then
            case {Test {GetData BVO1}} then
               {Ctrl setUnifier(BVO2 RunTime.tokens.'true')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'true')}
            else
               {Ctrl setUnifier(BVO2 RunTime.tokens.'false')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'false')}
            end
         else skip end
         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}
      end
   end

   class SAApplication
      from SABuiltinApplication

      meth AssertArity(Ctrl)
         DesigType = {@designator getType($)}
         ProcType  = case {Length @actualArgs}
                     of 0 then {OzTypes.encode 'procedure/0' nil}
                     [] 1 then {OzTypes.encode unaryProcOrObject nil}
                     [] 2 then {OzTypes.encode 'procedure/2' nil}
                     [] 3 then {OzTypes.encode 'procedure/3' nil}
                     [] 4 then {OzTypes.encode 'procedure/4' nil}
                     [] 5 then {OzTypes.encode 'procedure/5' nil}
                     [] 6 then {OzTypes.encode 'procedure/6' nil}
                     else {OzTypes.encode 'procedure/>6' nil} end
      in
         case
            {ConstrainTypes DesigType ProcType}
         then
            skip
         else
            PN  = {@designator getPrintName($)}
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'wrong arity in application of ' # pn(PN)
                   items: [hint(l:'Procedure type' m:{TypeToVS DesigType})
                           hint(l:'Application arity' m:{Length @actualArgs})
                           hint(l:'Application (names)'
                                m:{ApplToVS pn(PN)|PNs})
                           hint(l:'Application (values)'
                                m:{ApplToVS pn(PN)|Vals})])}
         end
      end

      meth sa(Ctrl)

\ifdef DEBUGSA
         {System.show application({@designator getPrintName($)} )}
\endif

         case
            SAApplication, checkDesignatorBuiltin($)
         then
            BIName = {System.printName {GetData @designator}}
            ArgsOk
         in
\ifdef DEBUGSA
            {System.show applying(BIName)}
\endif
            case
               {CondSelect BINameToMethod BIName unit}
            of
               unit
            then
               SABuiltinApplication, checkArguments(Ctrl false ArgsOk)
            elseof
               M
            then
\ifdef DEBUGSA
               {System.show applyingKnown(BIName)}
\endif
               SABuiltinApplication, checkArguments(Ctrl true ArgsOk)
               case
                  ArgsOk
               then
                  Msg = {AdjoinAt M {Width M}+1 Ctrl}
               in
                  SABuiltinApplication, Msg
               else
                  skip
               end
            end

            %%
            %% type-assertions go here if no type error raised yet
            %%

\ifdef DEBUGSA
            {System.show doneMsg(ArgsOk)}
\endif

            case ArgsOk then
               SABuiltinApplication, assertTypes(Ctrl BIName)
            else skip end

         elsecase
            SAApplication, checkDesignatorProcedure($)
         then
            DVal = {GetData @designator}
            PN   = {@designator getPrintName($)}
            ExpA = {Procedure.arity DVal}
            GotA = {Length @actualArgs}
         in
            case
               GotA \= ExpA
            then
               PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
               Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal number of arguments in application'
                      items: [hint(l:'Procedure' m:pn(PN))
                              hint(l:'Expected' m:ExpA)
                              hint(l:'Found' m:GotA)
                              hint(l:'Application (names)'
                                   m:{ApplToVS pn(PN)|PNs})
                              hint(l:'Application (values)'
                                   m:{ApplToVS pn(PN)|Vals})])}
            else skip end

         elsecase
            SAApplication, checkDesignatorObject($)
         then
            PN   = {@designator getPrintName($)}
            Cls  = {{@designator getValue($)} getClassNode($)}
            GotA = {Length @actualArgs}
         in
            case
               GotA \= 1
            then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal number of arguments in object application'
                      items: [hint(l:'Object' m:pn(PN))
                              hint(l:'Expected' m:1)
                              hint(l:'Found' m:GotA)])}
            elsecase
               Cls == unit
            then
               skip
            else
               Msg  = {Nth @actualArgs 1}
               Meth = {Cls getMethods($)}
            in
               SAApplication, checkMessage(Ctrl Msg Meth object PN)
            end

         elsecase
            {DetTests.det @designator}
         then
            Val = {GetPrintData @designator}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SAGenError
                   msg:   'applying non-procedure and non-object ' # oz(Val))}
         else
            SAApplication, AssertArity(Ctrl)
         end
      end

      meth checkDesignatorBuiltin($)
         {DetTests.det @designator}
         andthen {CompilerSupport.isBuiltin {GetData @designator}}
      end
      meth checkDesignatorProcedure($)
         {DetTests.det @designator}
         andthen {TypeTests.procedure {GetData @designator}}
      end
      meth checkDesignatorObject($)
         {DetTests.det @designator}
         andthen {TypeTests.object {GetData @designator}}
      end
      meth applyEnvSubst(Ctrl)
         {@designator applyEnvSubst(Ctrl)}
         {ForAll @actualArgs
          proc {$ A}
             {A applyEnvSubst(Ctrl)}
          end}
      end

   end

   class SABoolCase
      meth saDescend(Ctrl)
         % descend with global environment
         % will be saved and restored in clauses
         case {DetTests.det @arbiter}
            andthen {TypeTests.bool {GetData @arbiter}}
         then
            PN = {@arbiter getPrintName($)}
         in
\ifdef DEBUGSA
         {System.show isConst(PN)}
\endif
            case
               {TypeTests.'true' {GetData @arbiter}}
            then
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   'boolean guard ' # pn(PN) # ' is always true')}

               local T N in
                  {Ctrl getTopNeeded(T N)}
                  {Ctrl notTopNotNeeded}
                  {@alternative saDescend(Ctrl)}
                  {Ctrl setTopNeeded(T N)}
               end

               {@consequent saDescendAndCommit(Ctrl)}
            else
               % {TypeTests.'false' {GetData @arbiter}}
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   'boolean guard ' # pn(PN) # ' is always false')}

               local T N in
                  {Ctrl getTopNeeded(T N)}
                  {Ctrl notTopNotNeeded}
                  {@consequent saDescend(Ctrl)}
                  {Ctrl setTopNeeded(T N)}
               end

               {@alternative saDescendAndCommit(Ctrl)}
            end

         elsecase
            {ConstrainTypes
             {@arbiter getType($)}
             {OzTypes.encode bool nil}}
         then
            T N in
            {Ctrl getTopNeeded(T N)}
            {Ctrl notTopNotNeeded}

            {@consequent
             saDescendWithValue(Ctrl @arbiter RunTime.tokens.'true')}

            {@alternative
             saDescendWithValue(Ctrl @arbiter RunTime.tokens.'false')}

            {Ctrl setTopNeeded(T N)}
         else
            PN  = {@arbiter getPrintName($)}
            Val = {GetPrintData @arbiter}
         in
            {Ctrl.rep
             error(coord: @coord
                   msg:   'Non-boolean arbiter in boolean case statement'
                   kind:  SATypeError
                   items: hint(l:'Value' m:oz(Val))
                          | hint(l:'Type' m:{TypeToVS {@arbiter getType($)}})
                          | case {IsFree Val} then nil
                            else [hint(l:'Name' m:pn(PN))] end)}
         end
      end
      meth applyEnvSubst(Ctrl)
         {@arbiter applyEnvSubst(Ctrl)}
      end
   end

   class SABoolClause
      meth saDescendWithValue(Ctrl Arbiter Val)
         ArbV = {Arbiter getVariable($)}
         % arbiter value unknown, hence also save arbiter value
         Env  = {GetGlobalEnv {Add ArbV @globalVars}}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {Arbiter unifyVal(Ctrl Val)}
         SAStatement, saBody(Ctrl @statements)

         {Ctrl setTopNeeded(T N)}
         {InstallGlobalEnv Env}
      end
      meth saDescend(Ctrl)
         % arbiter value known, hence no need to save arbiter value
         Env  = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         SAStatement, saBody(Ctrl @statements)

         {Ctrl setTopNeeded(T N)}
         {InstallGlobalEnv Env}
      end
      meth saDescendAndCommit(Ctrl)
         SAStatement, saBody(Ctrl @statements)
      end
   end

   class SAPatternCase
\ifdef DEBUGSA
      meth sa(Ctrl)
         {System.show
          patternCase(@clauses {Map @globalVars
                                fun {$ V} {V getPrintName($)} end})}
      end
\endif
      meth saDescend(Ctrl)
         % descend with global environment
         % will be saved and restored in clauses
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {ForAll @clauses
          proc {$ C} {C saDescendWith(Ctrl @arbiter)} end}
         {@alternative saDescendWith(Ctrl @arbiter)}

         {Ctrl setTopNeeded(T N)}
      end
      meth applyEnvSubst(Ctrl)
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {@arbiter applyEnvSubst(Ctrl)}
         {ForAll @clauses
          proc {$ C} {C applyEnvSubst(Ctrl)} end}

         {Ctrl setTopNeeded(T N)}
      end
   end

   class SAPatternClause
      meth saDescendWith(Ctrl Arbiter)
\ifdef DEBUGSA
         {System.show patternClause}
\endif
         ArbV  = {Arbiter getVariable($)}
         % also save arbiter !!
         Env   = {GetGlobalEnv {Add ArbV @globalVars}}
         T N
      in
         {@pattern sa(Ctrl)}

         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {Ctrl setErrorMsg('pattern never matches')}
         {Ctrl setUnifier(Arbiter @pattern)}

         {Arbiter unify(Ctrl @pattern)}
         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}

         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
      meth applyEnvSubst(Ctrl)
         {@pattern applyEnvSubst(Ctrl)}
      end
   end

   class SARecordPattern
      from SAConstructionOrPattern
   end

   %
   % equation pattern:
   %   behave like equations for sa
   %   and like their rhs for all properties
   %
   class SAEquationPattern
      meth getValue($)
         {@right getValue($)}
      end
      meth setValue(Val)
         {@right setValue(Val)}
      end
      meth getLastValue($)
         {@right getLastValue($)}
      end
      meth setLastValue(Val)
         {@right setLastValue(Val)}
      end
      meth getLabel($)
         {@right getLabel($)}
      end
      meth getArgs($)
         {@right getArgs($)}
      end
      meth getType($)
         {@right getType($)}
      end
      meth isOpen($)
         {@right isOpen($)}
      end

      meth deref(VO)
         {@right deref(VO)}
      end

      meth sa(Ctrl)
\ifdef DEBUGSA
         {System.show equationPattern}
\endif
         {@right sa(Ctrl)}                            % analyse right hand side
         {@left unify(Ctrl @right)}                   % l -> r
      end

      meth reachable(Vs $)
\ifdef LOOP
         {System.show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
\endif
         {@right reachable({@left reachable(Vs $)} $)}
      end

      % unify: _ x Token U Construction U ValueNode

      meth unify(Ctrl RHS)
\ifdef LOOP
         {System.show unifyEP(RHS)}
\endif
         {@right unify(Ctrl RHS)}
      end

      meth applyEnvSubst(Ctrl)
         {@left applyEnvSubst(Ctrl)}
         {@right applyEnvSubst(Ctrl)}
      end
   end

   class SAElseNode
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
      meth saDescendWithValue(Ctrl Arbiter Val)
         ArbV  = {Arbiter getVariable($)}
         Env   = {GetGlobalEnv {Add ArbV @globalVars}}
         T N
      in
         {Arbiter unifyVal(Ctrl Val)}

         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
      meth saDescendWith(Ctrl Arbiter)
         ArbV  = {Arbiter getVariable($)}
         % also save arbiter !!
         Env   = {GetGlobalEnv {Add ArbV @globalVars}}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
      meth saDescendAndCommit(Ctrl)
         SAStatement, saBody(Ctrl @statements)
      end
   end
   class SANoElse
      meth saDescend(Ctrl)
         skip
      end
      meth saDescendWithValue(Ctrl Arbiter Val)
         skip
      end
      meth saDescendWith(Ctrl Arbiter)
         skip
      end
      meth saDescendAndCommit(Ctrl)
         skip
      end
   end

   class SAThreadNode
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
   end

   class SATryNode
      meth saDescend(Ctrl)
         Env1 Env2
         T N
      in
         % check try clause
         Env1 = {GetGlobalEnv @globalVars}

         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @tryStatements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env1}

         % check catch clause

         % the main reason to copy the global environment
         % here a second time (and not reuse the first one) is
         % that during GetGlobalEnv the types of all reachable
         % variables are cloned (possible optimization: compute
         % reachable variables only once and _only_ clone types here)

         Env2 = {GetGlobalEnv @globalVars}

         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @catchStatements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env2}
      end
   end

   class SALockNode
      meth saDescend(Ctrl)
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}
      end
      meth applyEnvSubst(Ctrl)
         {@lockVar applyEnvSubst(Ctrl)}
      end
   end

   class SAClassNode
      feat
         isComplex:false

      meth saSimple(Ctrl)
         IllClass TestClass
         DummyClass = {MakeDummyClass {@designator getPrintName($)}}
         Value = {New Core.classToken init(DummyClass)}
      in
         isToplevel <- {Ctrl getTop($)}

\ifdef ANALYSEINHERITANCE

         {AllUpTo @parents
          DetTypeTests.'class' ?IllClass ?TestClass} % do type test, return exc

\ifdef DEBUG
         {System.show classNode({@designator getPrintName($)}
                         {Map @parents fun {$ X} {X getPrintName($)} end})}
\endif
         case
            TestClass
         then
            PTs = {Map @parents fun {$ X} {X getValue($)} end}
\ifdef INHERITANCE
            NoDet
\endif
            PsDet
         in
            {AllUpTo @parents DetTests.det
\ifdef INHERITANCE
             ?NoDet
\else
             _
\endif
             ?PsDet}

            SAClassNode, InheritProperties(Value Ctrl PTs)
            SAClassNode, InheritAttributes(Value Ctrl PTs PsDet)
            SAClassNode, InheritFeatures(Value Ctrl PTs PsDet)
            SAClassNode, InheritMethods(Value Ctrl PTs PsDet)

\ifdef INHERITANCE
            case PsDet
            then skip else
               {Ctrl.rep
                warn(coord: @coord
                     kind:  SAGenWarn
                     msg:   'insufficient information in inheritance'
                     items: [hint(l:'Parent'
                                  m:pn({{Nth @parents NoDet}
                                        getPrintName($)}))])}
            end
\endif

         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'inheriting from non-class ' # oz({GetPrintData IllClass}))}
         end

\endif

         {Ctrl setErrorMsg('class definition failed')}
         {Ctrl setUnifier(@designator Value)}

         {@designator unify(Ctrl Value)}

         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}

\ifdef DEBUGSA
         {System.show lookedAhead({@designator getPrintName($)} Value)}
\endif
      end

      meth InheritProperties(Value Ctrl PTs)
         IllAtom TestAtom
      in

\ifdef DEBUGSA
         {System.show properties(@properties)}
\endif

         {AllUpTo @properties DetTypeTests.atom ?IllAtom ?TestAtom}

         % type test
         case TestAtom then
            % new determined properties
            Pro  = {Filter {Map @properties GetData}
                    TypeTests.atom}
            % properties of det parents
            PPro = {Map PTs fun {$ P}
                               case {DetTests.det P}
                               then {P getProperties($)}
                               else unit end
                            end}
            NthFinal TestFinal
         in
            {SomeUpToN PPro
             fun {$ P} P\=unit andthen {Member final P} end
             ?NthFinal ?TestFinal}

            case TestFinal then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   'inheritance from final class '
                      # pn({System.printName
                            {{Nth PTs NthFinal} getValue($)}}))}
            else
               NonUnitPro = {Filter PPro fun {$ P} P\=unit end}
            in
               % type & det test
               {Value setProperties({UnionAll Pro|NonUnitPro})}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-atomic class property '
                   # pn({IllAtom getPrintName($)}))}

         end
      end
      meth InheritAttributes(Value Ctrl PTs PsDet)
         Att  = {Map @attributes FirstOrId}
         IllFeat TestFeat
      in
         {AllUpTo Att DetTypeTests.feature ?IllFeat ?TestFeat}

\ifdef DEBUGSA
         {System.show attributes(Att TestFeat {Map Att GetData})}
\endif

         case
            TestFeat
         then
            AData = {Map Att GetData}
         in
            % distinct attributes required
            case
               {AllDistinct AData}
            then
               % parents determined?
               case PsDet then
                  PAtt = {Map PTs fun {$ P} {P getAttributes($)} end}
               in
                  % type & det test
                  case
                     {Not {Member unit PAtt}}
                     andthen
                     {All AData TypeTests.feature}
                  then
                     {Value setAttributes({UnionAll AData|PAtt})}
                  else
\ifdef INHERITANCE
                     {Ctrl.rep
                      warn(coord: @coord
                           kind:  SAGenWarn
                           msg:   'insufficient information about class attributes'
                          )}
\else
                     skip
\end
                  end
               % complain about parents elsewhere
               else skip end
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'duplicate attributes in class definition'
                      items: [hint(l:'Attributes found'
                                   m:{SetToVS {Ozify AData}})])}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                           msg:   'illegal class attribute '
                   items: [hint(l:'Attribute found' m:oz({GetPrintData IllFeat}))])}
         end
      end
      meth InheritFeatures(Value Ctrl PTs PsDet)
         Fea = {Map @features FirstOrId}
         IllFeat TestFeat
      in
\ifdef DEBUGSA
         {System.show features(Fea)}
\endif

         {AllUpTo Fea DetTypeTests.feature ?IllFeat ?TestFeat}

         case
            TestFeat
         then
            FData = {Map Fea GetData}
         in
            % distinct features required
            case
               {AllDistinct FData}
            then
               % parents determined?
               case PsDet then
                  PFea = {Map PTs fun {$ P} {P getFeatures($)} end}
               in
                  % type & det test
                  case
                     {Not {Member unit PFea}}
                     andthen
                     {All FData TypeTests.feature}
                  then
                     {Value setFeatures({UnionAll FData|PFea})}
                  else
\ifdef INHERITANCE
                     {Ctrl.rep
                      warn(coord: @coord
                           kind:  SAGenWarn
                           msg:   'insufficient information about class features')}
\else
                     skip
\end
                  end
               % complain about parents elsewhere
               else skip end
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'duplicate features in class definition'
                      items: [hint(l:'Features found'
                                   m:{SetToVS {Ozify FData}})])}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'illegal class feature '
                   items: [hint(l:'Feature found' m:oz({GetPrintData IllFeat}))])}
         end
      end
      meth InheritMethods(Value Ctrl PTs PsDet)
         Met  = {Map @methods fun {$ M} {M getPattern($)} end}
         IllLab TestLab
         IllReqMeth TestReq
         IllOptMeth TestOpt
      in
\ifdef DEBUGSA
         {System.show methods(PTs Met)}
\endif

         {AllUpTo Met
          fun {$ L#_} {DetTypeTests.literal L} end ?IllLab ?TestLab}
         {AllUpTo Met
          fun {$ _#(R#_)} {All R DetTypeTests.feature} end ?IllReqMeth ?TestReq}
         {AllUpTo Met
          fun {$ _#(_#O)} O==unit orelse {All O DetTypeTests.feature} end ?IllOptMeth ?TestOpt}

         case
            TestLab
         then
            case
               TestReq
            then
               case
                  TestOpt
               then
                  MData = {Map Met
                           fun {$ L#(R#O)}
                              {GetData L} #
                              ({Map R GetData} #
                               case O==unit then O
                               else {Map O GetData} end)
                           end}
                  MethNames = {Map MData fun {$ L#_} L end}
               in
            % distinct method names required
                  case
                     {AllDistinct MethNames}
                  then
               % parents determined?
                     case PsDet then
                        PMet = {Map PTs fun {$ P} {P getMethods($)} end}
                     in
                  % type & det test
                        case
                           {All MethNames TypeTests.literal}
                           andthen
                           {Not {Member unit PMet}}
                        then
                           NewMet   = {List.toRecord m MData}
                           TotalMet = {ApproxInheritance PMet NewMet}
                        in
                           {Value setMethods(TotalMet)}
                        else
\ifdef INHERITANCE
                           {Ctrl.rep
                            warn(coord: @coord
                                 kind:  SAGenWarn
                                 msg:   'insufficient information about method labels')}
\else
                           skip
\end
                        end
               % complain about parents elsewhere
                     else skip end
                  else
                     {Ctrl.rep
                      error(coord: @coord
                            kind:  SAGenError
                            msg:   'duplicate method names in class definition'
                            items: [hint(l:'Method names'
                                         m:{SetToVS {Ozify MethNames}})])}
                  end
               else
                  L#(_#O) = IllOptMeth
                  IllOpt  = {GetPrintData {AllUpTo O DetTypeTests.feature $ _}}
               in
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SATypeError
                         msg:   'illegal feature in method definition'
                         items: [hint(l:'Message label' m:oz({GetPrintData L}))
                                 hint(l:'Illegal feature' m:oz(IllOpt))])}
               end
            else
               L#(R#_) = IllReqMeth
               IllReq  = {GetPrintData {AllUpTo R DetTypeTests.feature $ _}}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   'illegal feature in method definition'
                      items: [hint(l:'Message found' m:oz({GetPrintData L}))
                              hint(l:'Illegal feature' m:oz(IllReq))])}
            end
         else
            L#_ = IllLab
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-literal method label '
                   items: [hint(l:'Label found' m:oz({GetPrintData L}))])}
         end
      end
      meth saDescend(Ctrl)
         {Ctrl pushSelf({@designator getValue($)})}

         % descend with global environment
         % will be saved in methods
         SAClassNode, SaBody(@methods Ctrl)

         {Ctrl popSelf}
      end
      meth SaBody(Methods Ctrl)
         case Methods of M|Mr then
            {M saDescend(Ctrl)}
            SAClassNode, SaBody(Mr Ctrl)
         [] nil then skip
         end
      end
      meth applyEnvSubst(Ctrl)

         {@designator applyEnvSubst(Ctrl)}
         {ForAll @parents
          proc {$ P}
             {P applyEnvSubst(Ctrl)}
          end}
         {ForAll @properties
          proc {$ P} {P applyEnvSubst(Ctrl)} end}
         {ForAll @attributes
          proc {$ I}
             case I of F#T then
                {F applyEnvSubst(Ctrl)}
                {T applyEnvSubst(Ctrl)}
             else {I applyEnvSubst(Ctrl)} end
          end}
         {ForAll @features
          proc {$ I}
             case I of F#T then
                {F applyEnvSubst(Ctrl)}
                {T applyEnvSubst(Ctrl)}
             else {I applyEnvSubst(Ctrl)} end
          end}
         {ForAll @methods
          proc {$ M} {M preApplyEnvSubst(Ctrl)} end}
      end
   end

   class SAMethod
      meth getPattern($)
         Fs R1 O1 R2 O2
      in
         Fs = {Map @formalArgs fun {$ M} {M getFormal($)} end}
         {Partition Fs fun {$ F} {Label F}==required end R1 O1}

         R2 = {Map R1 fun {$ R} R.1 end}
         O2 = {Map O1 fun {$ O} O.1 end}

         @label # (R2 # O2)
      end
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
         if {Ctrl getTop($)} then
            predicateRef <- {Ctrl declareToplevelProcedure($)}
         end
      end
      meth preApplyEnvSubst(Ctrl)
         {@label applyEnvSubst(Ctrl)}
         {ForAll @formalArgs
          proc {$ A} {A applyEnvSubst(Ctrl)} end}
      end
   end
   class SAMethodWithDesignator
      meth getPattern($)
         Fs R1 O1 R2 O2
      in
         Fs = {Map @formalArgs fun {$ M} {M getFormal($)} end}
         {Partition Fs fun {$ F} {Label F}==required end R1 O1}

         R2 = {Map R1 fun {$ R} R.1 end}
         O2 = case @isOpen then unit else {Map O1 fun {$ O} O.1 end} end

         @label # (R2 # O2)
      end
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
   end

   class SAMethFormal
      meth getFormal($)
         required(@feature)
      end
      meth applyEnvSubst(Ctrl)
         {@feature applyEnvSubst(Ctrl)}
      end
   end
   class SAMethFormalOptional
      meth getFormal($)
         optional(@feature)
      end
   end
   class SAMethFormalWithDefault
      meth getFormal($)
         optional(@feature)
      end
   end

   class SAObjectLockNode
      meth saDescend(Ctrl)
         % descend with same environment
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}
      end
   end

   class SAGetSelf
      meth sa(Ctrl)
         skip   %--** do more here if +warnforward
      end
      meth applyEnvSubst(Ctrl)
         {@destination applyEnvSubst(Ctrl)}
      end
   end

   class SAIfNode
      meth saDescend(Ctrl)
         % descend with global environment
         % will be saved and restored in clauses
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {ForAll @clauses
          proc {$ C} {C saDescend(Ctrl)} end}
         {@alternative saDescend(Ctrl)}

         {Ctrl setTopNeeded(T N)}
      end
   end

   class SAChoicesAndDisjunctions
      meth saDescend(Ctrl)
         % descend with global environment
         % will be saved and restored in clauses
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {ForAll @clauses
          proc {$ C} {C saDescend(Ctrl)} end}

         {Ctrl setTopNeeded(T N)}
      end
   end

   class SAClause
      meth saDescend(Ctrl)
         % shared local environment
         % for guard and body
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @guard)
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env}
      end
   end

   class SAValueNode
      attr type: unit
      meth init()
         type <- {OzValueToType @value}
      end
      meth getType($)
         @type
      end
      meth getPrintType(D $)
         {TypeToVS @type}
      end
      meth reflectType(_ $)
         value(@value)
      end
      meth getData(IsObj $)
         @value
      end
      meth getFullData(D IsData $)
         @value
      end

      meth getLastValue($)
         self
      end
      meth deref(VO)
         skip
      end
      meth reachable(Vs $)
         Vs
      end

      % unify: _ x Token U ValueNode

      meth unify(Ctrl RHS)
         case
            {UnifyTypesOf self RHS Ctrl @coord}
         then
            case
               @value == {RHS getValue($)}
            then
               skip
            else
               {IssueUnificationFailure Ctrl @coord
                [hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz({RHS getValue($)}))]}
            end
         else
            skip % do not continue on type error
         end
      end

      meth sa(Ctrl)
         skip
      end
      meth applyEnvSubst(Ctrl)
         skip
      end
   end

   class SAVariable
      attr
         lastValue : unit
         type: unit
      meth init()
         type <- {OzTypes.encode value nil}
      end
      meth getType($)
         @type
      end
      meth setType(T)
         type <- T
      end
      meth getPrintType(D $)
         {TypeToVS @type}
      end
      meth outputDebugType($)
         case @lastValue == unit then {TypeToVS @type}
         else {@lastValue getPrintType(AnalysisDepth $)}
         end
      end
      meth outputDebugMeths($)
         case @lastValue \= unit
            andthen {HasFeature @lastValue kind}
         then
            case @lastValue.kind
            of 'class' then
               case {@lastValue getMethods($)}
               of unit then unit
               elseof Ms then {Arity Ms} end
            [] 'object' then
               case {{@lastValue getClassNode($)} getMethods($)}
               of unit then unit
               elseof Ms then {Arity Ms} end
            else unit end
         else unit end
      end
      meth outputDebugAttrs($)
         case @lastValue \= unit
            andthen {HasFeature @lastValue kind}
         then
            case @lastValue.kind
            of 'class' then {@lastValue getAttributes($)}
            [] 'object' then {{@lastValue getClassNode($)} getAttributes($)}
            else unit end
         else unit end
      end
      meth outputDebugFeats($)
         case @lastValue \= unit
            andthen {HasFeature @lastValue kind}
         then
            case @lastValue.kind
            of 'class' then {@lastValue getFeatures($)}
            [] 'object' then {{@lastValue getClassNode($)} getFeatures($)}
            else unit end
         else unit end
      end
      meth outputDebugProps($)
         case @lastValue \= unit
            andthen {HasFeature @lastValue kind}
         then
            case @lastValue.kind
            of 'class' then {@lastValue getProperties($)}
            else unit end
         else unit end
      end
      meth getLastValue($)
         @lastValue
      end
      meth setLastValue(O)
         lastValue <- O
         case O == unit then skip
         else type <- {O getType($)} end
      end
      meth deref(VO)
         case
            @lastValue == unit                        % is free
         then
            SAVariable, setLastValue(VO)              % initialize with var-occ

         elsecase
            {@lastValue isVariableOccurrence($)}
         then
            NewVal = {@lastValue getValue($)}         % getLastValue($) ?
         in
            SAVariable, setLastValue(NewVal)          % var path compression
            case @lastValue == NewVal
            then skip else
               SAVariable, deref(VO)                  % recur
            end
         elsecase
            {@lastValue isConstruction($)}
         then
            NewVal = {@lastValue getLastValue($)}
         in
            case
               @lastValue == NewVal
            then
               skip                                   % self reference
            elsecase
               NewVal == unit
            then
               {@lastValue setLastValue(@lastValue)}  % non initialised
            else
               SAVariable, setLastValue(NewVal)       % constr path compression
               case
                  @lastValue == NewVal
               then skip else
                  SAVariable, deref(VO)               % recur
               end
            end
         else
            % number, atom, token (ground value)
            skip
         end
      end
      meth valToSubst(Value)
         {self ValToSubst(@printName nil AnalysisDepth Value)}
      end
      meth ValToSubst(PrintNameBase Seen Depth Value)
         case
            Depth =< 0
         then
\ifdef DEBUGSA
            {System.show valToSubstBreakDepth(Value)}
\endif
            SAVariable, setLastValue(unit) % stop analysis here

         elsecase
            {IsDet Value}
         then

\ifdef DEBUGSA
            {System.show valToSubstInt(Value)}
\endif

            case
               {IsInt Value}
            then
               SAVariable, setLastValue({New Core.intNode init(Value unit)})

            elsecase
               {IsFloat Value}
            then
               SAVariable, setLastValue({New Core.floatNode init(Value unit)})

            elsecase
               {IsAtom Value}
            then
               SAVariable, setLastValue({New Core.atomNode init(Value unit)})

            elsecase
               {IsName Value}
            then
               SAVariable,
               setLastValue({New Core.nameToken init(Value true)})

            elsecase
               {IsRecord Value}
            then
               RecArgs   = {Record.toListInd Value}
               Lab       = {Label Value}
               ConstrLab = case {IsAtom Lab} then
                              {New Core.atomNode init(Lab unit)}
                           elsecase {IsName Lab} then
                              {New Core.nameToken init(Lab true)}
                           end
               ConstrArgs ConstrValArgs Constr
            in
               {self recordValToArgs(RecArgs
                                     (Value#self)|Seen
                                     Depth
                                     PrintNameBase
                                     ?ConstrArgs
                                     ?ConstrValArgs)}

               Constr = {New Core.construction init(ConstrLab ConstrArgs false)}
               {Constr setValue({List.toRecord Lab ConstrValArgs})}
               {Constr makeType}

               SAVariable, setLastValue(Constr)

            elsecase
               {CompilerSupport.isBuiltin Value}
            then
               BI      = {New Core.builtinToken init(Value)}
            in
               SAVariable, setLastValue(BI)

            elsecase
               {IsProcedure Value}
            then
               ProcToken = {New Core.procedureToken init(Value)}
            in
               ProcToken.predicateRef = Value
               SAVariable, setLastValue(ProcToken)

            elsecase
               {IsClass Value}
            then
               Cls = {New Core.classToken init(Value)}
               Meths = {Record.make m {Class.methodNames Value}}
               Attrs = {Class.attrNames Value}
               Feats = {Class.featNames Value}
               Props = {Class.propNames Value}
            in
               {Record.forAll Meths fun {$} nil#unit end}
               {Cls setMethods(Meths)}
               {Cls setAttributes(Attrs)}
               {Cls setFeatures(Feats)}
               {Cls setProperties(Props)}
               SAVariable, setLastValue(Cls)

            elsecase
               {IsObject Value}
            then
               TheClass = {Class.get Value}
               Meths = {Record.make m {Class.methodNames TheClass}}
               Attrs = {Class.attrNames TheClass}
               Feats = {Class.featNames TheClass}
               Props = {Class.propNames TheClass}
               Cls   = {New Core.classToken init(TheClass)}
            in
               {Record.forAll Meths fun {$} nil#unit end}
               {Cls setMethods(Meths)}
               {Cls setAttributes(Attrs)}
               {Cls setFeatures(Feats)}
               {Cls setProperties(Props)}
               SAVariable, setLastValue({New Core.objectToken init(Value Cls)})

            elsecase
               {IsCell Value}
            then
               SAVariable, setLastValue({New Core.cellToken init(Value)})

            elsecase
               {IsLock Value}
            then
               SAVariable, setLastValue({New Core.lockToken init(Value)})

            elsecase
               {IsPort Value}
            then
               SAVariable, setLastValue({New Core.portToken init(Value)})

            elsecase
               {IsArray Value}
            then
               DummyArray = {New Core.arrayToken init(Value)}
            in
               SAVariable, setLastValue(DummyArray)

            elsecase
               {IsDictionary Value}
            then
               SAVariable, setLastValue({New Core.dictionaryToken init(Value)})

            elsecase
               {IsSpace Value}
            then
               SAVariable, setLastValue({New Core.spaceToken init(Value)})

            elsecase
               {IsThread Value}
            then
               SAVariable, setLastValue({New Core.threadToken init(Value)})

            elsecase
               {BitArray.is Value}
            then
               SAVariable, setLastValue({New Core.bitArrayToken init(Value)})

            elsecase
               {IsChunk Value}
            then
               SAVariable, setLastValue({New Core.chunkToken init(Value)})

            else
               SAVariable, setLastValue(unit)
            end

         else
            SAVariable, setLastValue(unit)
         end
      end
      meth recordValToArgs(RecArgs Seen Depth PrintNameBase ?ConstrArgs ?ConstrValArgs)

         case RecArgs
         of (F#X) | RAs
         then
            Assoc = {PLDotEQ X Seen}
            A = case {IsAtom F} then
                   {New Core.atomNode init(F unit)}
                elsecase {IsName F} then
                   {New Core.nameToken init(F true)}
                elsecase {IsInt F} then
                   {New Core.intNode init(F unit)}
                end
            VO CAr CVAr
         in

            case
               Assoc == unit % not seen
            then
               PrintName = {String.toAtom {VS2S PrintNameBase#'.'#F}}
               V = {New Core.variable init(PrintName generated unit)}

            in
               {V ValToSubst(PrintName Seen Depth-1 X)}
               {V occ(unit ?VO)}
               {VO updateValue}
            else
               {Assoc occ(unit ?VO)}
               {VO updateValue}
            end

            ConstrArgs = A#VO | CAr
            ConstrValArgs = F#VO | CVAr

            {self recordValToArgs(RAs Seen Depth PrintNameBase CAr CVAr)}
         elseof
            nil
         then
            ConstrArgs = nil
            ConstrValArgs = nil
         end
      end
      meth typeToSubst(Type)
         SAVariable, TypeToSubst(Type AnalysisDepth)
      end
      meth TypeToSubst(Type Depth)
         % no sharing is supported
         case Type of value(Value) then
            SAVariable, valToSubst(Value)
         [] type(Xs) then
            SAVariable, setType({OzTypes.encode Xs nil})
         [] record(Rec) then Lab ConstrLab Args ConstrArgs Constr in
            Lab = {Label Rec}
            ConstrLab = case {IsAtom Lab} then
                           {New Core.atomNode init(Lab unit)}
                        elsecase {IsName Lab} then
                           {New Core.nameToken init(Lab true)}
                        end
            SAVariable, RecordToSubst({Arity Rec} Rec Depth ?Args ?ConstrArgs)
            Constr = {New Core.construction init(ConstrLab ConstrArgs false)}
            {Constr setValue({List.toRecord Lab Args})}
            {Constr makeType()}
            SAVariable, setLastValue(Constr)
         end
      end
      meth RecordToSubst(Arity Rec Depth ?Args ?ConstrArgs)
         case Arity of F|Fr then ConstrFeat V VO Argr ConstrArgr in
            ConstrFeat = case {IsAtom F} then
                            {New Core.atomNode init(F unit)}
                         elsecase {IsName F} then
                            {New Core.nameToken init(F true)}
                         elsecase {IsInt F} then
                            {New Core.intNode init(F unit)}
                         end
            V = {New Core.variable init('' generated unit)}
            {V TypeToSubst(Rec.F Depth - 1)}
            {V occ(unit ?VO)}
            {VO updateValue}
            Args = F#VO|Argr
            ConstrArgs = ConstrFeat#VO|ConstrArgr
            SAVariable, RecordToSubst(Fr Rec Depth ?Argr ?ConstrArgr)
         [] nil then
            Args = nil
            ConstrArgs = nil
         end
      end
      meth reflectType(Depth $)
         case @lastValue of unit then type({OzTypes.decode @type})
         elseof X then
            if {HasFeature X ImAVariableOccurrence} then
               type({OzTypes.decode @type})
            else
               {X reflectType(Depth $)}
            end
         end
      end
      meth reachable(Vs $)
\ifdef LOOP
         {System.show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
\endif
         SAVariable, deref(@lastValue)

         case
            @lastValue
         of
            unit         % uninitialized variable
         then
            {Add self Vs}
         else
            SAVariable, deref(@lastValue)

            case
               {@lastValue isVariableOccurrence($)} % free variable
            then
               % save self + representant (might differ!)
               {Add self {Add {@lastValue getVariable($)} Vs}}
            elsecase
               {@lastValue isConstruction($)}
            then
               %
               % if we do not implement ft unification fully
               % but only on determined records, then
               % we actually need not save self here.
               %
               {@lastValue reachable({Add self Vs} $)}
            else
               Vs       % ground: int, float, atom, token
            end
         end
      end
  end

   class SAVariableOccurrence
      meth outputDebugValue($)
         %--** provide more readable output here
         {System.valueToVirtualString {self getValue($)} 10 10}#' // '#
         {System.valueToVirtualString {GetData self} 10 10}
      end

      meth getLastValue($)
         {@variable deref(self)}
         {@variable getLastValue($)}
      end
      meth deref(VO)
         {@variable deref(VO)}
      end

      % copies the value Val after replacing variable occurrences
      % with the currently last variable occurrences ones of the
      % same variable
      %
      % if Val is unit, then VO is returned as current value

      meth updateValue
         SAVariableOccurrence, UpdateValue({@variable getLastValue($)})
      end
      meth UpdateValue(O)
\ifdef DEBUGSA
         {System.show updating(O)}
\endif
         case
            O==unit                       % no value known
         then
            {self setValue(self)}         % initialize value
         elsecase
            {O isVariableOccurrence($)}   % fully deref var occs
         then
            OLV = {O getLastValue($)}
         in
            case O == OLV
               orelse {O getVariable($)} == @variable
            then
               {self setValue(O)}
            else
               SAVariableOccurrence, UpdateValue(OLV)
            end
         elsecase
            {O isConstruction($)}
         then
            Lab NLab Args NArgs
         in
            Lab   = {O getLabel($)}
            NLab  = {Lab getLastValue($)}

            Args  = {O getArgs($)}
            NArgs = {Map Args
                     fun {$ Arg}
                        case Arg of F#T then
                           {F getLastValue($)}#{T getLastValue($)}
                        else
                           {Arg getLastValue($)}
                        end
                     end}

            % no change in construction
            case Args == NArgs
               andthen Lab == NLab
            then
\ifdef DEBUGSA
               {System.show notCopyingSame}
\endif
               {self setValue(O)}
            else
\ifdef DEBUGSA
               {System.show copyingStruct({O getValue($)})}
\endif
               Constr = {New Core.construction init(NLab NArgs {O isOpen($)})}
            in
               % construction value could be recomputed here
               % we save the effort for efficiency reasons
               % this implies that the variable _occurrences_
               % in construction values do not have any significance
               {Constr setValue({O getValue($)})}
               {Constr setLastValue(Constr)}
               {self setValue(Constr)}
            end
         else
            % atom, integer, float, token (ground values)
            {self setValue(O)}
         end
      end

      % there is only one type field per variable
      % this could be improved but would - in the
      % current state - invalidate an invariant
      % wrt saving/installing variable environments
      % for conditional clauses

      meth setType(T)
         {@variable setType(T)}
      end
      meth getType($)
         {@variable getType($)}
      end
      meth getPrintType(D $)
         {@variable getPrintType(D $)}
      end
      meth reflectType(Depth $)
         {@variable reflectType(Depth $)}
      end

      meth getData(IsObj $)
         {@variable deref(self)}
         {@value getValue($)}
      end
      meth getFullData(D IsData $)
         case
            {HasFeature @value ImAVariableOccurrence}
         then
            case IsData then _
            else   % dummy variable with right print name
               {CompilerSupport.nameVariable $ {@variable getPrintName($)}}
            end
         else
            {@value getFullData(D IsData $)}
         end
      end

      meth getPrintName($)
         {@variable getPrintName($)}
      end
      meth applyEnvSubst(Ctrl)
         SAVariableOccurrence, updateValue
      end

      meth reachable(Vs $)
\ifdef LOOP
         {System.show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
\endif
         case
            {Member @variable Vs}
         then
            Vs
         else
            {@variable reachable(Vs $)}
         end
      end

      %% unifyVal: _ x Token U Construction U ValueNode

      meth unifyVal(Ctrl RHS)
\ifdef LOOP
         {System.show unifyVO({self getPrintName($)} RHS)}
\endif
         LHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         case
            {Not {UnifyTypesOf self RHS Ctrl @coord}}
         then
            skip % do not continue on type error
         elsecase
            {LHS isVariableOccurrence($)}
         then
            SAVariableOccurrence, bind(Ctrl RHS)
         elsecase
            {LHS isConstruction($)}
         then
            {LHS unify(Ctrl RHS)}
         elsecase
            {IsToken LHS}
         then
            case
               {IsToken RHS}
            then
               % token = token

               case
                  {LHS getValue($)} == {RHS getValue($)}
               then
                  skip
               else
                  {IssueUnificationFailure Ctrl @coord
                   [hint(l:'First value' m:oz({LHS getValue($)}))
                    hint(l:'Second value' m:oz({RHS getValue($)}))
                   ]}
               end
            else
               {RHS unify(Ctrl LHS)}
            end
         else
            % LHS is ValueNode
            {LHS unify(Ctrl RHS)}
         end
      end

      %% Bind: _ x VariableOccurrence U Token U Construction U ValueNode

      meth bind(Ctrl RHS)
\ifdef DEBUGSA
         {System.show bind({self getPrintName($)} {self getType($)} {RHS getValue($)})}
\endif
         case
            {UnifyTypesOf self RHS Ctrl @coord}
         then
            % set new value for following occurrences
            {@variable setLastValue(RHS)}
         else
            skip % not continue on type error
         end
      end

      %% unify: _ x VariableOccurrence U Token U Construction U ValueNode

      meth unify(Ctrl TorC)
\ifdef LOOP
         case
            {TorC isVariableOccurrence($)}
         then
            {System.show unifyV({self getPrintName($)} {TorC getPrintName($)})}
         else
            {System.show unifyV({self getPrintName($)} TorC)}
         end
\endif

         LHS RHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         case
            {UnifyTypesOf LHS TorC Ctrl @coord}
         then
            case
               {TorC isVariableOccurrence($)}
            then
               % implicit deref
               RHS = {TorC getLastValue($)}
            elsecase
               {TorC isConstruction($)}
            then
               {TorC deref(TorC)}
               RHS = {TorC getLastValue($)}
            else
               RHS = TorC
            end

            SAVariableOccurrence, UnifyDeref(Ctrl LHS RHS)
         else
            skip % do not continue on type error
         end
      end

      %% UnifyDeref: _ x VariableOccurrence U Token U Construction U ValueNode

      meth UnifyDeref(Ctrl LHS RHS)
\ifdef LOOP
         {System.show unifyDR({self getPrintName($)} LHS RHS)}
\endif
         case
            LHS == RHS
         then
            skip                                % nothing to do
         else
            case
               {LHS isVariableOccurrence($)}
            then
               {LHS bind(Ctrl RHS)}
            elsecase
               {RHS isVariableOccurrence($)}
            then
               {RHS bind(Ctrl LHS)}
            elsecase
               {LHS isConstruction($)}
            then
               %--** here is some work on extension to ft unification
               case
                  {RHS isConstruction($)}
               then
                  {RHS bind(Ctrl LHS)}
               else
                  skip % and fail on unification
               end
               {LHS unify(Ctrl RHS)}
            elsecase
               {RHS isConstruction($)}
            then
               {RHS unify(Ctrl LHS)}
            elsecase
               {IsToken LHS}
            then
               case
                  {IsToken RHS}
               then
                  % both are tokens

                  case
                     {LHS getValue($)} == {RHS getValue($)}
                  then
                     skip
                  else
                     {IssueUnificationFailure Ctrl @coord
                      [hint(l:'First value' m:oz({LHS getValue($)}))
                       hint(l:'Second value' m:oz({RHS getValue($)}))
                      ]}
                  end
               else
                  % RHS is ValueNode
                  {RHS unify(Ctrl LHS)}
               end
            else
               % LHS is ValueNode
               {LHS unify(Ctrl RHS)}
            end
         end
      end
      meth sa(Ctrl)
         skip
\ifdef DEBUGSA
         {System.show varOccurrence({self getPrintName($)} @value)}
\endif
      end
   end

   class SAToken
      attr type: unit
      meth init()
         type <- {OzValueToType @value}
      end
      meth getLastValue($)
         self
      end
      meth getType($)
         @type
      end
      meth getPrintType(D $)
         {TypeToVS @type}
      end
      meth reflectType(_ $)
         type({OzTypes.decode @type})
      end
      meth getData(IsObj $)
         case IsObj then self
         else @value end
      end
      meth getFullData(D IsData $)
         case IsData then self
         else @value end
      end
   end

   class SANameToken
      meth reflectType(_ $)
         case @isToplevel andthen {Not {CompilerSupport.isCopyableName @value}}
         then value(@value)
         else type({OzTypes.decode @type})
         end
      end
   end
end
