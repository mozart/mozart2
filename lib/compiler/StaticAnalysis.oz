%%%
%%% Author:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
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

functor
import
   BootName(newUnique newNamed) at 'x-oz://boot/Name'
   CompilerSupport(newCopyableName
                   newProcedureRef newCopyableProcedureRef
                   nameVariable chunkArity
                   isBuiltin
                   isLocalDet) at 'x-oz://boot/CompilerSupport'
   System(eq printName
\ifdef DEBUGSA
          show
\endif
         )
   RecordC(hasLabel tell reflectArity '^')
   Type(is)
   Core
   Builtins(getInfo)
   RunTime(tokens)
export
   ImAValueNode
   ImAVariableOccurrence
   ImAToken

   statement:              SAStatement
   typeOf:                 SATypeOf
   stepPoint:              SAStepPoint
   declaration:            SADeclaration
   skipNode:               SASkipNode
   equation:               SAEquation
   construction:           SAConstruction
   definition:             SADefinition
   application:            SAApplication
   ifNode:                 SAIfNode
   ifClause:               SAIfClause
   patternCase:            SAPatternCase
   patternClause:          SAPatternClause
   sideCondition:          SASideCondition
   recordPattern:          SARecordPattern
   equationPattern:        SAEquationPattern
   elseNode:               SAElseNode
   noElse:                 SANoElse
   tryNode:                SATryNode
   lockNode:               SALockNode
   classNode:              SAClassNode
   method:                 SAMethod
   methFormal:             SAMethFormal
   methFormalOptional:     SAMethFormalOptional
   methFormalWithDefault:  SAMethFormalWithDefault
   objectLockNode:         SAObjectLockNode
   getSelf:                SAGetSelf
   exceptionNode:          SAExceptionNode
   valueNode:              SAValueNode
   variable:               SAVariable
   variableOccurrence:     SAVariableOccurrence
   token:                  SAToken
require
   Space(waitStable)
   Search(base)
   FD(less distinct distribute record sup)
   FS(var value include subset reflect monitorIn)
prepare
   \insert POTypes

   FdSup = FD.sup

   fun {MakeDummyProcedure N}
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
         unit   % weaker analysis for procedures with arity > 20
      end
   end

   local
      Meth = 'meth'(noop # proc {$ noop} skip end)
   in
      fun {MakeDummyClass PN}
         {OoExtensions.'class' nil Meth 'attr' 'feat' nil
          case PN of unit then '_' else PN end}
      end

      fun {MakeDummyObject PN}
         {New {MakeDummyClass PN} noop()}
      end
   end


   %%-----------------------------------------------------------------------
   %% Some constants and shorthands

   SAGenError    = 'static analysis error'
   SAGenWarn     = 'static analysis warning'
   SATypeError   = 'type error'

   AnalysisDepth = 3          % analysis of current environment
   AnalysisWidth = w(5 10 50) % analysis of current environment at depth 1 2 3
                              % must be a tuple of width AnalysisDepth
   PrintDepth    = 3          % output of analysed structure

   fun {NormalizeCoord Coord}
      case Coord of unit then Coord
      else pos(Coord.1 Coord.2 Coord.3)
      end
   end

   fun {FirstOrId X}
      case X of F#_ then F else X end
   end

   %% assumes privacy of the following feature names used in Core:

   ImAVariableOccurrence = {NewName}
   ImAValueNode          = {NewName}
   ImARecordConstr       = {NewName}
   ImAToken              = {NewName}

   %% GetClassData: T -> <value>
   %% given a T node, assumes a class value and
   %% returns an associated class token or unit

   fun {GetClassData X}
      XV = {X getValue($)}
   in
      if {IsDet XV} andthen {IsObject XV} then
         if XV == X then
            unit % variable
         elseif {HasFeature XV ImAToken}
            andthen {IsClass {XV getValue($)}}
         then
            XV
         elseif {HasFeature XV ImAVariableOccurrence}
         then
            {GetClassData XV}
         else
            unit % type checking elsewhere
         end
      else
         unit    % variable
      end
   end

   %% GetClassOfObjectData: T -> <value>
   %% given a T node, assumes an object value and
   %% returns an associated class token or unit

   fun {GetClassOfObjectData X}
      XV = {X getValue($)}
   in
      if {IsDet XV}
         andthen {IsObject XV}
      then
         if XV==X
         then
            unit % variable
         elseif {HasFeature XV ImAToken}
            andthen {IsObject {XV getValue($)}}
         then
            {XV getClassNode($)}
         elseif {HasFeature XV ImAVariableOccurrence}
         then
            {GetClassOfObjectData XV}
         else
            unit % type checking elsewhere
         end
      else
         unit % variable
      end
   end

   %% GetValue: T -> <value>
   %% given a T node, returns the associated value
   %% ie, an integer/float/atom/construction, or a token;
   %% constructions may contain embedded T nodes

   fun {GetDataObject X}
      {X getData(true $)}
   end

   %% GetData: T -> <value>
   %% given a T node, returns the associated value
   %% ie, an integer/float/atom/construction; or the
   %% value associated with a token (proc/builtin/class etc.)
   %% constructions may contain embedded T nodes

   fun {GetData X}
      {X getData(false $)}
   end

   %% GetFullData: T -> <oz-term>
   %% given a T node, returns the associated value
   %% ie, an integer/float/atom/construction; or the
   %% value associated with a token (proc/builtin/class etc.)
   %% constructions are expanded recursively up to limited depth

   fun {GetFullData X}
      {X getFullData(PrintDepth true $)}
   end

   fun {GetPrintData X}
      oz({X getFullData(PrintDepth false $)})
   end

   %%
   %% Type predicates

   fun {IsToken X}
      {IsObject X} andthen {HasFeature X ImAToken}
   end

   %%
   %% Determination predicates

   DetTests
   = dt(any:    fun {$ X}
                   true
                end
        det:    fun {$ X} XD = {GetData X} in
                   {IsDet XD} andthen
                   if {IsObject XD} then
                      {Not {HasFeature XD ImAVariableOccurrence}}
                   else true end
                end
        detOrKinded:
           fun {$ X} XD = {GetData X} in
              if {IsDet XD} then
                 if {IsObject XD} then
                    {Not {HasFeature XD ImAVariableOccurrence}}
                 else true end
              else {IsKinded XD} end
           end)

   %%
   %% three valued tests for recursive data structures
   %%

   fun {IsListNow S}
      if {IsDet S} then
         case S
         of nil then true
         elseof _|Sr then
            {IsListNow Sr}
         else false end
      else unit end
   end

   fun {IsStringNow S}
      if {IsDet S} then
         case S
         of nil then true
         elseof I|Sr then
            if {IsDet I} then
               {IsChar I} andthen {IsStringNow Sr}
            else unit end
         else false end
      else unit end
   end

   %% approximation of isVirtualString

   fun {IsVirtualStringNow S}
      if {IsDet S} then
         if {IsAtom S}
            orelse {IsInt S}
            orelse {IsFloat S}
            orelse {IsByteString S}
         then true
         elsecase {IsStringNow S} of true then true
         [] unit then unit
         elseif {IsTuple S}
            andthen {Label S} == '#'
         then unit
         else false end
      else unit end
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
            'String.is'         : doCheckType(rec IsStringNow)
            'Tuple.is'          : doCheckType(det IsTuple)
            'Unit.is'           : doCheckType(det IsUnit)
            'VirtualString.is'  : doCheckType(rec IsVirtualStringNow)
            'Record.label'      : doLabel
            'Record.width'      : doWidth
            'Procedure.arity'   : doProcedureArity
            'Value.\'=\''       : doEq
            'Value.\'.\''       : doDot
            'Object.\',\''      : doComma
            'Object.\'<-\''     : doAssignAccess
            'Object.\'@\''      : doAssignAccess
            'Value.catAssignOO' : doCatAssignAccessOO
            'Value.catAccessOO' : doCatAssignAccessOO
            'Value.catExchangeOO':doCatAssignAccessOO
            'Value.catAssign'   : doCatAssignAccess
            'Value.catAccess'   : doCatAssignAccess
            'Value.catExchange' : doCatAssignAccess
            'Value.dotAssign'   : doDotAssignExchange
            'Value.dotExchange' : doDotAssignExchange
            'Bool.and'          : doAnd
            'Bool.or'           : doOr
            'Bool.not'          : doNot
       )



define

   %%
   %% kinded records

   fun {CurrentArity R}
      if {IsDet R} then {Arity R}
      elseif {IsFree R} then nil
      else {RecordC.reflectArity R}
      end
   end

   fun {HasFeatureNow R F}
      {Member F {CurrentArity R}}
   end

   %%-----------------------------------------------------------------------
   %% this translation routine is here since it depends on FD and hence
   %% refers to a resource. no other reason: logically, it belongs to POTypes

   OzTypes = {MkOzPartialOrder}

   local
      OTE = OzTypes.encode
   in
      fun {OzValueToType V}
         if {CompilerSupport.isLocalDet V} then
            case {Value.status V}
            of det(T) then
               case T
               of int then
                  {OTE if {IsChar V} then char
                       elseif V=<FdSup andthen V>=0 then fdIntC
                       else int
                       end nil}
               [] float then
                  {OTE float nil}
               [] atom then
                  {OTE if V==nil then nilAtom
                       else atom
                       end nil}
               [] name then
                  {OTE case V
                       of true  then bool
                       [] false then bool
                       [] unit  then 'unit'
                       else name
                       end nil}
               [] tuple then
                  {OTE case V
                       of _|_ then cons
                       [] _#_ then pair
                       else tuple
                       end nil}
               [] record then
                  {OTE record nil}
               [] procedure then
                  {OTE case {ProcedureArity V}
                       of 0 then 'procedure/0'
                       [] 1 then 'procedure/1'
                       [] 2 then 'procedure/2'
                       [] 3 then 'procedure/3'
                       [] 4 then 'procedure/4'
                       [] 5 then 'procedure/5'
                       [] 6 then 'procedure/6'
                       else 'procedure/>6'
                       end nil}
               [] cell then
                  {OTE cell nil}
               [] space then
                  {OTE space nil}
               [] 'thread' then
                  {OTE 'thread' nil}
               [] bitString then
                  {OTE bitString nil}
               [] byteString then
                  {OTE byteString nil}
               [] array then
                  {OTE array nil}
               [] dictionary then
                  {OTE dictionary nil}
               [] 'class' then
                  {OTE 'class' nil}
               [] object then
                  {OTE object nil}
               [] 'lock' then
                  {OTE 'lock' nil}
               [] port then
                  {OTE port nil}
               [] bitArray then
                  {OTE bitArray nil}
               [] chunk then
                  {OTE chunk [array dictionary 'class'
                              'object' 'lock' port
                              bitArray]}
               [] fset then
                  {OTE fset nil}
               else
                  {OTE value [int float record procedure
                              cell chunk space 'thread']}
               end
            [] kinded(T) then
               case T
               of int then
                  {OTE fdIntC nil}
               [] record then
                  {OTE recordC nil}
               else
                  {OTE value [fdIntC recordC]}
               end
            [] free then
               {OTE value nil}
            [] future then
               {OTE value nil}
            [] failed then
               {OTE value nil}
            end
         else
            {OTE value nil}
         end
      end
   end

   %%-----------------------------------------------------------------------
   %% Some constants and shorthands

   fun {Bool2Token B}
      if B then RunTime.tokens.'true' else RunTime.tokens.'false' end
   end

   TypeTests = {AdjoinAt Type.is object
                fun {$ X}
                   {IsObject X} andthen
                   {Not {HasFeature X ImARecordConstr}
                    orelse {HasFeature X ImAValueNode}
                    orelse {HasFeature X ImAToken}}
                end}

   %%-----------------------------------------------------------------------
   %% Determination & type predicates

   local
      fun {Maybe Type}
         fun {$ X}
            XX = {GetData X}
         in
            if {IsDet XX} then
               if {IsObject XX}
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
         if {IsDet XX} then
            if {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            else
               case XX
               of A#B then
                  {DetTypeTest L A}
                  andthen {DetTypeTest R B}
               else false end
            end
         else true end
      end
      fun {MaybeListOf T X}
         XX = {GetData X}
      in
         if {IsDet XX} then
            if {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            else
               case XX
               of X|XXr then
                  {DetTypeTest T X}
                  andthen {MaybeListOf T XXr}
               [] nil then true
               else false end
            end
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
         if {IsDet XX} then
            if {IsObject XX}
               andthen {HasFeature XX ImAVariableOccurrence}
            then true
            elseif {IsAtom XX}
               orelse {IsInt XX}
               orelse {IsFloat XX}
               orelse {IsByteString XX}
               orelse {MaybeString X}
            then true
            elseif {IsTuple XX} andthen {Label XX}=='#'
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
      %% flat type tests generalize to "isdet then type"
      %% complex ones must be recursively checked

      DetTypeTests
      = {Adjoin {Record.map TypeTests Maybe} DetTypeTests2}

      fun {DetTypeTest T X}
         if
            {Width T} == 0
         then
            {DetTypeTests.{Label T} X}

         else
            case T
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
   end

%-----------------------------------------------------------------------
%

   fun {GetReachable V}
      L = {V getLastValue($)}
      T = {V getType($)}
   in
      %% L == unit if V is uninitialized
      %% eg, first use within conditional;
      %% atomic data need not be saved

      if
         L==unit
      then

         if {OzTypes.isMinimal T}
         then env(var:V last:L)
         else
            %% copy non-minimal types
            {V setType({OzTypes.clone T})}
            env(var:V last:L type:T)
         end

      elseif
         {HasFeature L ImAVariableOccurrence}
      then
\ifdef DEBUGSA
         {System.show env(var:V last:L data:{GetDataObject L} type:T)}
\endif
         if {OzTypes.isMinimal T}
         then env(var:V last:L data:{GetDataObject L})
         else
            %% copy non-constant types
            {V setType({OzTypes.clone T})}
            env(var:V last:L data:{GetDataObject L} type:T)
         end

      elseif
         {L isRecordConstr($)}
      then
\ifdef DEBUGSA
         {System.show env(var:V last:L data:{GetDataObject L} type:T)}
\endif
         if {OzTypes.isMinimal T}
         then env(var:V last:L data:{GetDataObject L})
         else
            %% copy non-constant types
            {V setType({OzTypes.clone T})}
            env(var:V last:L data:{GetDataObject L} type:T)
         end

      else
         %% L is atomic: int, float, atom, token

         %% T must have constant type, but it need not be {OzTypes.minimal T}
         %% (T could be, e.g., [atom nilAtom])

         env(var:V last:L)
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

      if {HasFeature E data}
      then {L setValue(E.data)}
      end

      if {HasFeature E type}
      then {V setType(E.type)}
      end
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

   %%-----------------------------------------------------------------------
   %%
   %% ValueToErrorLine: VS x Oz-Value -> <error line>
   %%

   fun {ValueToErrorLine Text X}
      if X == unit then nil
      else XD in
         XD = {GetPrintData X}
         if {HasFeature X ImAVariableOccurrence} then
            [hint(l:Text m:pn({X getPrintName($)})#' = '#XD)]
         else
            [hint(l:Text m:XD)]
         end
      end
   end

%
% IssueTypeError: OzPOType x OzPOType x Oz-Value x Oz-Value
%

   proc {IssueTypeError TX TY X Y Ctrl Coord}
\ifdef DEBUGSA
      {System.show issuetypeerror(TX TY X Y)}
\endif

      ErrMsg UnifLeft UnifRight Msgs Items
   in

      ErrMsg = {Ctrl getErrorMsg($)}
      {Ctrl getUnifier(UnifLeft UnifRight)}

      Msgs   = [[hint(l:'First type' m:{TypeToVS TX})
                 hint(l:'Second type' m:{TypeToVS TY})]
                {ValueToErrorLine 'First value' X}
                {ValueToErrorLine 'Second value' Y}
                if UnifLeft \= unit andthen UnifRight \= unit then
                   [hint(l:'Original assertion'
                         m:({GetPrintData UnifLeft}#' = '#
                            {GetPrintData UnifRight}))]
                else nil
                end]
      Items  = {FoldR Msgs Append nil}

      if {Ctrl getNeeded($)} then
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
      if
         {OzTypes.clash TX TY}
      then
         {IssueTypeError TX TY X Y Ctrl Coord}
         false
      else
         {OzTypes.constrain TX TY}
         {OzTypes.constrain TY TX}
         true
      end
   end

%
% ConstrainTypes: OzPOType x OzPOType
%

   fun {ConstrainTypes TX TY}
\ifdef DEBUGSA
      {System.show constrainTypes({OzTypes.toList TX} {OzTypes.toList TY})}
\endif
      if
         {OzTypes.clash TX TY}
      then
         false
      else
         {OzTypes.constrain TX TY}
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

      Text1 = if UnifLeft \= unit
                 andthen UnifRight \= unit
              then
                 {Append Msgs
                  [hint(l:'Original assertion'
                        m:({GetPrintData UnifLeft}#' = '#
                           {GetPrintData UnifRight}))]}
              else
                 Msgs
              end

      Text2 = if Origin==Coord orelse Coord==unit then Text1
              else {Append Text1 [Offend]}
              end

      if {Ctrl getNeeded($)} then
         {Ctrl.rep error(coord: Origin
                         kind:  SAGenError
                         msg:   case ErrMsg of unit then
                                   'unification error in needed statement'
                                else ErrMsg
                                end
                         items: Text2)}
      else
         {Ctrl.rep warn(coord: Origin
                        kind:  SAGenWarn
                        msg:   case ErrMsg of unit then
                                  'unification error in possibly unneeded statement'
                               else ErrMsg
                               end
                        items: Text2)}
      end
   end

%-----------------------------------------------------------------------
% some formatting

   fun {ListToVS Xs L Sep R}
      case Xs of X1|Xr then
         L#X1#{FoldR Xr fun {$ X In} Sep#X#In end R}
      [] nil then L#R
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

   fun {TypeToVS T}
      {ListToVS {OzTypes.decode T} '' ' ++ ' ''}
   end

   fun {Ozify Xs}
      {Map Xs fun {$ X} oz(X) end}
   end

   fun {FormatArity Xs}
      {Ozify {CurrentArity Xs}}
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
            if {P X}
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
            if {P X} then Idx = N true
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
      if {Member X Ys}
      then Ys else X|Ys end
   end

   fun {Union Xs Ys}
      case Xs of nil then Ys
      elseof X|Xr then
         if {Member X Ys}
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
      case Ys of nil then unit
      [] Y#V|Yr then
         if {System.eq X Y} then V
         else {PLDotEQ X Yr}
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
               if {HasFeature I2 F}
               then {AdjoinAt I2 F (nil#unit)}
               else {AdjoinAt I2 F M.F}
               end
            end I1}
        end m} % combine parents methods
       PNew}   % and then adjoin new information
   end

   %%-----------------------------------------------------------------------
   %%  global control information

   class Control
      prop final
      feat
         rep                 % the reporter object
         state               % interface switch control
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

      meth init(Rep State)
         self.rep = Rep
         self.state = State
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
            N = case PrintName of unit then {NewName}
                else {BootName.newNamed {System.printName PrintName}}
                end
         elseof Xs then
            N = {CompilerSupport.newCopyableName
                 case PrintName of unit then '' else {System.printName PrintName} end}
            toCopy <- N|Xs
         end
      end
      meth declareToplevelProcedure(?ProcedureRef)
         case @toCopy of unit then
            ProcedureRef = {CompilerSupport.newProcedureRef}
         elseof Xs then
            ProcedureRef = {CompilerSupport.newCopyableProcedureRef}
            toCopy <- ProcedureRef|Xs
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

      %% a complex statement is one which may do more than suspend immediately
      %% or bind a variable; _not_ complex in this sense are constraints,
      %% declarations, definitions, class nodes, etc.
      %% (a class with isComplex = false must provide an saSimple method)
      %%
      %% we only deal with definitions and class nodes at this point

      feat
         isComplex:true

         %%
         %% static analysis iteration
         %%

      meth staticAnalysis(Rep State Ss)
         Ctrl = {New Control init(Rep State)}
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
         if self.isComplex then          % if this statement is complex
            skip                         % then terminate
         else
            {Ctrl setCoord(@coord)}      % save coordinates for error messages
            {self applyEnvSubst(Ctrl)}
            {self saSimple(Ctrl)}
            if @next \= self then        % if there is another one
               {@next SaLookahead(Ctrl)}
            end
         end
      end

      meth saBody(Ctrl Ss)
         case Ss of S|_ then
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

   class SATypeOf from SAStatement
      meth sa(Ctrl) T in
         {@arg reflectType(AnalysisDepth ?T)}
         value <- {OptimizeTypeRepr T}
         %--** the new information about res is not propagated
      end
   end

   class SAStepPoint from SAStatement
      meth saDescend(Ctrl)
         SAStatement, saBody(Ctrl @statements)
      end
   end

   class SASkipNode from SAStatement
   end

   class SADeclaration from SAStatement
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
         %% descend with same environment
         SAStatement, saBody(Ctrl @statements)
      end
   end

   class SAEquation from SAStatement
      meth sa(Ctrl)
\ifdef DEBUGSA
         {System.show saEQ(@left @right)}
\endif
         {@right sa(Ctrl)}                            % analyse right hand side

         {Ctrl setErrorMsg('equality constraint failed')}

         %% constructions forward the unification task
         %% to their associated record value token
         if {@right isConstruction($)}
         then
            {Ctrl setUnifier(@left {@right getValue($)})}
            {@left unify(Ctrl {@right getValue($)})}
         else
            {Ctrl setUnifier(@left @right)}
            {@left unify(Ctrl @right)}              % l -> r
         end

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
         value

      meth init()
         type <- {OzTypes.encode record nil}
      end
      meth getValue($)
         @value
      end
      meth reachable(Vs $)
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

      meth makeValue(Ctrl IsOpen ?Rec)
         if {DetTypeTests.literal @label} then Args IllFeat TestFeats in
            Args = {FoldL @args
                    fun {$ In Arg}
                       case Arg of F#_ then F|In else In end
                    end nil}
            {AllUpTo Args DetTypeTests.feature ?IllFeat ?TestFeats}
            if TestFeats then
               LData = {GetData @label}
               FData = {List.mapInd @args
                        fun {$ I Arg} FF TT in
                           case Arg of F#T then
                              FF = {GetData F}
                              TT = T
                           else
                              FF = I
                              TT = Arg
                           end
                           FF#if {TT isConstruction($)} then {TT getValue($)}
                              else TT
                              end
                        end}
            in
               if IsOpen then
                  if {DetTests.det @label} then
                     Rec = {RecordC.tell LData}
                  end
                  if {All Args DetTests.det} then
                     {ForAll FData proc {$ F#V}
                                      {RecordC.'^' Rec F V}
                                   end}
                  end
               elseif {DetTests.det @label}
                  andthen {All Args DetTests.det}
               then
                  try
                     Rec = {List.toRecord LData FData}
                  catch error(kernel(recordConstruction ...) ...) then
                     Fields = {Map FData fun {$ F#_} F end}
                  in
                     {Ctrl.rep
                      error(coord: {@label getCoord($)}
                            kind:  SAGenError
                            msg:   'duplicate feature in record construction'
                            items: [hint(l:'Features found'
                                         m:{SetToVS {Ozify Fields}})])}
                  end
               end
            else Coord in
               {@label getCoord(?Coord)}
               {Ctrl.rep error(coord: Coord
                               kind:  SAGenError
                               msg:   'illegal record feature'
                               items: [hint(l:'Feature found'
                                            m:{GetPrintData IllFeat})])}
            end
         else Coord in
            {@label getCoord(?Coord)}
            {Ctrl.rep error(coord: Coord
                            kind:  SAGenError
                            msg:   'illegal record label'
                            items: [hint(l:'Label found'
                                         m:{GetPrintData @label})])}
         end
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
      meth sa(Ctrl)

\ifdef DEBUGSA
         {System.show saConstruction}
\endif

         {ForAll
          @args
          proc {$ Arg}
             case Arg of _#T then
                {T sa(Ctrl)}
             else
                {Arg sa(Ctrl)}
             end
          end}

         value <- {New RecordConstr
                   init(SAConstruction,makeValue(Ctrl false $) self)}
      end
   end

   class SADefinition from SAStatement
      feat
         isComplex:false
      meth saSimple(Ctrl)
         case {MakeDummyProcedure {Length @formalArgs}} of unit then skip
         elseof DummyProc then Value in
            Value = {New Core.procedureToken init(DummyProc self)}
            if {Not {self isClauseBody($)}}
               andthen {Ctrl getTop($)}
               andthen {Not {Member 'dynamic' @procFlags}}
            then
               procedureRef <- {Ctrl declareToplevelProcedure($)}
            end
            {@designator unifyVal(Ctrl Value)}
         end
\ifdef DEBUGSA
         {System.show lookedAhead({@designator getPrintName($)} Value)}
\endif
      end
      meth saDescend(Ctrl)
         Env = {GetGlobalEnv @globalVars}
         T N
      in
         {Ctrl getTopNeeded(T N)}
         if {Member 'instantiate' @procFlags} then
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

   class SABuiltinApplication from SAStatement

      meth TypeCheckN(Ctrl N VOs Ts $)
         case VOs#Ts of nil#nil then 0
         [] (VO|VOr)#(T|Tr) then
            if {DetTypeTest T VO} then
               SABuiltinApplication, TypeCheckN(Ctrl N + 1 VOr Tr $)
            else N
            end
         end
      end

      meth typeCheck(Ctrl VOs Ts $)
         SABuiltinApplication, TypeCheckN(Ctrl 1 VOs Ts $)
      end

      meth detCheck(Ctrl VOs Ds $)
         case VOs#Ds of nil#nil then true
         [] (VO|VOr)#(D|Dr) then
            {DetTests.{Label D} VO}
            andthen SAApplication, detCheck(Ctrl VOr Dr $)
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
            of (T|Tr) # (_|Dr)
            then
\ifdef DEBUG
               {System.show asserting(A T)}
\endif
               if
                  {ConstrainTypes
                   {A getType($)}
                   {OzTypes.encode {Label T} nil}}
               then
                  SABuiltinApplication, AssertTypes(Ctrl N+1 Ar Tr Dr)
               else
                  PN  = pn({@designator getPrintName($)})
                  PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
                  Vals= {Map @actualArgs fun {$ A} {GetPrintData A} end}
                  Ts  = {Map @actualArgs fun {$ A} {TypeToVS {A getType($)}} end}
               in
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SATypeError
                         msg:   'ill-typed application'
                         items: [hint(l:'Procedure' m:PN)
                                 hint(l:'At argument' m:N)
                                 hint(l:'Type found'
                                      m:{TypeToVS {A getType($)}})
                                 hint(l:'Expected' m:oz(T))
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
         I     = {Builtins.getInfo BIName}
         Types = I.types
         Det   = I.det
      in
\ifdef DEBUGSA
         {System.show assert(BIName I @actualArgs)}
\endif
         SABuiltinApplication, AssertTypes(Ctrl 1 @actualArgs Types Det)
      end

      meth checkMessage(Ctrl MsgArg Meth Type PN)
         Msg     = {GetData MsgArg}
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
         end

         if Meth==unit
         then
            skip
         elseif
            {IsDet Msg} andthen {IsRecord Msg}
         then
            if
               {HasFeature Meth {Label Msg}}
            then
               Req # Opt = Meth.{Label Msg}
            in

               {ForAll Req
                proc {$ R}
                   if {IsObject R} andthen {HasFeature R ImAVariableOccurrence}
                   then skip
                   elseif {HasFeature Msg R} then skip
                   else
                      {Ctrl.rep
                       error(coord: @coord
                             kind:  SAGenError
                             msg:   'missing message feature in ' # Where
                             items: [hint(l:What m:pn(PN))
                                     hint(l:'Required feature' m:oz(R))
                                     hint(l:'Message found'
                                          m:{GetPrintData MsgArg})])}
                   end
                end}

               if
                  Opt \= unit
               then
                  {ForAll {Arity Msg}
                   proc {$ F}
                      if {Member F Req}
                         orelse {Member F Opt}
                      then skip else
                         {Ctrl.rep
                          error(coord: @coord
                                kind:  SAGenError
                                msg:   'illegal message feature in ' # Where
                                items: [hint(l:What m:pn(PN))
                                        hint(l:'Required features'
                                             m:{SetToVS {Ozify Req}})
                                        hint(l:'Optional features'
                                             m:{SetToVS {Ozify Opt}})
                                        hint(l:'Message found'
                                             m:{GetPrintData MsgArg})])}
                      end
                   end}
               else skip end

            elseif
               {HasFeature Meth otherwise}
            then skip else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal message label in ' # Where
                      items: [hint(l:What m:pn(PN))
                              hint(l:'Message found'
                                   m:{GetPrintData MsgArg})
                              hint(l:'Expected'
                                   m:{SetToVS {FormatArity Meth}})])}
            end
         else
            skip
         end
      end

      %% Det:     flag whether to check determination
      %% Returns: success flag depending on whether
      %%          the arguments have been tested

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
               PN  = pn(N)
               PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
               Vals= {Map @actualArgs fun {$ A} {GetPrintData A} end}
            in
               {Ctrl.rep error(coord: @coord
                               kind:  SATypeError
                               msg:   'ill-typed builtin application'
                               items: [hint(l:'Builtin' m:PN)
                                       hint(l:'At argument' m:Pos)
                                       hint(l:'Expected types'
                                            m:{ProdToVS {Ozify BIInfo.types}})
                                       hint(l:'Argument names'
                                            m:{ApplToVS PN|PNs})
                                       hint(l:'Argument values'
                                            m:{ApplToVS PN|Vals})])}
               false
            end
         else
            Val = {GetPrintData @designator}
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Vals= {Map @actualArgs fun {$ A} {GetPrintData A} end}
         in
            {Ctrl.rep error(coord: @coord
                            kind:  SAGenError
                            msg:   'illegal arity in application'
                            items: [hint(l:'Arity found' m:NumArgs)
                                    hint(l:'Expected' m:ProcArity)
                                    hint(l:'Argument names'
                                         m:{ApplToVS pn(N)|PNs})
                                    hint(l:'Argument values'
                                         m:{ApplToVS Val|Vals})])}
            false
         end
      end

      meth doNewName(Ctrl)
         BndVO BndV PrintName Token
      in
         BndVO = {Nth @actualArgs 1}
         {BndVO getVariable(?BndV)}
         {BndV getPrintName(?PrintName)}
         Token = if {Ctrl getTop($)} then TheName in
                    {Ctrl declareToplevelName(PrintName ?TheName)}
                    self.codeGenMakeEquateLiteral = TheName
                    {New Core.valueNode init(TheName unit)}
                 else TheName in
                    TheName = case PrintName of unit then {NewName}
                              else {BootName.newNamed {System.printName PrintName}}
                              end
                    {New Core.token init(TheName)}
                 end
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewUniqueName(Ctrl)
         NName = {GetData {Nth @actualArgs 1}}
         Value = {BootName.newUnique NName}   % always succeeds
         Token = {New Core.valueNode init(Value unit)}
         BndVO = {Nth @actualArgs 2}
      in
\ifdef DEBUGSA
         {System.show newUniqueName(NName Token)}
\endif
         {BndVO unifyVal(Ctrl Token)}
         self.codeGenMakeEquateLiteral = Value
      end

      meth doNewLock(Ctrl)
         Token = {New Core.token init({NewLock})}
         BndVO = {Nth @actualArgs 1}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewPort(Ctrl)
         Token = {New Core.token init({NewPort _})}
         BndVO = {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewCell(Ctrl)
         Token = {New Core.token init({NewCell _})}
         BndVO = {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewArray(Ctrl)
         Low  = {GetData {Nth @actualArgs 1}}
         High = {GetData {Nth @actualArgs 2}}
         Token= {New Core.token init({Array.new Low High _})}
         BndVO= {Nth @actualArgs 4}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewDictionary(Ctrl)
         Token= {New Core.token init({Dictionary.new})}
         BndVO= {Nth @actualArgs 1}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNewChunk(Ctrl)
         Rec  = {GetData {Nth @actualArgs 1}}
         Token= {New Core.token init({NewChunk Rec})}
         BndVO= {Nth @actualArgs 2}
      in
         {BndVO unifyVal(Ctrl Token)}
      end

      meth doNew(Ctrl)
         ClsArg   = {Nth @actualArgs 1}
         Cls      = {GetClassData ClsArg}
         DummyObj = {MakeDummyObject {ClsArg getPrintName($)}}
         Msg      = {Nth @actualArgs 2}
         Token    = {New Core.objectToken init(DummyObj Cls)}
         BndVO    = {Nth @actualArgs 3}
         PN       = {BndVO getPrintName($)}
\ifdef DEBUGSA
         {System.show doNew(Token)}
\endif
      in
         {BndVO unifyVal(Ctrl Token)}

         if Cls == unit
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
         FirstArg = {Nth @actualArgs 1}
         RecOrCh  = {GetData FirstArg}
         F        = {GetData {Nth @actualArgs 2}}
      in
\ifdef DEBUGSA
         {System.show dot(FirstArg RecOrCh F)}
\endif
         %% dot selection from object
         if
            {IsDet RecOrCh}
            andthen {TypeTests.object RecOrCh}
         then

            case {GetClassOfObjectData FirstArg}
            of unit then
               skip
            elseof Cls then
               Fs  = {Cls getFeatures($)}
            in
               if
                  Fs == unit orelse {Member F Fs}
               then
                  skip
               else
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SAGenError
                         msg:   'illegal feature selection from object'
                         items: [hint(l:'Feature found' m:oz(F))
                                 hint(l:'Expected one of'
                                      m:{SetToVS {Ozify Fs}})])}
               end
            end

            %% dot selection from class
         elseif
            {IsDet RecOrCh}
            andthen {TypeTests.'class' RecOrCh}
         then
            case {GetClassData FirstArg}
            of unit then
               skip
            elseof Cls then
               Fs  = {Cls getFeatures($)}
            in
               if Fs == unit
                  orelse {Member F Fs}
               then skip else
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SAGenError
                         msg:   'illegal feature selection from class'
                         items: [hint(l:'Feature found' m:oz(F))
                                 hint(l:'Expected one of'
                                      m:{SetToVS {Ozify Fs}})])}
               end
            end

            %% dot selection from record
         elseif
            {IsDet RecOrCh}
            andthen {TypeTests.record RecOrCh}
         then
            if {HasFeature RecOrCh F}
            then
               BndVO = {Nth @actualArgs 3}
            in
\ifdef DEBUGSA
               {System.show dotSelectionFromRecord}
\endif
               {Ctrl setErrorMsg('feature selection (.) on record failed')}
               {Ctrl setUnifier(BndVO RecOrCh.F)}

               {BndVO unify(Ctrl RecOrCh.F)}
\ifdef DEBUGSA
               {System.show unified({BndVO getLastValue($)})}
\endif

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            else
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal feature selection on record'
                      items: [hint(l:'Feature found' m:oz(F))
                              hint(l:'Expected one of'
                                   m:{SetToVS {FormatArity RecOrCh}})])}
            end

            %% dot selection from non-determined record
         elseif
            {TypeTests.recordC RecOrCh}
         then
            if {HasFeatureNow RecOrCh F}
            then
               BndVO = {Nth @actualArgs 3}
            in
               {Ctrl setErrorMsg('feature selection (.) on record failed')}
               {Ctrl setUnifier(BndVO RecOrCh.F)}

               {BndVO unify(Ctrl {RecordC.'^' RecOrCh F})}

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            else
               skip
            end

         else
            skip
         end
      end

      meth doComma(Ctrl)
         Cls  = {GetClassData {Nth @actualArgs 1}}
         Msg  = {Nth @actualArgs 2}
         PN   = {{Nth @actualArgs 1} getPrintName($)}
      in
         if Cls == unit
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
         if
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
            Hint = if Final
                   then '(correct use requires method application)'
                   else '(may be a correct forward declaration)'
                   end
            Cls  = if Final
                   then 'In final class'
                   else 'In class'
                   end
         in
            if
               Final orelse
               {Ctrl.state getSwitch(warnforward $)}
            then
               {Ctrl.rep
                warn(coord: @coord
                     kind:  SAGenWarn
                     msg:   case {System.printName {GetData @designator}}
                            of 'Object.\'<-\'' then 'access of'
                            [] 'Object.\'@\'' then 'assignment to'
                            end#' undefined attribute'
                     items: [hint(l:'Statement' m:Expr)
                             hint(l:Cls
                                  m:pn({System.printName {Self getValue($)}}))
                             hint(l:'Expected one of' m:{SetToVS {Ozify Attrs}})
                             line(Hint)])}
            end
         end
      end

      meth doDotAssignExchange(Ctrl)
         DictV = {Nth @actualArgs 1}
         Dict  = {GetData DictV}
         FeaV = {Nth @actualArgs 2}
         Fea  = {GetData FeaV}
         ValV = {Nth @actualArgs 3}
      in
         if {DetTests.det DictV} then
            DictOz = {GetPrintData DictV}
            FeaOz = {GetPrintData FeaV}
            ValOz = {GetPrintData ValV}
            Expr = DictOz#'.'#FeaOz#' := '#ValOz
         in
            %% First arg is known
            if {Not {IsDictionary Dict} orelse {IsArray Dict}} then
               {Ctrl.rep
                error(coord: @coord
                      kind : SAGenError
                      msg  : 'expected a dictionary or array as 1st argument of <dict/array>.<feat> := <val>'
                      items:[hint(l:'Statement' m:Expr)
                             hint(l:'Value' m:{GetPrintData DictV})
                             hint(l:'Type' m:oz({Value.type Dict}))])}
            end
            %% First element is array or dict. Check second arg
            if {DetTests.det FeaV} then
               %% Second element is known
               if {IsArray Dict} andthen {Not {IsInt Fea}} then
                  {Ctrl.rep
                   error(coord: @coord
                         kind : SAGenError
                         msg  : 'expected an int as 2nd argument of <array>.<int> := <val>'
                         items:[hint(l:'Statement' m:Expr)
                                hint(l:'Value' m:{GetPrintData FeaV})
                                hint(l:'Type' m:oz({Value.type Fea}))])}
               end
               if {IsDictionary Dict} andthen {Not {IsLiteral Fea} orelse {IsInt Fea}} then
                  {Ctrl.rep
                   error(coord: @coord
                         kind : SAGenError
                         msg  : 'expected a feature as 2nd argument of <dict>.<feat> := <val>'
                         items:[hint(l:'Statement' m:Expr)
                                hint(l:'Value' m:{GetPrintData FeaV})
                                hint(l:'Type' m:oz({Value.type Fea}))])}
               end
            end
         elseif {DetTests.det Fea} andthen {Not {IsLiteral Fea} orelse {IsInt Fea}} then
            %% Dict/Array is unknown, 2nd arg is known but not literal or int
            DictOz = {GetPrintData DictV}
            FeaOz = {GetPrintData FeaV}
            ValOz = {GetPrintData ValV}
            Expr = DictOz#'.'#FeaOz#' := '#ValOz
         in
            {Ctrl.rep
             error(coord: @coord
                   kind : SAGenError
                   msg  : 'expected a feature as 2nd argument of <dict/array>.<feat> := <val>'
                   items:[hint(l:'Statement' m:Expr)
                          hint(l:'Value' m:{GetPrintData FeaV})
                          hint(l:'Type' m:oz({Value.type Fea}))])}
         end
      end

      meth doCatAssignAccess(Ctrl oo:OO<=false)
         FeaV = {Nth @actualArgs 1}
         Fea  = {GetData FeaV}
         ValV = {Nth @actualArgs 2}
      in
         if {DetTests.det FeaV} then
            PrintName = {System.printName {GetData @designator}}
            FeaOz = {GetPrintData FeaV}
            ValOz = {GetPrintData ValV}
            VarOz = {GetPrintData {List.last @actualArgs}}
            Expr = case PrintName
                   of 'Value.catAccess'   then '@'#FeaOz# ' = '#ValOz
                   [] 'Value.catAccessOO' then '@'#FeaOz# ' = '#ValOz
                   [] 'Value.catAssign'   then     FeaOz#' := '#ValOz
                   [] 'Value.catAssignOO' then     FeaOz#' := '#ValOz
                   [] 'Value.catExchange'   then VarOz#' = ('#FeaOz#' := '#ValOz#')'
                   [] 'Value.catExchangeOO' then VarOz#' = ('#FeaOz#' := '#ValOz#')'
                   end
         in
            if {IsLiteral Fea} then
               if OO then
                  Self = {Ctrl getSelf($)}
                  Attrs = case Self of unit then unit
                          else {Self getAttributes($)} end
                  Props = case Self of unit then unit
                          else {Self getProperties($)} end
               in
                  %%{Show 'self'(Self)}
                  %%{Show attrs(Attrs)}
                  %%{Show props(Props)}
                  if Attrs==unit orelse {Member Fea Attrs} then skip else
                     Final = (Props\=unit andthen {Member final Props})
                  in
                     if Final orelse {Ctrl.state getSwitch(warnforward $)} then
                        {Ctrl.rep
                         warn(coord: @coord
                              kind : SAGenWarn
                              msg  : case PrintName
                                     of 'Value.catAccessOO' then 'access of'
                                     [] 'Value.catAssignOO' then 'assignment to'
                                     [] 'Value.catExchangeOO' then 'exchange on'
                                     end#' undefined attribute'
                              items:[hint(l:'Statement' m:Expr)
                                     hint(l:if Final
                                            then 'In final class'
                                            else 'In class' end
                                          m:pn({System.printName {Self getValue($)}}))
                                     hint(l:'Expected one of' m:{SetToVS {Ozify Attrs}})
                                     line(if Final
                                          then '(correct use requires method application)'
                                          else '(may be a correct forward declaration)' end)])}
                     end
                  end
               else
                  {Ctrl.rep
                   error(coord: @coord
                         kind : SAGenError
                         msg  : case PrintName
                                of 'Value.catAccess' then 'access of'
                                [] 'Value.catAssign' then 'assignment to'
                                [] 'Value.catExchange' then 'exchange on'
                                end#' attribute outside of a class definition'
                         items:[hint(l:'Statement' m:Expr)])}
               end
            elseif {IsCell Fea} then skip
            elsecase Fea of D#K then
               if {DetTests.det D} then
                  Dict = {GetData D}
               in
                  %% First element of tuple is known
                  if {Not {IsDictionary Dict} orelse {IsArray Dict}} then
                     {Ctrl.rep
                      error(coord: @coord
                            kind : SAGenError
                            msg  : 'expected dictionary or array as 1st argument of the hash tuple'
                            items:[hint(l:'Statement' m:Expr)
                                   hint(l:'Value' m:{GetPrintData D})
                                   hint(l:'Type' m:oz({Value.type Dict}))])}
                  end
                  %% First element is array or dict. Check second element of tuple.
                  if {DetTests.det K} then
                     Key  = {GetData K}
                  in
                     %% Second element is known
                     if {IsArray Dict} andthen {Not {IsInt Key}} then
                        {Ctrl.rep
                         error(coord: @coord
                               kind : SAGenError
                               msg  : 'expected an int as 2nd argument of array#int tuple'
                               items:[hint(l:'Statement' m:Expr)
                                      hint(l:'Value' m:{GetPrintData K})
                                      hint(l:'Type' m:oz({Value.type Key}))])}
                     end
                     if {IsDictionary Dict} andthen {Not {IsLiteral Key} orelse {IsInt Key}} then
                        {Ctrl.rep
                         error(coord: @coord
                               kind : SAGenError
                               msg  : 'expected a feature as 2nd argument of dict#feat tuple'
                               items:[hint(l:'Statement' m:Expr)
                                      hint(l:'Value' m:{GetPrintData K})
                                      hint(l:'Type' m:oz({Value.type Key}))])}
                     end
                  end
               elseif {DetTests.det K} then
                  Key  = {GetData K}
               in
                  %% First element unknowm, check second element is a feature
                  if {Not {IsLiteral Key} orelse {IsInt Key}} then
                     {Ctrl.rep
                      error(coord: @coord
                            kind : SAGenError
                            msg  : 'expected a literal or int as 2nd argument of the hash tuple'
                            items:[hint(l:'Statement' m:Expr)
                                   hint(l:'Value' m:{GetPrintData K})
                                   hint(l:'Type' m:oz({Value.type Key}))])}
                  end
               end
            else
               {Ctrl.rep
                error(coord: @coord
                      kind : SAGenError
                      msg  : if OO then
                                'expected a literal, cell, dictionary#literal or array#int'
                             else
                                'expected a cell, dictionary#literal or array#int'
                             end
                      items:[hint(l:'Statement' m:Expr)
                             hint(l:'Value' m:FeaOz)
                             hint(l:'Type' m:oz({Value.type Fea}))])}
            end
         end
      end

      meth doCatAssignAccessOO(Ctrl)
         {self doCatAssignAccess(Ctrl oo:true)}
      end

      meth doAnd(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         BVO3 = {Nth @actualArgs 3}
         Val1 = {GetData BVO1}
         Val2 = {GetData BVO2}
      in
         if
            {IsDet Val1} andthen {IsDet Val2}
         then
            Token = {Bool2Token {And Val1 Val2}}
         in
            {Ctrl setErrorMsg('boolean and failed')}
            {Ctrl setUnifier(BVO3 Token)}

            {BVO3 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
      end

      meth doOr(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         BVO3 = {Nth @actualArgs 3}
         Val1 = {GetData BVO1}
         Val2 = {GetData BVO2}
      in
         if
            {IsDet Val1} andthen {IsDet Val2}
         then
            Token = {Bool2Token {Or Val1 Val2}}
         in
            {Ctrl setErrorMsg('boolean and failed')}
            {Ctrl setUnifier(BVO3 Token)}

            {BVO3 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
      end

      meth doNot(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         Val1 = {GetData BVO1}
      in
         if
            {IsDet Val1}
         then
            Token = {Bool2Token {Not Val1}}
         in
            {Ctrl setErrorMsg('boolean not failed')}
            {Ctrl setUnifier(BVO2 Token)}

            {BVO2 unifyVal(Ctrl Token)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
      end

      meth doLabel(Ctrl)
         BVO1 = {Nth @actualArgs 1}
         BVO2 = {Nth @actualArgs 2}
         Val  = {BVO1 getValue($)}
      in
         if
            {Val isRecordConstr($)}
         then
            Lab={Val getLabel($)} LabNode
         in
            if {IsDet Lab} then

               {Ctrl setErrorMsg('label assertion failed')}
               {Ctrl setUnifier(BVO2 Val)}

               LabNode = {New Core.valueNode init(Lab unit)}
               {BVO2 unify(Ctrl LabNode)}

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            end
         end
      end

      meth doWidth(Ctrl)
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
         Data  = {GetData BVO1}
      in
         if
            {IsDet Data}
         then
            IntVal= {New Core.valueNode init({Width Data} @coord)}
         in
            {Ctrl setErrorMsg('width assertion failed')}
            {Ctrl setUnifier(BVO2 IntVal)}

            {BVO2 unifyVal(Ctrl IntVal)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
      end

      meth doProcedureArity(Ctrl)
         BVO1  = {Nth @actualArgs 1}
         BVO2  = {Nth @actualArgs 2}
         Data  = {GetData BVO1}
      in
         if
            {IsDet Data}
         then
            IntVal = {New Core.valueNode init({Procedure.arity Data} @coord)}
         in
            {Ctrl setErrorMsg('assertion of procedure arity failed')}
            {Ctrl setUnifier(BVO2 IntVal)}

            {BVO2 unifyVal(Ctrl IntVal)}

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
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
         if {DetTests.det BVO1} then
            {Ctrl setErrorMsg('type test failed')}

            if {Test {GetData BVO1}} then
               {Ctrl setUnifier(BVO2 RunTime.tokens.'true')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'true')}
            else
               {Ctrl setUnifier(BVO2 RunTime.tokens.'false')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'false')}
            end

            {Ctrl resetUnifier}
            {Ctrl resetErrorMsg}
         end
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

         if {DetTests.detOrKinded BVO1} then
            if {Test {GetData BVO1}} then
               {Ctrl setUnifier(BVO2 RunTime.tokens.'true')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'true')}
            else
               {Ctrl setUnifier(BVO2 RunTime.tokens.'false')}
               {BVO2 unifyVal(Ctrl RunTime.tokens.'false')}
            end
         end
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
         if
            {ConstrainTypes DesigType ProcType}
         then
            skip
         else
            PN  = pn({@designator getPrintName($)})
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Vals= {Map @actualArgs fun {$ A} {GetPrintData A} end}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'wrong arity in application of '#PN
                   items: [hint(l:'Procedure type' m:{TypeToVS DesigType})
                           hint(l:'Application arity' m:{Length @actualArgs})
                           hint(l:'Application (names)'
                                m:{ApplToVS PN|PNs})
                           hint(l:'Application (values)'
                                m:{ApplToVS PN|Vals})])}
         end
      end

      meth sa(Ctrl)

\ifdef DEBUGSA
         {System.show application({@designator getPrintName($)} )}
\endif

         if
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
               if
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

            if ArgsOk then
               SABuiltinApplication, assertTypes(Ctrl BIName)
            end

         elseif
            SAApplication, checkDesignatorProcedure($)
         then
            DVal = {GetData @designator}
            ExpA = {Procedure.arity DVal}
            GotA = {Length @actualArgs}
         in
            if
               GotA \= ExpA
            then
               PN  = pn({@designator getPrintName($)})
               Val = {GetPrintData @designator}
               PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
               Vals= {Map @actualArgs fun {$ A} {GetPrintData A} end}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal arity in application'
                      items: [hint(l:'Arity found' m:GotA)
                              hint(l:'Expected' m:ExpA)
                              hint(l:'Application (names)'
                                   m:{ApplToVS PN|PNs})
                              hint(l:'Application (values)'
                                   m:{ApplToVS Val|Vals})])}
            end

         elseif
            SAApplication, checkDesignatorObject($)
         then
            PN   = {@designator getPrintName($)}
            Cls  = {{@designator getValue($)} getClassNode($)}
            GotA = {Length @actualArgs}
         in
            if
               GotA \= 1
            then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal number of arguments in object application'
                      items: [hint(l:'Object' m:pn(PN))
                              hint(l:'Number found' m:GotA)
                              hint(l:'Expected' m:1)])}
            elseif
               Cls == unit
            then
               skip
            else
               Msg  = {Nth @actualArgs 1}
               Meth = {Cls getMethods($)}
            in
               SAApplication, checkMessage(Ctrl Msg Meth object PN)
            end

         elseif
            {DetTests.det @designator}
         then
            Val = {GetPrintData @designator}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SAGenError
                   msg:   'applying non-procedure and non-object'
                   items: [hint(l:'Value found' m:Val)])}
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

   class SAIfNode from SAStatement
      meth saDescend(Ctrl)
         %% descend with global environment
         %% will be saved and restored in clauses
         if {DetTests.det @arbiter}
            andthen {TypeTests.bool {GetData @arbiter}}
         then
            PN = {@arbiter getPrintName($)}
         in
\ifdef DEBUGSA
            {System.show isConst(PN)}
\endif
            if
               {TypeTests.'true' {GetData @arbiter}}
            then
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   ('boolean guard' #
                             case PN of unit then ""
                             else ' ' # pn(PN)
                             end # ' is always true'))}

               local T N in
                  {Ctrl getTopNeeded(T N)}
                  {Ctrl notTopNotNeeded}
                  {@alternative saDescend(Ctrl)}
                  {Ctrl setTopNeeded(T N)}
               end

               {@consequent saDescendAndCommit(Ctrl)}
            else
               %% {TypeTests.'false' {GetData @arbiter}}
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   ('boolean guard' #
                             case PN of unit then ""
                             else ' ' # pn(PN)
                             end # ' is always false'))}

               local T N in
                  {Ctrl getTopNeeded(T N)}
                  {Ctrl notTopNotNeeded}
                  {@consequent saDescend(Ctrl)}
                  {Ctrl setTopNeeded(T N)}
               end

               {@alternative saDescendAndCommit(Ctrl)}
            end

         elseif
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
         in
            {Ctrl.rep
             error(coord: @coord
                   msg:   'Non-boolean arbiter in `if\' statement'
                   kind:  SATypeError
                   items: (hint(l:'Value' m:{GetPrintData @arbiter})|
                           hint(l:'Type' m:{TypeToVS {@arbiter getType($)}})|
                           case PN of unit then nil
                           else [hint(l:'Name' m:pn(PN))]
                           end))}
         end
      end
      meth applyEnvSubst(Ctrl)
         {@arbiter applyEnvSubst(Ctrl)}
      end
   end

   class SAIfClause
      meth saDescendWithValue(Ctrl Arbiter Val)
         ArbV = {Arbiter getVariable($)}
         %% arbiter value unknown, hence also save arbiter value
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
         %% arbiter value known, hence no need to save arbiter value
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

   class SAPatternCase from SAStatement
\ifdef DEBUGSA
      meth sa(Ctrl)
         {System.show
          patternCase(@clauses {Map @globalVars
                                fun {$ V} {V getPrintName($)} end})}
      end
\endif
      meth saDescend(Ctrl)
         %% descend with global environment
         %% will be saved and restored in clauses
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
         ArbV = {Arbiter getVariable($)}
         %% also save arbiter:
         Env  = {GetGlobalEnv {Add ArbV @globalVars}}
         T N PVal
      in
         {@pattern sa(Ctrl)}

         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopNotNeeded}

         {Ctrl setErrorMsg('pattern never matches')}
         {@pattern getPatternValue(?PVal)}
         {Ctrl setUnifier(Arbiter PVal)}

         {Arbiter unify(Ctrl PVal)}
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

   class SASideCondition
      meth getPatternValue($)
         {@pattern getPatternValue($)}
      end
      meth sa(Ctrl)
         {@pattern sa(Ctrl)}
         SAStatement, saBody(Ctrl @statements)
      end
      meth applyEnvSubst(Ctrl)
         {@pattern applyEnvSubst(Ctrl)}
         {@arbiter applyEnvSubst(Ctrl)}
      end
   end

   class SARecordPattern
      from SAConstructionOrPattern
      meth sa(Ctrl)

\ifdef DEBUGSA
         {System.show saConstruction}
\endif

         {ForAll
          @args
          proc {$ Arg}
             case Arg of _#T then
                {T sa(Ctrl)}
             else
                {Arg sa(Ctrl)}
             end
          end}

         value <- {New RecordConstr
                   init(SAConstruction,makeValue(Ctrl @isOpen $) self)}
      end

      meth getPatternValue($)
         %% the value of record patterns is
         %% not the pattern itself, but stored in it
         {self getValue($)}
      end
   end

   %%
   %% equation pattern:
   %%   behave like equations for sa
   %%   and like their rhs for all properties
   %%
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
      meth getPatternValue($)
         {@right getPatternValue($)}
      end
      meth isOpen($)
         {@right isOpen($)}
      end
      meth isRecordConstr($)
         {@right isRecordConstr($)}
      end

      meth deref(VO)
         {@right deref(VO)}
      end

      meth sa(Ctrl)
\ifdef DEBUGSA
         {System.show equationPattern(@left @right)}
\endif
         {Ctrl setErrorMsg('equational constraint in pattern failed')}

         {@right sa(Ctrl)}                          % analyse right hand side

         %% patterns forward the unification task
         %% to their associated record value token
         if {@right isConstruction($)}
         then
            {Ctrl setUnifier(@left {@right getValue($)})}
            {@left unify(Ctrl {@right getValue($)})}
         else
            {Ctrl setUnifier(@left @right)}
            {@left unify(Ctrl @right)}              % l -> r
         end

         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}
      end

      meth reachable(Vs $)
         {@right reachable({@left reachable(Vs $)} $)}
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
         %% also save arbiter !!
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

   class SATryNode from SAStatement
      meth saDescend(Ctrl)
         Env1 Env2
         T N
      in
         %% check try clause
         Env1 = {GetGlobalEnv @globalVars}

         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @tryStatements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env1}

         %% check catch clause

         %% the main reason to copy the global environment
         %% here a second time (and not reuse the first one) is
         %% that during GetGlobalEnv the types of all reachable
         %% variables are cloned (possible optimization: compute
         %% reachable variables only once and _only_ clone types here)

         Env2 = {GetGlobalEnv @globalVars}

         {Ctrl notTopNotNeeded}
         SAStatement, saBody(Ctrl @catchStatements)
         {Ctrl setTopNeeded(T N)}

         {InstallGlobalEnv Env2}
      end
   end

   class SALockNode from SAStatement
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

   class SAClassNode from SAStatement
      feat
         isComplex:false

      meth saSimple(Ctrl)
         IllClass TestClass
         DummyClass = {MakeDummyClass
                       case @printName of '' then
                          {@designator getPrintName($)}
                       elseof X then X
                       end}
         Value = {New Core.classToken init(DummyClass)}
      in
         isToplevel <- {Ctrl getTop($)}

         {AllUpTo @parents
          DetTypeTests.'class' ?IllClass ?TestClass} % do type test, return exc

\ifdef DEBUG
         {System.show classNode({@designator getPrintName($)}
                                {Map @parents fun {$ X} {X getPrintName($)} end})}
\endif
         if
            TestClass
         then
            PTs = {Map @parents fun {$ X} {X getValue($)} end}
            PsDet
         in
            {AllUpTo @parents DetTests.det _  PsDet}

            SAClassNode, InheritProperties(Value Ctrl PTs)
            SAClassNode, InheritAttributes(Value Ctrl PTs PsDet)
            SAClassNode, InheritFeatures(Value Ctrl PTs PsDet)
            SAClassNode, InheritMethods(Value Ctrl PTs PsDet)
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'inheriting from non-class'
                   items: [hint(l:'Value found' m:{GetPrintData IllClass})])}
         end

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

         %% type test
         if TestAtom then
            %% new determined properties
            Pro  = {Filter {Map @properties GetData} TypeTests.atom}
            %% properties of det parents
            PPro = {Map PTs fun {$ P}
                               if {DetTests.det P} then {P getProperties($)}
                               else unit
                               end
                            end}
            NthFinal TestFinal
         in
            {SomeUpToN PPro
             fun {$ P} P\=unit andthen {Member final P} end
             ?NthFinal ?TestFinal}

            if TestFinal then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   ('inheritance from final class '#
                              pn({System.printName
                                  {{Nth PTs NthFinal} getValue($)}})))}
            else
               NonUnitPro = {Filter PPro fun {$ P} P\=unit end}
            in
               %% type & det test
               {Value setProperties({UnionAll Pro|NonUnitPro})}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-atomic class property'
                   items: [hint(l:'Property found'
                                m:{GetPrintData IllAtom})])}
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

         if
            TestFeat
         then
            AData = {Map Att GetData}
         in
            %% distinct attributes required
            if
               {AllDistinct AData}
            then
               %% parents determined?
               if PsDet then
                  PAtt = {Map PTs fun {$ P} {P getAttributes($)} end}
               in
                  %% type & det test
                  if
                     {Not {Member unit PAtt}}
                     andthen
                     {All AData TypeTests.feature}
                  then
                     {Value setAttributes({UnionAll AData|PAtt})}
                  else
                     skip
                  end
                  %% complain about parents elsewhere
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
                   msg:   'illegal class attribute'
                   items: [hint(l:'Attribute found'
                                m:{GetPrintData IllFeat})])}
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

         if
            TestFeat
         then
            FData = {Map Fea GetData}
         in
            %% distinct features required
            if
               {AllDistinct FData}
            then
               %% parents determined?
               if PsDet then
                  PFea = {Map PTs fun {$ P} {P getFeatures($)} end}
               in
                  %% type & det test
                  if
                     {Not {Member unit PFea}}
                     andthen
                     {All FData TypeTests.feature}
                  then
                     {Value setFeatures({UnionAll FData|PFea})}
                  else
                     skip
                  end
                  %% complain about parents elsewhere
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
                   msg:   'illegal class feature'
                   items: [hint(l:'Feature found'
                                m:{GetPrintData IllFeat})])}
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

         if
            TestLab
         then
            if TestReq then
               if TestOpt then
                  MData = {Map Met
                           fun {$ L#(R#O)}
                              {GetData L} #
                              ({Map R GetData} #
                               if O==unit then O
                               else {Map O GetData} end)
                           end}
                  MethNames = {Map MData fun {$ L#_} L end}
               in
                  %% distinct method names required
                  if {AllDistinct MethNames} then
                     %% parents determined?
                     if PsDet then
                        PMet = {Map PTs fun {$ P} {P getMethods($)} end}
                     in
                        %% type & det test
                        if
                           {All MethNames TypeTests.literal}
                           andthen
                           {Not {Member unit PMet}}
                        then
                           NewMet   = {List.toRecord m MData}
                           TotalMet = {ApproxInheritance PMet NewMet}
                        in
                           {Value setMethods(TotalMet)}
                        end
                        %% complain about parents elsewhere
                     end
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
                         items: [hint(l:'Message label' m:{GetPrintData L})
                                 hint(l:'Illegal feature' m:IllOpt)])}
               end
            else
               L#(R#_) = IllReqMeth
               IllReq  = {GetPrintData {AllUpTo R DetTypeTests.feature $ _}}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   'illegal feature in method definition'
                      items: [hint(l:'Message found' m:{GetPrintData L})
                              hint(l:'Illegal feature' m:IllReq)])}
            end
         else
            L#_ = IllLab
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-literal method label'
                   items: [hint(l:'Label found' m:{GetPrintData L})])}
         end
      end
      meth saDescend(Ctrl)
         {Ctrl pushSelf({@designator getValue($)})}

         %% descend with global environment
         %% will be saved in methods
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
         {List.partition Fs fun {$ F} {Label F}==required end R1 O1}

         R2 = {Map R1 fun {$ R} R.1 end}
         O2 = if @isOpen then unit else {Map O1 fun {$ O} O.1 end} end

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
         if {Ctrl getTop($)} andthen {self isOptimizable($)} then
            procedureRef <- {Ctrl declareToplevelProcedure($)}
         end
      end
      meth preApplyEnvSubst(Ctrl)
         {@label applyEnvSubst(Ctrl)}
         {ForAll @formalArgs
          proc {$ A} {A applyEnvSubst(Ctrl)} end}
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
   class SAMethFormalOptional from SAMethFormal   %--** why inherit?
      meth getFormal($)
         optional(@feature)
      end
   end
   class SAMethFormalWithDefault
      meth getFormal($)
         optional(@feature)
      end
      meth applyEnvSubst(Ctrl)
         {@feature applyEnvSubst(Ctrl)}
         case @default of unit then skip
         elseof VO then {VO applyEnvSubst(Ctrl)}
         end
      end
   end

   class SAObjectLockNode from SAStatement
      meth saDescend(Ctrl)
         %% descend with same environment
         T N in
         {Ctrl getTopNeeded(T N)}
         {Ctrl notTopButNeeded}
         SAStatement, saBody(Ctrl @statements)
         {Ctrl setTopNeeded(T N)}
      end
   end

   class SAGetSelf from SAStatement
      meth sa(Ctrl)
         skip   %--** do more here if +warnforward
      end
      meth applyEnvSubst(Ctrl)
         {@destination applyEnvSubst(Ctrl)}
      end
   end

   class SAExceptionNode from SAStatement
   end

   class SAValueNode
      attr type: unit
      meth init()
         type <- {OzValueToType @value}
      end
      meth getPatternValue($)
         self
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
         if IsData then @value
         else @value
         end
      end
      meth getLastValue($)
         self
      end
      meth isRecordConstr($)
         false
      end
      meth deref(VO)
         skip
      end
      meth reachable(Vs $)
         Vs
      end

      %% unify: _ x Token U ValueNode

      meth unify(Ctrl RHS)
\ifdef LOOP
         {System.show unifyVN(@value {RHS getValue($)})}
\endif
         if
            {UnifyTypesOf self RHS Ctrl @coord}
         then
            RVal = {RHS getValue($)}
         in
            if
               {IsDet RVal} andthen @value == {RHS getValue($)}
            then skip else
               if {IsFree RVal}
               then skip else
                  {IssueUnificationFailure Ctrl @coord
                   [hint(l:'First value' m:oz(@value))
                    hint(l:'Second value' m:oz(RVal))]}
               end
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
         if @lastValue == unit then {TypeToVS @type}
         else {@lastValue getPrintType(AnalysisDepth $)}
         end
      end
      meth outputDebugMeths($)
         if {IsToken @lastValue} then Value in
            {@lastValue getValue(?Value)}
            if {IsClass Value} then
               case {@lastValue getMethods($)} of unit then unit
               elseof Ms then {Arity Ms}
               end
            elseif {IsObject Value} then
               case {{@lastValue getClassNode($)} getMethods($)}
               of unit then unit
               elseof Ms then {Arity Ms}
               end
            else unit
            end
         else unit
         end
      end
      meth outputDebugAttrs($)
         if {IsToken @lastValue} then Value in
            {@lastValue getValue(?Value)}
            if {IsClass Value} then
               {@lastValue getAttributes($)}
            elseif {IsObject Value} then
               {{@lastValue getClassNode($)} getAttributes($)}
            else unit
            end
         else unit
         end
      end
      meth outputDebugFeats($)
         if {IsToken @lastValue} then Value in
            {@lastValue getValue(?Value)}
            if {IsClass Value} then
               {@lastValue getFeatures($)}
            elseif {IsObject Value} then
               {{@lastValue getClassNode($)} getFeatures($)}
            else unit
            end
         else unit
         end
      end
      meth outputDebugProps($)
         if {IsToken @lastValue} then Value in
            {@lastValue getValue(?Value)}
            if {IsClass Value} then
               {@lastValue getProperties($)}
            elseif {IsObject Value} then
               {{@lastValue getClassNode($)} getProperties($)}
            else unit
            end
         else unit
         end
      end
      meth getLastValue($)
         @lastValue
      end
      meth setLastValue(O)
         lastValue <- O
         if O \= unit then
            type <- {O getType($)}
         end
      end
      meth deref(VO)
         if @lastValue == unit then                   % is free
            SAVariable, setLastValue(VO)              % initialize with var-occ

         elseif {HasFeature @lastValue ImAVariableOccurrence} then
            NewVal = {@lastValue getValue($)}         % getLastValue($) ?
         in
            SAVariable, setLastValue(NewVal)          % var path compression
            if @lastValue \= NewVal then
               SAVariable, deref(VO)                  % recur
            end

         elseif {@lastValue isRecordConstr($)} then
            NewVal = {@lastValue getLastValue($)}
         in
            if @lastValue == NewVal then
               skip                                   % self reference
            elseif NewVal == unit then
               {@lastValue setLastValue(@lastValue)}  % non initialised
            else
               SAVariable, setLastValue(NewVal)       % constr path compression
               if @lastValue \= NewVal then
                  SAVariable, deref(VO)               % recur
               end
            end

         else
            %% number, atom, token (ground value)
            skip
         end
      end
      meth valToSubst(Value)
         SAVariable, ValToSubst(nil AnalysisDepth Value)
      end
      meth ValToSubst(Seen Depth Val) ValRepr in
         ValRepr =
         if Depth =< 0 then
\ifdef DEBUGSA
            {System.show valToSubstBreakDepth(Val)}
\endif
            unit   % stop analysis here
         elseif {CompilerSupport.isLocalDet Val} then
            case {Value.status Val} of det(Type) then
\ifdef DEBUGSA
               {System.show valToSubst(Val)}
\endif
               case Type of int then
                  {New Core.valueNode init(Val unit)}
               [] float then
                  {New Core.valueNode init(Val unit)}
               [] atom then
                  {New Core.valueNode init(Val unit)}
               [] name then
                  {New Core.valueNode init(Val unit)}
               [] tuple then
                  SAVariable, RecordToSubst(Seen Depth Val $)
               [] record then
                  SAVariable, RecordToSubst(Seen Depth Val $)
               [] procedure then
                  {New Core.valueNode init(Val unit)}
               [] cell then
                  {New Core.valueNode init(Val unit)}
               [] array then
                  {New Core.valueNode init(Val unit)}
               [] dictionary then
                  {New Core.valueNode init(Val unit)}
               [] bitArray then
                  {New Core.valueNode init(Val unit)}
               [] 'class' then
                  Cls = {New Core.classToken init(Val)}
                  Meths = {Record.make m {OoExtensions.getMethNames Val}}
                  Attrs = {OoExtensions.getAttrNames Val}
                  Feats = {OoExtensions.getFeatNames Val}
                  Props = {OoExtensions.getProps Val}
               in
                  {Record.forAll Meths fun {$} nil#unit end}
                  {Cls setMethods(Meths)}
                  {Cls setAttributes(Attrs)}
                  {Cls setFeatures(Feats)}
                  {Cls setProperties(Props)}
                  Cls
               [] object then
                  TheClass = {OoExtensions.getClass Val}
                  Meths = {Record.make m {OoExtensions.getMethNames TheClass}}
                  Attrs = {OoExtensions.getAttrNames TheClass}
                  Feats = {OoExtensions.getFeatNames TheClass}
                  Props = {OoExtensions.getProps TheClass}
                  Cls   = {New Core.classToken init(TheClass)}
               in
                  {Record.forAll Meths fun {$} nil#unit end}
                  {Cls setMethods(Meths)}
                  {Cls setAttributes(Attrs)}
                  {Cls setFeatures(Feats)}
                  {Cls setProperties(Props)}
                  {New Core.objectToken init(Val Cls)}
               [] 'lock' then
                  {New Core.valueNode init(Val unit)}
               [] port then
                  {New Core.valueNode init(Val unit)}
               [] chunk then Rec RecRepr in
                  Rec = {List.toRecord void
                         {Map {CompilerSupport.chunkArity Val}
                          fun {$ F} F#Val.F end}}
                  SAVariable, RecordToSubst(Seen Depth Rec ?RecRepr)
                  {New Core.token init({NewChunk {RecRepr getValue($)}})}
               [] space then
                  {New Core.valueNode init(Val unit)}
               [] 'thread' then
                  {New Core.valueNode init(Val unit)}
               [] byteString then
                  {New Core.valueNode init(Val unit)}
               [] bitString then
                  {New Core.valueNode init(Val unit)}
               else unit
               end
            else unit
            end
         else unit
         end
         SAVariable, setLastValue(ValRepr)
         SAVariable, setType({OzValueToType Val})
      end
      meth RecordToSubst(Seen Depth Val $)
         RecArgs = {Record.toListInd Val}
         Lab     = {Label Val}
         RecConstrValArgs RecVal
      in
         %% reconstruct heap only up to limited width of records
         SAVariable, RecordValToArgs(RecArgs
                                     (Val#self)|Seen
                                     Depth
                                     AnalysisWidth.Depth
                                     ?RecConstrValArgs)
         if {Width Val} =< AnalysisWidth.Depth then
            RecVal = {List.toRecord Lab RecConstrValArgs}
         else
            RecVal = {RecordC.tell Lab}
            {ForAll RecConstrValArgs proc {$ F#A}
                                        {RecordC.'^' RecVal F A}
                                     end}
         end
         {New RecordConstr init(RecVal unit)}
      end
      meth RecordValToArgs(RecArgs Seen Depth Width ?ConstrValArgs)
         case RecArgs of (F#X)|RAs andthen Width > 0 then V VO CVAr in
            case {PLDotEQ X Seen} of unit then   % not seen
               V = {New Core.generatedVariable init('RecordArg' unit)}
               {V ValToSubst(Seen Depth - 1 X)}
            elseof X then
               V = X
            end
            {V occ(unit ?VO)}
            {VO updateValue()}
            ConstrValArgs = F#VO|CVAr
            SAVariable, RecordValToArgs(RAs Seen Depth Width - 1 CVAr)
         else
            ConstrValArgs = nil
         end
      end
      meth typeToSubst(Type)
         SAVariable, TypeToSubst(Type AnalysisDepth)
      end
      meth TypeToSubst(Type Depth)
         %% no sharing is supported
         case Type of value(Value) then
            SAVariable, valToSubst(Value)
         [] type(Xs) then
            SAVariable, setType({OzTypes.encode Xs nil})
         [] record(Rec) then Lab RecArgs RecConstr in
            Lab = {Label Rec}
            SAVariable, RecordTypeToSubst({Arity Rec} Rec Depth _ ?RecArgs)
            RecConstr = {New RecordConstr
                         init({List.toRecord Lab RecArgs} unit)}
            SAVariable, setLastValue(RecConstr)
         end
      end
      meth RecordTypeToSubst(Arity Rec Depth ?Args ?RecArgs)
         case Arity of F|Fr then RecFeat V VO Argr RecArgr in
            RecFeat = {New Core.valueNode init(F unit)}
            V = {New Core.generatedVariable init('RecordType' unit)}
            {V TypeToSubst(Rec.F Depth - 1)}
            {V occ(unit ?VO)}
            {VO updateValue()}
            Args = F#VO|Argr
            RecArgs = RecFeat#VO|RecArgr
            SAVariable, RecordTypeToSubst(Fr Rec Depth ?Argr ?RecArgr)
         [] nil then
            Args = nil
            RecArgs = nil
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
         case @lastValue of unit then        % uninitialized variable
            {Add self Vs}
         else
            SAVariable, deref(@lastValue)

            if {HasFeature @lastValue ImAVariableOccurrence} then
               %% save self + representant (might differ!)
               {Add self {Add {@lastValue getVariable($)} Vs}}

            elseif {@lastValue isRecordConstr($)} then
               %%
               %% if we do not implement ft unification fully
               %% but only on determined records, then
               %% we actually need not save self here.
               %%
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
         {Value.toVirtualString {self getValue($)} 10 10}#' // '#
         {Value.toVirtualString {GetData self} 10 10}
      end

      meth getPatternValue($)
         self
      end
      meth getLastValue($)
         {@variable deref(self)}
         {@variable getLastValue($)}
      end
      meth isRecordConstr($)
         false
      end
      meth deref(VO)
         {@variable deref(VO)}
      end

      %% copies the value Val after replacing variable occurrences
      %% with the currently last variable occurrences of the
      %% same variable
      %%
      %% if Val is unit, then VO is returned as current value

      meth updateValue
         SAVariableOccurrence, UpdateValue({@variable getLastValue($)})
      end
      meth UpdateValue(O)
\ifdef DEBUGSA
         {System.show updating(O)}
\endif
         if
            O==unit                       % no value known
         then
            {self setValue(self)}         % initialize value
         elseif
            {HasFeature O ImAVariableOccurrence}   % fully deref var occs
         then
            OLV = {O getLastValue($)}
         in
            if O == OLV
               orelse {O getVariable($)} == @variable
            then
               {self setValue(O)}
            else
               SAVariableOccurrence, UpdateValue(OLV)
            end
         elseif
            {O isRecordConstr($)}
         then
            Args NArgs
         in
            Args  = {O getArgs($)}
            NArgs = {Map Args
                     fun {$ Arg}
                        case Arg of F#T then
                           F#{T getLastValue($)}
                        else
                           {Arg getLastValue($)}
                        end
                     end}

            %% no change in record value
            if Args == NArgs then
\ifdef DEBUGSA
               {System.show notCopyingSame}
\endif
               {self setValue(O)}
            else
\ifdef DEBUGSA
               {System.show copyingStruct({O getValue($)})}
\endif
               LData = {O getLabel($)}
               FData = {List.mapInd NArgs
                        fun {$ I Arg}
                           case Arg of _#_ then Arg else I#Arg end
                        end}
               Rec
            in
               if
                  {O isOpen($)}
               then
                  if {IsDet LData} then
                     Rec = {RecordC.tell LData}
                  else skip end
                  {ForAll FData proc {$ F#V}
                                   {RecordC.'^' Rec F V}
                                end}
               else
                  Rec = {List.toRecord LData FData}
               end

               {self setValue( {New RecordConstr
                                init(Rec {O getOrigin($)})} )}
            end
         else
            %% atom, integer, float, token (ground values)
            {self setValue(O)}
         end
      end

      %% there is only one type field per variable
      %% this could be improved but would - in the
      %% current state - invalidate an invariant
      %% wrt saving/installing variable environments
      %% for conditional clauses

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
         if {HasFeature @value ImAVariableOccurrence} then
            if IsData then _
            else   % dummy variable with right print name
               case {@variable getPrintName($)} of unit then _
               elseof PrintName then {CompilerSupport.nameVariable $ {System.printName PrintName}}
               end
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
         if
            {Member @variable Vs}
         then
            Vs
         else
            {@variable reachable(Vs $)}
         end
      end

      %% unifyVal: _ x Token U RecordConstr U ValueNode

      meth unifyVal(Ctrl RHS)
\ifdef LOOP
         {System.show unifyVO({self getPrintName($)} RHS)}
\endif
         LHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         if
            {Not {UnifyTypesOf self RHS Ctrl @coord}}
         then
            skip % do not continue on type error
         elseif
            {HasFeature LHS ImAVariableOccurrence}
         then
            SAVariableOccurrence, bind(Ctrl RHS)
         elseif
            {LHS isRecordConstr($)}
         then
            {LHS unify(Ctrl RHS)}
         else
            %% LHS is Valuenode or Token
            {LHS unify(Ctrl RHS)}
         end
      end

      %% Bind: _ x VariableOccurrence U Token U RecordConstr U ValueNode

      meth bind(Ctrl RHS)
\ifdef LOOP
         {System.show bind({self getPrintName($)} {self getType($)} {RHS getValue($)})}
\endif
         if
            {UnifyTypesOf self RHS Ctrl @coord}
         then
            %% set new value for following occurrences
            {@variable setLastValue(RHS)}
         else
            skip % not continue on type error
         end
      end

      %% unify: _ x VariableOccurrence U Token U RecordConstr U ValueNode

      meth unify(Ctrl TorC)
\ifdef LOOP
         if
            {HasFeature TorC ImAVariableOccurrence}
         then
            {System.show unifyV({self getPrintName($)} {TorC getPrintName($)})}
         else
            {System.show unifyV({self getPrintName($)} TorC)}
         end
\endif

         LHS RHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         if
            {UnifyTypesOf LHS TorC Ctrl @coord}
         then
            if
               {HasFeature TorC ImAVariableOccurrence}
            then
               %% implicit deref
               RHS = {TorC getLastValue($)}
            elseif
               {TorC isRecordConstr($)}
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

      %% UnifyDeref: _ x VariableOccurrence U Token U RecordConstr U ValueNode

      meth UnifyDeref(Ctrl LHS RHS)
\ifdef LOOP
         {System.show unifyDR({self getPrintName($)} LHS RHS)}
\endif
         if
            LHS == RHS
         then
            skip                                % nothing to do
         else
            if
               {HasFeature LHS ImAVariableOccurrence}
            then
               {LHS bind(Ctrl RHS)}
            elseif
               {HasFeature RHS ImAVariableOccurrence}
            then
               {RHS bind(Ctrl LHS)}
            elseif
               {LHS isRecordConstr($)}
            then
               %--** here is some work on extension to ft unification
               if
                  {RHS isRecordConstr($)}
               then
                  {RHS bind(Ctrl LHS)}
               else
                  skip % and fail on unification
               end
               {LHS unify(Ctrl RHS)}
            elseif
               {RHS isRecordConstr($)}
            then
               {RHS unify(Ctrl LHS)}
            else
               %% LHS is ValueNode or Token
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
         if IsObj then self
         else @value end
      end
      meth getFullData(D IsData $)
         if IsData then self
         else @value
         end
      end
      meth isRecordConstr($)
         false
      end
      meth unify(Ctrl RHS)
\ifdef LOOP
         {System.show unifyT(@value {RHS getValue($)})}
\endif
         if {UnifyTypesOf self RHS Ctrl unit} then RVal in
            {RHS getValue(?RVal)}
            if {IsToken RHS} andthen @value == RVal then skip
            else
               {IssueUnificationFailure Ctrl unit
                [hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz(RVal))]}
            end
         end
      end
   end

   class RecordConstr
      feat !ImARecordConstr
      attr value type lastValue origin

      meth init(Val Origin)
         RecordConstr, setValue(Val)
         RecordConstr, makeType
         RecordConstr, setLastValue(self)
         origin <- Origin
      end
      meth isRecordConstr($)
         true
      end
      meth getValue($)
         @value
      end
      meth setValue(Val)
         value <- Val
      end
      meth getCodeGenValue($)
         if @origin==unit % top-level value
         then @value
         else {@origin getCodeGenValue($)}
         end
      end
      meth makeVO(CS VHd VTl ?VO)
         case @origin==unit of false then
            {@origin makeVO(CS VHd VTl ?VO)}
         end
      end
      meth getLastValue($)
         @lastValue
      end
      meth setLastValue(O)
         lastValue <- O
      end
      meth getLabel($)
         if {IsDet @value} then {Label @value} else _ end
      end
      meth getArgs($)
         {Map {CurrentArity @value}
          fun {$ F} F#{RecordC.'^' @value F} end}
      end
      meth isOpen($)
         {Not {IsDet @value}}
      end
      meth getOrigin($)
         @origin
      end
      meth makeType
         type <- {OzValueToType @value}
      end
      meth getType($)
         @type
      end
      meth getPrintType(D $)
         if
            D =< 0
         then
            {TypeToVS @type}
         else
            {self deref(self)}
            if
               {IsDet @value}
            then
               if {IsTuple @value} then
                  {ListToVS
                   '(' | {Map {Record.toList @value}
                          fun {$ X} {X getPrintType(D-1 $)} end}
                   {Value.toVirtualString {Label @value} 0 0} ' ' ' )'}
               else
                  {ListToVS
                   '(' | {Map {Record.toListInd @value}
                          fun {$ F#X}
                             {Value.toVirtualString F 0 0} # ': ' #
                             {X getPrintType(D-1 $)}
                          end}
                   {Value.toVirtualString {Label @value} 0 0} ' ' ' )'}
               end
            elseif
               {IsFree @value}
            then
               {TypeToVS @type}
            else
               Lab = if {RecordC.hasLabel @value} then {Label @value} else _ end
            in
               {ListToVS
                '(' | {Map {CurrentArity @value}
                       fun {$ F}
                          {Value.toVirtualString F 0 0} # ': ' #
                          {{RecordC.'^' @value F} getPrintType(D-1 $)}
                       end}
                {Value.toVirtualString Lab 0 0}  ' ' '...)'}
            end
         end
      end
      meth reflectType(Depth $)
         try
            if
               Depth > 0 andthen {IsDet @value}
            then
               Lab  = {Label @value}
               Args = {List.mapInd
                       RecordConstr, getArgs($)
                       fun {$ I Arg}
                          case Arg of F#X then
                             F#{X reflectType(Depth - 1 $)}
                          else
                             I#{Arg reflectType(Depth - 1 $)}
                          end
                       end}
            in
               record({List.toRecord Lab Args})
            else fail unit
            end
         catch failure(...) then
            type({OzTypes.decode @type})
         end
      end
      meth setType(T)
         type <- T
      end
      meth getData(IsObj $)
         @value
      end
      meth getFullData(D IsData $)
         if
            D =< 0
         then
            _
         else
            {self deref(self)}
            if
               {IsDet @value}
            then
               {Record.map @value fun {$ X} {X getFullData(D-1 IsData $)} end}
            elseif
               {IsFree @value}
            then
               @value
            else
               Rec
               Lab = if {RecordC.hasLabel @value} then {Label @value} else _ end
            in
               if {IsDet Lab} then
                  Rec = {RecordC.tell Lab}
               else skip end
               {ForAll {CurrentArity @value}
                proc {$ F}
                   {RecordC.'^' Rec F}=
                   {{RecordC.'^' @value F} getFullData(D-1 IsData $)}
                end}
               Rec
            end
         end
      end
      meth deref(VO)
         if @lastValue == unit then                     % is "free"
            RecordConstr, setLastValue(VO)   % initialize with self

         elseif {@lastValue isRecordConstr($)} then
            NewVal = {@lastValue getLastValue($)}
         in
            if @lastValue == NewVal then
               skip                                     % self reference
            elseif NewVal == unit then
               {@lastValue setLastValue(@lastValue)}    % non initialised
            else
               RecordConstr, setLastValue(NewVal) % constr path compr
               RecordConstr, deref(VO)
            end

         else
            skip % atom
         end
      end

      %% reachability for record values is defined through
      %% the original program node

      meth reachable(Vs $)
         %% record values, like variables, can become bound during
         %% value propagation, therefore, they too need to be snapshot
         %% and restored by GetGlobalEnv/InstallGlobalEnv
         Vs2 = {Add self Vs}
      in
         if @origin==unit then Vs2
         else {@origin reachable(Vs2 $)} end
      end

      %% Bind: _ x RecordConstr

      meth bind(Ctrl RHS)
\ifdef LOOP
         {System.show bindRecordConstr(self {RHS getValue($)})}
\endif
         if
            {UnifyTypesOf self RHS Ctrl unit}
         then
            %% set new value for following occurrences
            RecordConstr, setLastValue(RHS)
         else
            skip % not continue on type error
         end
      end

      %% unify: _ x Token U RecordConstr U ValueNode

      meth unify(Ctrl RHS)
\ifdef LOOP
         {System.show unifyC(RHS)}
\endif
         if
            {Not {UnifyTypesOf self RHS Ctrl unit}}
         then
            skip % do not continue on type error
         elseif
            {RHS isRecordConstr($)}
         then
            RLab  = {RHS getLabel($)}
            RArgs = {RHS getArgs($)}
            ROpen = {RHS isOpen($)}
            RVal  = {GetData RHS}
            LLab  = {self getLabel($)}
            LArgs = {self getArgs($)}
            LOpen = {self isOpen($)}
         in
            if
               {IsDet LLab} andthen {IsDet RLab}
            then
               if
                  LLab==RLab
               then
                  skip
               else
                  {IssueUnificationFailure Ctrl unit
                   [hint(l:'Incompatible labels'
                         m:oz(LLab) # ' and ' # oz(RLab))
                    hint(l:'First value' m:oz(@value))
                    hint(l:'Second value' m:oz(RVal))]}
               end
            else skip end

            if
               {Not LOpen} andthen {Not ROpen}
               andthen {Length LArgs} \= {Length RArgs}
            then
               {IssueUnificationFailure Ctrl unit
                [hint(l:'Incompatible widths'
                      m:{Length LArgs} # ' and ' # {Length RArgs})
                 hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz(RVal))]}
            else skip end

            if
               {IsDet @value} andthen {IsDet RVal}
            then
               if {Arity @value} == {Arity RVal} then
                  {ForAll {Arity @value}
                   proc {$ F}
                      VF = @value.F
                      RF = RVal.F
                   in
                      if
                         {HasFeature RF ImAVariableOccurrence}
                      then
                         {RF unify(Ctrl VF)}
                      else
                         {VF unify(Ctrl RF)}
                      end
                   end}
               else
                  {IssueUnificationFailure Ctrl unit
                   [hint(l:'Incompatible arities'
                         m:oz({Arity @value}) # ' and ' # oz({Arity RVal}))
                    hint(l:'First value' m:oz(@value))
                    hint(l:'Second value' m:oz(RVal))]}
               end
            else
               LArity = {CurrentArity @value}
               RArity = {CurrentArity RVal}
            in
               {ForAll RArity
                proc {$ F}
                   if
                      {Member F LArity}
                   then
                      VF = {RecordC.'^' @value F}
                      RF = {RecordC.'^' RVal F}
                   in
                      if
                         {HasFeature RF ImAVariableOccurrence}
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

         else
            %% ValueNode or Token
            {RHS unify(Ctrl self)}
         end
      end
   end
end
