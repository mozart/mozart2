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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\define ANALYSEINHERITANCE


/*
\define DEBUGSA
\define LOOP
\define INHERITANCE
\define DEBUGSA_POS
\define REMINDER
\define DEBUG_SAVESUBST
*/

local

%-----------------------------------------------------------------------
% Some constants and shorthands

   SAGenError  = 'static analysis error'
   SAGenWarn   = 'static analysis warning'
   SATypeError = 'type error'


   DPut = Dictionary.put
   DGet = Dictionary.get
   DNew = Dictionary.new
   DCGet= Dictionary.condGet
   DMem = Dictionary.member
   VS2S = VirtualString.toString
   IsVS = IsVirtualString
   Partition = List.partition
   FSClone = {`Builtin` fsClone 2}

   IsConstType = IsDet

   fun {TypeClone T}
      case {IsFree T} then _ else {FSClone T} end
   end

   fun {FirstOrId X}
      case X of F#_ then F else X end
   end

   fun {First F#_}
      F
   end

   fun {Second _#S}
      S
   end

% assumes privacy of the following feature names
% introduced in CoreLanguage:
%
% ImAVariableOccurrence
% ImAValueNode
% ImAConstruction
% ImAToken

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

   fun {KindedRecordToList R}
      {FoldR {CurrentArity R}
       fun {$ A In} R.A|In end nil}
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

   fun {GetValue X}
      XV = {X getValue($)}
   in
      case {IsDet XV}
         andthen {IsObject XV}
      then
         case XV==X
         then
            XV
         elsecase {HasFeature XV ImAValueNode}
            orelse {HasFeature XV ImAToken}
         then
            XV
         elsecase {HasFeature XV ImAConstruction}
            orelse {HasFeature XV ImAVariableOccurrence}
         then
            {GetData XV}
         else
            XV
         end
      else
         XV
      end
   end

% GetData: T -> <value>
% given a T node, returns the associated value
% ie, an integer/float/atom/construction; or the
% value associated with a token (proc/builtin/class etc.)
% constructions may contain embedded T nodes

   fun {GetData X}
      XV = {X getValue($)}
   in
      case {IsDet XV}
         andthen {IsObject XV}
      then
         case XV==X
         then
            XV
         elsecase {HasFeature XV ImAValueNode}
            orelse {HasFeature XV ImAToken}
         then
            {XV getValue($)}
         elsecase {HasFeature XV ImAConstruction}
            orelse {HasFeature XV ImAVariableOccurrence}
         then
            {GetData XV}
         else
            XV
         end
      else
         XV
      end
   end

% GetPrintData: T -> <oz-term>
% given a T node, returns the associated value
% ie, an integer/float/atom/construction; or the
% value associated with a token (proc/builtin/class etc.)
% constructions are expanded recursively

   fun {GetPrintData X}
      XD = {GetData X}
   in
      case
         {IsDet XD}
      then
         case
            {IsRecord XD}
         then
            {Record.map XD GetPrintData}
         elsecase
            {IsObject XD}
         then
            case
               {HasFeature XD ImAVariableOccurrence}
            then
               X
            in
               {NameVariable X {XD getPrintName($)}}
               X
%                 {PrintNameToVirtualString
%                  {XD getPrintName($)}}
            elsecase
               {HasFeature XD ImAToken}
            then
               {XD output2(_ $ _)}
            else
               XD
            end
         else
            XD
         end
      elsecase
         {IsFree XD}
      then
         XD
      elsecase
         {IsRecordC XD}
      then
         Rec
         Lab = case {Record.hasLabel XD} then {Label XD} else _ end
      in
         case {IsDet Lab} then
            Rec = {TellRecord Lab}
         else skip end
         {ForAll {CurrentArity XD}
          proc {$ F}
             Rec^F = {GetPrintData XD^F}
          end}
         Rec
      elsecase
         {FD.is XD}
      then
         XD
      else
         XD
      end
   end

%-----------------------------------------------------------------------
% Type predicates

   fun {IsAny _}
      true
   end

   TypeTests
   = tt(value:             IsAny
        any:               IsAny
        number:            IsNumber
        int:               IsInt
        char:              IsChar
        float:             IsFloat
        literal:           IsLiteral
        atom:              IsAtom
        name:              IsName
        bool:              IsBool
        'true':            fun {$ X}
                              X == true
                           end
        'false':           fun {$ X}
                              X == false
                           end
        'unit':            IsUnit
        feature:           fun {$ X}
                              {TypeTests.int X} orelse {TypeTests.literal X}
                           end
        comparable:        fun {$ X}
                              {TypeTests.number X} orelse {TypeTests.atom X}
                           end
        record:            IsRecord
        recordC:           IsRecordC
        tuple:             IsTuple
        recordOrChunk:     fun {$ X}
                              {TypeTests.record X} orelse {TypeTests.chunk X}
                           end
        recordCOrChunk:    fun {$ X}
                              {TypeTests.recordC X} orelse {TypeTests.chunk X}
                           end
        token:             fun {$ X}
                              {IsObject X} andthen {HasFeature X ImAToken}
                           end
        builtin:           IsBuiltin
        procedure:         IsProcedure
        procedureOrObject: fun {$ X}
                              {TypeTests.procedure X}
                              orelse {TypeTests.object X}
                           end
        'nullary procedure':fun {$ X}
                              {TypeTests.procedure X}
                              andthen {Procedure.arity X} == 0
                           end
        'unary procedure': fun {$ X}
                              {TypeTests.procedure X}
                              andthen {Procedure.arity X} == 1
                           end
        'binary procedure':fun {$ X}
                              {TypeTests.procedure X}
                              andthen {Procedure.arity X} == 2
                           end
        'ternary procedure':fun {$ X}
                              {TypeTests.procedure X}
                              andthen {Procedure.arity X} == 3
                            end
        'n-ary procedure': fun {$ X}
                              {TypeTests.procedure X}
                              andthen {Procedure.arity X} > 3
                           end
        cell:              IsCell
        chunk:             IsChunk
        array:             IsArray
        dictionary:        IsDictionary
        'class':           IsClass
        object:            fun {$ X}
                              {IsObject X} andthen
                              {Not {HasFeature X ImAConstruction}
                               orelse {HasFeature X ImAValueNode}
                               orelse {HasFeature X ImAToken}}
                           end
        'lock':            IsLock
        port:              IsPort
        space:             IsSpace
        'thread':          IsThread
        virtualString:     IsVirtualString
        string:            IsString
        list:              IsList
        pair:              fun {$ X}
                              case X of _#_ then true else false end
                           end
       )

%-----------------------------------------------------------------------
% Determination predicates

   DetTests
   = dt(det:    fun {$ X} XD = {GetData X} in
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
                end
        any:    IsAny
        atomic: fun {$ X} XD = {GetData X} in
                   {IsDet XD} andthen
                   case {IsObject XD} then
                      {Not {HasFeature XD ImAVariableOccurrence}
                       orelse {HasFeature XD ImAConstruction}}
                   else false end
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
      DetTypeTests2
      = dtt(list: MaybeList
            listOf: MaybeListOf
            pairOf: MaybePairOf
            string: MaybeString)

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
            raise illegalTypeDeclaration(T) end
         end
      end
   end

%-----------------------------------------------------------------------
% perform determination & type checks

   local
      fun {TypeCheckN N VOs Ts}
         case VOs of nil then
            Ts = nil
            0
         [] VO|VOr then
            T|Tr = Ts
         in
            case
               {DetTypeTest T VO}
            then
               {TypeCheckN N+1 VOr Tr}
            else
               N
            end
         end
      end
   in
      fun {TypeCheck VOs Ts}
         {TypeCheckN 1 VOs Ts}
      end
   end

   fun {DetCheck VOs Ds}
      case VOs of nil then
         Ds = nil
         true
      [] VO|VOr then
         D|Dr = Ds
      in
         {DetTests.{Label D} VO}
         andthen
         {DetCheck VOr Dr}
      end
   end

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

         case {IsConstType T}
         then env(var:V last:L)
         else
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L type:T)
         end

      elsecase
         {L isVariableOccurrence($)}
      then
\ifdef DEBUGSA
         {Show env(var:V last:L data:{GetValue L} type:T)}
\endif
         case {IsConstType T}
         then env(var:V last:L data:{GetValue L})
         else
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L data:{GetValue L} type:T)
         end

      elsecase
         {L isConstruction($)}
      then
\ifdef DEBUGSA
         {Show env(var:V last:L data:{GetValue L} type:T)}
\endif
         case {IsConstType T}
         then env(var:V last:L data:{GetValue L})
         else
            % copy non-constant types
            {V setType({TypeClone T})}
            env(var:V last:L data:{GetValue L} type:T)
         end

      else
         % L is atomic: int, float, atom, token
         % has constant type
         case {IsConstType T}
         then env(var:V last:L)
         else {Show weird(L T)}
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
      {Show installing(E)}
      {Show install({V getPrintName($)} L {V getLastValue($)})}
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
      {Show v(Vs {Map Vs fun {$ V} {V getPrintName($)} end})}
      {Show r(ReachableVs {Map ReachableVs fun {$ V} {V getPrintName($)} end})}
\endif

      {Map ReachableVs GetReachable}
   end

   proc {InstallGlobalEnv Env}
      {ForAll Env InstallEntry}
   end

%-----------------------------------------------------------------------
% type equality assertions

% TryUnifyTypes: FSET x FSET
% propagate type information both ways
% (cloning values to avoid incorrect backflow of data)

   fun {TryUnifyTypes TX TY}
      try
         case {IsConstType TX}
            orelse {IsConstType TY}
         then
            TX = TY
         else
            TX = {TypeClone TY}
            TY = {TypeClone TX}
         end
         true
      catch
         failure(...)
      then
         false
      end
   end

%
% IssueTypeError: FSET x FSET x VALUE x VALUE
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

   proc {IssueTypeError TX TY X Y Ctrl Top Coord}
\ifdef DEBUGSA
      {Show issuetypeerror(TX TY X Y)}
\endif

      ErrMsg UnifLeft UnifRight Msgs Body
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
      Body   = {FoldR Msgs Append nil}

      case Top then
         {Ctrl.rep
          error(coord:Coord kind:SATypeError msg:ErrMsg body:Body)}
      else
         {Ctrl.rep
          warn(coord:Coord kind:SAGenWarn msg:ErrMsg body:Body)}
      end
   end

   fun {UnifyTypes X Y Ctrl Top Coord}
      TX = {X getType($)}
      TY = {Y getType($)}
   in
      case
         {TryUnifyTypes TX TY}
      then
         true
      else
         {IssueTypeError TX TY X Y Ctrl Top Coord}
         false
      end
   end

%-----------------------------------------------------------------------
% equality assertions

   proc {IssueUnificationFailure Ctrl Top Coord Msgs}
      Origin Offend UnifLeft UnifRight Text1 Text2
   in
      Origin = {Ctrl getCoord($)}
      {Ctrl getUnifier(UnifLeft UnifRight)}
      Offend = hint(l:'Offending term in' m:Coord)

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

      Text2 = case Origin==Coord then Text1
              else {Append Text1 [Offend]} end

      case Top then
         {Ctrl.rep error(coord: Origin
                         kind:  SAGenError
                         msg:   'unification error on top level'
                         body:  Text2)}
      else
         {Ctrl.rep warn(coord: Origin
                        kind:  SAGenWarn
                        msg:   'unification error below top level'
                        body:  Text2)}
      end
   end

%-----------------------------------------------------------------------
%

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
         unit
      end
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

   fun {SeqToVS Xs}
      {ListToVS Xs '' ' ' ''}
   end

   fun {ProdToVS Xs}
      {ListToVS Xs '' ' x ' ''}
   end

   fun {ApplToVS Xs}
      {ListToVS Xs '{' ' ' '}'}
   end

   fun {FormatArity Xs}
      {Map {Arity Xs}
       fun {$ X} case {IsName X} then oz(X) else X end end}
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

   local
      fun {AllUpToAux Xs P N Ill}
         case Xs
         of nil then
            Ill = N   % avoid free variables
            true
         [] X|Xr then
            case {P X}
            then {AllUpToAux Xr P N+1 Ill}
            else Ill = N false end
         end
      end
   in
      fun {AllUpTo Xs P ?Ill}
         {AllUpToAux Xs P 1 Ill}
      end
   end

   local
      fun {SomeUpToAux Xs P N Ill}
         case Xs
         of nil then
            Ill = N   % avoid free variables
            false
         [] X|Xr then
            case {P X} then Ill = N true
            else {SomeUpToAux Xr P N+1 Ill}
            end
         end
      end
   in
      fun {SomeUpTo Xs P ?Wit}
         {SomeUpToAux Xs P 1 Wit}
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
         toplevelNames: unit % list of names in a virtual toplevel
         errorMsg: unit      % currently active error message
         unifierLeft: unit   % last unification requested
         unifierRight: unit  %

      meth init(Rep Switches)
         self.rep = Rep
         self.switches = Switches
         'self'        <- nil
         coord         <- unit
         toplevelNames <- unit
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
            raise popEmptyStack end
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

      meth beginVirtualToplevel(Coord)
         case @toplevelNames == unit then
            toplevelNames <- nil
         else
            {self.rep
             error(coord: Coord
                   kind:  SAGenError
                   msg:   'nested procedures with virtual toplevels')}
         end
      end
      meth declareToplevelName(N)
         case @toplevelNames == unit then skip
         else toplevelNames <- N|@toplevelNames
         end
      end
      meth endVirtualToplevel(?Ns)
         Ns = @toplevelNames
         toplevelNames <- unit
      end
      meth isVirtualToplevel($)
         @toplevelNames \= unit
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

   class SADefault
      meth applyEnvSubst(Ctrl Top)
         skip
      end
      meth saDescend(Ctrl Top)
         skip
      end
      meth sa(Ctrl Top)
         skip
      end
   end

   class SAStatement
      from SADefault

      % a complex statement is one which may do more than suspend immediately
      % or bind a variable; _not_ complex in this sense are constraints,
      % declarations, definitions, class nodes, etc.
      % (a class with isComplex = false should provide an saLookahead method)
      %
      % we only deal with definitions and class nodes at this point

      feat
         isComplex:true

      meth staticAnalysis(Rep Switches Ss)
         Ctrl = {New Control init(Rep Switches)}
      in
         {self SaDo(Ctrl true true)}       % initiate first lookahead
      end

      %%
      %% save coordinates for error messages
      %%

      meth saveCoord(Ctrl)
         {Ctrl setCoord({self getCoord($)})}
      end

      %%
      %% static analysis iteration
      %%

      meth saSimple(Ctrl Top)
         skip
\ifdef DEBUGSA_POS
         case @coord of pos(F L C) then
            {System.showError {Error.formatPos F L C unit}}
         [] pos(F L C _ _ _) then
            {System.showError {Error.formatPos F L C unit}}
         [] posNoDebug(F L C) then
            {System.showError {Error.formatPos F L C unit}}
         else skip
         end
\endif
      end
      meth saLookahead(Ctrl Top)
         {self applyEnvSubst(Ctrl Top)}      % apply old substitutions
         {self saSimple(Ctrl Top)}
         case
            self.isComplex                   % if this statement is complex
            orelse
            @next==self                      % or there is no other one
         then
            skip                             % then terminate
         else
            {@next saLookahead(Ctrl Top)}    % otherwise proceed
         end
      end
      meth SaDo(Ctrl Top Cpx)
         case
            Cpx                              % if last statement was complex
         then
            SAStatement, saveCoord(Ctrl)
            {self saLookahead(Ctrl Top)}     % then do lookahead
         else
            {self applyEnvSubst(Ctrl Top)}   % apply old substitutions
         end

         SAStatement, saveCoord(Ctrl)
         {self sa(Ctrl Top)}
         {self saDescend(Ctrl Top)}

         case
            @next==self
         then
            skip
         else
            {@next SaDo(Ctrl Top self.isComplex)}
         end
      end
      meth saBody(Ctrl Top Ss)
         case
            Ss
         of
            S|Sr
         then
            {S SaDo(Ctrl Top true)} % new lookahead in bodies // self.isComplex
         end
      end
   end

   class SADeclaration
      meth sa(Ctrl Top)
\ifdef DEBUGSA
         {Show declaration({Map @localVars fun {$ V} {V getPrintName($)} end})}
\endif
         {ForAll @localVars proc {$ V} {V setToplevel(Top)} end}
      end
      meth saDescend(Ctrl Top)
         % descend with same environment
         SAStatement, saBody(Ctrl Top @body)
      end
   end

   class SASkipNode
      meth sa(Ctrl Top)
         SAStatement, sa(Ctrl Top)
      end
   end

   class SAEquation
      meth sa(Ctrl Top)
\ifdef DEBUGSA
         {Show saEQ(@left @right)}
\endif
         {@right sa(Ctrl Top)}                            % analyse right hand side
         {@left unify(Ctrl Top @right)}                   % l -> r
      end
      meth applyEnvSubst(Ctrl Top)
         {@left applyEnvSubst(Ctrl Top)}
         {@right applyEnvSubst(Ctrl Top)}
      end
   end

   class SAConstructionOrPattern
      attr
         type: unit
         lastValue : unit

      meth init()
         type <- {OzTypes.new record nil}
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
      meth setType(T)
         type <- T
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
         {Show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
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

      meth makeConstruction(Ctrl)
         Coord= {@label getCoord($)}
         Args = {FoldL @args
                 fun {$ In Arg}
                    case Arg of F#_ then F|In else In end
                 end nil}
      in
         case
            {DetTypeTests.literal @label}
            andthen
            {All Args DetTypeTests.feature}
         then
            LData = {GetData @label}
            FData = {List.mapInd @args
                     fun {$ I Arg}
                        case Arg of F#T then {GetData F}#T else I#Arg end
                     end}
            Fields= {Map FData fun {$ F#_} F end}
         in
\ifdef DEBUGSA
         {Show makeConstruction(LData FData Fields)}
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
                  {Show noRecordConstructed}
\endif
                  value <- _ % no record constructed
               end
            else
               {Ctrl.rep
                error(coord: Coord
                      kind:  SAGenError
                      msg:   'duplicate features in record construction'
                      body:  [hint(l:'Features found' m:{SetToVS Fields})])}
            end
         else
            {Ctrl.rep error(coord: Coord
                            kind:  SAGenError
                            msg:   'ill-typed construction')}
         end
\ifdef DEBUGSA
         {Show madeConstruction(@value)}
\endif
      end

      %% Bind: _ x Construction

      meth bind(Ctrl Top RHS)
\ifdef DEBUGSA
         {Show bindConstruction(self {RHS getValue($)})}
\endif
         case
            {Not {UnifyTypes self RHS Ctrl Top {@label getCoord($)}}}
         then
            skip % not continue on type error
         else
            % set new value for following occurrences
            SAConstructionOrPattern, setLastValue(RHS)
         end
      end

      % unify: _ x Token U Construction U ValueNode

      meth unify(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyC(RHS)}
\endif
         Coord = {@label getCoord($)}
      in
         case
            {Not {UnifyTypes self RHS Ctrl Top Coord}}
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
               {@label unify(Ctrl Top RLab)}               % unify labels
            elsecase
               {RLab isVariableOccurrence($)}
            then
               {RLab unify(Ctrl Top @label)}
            else                                % both labels must be known
\ifdef DEBUGSA
               {Show label({GetData @label} {GetData RLab})}
\endif
               case
                  {GetData @label}=={GetData RLab}
               then
                  skip
               else
                  {IssueUnificationFailure Ctrl Top Coord
                   [hint(l:'incompatible labels'
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
               {IssueUnificationFailure Ctrl Top Coord
                [hint(l:'incompatible widths'
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
                      {RF unify(Ctrl Top VF)}
                   else
                      {VF unify(Ctrl Top RF)}
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
                         {RF unify(Ctrl Top VF)}
                      else
                         {VF unify(Ctrl Top RF)}
                      end
                   else
                      %--** incomplete ft unification
                      skip
                   end
                end}
            end

         elsecase
            {TypeTests.token RHS}
            orelse
            {IsAtom {RHS getValue($)}}
         then

            case
               @isOpen
            then
               {@label unify(Ctrl Top RHS)}
            elsecase
               {Length @args}\=0
            then
               {IssueUnificationFailure Ctrl Top Coord
                [hint(l:'Incompatible widths'
                      m:{Length @args} # ' and ' # 0)
                 hint(l:'First value' m:oz(@value))
                 hint(l:'Second value' m:oz({RHS getValue($)}))]}
            else
               {@label unify(Ctrl Top RHS)}
            end

         else
            {IssueUnificationFailure Ctrl Top Coord
             [line('record = number')
              hint(l:'First value' oz(@value))
              hint(l:'Second value' oz({RHS getValue($)}))]}
         end
      end
      meth sa(Ctrl Top)

\ifdef DEBUGSA
         {Show saConstruction}
\endif

         {ForAll @args
          proc {$ Arg}
             case Arg of F#T then
                {F sa(Ctrl Top)}
                {T sa(Ctrl Top)}
             else
                {Arg sa(Ctrl Top)}
             end
          end}
         SAConstructionOrPattern, makeConstruction(Ctrl)
         SAConstructionOrPattern, makeType
      end
      meth applyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
         {@label applyEnvSubst(Ctrl Top)}
         {ForAll @args
          proc {$ Arg}
             case Arg of F#T then
                {F applyEnvSubst(Ctrl Top)}
                {T applyEnvSubst(Ctrl Top)}
             else
                {Arg applyEnvSubst(Ctrl Top)}
             end
          end}
      end
   end

   class SAConstruction
      from SAConstructionOrPattern
   end

   % definitions and class definitions
   class SAAbstraction
      attr value: unit
      meth getValue($)
         @value
      end
   end

   class SADefinition
      from SAAbstraction
      feat
         isComplex:false
      meth saSimple(Ctrl Top)
         DummyProc ID
      in
         DummyProc = {MakeDummyProcedure {Length @formalArgs}}
         value     <- {New Core.procedureToken init(DummyProc)}

         % prepare some feature values for the code generator:
         case {self isClauseBody($)} then
            @value.clauseBodyStatements = @body
            ID = 0
         else
            case Top then
               ID = {GenerateAbstractionTableID {Ctrl isVirtualToplevel($)}}
            else
               ID = 0
            end
         end
         self.abstractionTableID = ID
         @value.abstractionTableID = ID

         {@designator unifyVal(Ctrl Top @value)}

\ifdef DEBUGSA
         {Show lookedAhead({@designator getPrintName($)} @value)}
\endif
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show definition({@designator getPrintName($)} Top)}
\endif
      end
      meth saDescend(Ctrl Top)
         Env = {GetGlobalEnv @globalVars}
      in
         case {Member 'instantiate' @procFlags} then
            {Ctrl beginVirtualToplevel(@coord)}
            SAStatement, saBody(Ctrl true @body)
            toplevelNames <- {Ctrl endVirtualToplevel($)}
         else
            SAStatement, saBody(Ctrl false @body)
         end
         {InstallGlobalEnv Env}
      end
      meth applyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
         {@designator applyEnvSubst(Ctrl Top)}
      end
   end

   class SAFunctionDefinition
   end

   class SAClauseBody
   end

   class SABuiltinApplication

      meth AssertTypes(Ctrl N Args Types Det)
         case Args
         of nil then skip
         elseof A|Ar then
            case Types # Det
            of (T|Tr) # (D|Dr)
            then
\ifdef DEBUG
         {Show asserting(A T D)}
\endif
               case
                  {TryUnifyTypes {OzTypes.new {Label T} nil} {A getType($)}}
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
                         body:  [hint(l:'Procedure' m:PN)
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

         case {GetBuiltinInfo BIName}
         of noInformation then skip
         elseof I then
            Types = I.types
            Det   = I.det
         in
\ifdef DEBUGSA
            {Show assert(BIName I @actualArgs)}
\endif
            SABuiltinApplication, AssertTypes(Ctrl 1 @actualArgs Types Det)
         end
      end

      meth checkMessage(Ctrl Top MsgArg Meth Type PN)
         Msg     = {GetData MsgArg}
         MsgData = {GetPrintData MsgArg}
\ifdef DEBUG
         {Show checkingMsg(pn:PN arg:MsgArg msg:Msg met:Meth)}
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
                             body:  [hint(l:What m:pn(PN))
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
                                body:  [hint(l:What m:pn(PN))
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
                      body:  [hint(l:What m:pn(PN))
                              hint(l:'Expected' m:{SetToVS {FormatArity Meth}})
                              hint(l:'Message found' m:oz(MsgData))])}
            end
         else
            skip
         end
      end

      % Det: flag whether to check determination

      meth checkArguments(Ctrl N Det $)
         BIInfo = {GetBuiltinInfo N}
      in
         case BIInfo
         of noInformation then false
         elsecase
            {Length @actualArgs} == {Length BIInfo.types}
         then
            case
               {TypeCheck @actualArgs BIInfo.types}
            of
               0 % no type error
            then
\ifdef DEBUGSA
               {Show det({Map @actualArgs GetData}
                         {DetCheck @actualArgs BIInfo.det})}
\endif
               {Not Det} orelse {DetCheck @actualArgs BIInfo.det}
            elseof
               Pos
            then
               PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
               Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
               Ts  = {Map BIInfo.types fun {$ T} oz(T) end}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   'ill-typed application'
                      body:  [hint(l:'Builtin' m:pn(N))
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
                            body:  [hint(l:'Builtin' m:N)
                                    hint(l:'Expected'
                                         m:{Length BIInfo.types})
                                    hint(l:'Found' m:{Length @actualArgs})
                                    hint(l:'Argument names'
                                         m:{ApplToVS pn(N)|PNs})
                                    hint(l:'Argument values'
                                         m:{ApplToVS pn(N)|Vals})])}
            false
         end
      end

      meth doBuiltin(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'builtin' true B)

         case B then
            BIName = {GetData {Nth @actualArgs 1}}
            BIArity= {GetData {Nth @actualArgs 2}}
            BndVO  = {Nth @actualArgs 3}
         in
            try
               Proc = {`Builtin` BIName BIArity}
               BI = {New Core.builtinToken init(Proc)}
            in
\ifdef DEBUGSA
               {Show newBuiltin(BIName BIArity Proc)}
\endif
               {BndVO unifyVal(Ctrl Top BI)}

            catch
               error(system(K ...) ...) = Exc
            then
\ifdef DEBUGSA
               {Show '******' # Exc}
\endif
               case K of builtinUndefined then
                  {Ctrl.rep
                   warn(coord: @coord
                        kind:  SAGenWarn
                        msg:   'builtin undefined'
                        body:  [hint(l:'Name' m:pn(BIName))
                                hint(l:'Arity' m:BIArity)])}
               [] builtinArity then
                  {Ctrl.rep
                   warn(coord: @coord
                        kind:  SAGenWarn
                        msg:   'builtin has wrong arity'
                        body:  [hint(l:'Name' m:pn(BIName))
                                hint(l:'Arity' m:BIArity)])}
               end
            end

         else skip end
      end
      meth doNewName(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewName' true B)

         case B then
            BndVO BndV PrintName TheName Top0 Token
         in
            BndVO = {Nth @actualArgs 1}
            {BndVO getVariable(?BndV)}
            {BndV getPrintName(?PrintName)}
            case Top andthen {BndV getOrigin($)} \= generated then
               TheName = {NewNamedName PrintName}
               {Ctrl declareToplevelName(TheName)}
            else
               TheName = {NewName}
            end
            Top0 = (Top andthen
                    {Not {Ctrl.switches getSwitch(debuginfovarnames $)}})
            Token = {New Core.nameToken init(PrintName TheName Top0)}
            {BndVO unifyVal(Ctrl Top Token)}
            case Top then self.codeGenMakeEquateLiteral = TheName
            else skip end
         else skip end
      end
      meth doNewUniqueName(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewUniqueName' true B)

         case B then
            NName = {GetData {Nth @actualArgs 1}}
            Value = {{`Builtin` 'NewUniqueName' 2} NName}   % always succeeds
            Token = {New Core.nameToken init(NName Value true)}
            BndVO = {Nth @actualArgs 2}
         in
\ifdef DEBUGSA
            {Show newUniqueName(NName Token)}
\endif
            {BndVO unifyVal(Ctrl Top Token)}
            self.codeGenMakeEquateLiteral = Value
         else
            skip
         end
      end
      meth doTclNames(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'getTclNames' true B)

         case B then
            BVO1 = {Nth @actualArgs 1}
            BVO2 = {Nth @actualArgs 2}
            BVO3 = {Nth @actualArgs 3}
            TclSlaves TclSlaveEntry TclName
         in
            {{`Builtin` getTclNames 3} ?TclSlaves ?TclSlaveEntry ?TclName}
            {BVO1 unifyVal(Ctrl Top
                           {New Core.nameToken
                            init({BVO1 getPrintName($)} TclSlaves false)})}
            {BVO2 unifyVal(Ctrl Top
                           {New Core.nameToken
                            init({BVO2 getPrintName($)} TclSlaveEntry false)})}
            {BVO3 unifyVal(Ctrl Top
                           {New Core.nameToken
                            init({BVO3 getPrintName($)} TclName false)})}
         else skip end
      end
      meth doNewLock(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewLock' true B)

         case B then
            Token = {New Core.lockToken init({NewLock})}
            BndVO = {Nth @actualArgs 1}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewPort(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewPort' true B)

         case B then
            Token = {New Core.portToken init({NewPort _})}
            BndVO = {Nth @actualArgs 2}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewCell(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewCell' true B)

         case B then
            Token = {New Core.cellToken init({NewCell _})}
            BndVO = {Nth @actualArgs 2}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewArray(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewArray' true B)

         case B then
            Low  = {GetData {Nth @actualArgs 1}}
            High = {GetData {Nth @actualArgs 2}}
            Token= {New Core.arrayToken init({Array.new Low High _})}
            BndVO= {Nth @actualArgs 4}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewDictionary(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewDictionary' true B)

         case B then
            Token= {New Core.dictionaryToken init({Dictionary.new})}
            BndVO= {Nth @actualArgs 1}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewChunk(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'NewChunk' true B)

         case B then
            Rec  = {GetData {Nth @actualArgs 1}}
            Token= {New Core.chunkToken init({NewChunk Rec})}
            BndVO= {Nth @actualArgs 2}
         in
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNewSpace(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'Space.new' true B)

         case B then
            Pred = {GetData {Nth @actualArgs 1}}
            Token= {New Core.spaceToken init({Space.new proc {$ _} skip end})}
            BndVO= {Nth @actualArgs 2}
         in
\ifdef DEBUGSA
            {Show space({{Nth @actualArgs 2} getPrintName($)} Pred)}
\endif
            {BndVO unifyVal(Ctrl Top Token)}
         else skip end
      end
      meth doNew(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'New' true B)

         case B then
            DummyObject = {New BaseObject noop}
            Cls  = {GetClassData {Nth @actualArgs 1}}
            Msg  = {Nth @actualArgs 2}
            Token= {New Core.objectToken init(DummyObject Cls)}
            BndVO= {Nth @actualArgs 3}
            PN   = {BndVO getPrintName($)}
         in
            {BndVO unifyVal(Ctrl Top Token)}

            case Cls == unit
            then skip else
               Meth = {Cls getMethods($)}
            in
               SABuiltinApplication, checkMessage(Ctrl Top Msg Meth new PN)
            end
         else
            skip
\ifdef DEBUGSA
            {Show noObjectCreation({{Nth @actualArgs 3} getPrintName($)})}
\endif
         end
      end
      meth doDot(Ctrl Top B)
\ifdef DEBUGSA
         {Show dot(@actualArgs {Map @actualArgs GetData})}
\endif


         SABuiltinApplication, checkArguments(Ctrl '.' true B)

         case B then
            FirstArg = {Nth @actualArgs 1}
            RecOrCh  = {GetData FirstArg}
            F        = {GetData {Nth @actualArgs 2}}
         in
\ifdef DEBUGSA
            {Show dot(FirstArg RecOrCh F)}
\endif
            case
               {IsDet RecOrCh}
               andthen {TypeTests.object RecOrCh}
            then
\ifdef DEBUGSA
               {Show dotobj}
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
                            body:  [hint(l:'Expected' m:{SetToVS {Ozify Fs}})
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
                            body:  [hint(l:'Expected' m:{SetToVS {Ozify Fs}})
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

                  {BndVO unify(Ctrl Top RecOrCh.F)}

                  {Ctrl resetUnifier}
                  {Ctrl resetErrorMsg}
               else
                  {Ctrl.rep
                   error(coord: @coord
                         kind:  SAGenError
                         msg:   'illegal feature selection from record'
                         body:  [hint(l:'Expected' m:{SetToVS {FormatArity RecOrCh}})
                                 hint(l:'Found' m:oz(F))])}
               end
            elsecase
               {TypeTests.recordC RecOrCh}
               andthen {HasFeatureNow RecOrCh F}
            then
               BndVO = {Nth @actualArgs 3}
            in
               {Ctrl setErrorMsg('dot selection failed')}
               {Ctrl setUnifier(BndVO RecOrCh.F)}

               {BndVO unify(Ctrl Top RecOrCh^F)}

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            else
               skip
            end
         else
            skip
         end
      end
      meth doHat(Ctrl Top B)
\ifdef DEBUGSA
         {Show hat(@actualArgs {Map @actualArgs GetData})}
\endif

         SABuiltinApplication, checkArguments(Ctrl '^' true B)

         case B then
            Rec = {GetData {Nth @actualArgs 1}}
            Fea = {GetData {Nth @actualArgs 2}}
         in
\ifdef DEBUGSA
            {Show hat(Rec Fea)}
\endif
            case
               {HasFeatureNow Rec Fea}
            then
               BndVO = {Nth @actualArgs 3}
            in
               {Ctrl setErrorMsg('feature selection (^) failed')}
               {Ctrl setUnifier(BndVO Rec^Fea)}

               {BndVO unify(Ctrl Top Rec^Fea)}

               {Ctrl resetUnifier}
               {Ctrl resetErrorMsg}
            elsecase
               {IsDet Rec}
            then
               {Ctrl.rep
                error(coord: @coord
                      kind:  SAGenError
                      msg:   'illegal feature selection from record'
                      body:  [hint(l:'Expected' m:{SetToVS {FormatArity Rec}})
                              hint(l:'Found' m:oz(Fea))])}
            else
               skip
            end
         else
            skip
         end
      end
      meth doComma(Ctrl Top B)
         Cls  = {GetClassData {Nth @actualArgs 1}}
         Msg  = {Nth @actualArgs 2}
         PN   = {{Nth @actualArgs 1} getPrintName($)}
      in
         B = true % this is a hack; should be passed to checkMessage

         case Cls == unit
         then skip else
            Meth = {Cls getMethods($)}
         in
            SABuiltinApplication, checkMessage(Ctrl Top Msg Meth 'class' PN)
         end
      end
      meth doAssignAccess(PName OpName Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl PName true B)

         case B then
            Self = {Ctrl getSelf($)}
         in
            case
               Self==unit   % this may happen with +selfallowedanywhere
            then
               skip
            else
               Fea  = {GetData {Nth @actualArgs 1}}
               CTok = {Self getValue($)}
               Attrs= {CTok getAttributes($)}
               Props= {CTok getProperties($)}
            in
               case
                  Attrs==unit orelse {Member Fea Attrs}
               then
                  skip
               else
                  Val  = {GetData {Nth @actualArgs 2}}
                  Expr = case PName
                         of '<-' then oz(Fea) # ' <- ' # oz(Val)
                         elseof '@' then '@' # oz(Fea) # ' = ' # oz(Val)
                         end
                  Final = (Props\=unit andthen {Member final Props})
                  Hint = case Final
                         then '(correct use requires method application)'
                         else '(may be a correct forward declaration)'
                         end
                  Cls  = case Final
                         then 'In Final Class '
                         else 'In Class '
                         end
               in
                  case
                     Final orelse
                     {Ctrl.switches getSwitch(warnforward $)}
                  then
                     {Ctrl.rep
                      warn(coord: @coord
                           kind:  SAGenWarn
                           msg:   'applying ' # PName #
                           ' to unavailable attribute'
                           body:  [hint(l:'Expression' m:Expr)
                                   hint(l:Cls
                                        m:pn({{Self getDesignator($)}
                                              getPrintName($)}))
                                   hint(l:'Expected' m:{SetToVS {Ozify Attrs}})
                                   line(Hint)])}
                  else skip end
               end
            end
         else skip end
      end
      meth doGetTrue(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'getTrue' true B)

         case B then
            BndVO = {Nth @actualArgs 1}
            Token = {New Core.nameToken
                     init({BndVO getPrintName($)} `true` true)}
         in
            {BndVO unifyVal(Ctrl Top Token)}
            self.codeGenMakeEquateLiteral = {Token getValue($)}
         else skip end
      end
      meth doGetFalse(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'getFalse' true B)

         case B then
            BndVO = {Nth @actualArgs 1}
            Token = {New Core.nameToken
                     init({BndVO getPrintName($)} `false` true)}
         in
            {BndVO unifyVal(Ctrl Top Token)}
            self.codeGenMakeEquateLiteral = {Token getValue($)}
         else skip end
      end
      meth doAndOr(PName Junctor Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl PName true B)

         case B then
            BVO1 = {Nth @actualArgs 1}
            BVO2 = {Nth @actualArgs 2}
            BVO3 = {Nth @actualArgs 3}
            Val1 = {GetData BVO1}
            Val2 = {GetData BVO2}
         in
            case
               {IsDet Val1} andthen {IsDet Val2}
            then
               Result = {Junctor Val1 Val2}
               PN = case Result then 'true' else 'false' end
               Token = {New Core.nameToken init(PN Result true)}
            in
               {BVO3 unifyVal(Ctrl Top Token)}
            else
               skip
            end
         else skip end
      end
      meth doNot(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'Not' true B)

         case B then
            BVO1 = {Nth @actualArgs 1}
            BVO2 = {Nth @actualArgs 2}
            Val1 = {GetData BVO1}
         in
            case
               {IsDet Val1}
            then
               Result = {Not Val1}
               PN = case Result then 'true' else 'false' end
               Token = {New Core.nameToken init(PN Result true)}
            in
               {BVO2 unifyVal(Ctrl Top Token)}
            else skip end
         else skip end
      end
      meth doLabel(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'Label' true B)

         case B then
            BVO1 = {Nth @actualArgs 1}
            BVO2 = {Nth @actualArgs 2}
            Val  = {BVO1 getValue($)}
         in
            case
               {HasFeature Val ImAConstruction}
            then
               {BVO2 unify(Ctrl Top {Val getLabel($)})}
            else skip end
         else skip end
      end
      meth doWidth(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'Width' true B)

         case B then
            BVO1  = {Nth @actualArgs 1}
            BVO2  = {Nth @actualArgs 2}
            Data  = {GetData BVO1}
         in
            case
               {IsDet Data}
            then
               IntVal= {New Core.intNode init({Width Data} @coord)}
            in
               {BVO2 unifyVal(Ctrl Top IntVal)}
            else skip end
         else skip end
      end
      meth doProcedureArity(Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl 'ProcedureArity' true B)

         case B then
            BVO1  = {Nth @actualArgs 1}
            BVO2  = {Nth @actualArgs 2}
            Data  = {GetData BVO1}
         in
            case
               {IsDet Data}
            then
               IntVal = {New Core.intNode init({Procedure.arity Data} @coord)}
            in
               {BVO2 unifyVal(Ctrl Top IntVal)}
            else skip end
         else skip end
      end
      meth doDetType(PName Test Ctrl Top B)
\ifdef DEBUGSA
         {Show doDetType(PName Test)}
\endif

         SABuiltinApplication, checkArguments(Ctrl PName true B)

         case B then
            BVO1  = {Nth @actualArgs 1}
            BVO2  = {Nth @actualArgs 2}
         in
            case {DetTests.det BVO1} then
               case {Test {GetPrintData BVO1}} then
                  {BVO2 unifyVal(Ctrl Top
                                 {New Core.nameToken
                                  init('`true`' `true` true)})}
               else
                  {BVO2 unifyVal(Ctrl Top
                                 {New Core.nameToken
                                  init('`false`' `false` true)})}
               end
            else skip end
         else skip end
      end
      meth doRecDetType(PName ThreeValuedTest Ctrl Top B)
\ifdef DEBUGSA
         {Show doDetType(PName ThreeValuedTest)}
\endif

         SABuiltinApplication, checkArguments(Ctrl PName true B)

         case B then
            BVO1  = {Nth @actualArgs 1}
            BVO2  = {Nth @actualArgs 2}
         in
            case {ThreeValuedTest {GetPrintData BVO1}}
            of true then
               {BVO2 unifyVal(Ctrl Top
                              {New Core.nameToken
                               init('`true`' `true` true)})}
            elseof false then
               {BVO2 unifyVal(Ctrl Top
                              {New Core.nameToken
                               init('`false`' `false` true)})}
            elseof unit then
               skip
            end
         else skip end
      end
      meth doKindedType(PName Test Ctrl Top B)

         SABuiltinApplication, checkArguments(Ctrl PName true B)

         case B then
            BVO1  = {Nth @actualArgs 1}
            BVO2  = {Nth @actualArgs 2}
            Data  = {GetData BVO1}
         in
            case {IsKinded Data} then
               case {Test Data} then
                  {BVO2 unifyVal(Ctrl Top
                                 {New Core.nameToken
                                  init('`true`' `true` true)})}
               else
                  {BVO2 unifyVal(Ctrl Top
                                 {New Core.nameToken
                                  init('`false`' `false` true)})}
               end
            else skip end
         else skip end
      end
   end

   class SAApplication
      from SABuiltinApplication

      meth AssertArity(Ctrl $)
         DesigType = {@designator getType($)}
         ProcType  = case {Length @actualArgs}
                     of 0 then TypeConstants.'nullary procedure'
                     [] 1 then {OzTypes.new procedureOrObject nil}
                     [] 2 then TypeConstants.'binary procedure'
                     [] 3 then TypeConstants.'ternary procedure'
                     else TypeConstants.'n-ary procedure' end
      in
         case
            {TryUnifyTypes ProcType DesigType}
         then
            true
         else
            PN  = {@designator getPrintName($)}
            PNs = {Map @actualArgs fun {$ A} pn({A getPrintName($)}) end}
            Val = {GetPrintData @designator}
            Vals= {Map @actualArgs fun {$ A} oz({GetPrintData A}) end}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'wrong arity in application of ' # pn(PN)
                   body:  [hint(l:'Procedure type' m:{TypeToVS ProcType})
                           hint(l:'Application arity' m:{Length @actualArgs})
                           hint(l:'Application (names)'
                                m:{ApplToVS pn(PN)|PNs})
                           hint(l:'Application (values)'
                                m:{ApplToVS pn(PN)|Vals})])}
            false
         end
      end

      meth sa(Ctrl Top)

\ifdef DEBUGSA
         {Show application({@designator getPrintName($)} )}
\endif
         {@designator sa(Ctrl Top)}

         {ForAll @actualArgs proc {$ A} {A sa(Ctrl Top)} end}

         case
            {Not SAApplication, AssertArity(Ctrl $)}
         then
            skip % do not continue on type error
         elsecase
            SAApplication, checkDesignatorBuiltin($)
         then
            BIName = {GetBuiltinName {GetData @designator}}
            ArgsOk
         in
\ifdef DEBUGSA
            {Show applying(BIName)}
\endif
            case BIName
            of 'NewName'        then
               SABuiltinApplication, doNewName(Ctrl Top ArgsOk)
            [] 'NewUniqueName'  then
               SABuiltinApplication, doNewUniqueName(Ctrl Top ArgsOk)
            [] 'NewCell'        then
               SABuiltinApplication, doNewCell(Ctrl Top ArgsOk)
            [] 'NewLock'        then
               SABuiltinApplication, doNewLock(Ctrl Top ArgsOk)
            [] 'NewPort'        then
               SABuiltinApplication, doNewPort(Ctrl Top ArgsOk)
            [] 'NewArray'       then
               SABuiltinApplication, doNewArray(Ctrl Top ArgsOk)
            [] 'NewDictionary'  then
               SABuiltinApplication, doNewDictionary(Ctrl Top ArgsOk)
            [] 'NewChunk'       then
               SABuiltinApplication, doNewChunk(Ctrl Top ArgsOk)
            [] 'Space.new'      then
               SABuiltinApplication, doNewSpace(Ctrl Top ArgsOk)
            [] 'New'            then
               SABuiltinApplication, doNew(Ctrl Top ArgsOk)
            [] 'IsArray'        then
               SABuiltinApplication, doDetType('IsArray' IsCell Ctrl Top ArgsOk)
            [] 'IsAtom'         then
               SABuiltinApplication, doDetType('IsAtom' IsAtom Ctrl Top ArgsOk)
            [] 'IsBool'         then
               SABuiltinApplication, doDetType('IsBool' IsBool Ctrl Top ArgsOk)
            [] 'IsCell'         then
               SABuiltinApplication, doDetType('IsCell' IsCell Ctrl Top ArgsOk)
            [] 'IsChar'         then
               SABuiltinApplication, doDetType('IsChar' IsChar Ctrl Top ArgsOk)
            [] 'IsChunk'        then
               SABuiltinApplication, doDetType('IsChunk' IsChunk Ctrl Top ArgsOk)
            [] 'IsDet'          then
               SABuiltinApplication, doDetType('IsDet' IsDet Ctrl Top ArgsOk)
            [] 'IsDictionary'   then
               SABuiltinApplication, doDetType('IsDictionary' IsDictionary Ctrl Top ArgsOk)
            [] 'IsFloat'        then
               SABuiltinApplication, doDetType('IsFloat' IsFloat Ctrl Top ArgsOk)
            [] 'IsInt'          then
               SABuiltinApplication, doDetType('IsInt' IsInt Ctrl Top ArgsOk)
            [] 'IsList'         then
               SABuiltinApplication, doRecDetType('IsList' IsListNow Ctrl Top ArgsOk)
            [] 'IsLiteral'      then
               SABuiltinApplication, doDetType('IsLiteral' IsLiteral Ctrl Top ArgsOk)
            [] 'IsLock'         then
               SABuiltinApplication, doDetType('IsLock' IsLock Ctrl Top ArgsOk)
            [] 'IsName'         then
               SABuiltinApplication, doDetType('IsName' IsName Ctrl Top ArgsOk)
            [] 'IsNumber'       then
               SABuiltinApplication, doDetType('IsNumber' IsNumber Ctrl Top ArgsOk)
            [] 'IsObject'       then
               SABuiltinApplication, doDetType('IsObject' IsObject Ctrl Top ArgsOk)
            [] 'IsPort'         then
               SABuiltinApplication, doDetType('IsPort' IsPort Ctrl Top ArgsOk)
            [] 'IsProcedure'    then
               SABuiltinApplication, doDetType('IsDet' IsProcedure Ctrl Top ArgsOk)
            [] 'IsRecord'       then
               SABuiltinApplication, doDetType('IsRecord' IsRecord Ctrl Top ArgsOk)
            [] 'IsRecordC'      then
               SABuiltinApplication, doKindedType('IsRecordC' IsRecordC Ctrl Top ArgsOk)
            [] 'IsSpace'        then
               SABuiltinApplication, doDetType('IsSpace' IsSpace Ctrl Top ArgsOk)
            [] 'IsString'       then
               SABuiltinApplication,
               doRecDetType('IsString' IsStringNow Ctrl Top ArgsOk)
            [] 'IsTuple'        then
               SABuiltinApplication, doDetType('IsTuple' IsTuple Ctrl Top ArgsOk)
            [] 'IsUnit'         then
               SABuiltinApplication, doDetType('IsUnit' IsUnit Ctrl Top ArgsOk)
            [] 'IsVirtualString'then
               SABuiltinApplication,
               doRecDetType('IsVirtualString' IsVirtualStringNow Ctrl Top ArgsOk)
            [] 'Label'          then
               SABuiltinApplication, doLabel(Ctrl Top ArgsOk)
            [] 'Width'          then
               SABuiltinApplication, doWidth(Ctrl Top ArgsOk)
            [] 'ProcedureArity' then
               SABuiltinApplication, doProcedureArity(Ctrl Top ArgsOk)
            [] 'getTclNames'    then
               SABuiltinApplication, doTclNames(Ctrl Top ArgsOk)
            [] '.'              then
               SABuiltinApplication, doDot(Ctrl Top ArgsOk)
            [] '^'              then
               SABuiltinApplication, doHat(Ctrl Top ArgsOk)
            [] ','              then
               SABuiltinApplication, doComma(Ctrl Top ArgsOk)
            [] '<-'             then
               SABuiltinApplication, doAssignAccess('<-' 'Assignment' Ctrl Top ArgsOk)
            [] '@'              then
               SABuiltinApplication, doAssignAccess('@' 'Access' Ctrl Top ArgsOk)
            [] 'builtin'        then
               SABuiltinApplication, doBuiltin(Ctrl Top ArgsOk)
            [] 'getTrue'        then
               SABuiltinApplication, doGetTrue(Ctrl Top ArgsOk)
            [] 'getFalse'       then
               SABuiltinApplication, doGetFalse(Ctrl Top ArgsOk)
            [] 'And'            then
               SABuiltinApplication, doAndOr('And' And Ctrl Top ArgsOk)
            [] 'Or'             then
               SABuiltinApplication, doAndOr('Or' Or Ctrl Top ArgsOk)
            [] 'Not'            then
               SABuiltinApplication, doNot(Ctrl Top ArgsOk)
            else
               SABuiltinApplication, checkArguments(Ctrl BIName false ArgsOk)
            end

            %%
            %% type-assertions go here if no type error raised yet
            %%

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
                      body:  [hint(l:'Procedure' m:pn(PN))
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
                      body:  [hint(l:'Object' m:pn(PN))
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
               SAApplication, checkMessage(Ctrl Top Msg Meth object PN)
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
            skip
         end
      end

      meth checkDesignatorBuiltin($)
         {DetTests.det @designator}
         andthen {TypeTests.builtin {GetData @designator}}
      end
      meth checkDesignatorProcedure($)
         {DetTests.det @designator}
         andthen {TypeTests.procedure {GetData @designator}}
      end
      meth checkDesignatorObject($)
         {DetTests.det @designator}
         andthen {TypeTests.object {GetData @designator}}
      end
      meth applyEnvSubst(Ctrl Top)
         {@designator applyEnvSubst(Ctrl Top)}
         {ForAll @actualArgs
          proc {$ A}
             {A applyEnvSubst(Ctrl Top)}
          end}
      end

   end

   class SABoolCase
      meth sa(Ctrl Top)
\ifdef DEBUGSA
         {Show boolCase}
\endif
         skip
      end
      meth saDescend(Ctrl Top)
         % descend with global environment
         % will be saved and restored in clauses
         case {DetTests.det @arbiter}
            andthen {TypeTests.bool {GetData @arbiter}}
         then
            PN = {@arbiter getPrintName($)}
         in
            case
               {TypeTests.'true' {GetData @arbiter}}
            then
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   'boolean guard ' # pn(PN) # ' is always true')}

               {@alternative saDescend(Ctrl false)}
               {@consequent saDescendAndCommit(Ctrl Top)}

            else
               % {TypeTests.'false' {GetData @arbiter}}
               {Ctrl.rep
                warn(coord: {@arbiter getCoord($)}
                     kind:  SAGenWarn
                     msg:   'boolean guard ' # pn(PN) # ' is always false')}

               {@consequent saDescend(Ctrl false)}
               {@alternative saDescendAndCommit(Ctrl Top)}
            end

         elsecase
            {Not {DetTypeTests.bool @arbiter}}
         then
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'Non-boolean arbiter in boolean case statement')}

         else
            {@consequent
             saDescendWithValue(Ctrl false @arbiter
                                self.expansionOccs.'`true`')}

            {@alternative
             saDescendWithValue(Ctrl false @arbiter
                                self.expansionOccs.'`false`')}
         end
      end
      meth applyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
         {@arbiter applyEnvSubst(Ctrl Top)}
         {@consequent applyEnvSubst(Ctrl false)}
         {@alternative applyEnvSubst(Ctrl false)}
      end
   end

   class SABoolClause
      from SADefault
      meth sa(Ctrl Top)
         skip
      end
      meth saDescendWithValue(Ctrl Top Arbiter Val)
         ArbV = {Arbiter getVariable($)}
         % arbiter value unknown, hence also save arbiter value
         Env  = {GetGlobalEnv {Add ArbV @globalVars}}
      in
         case
            {TryUnifyTypes
             {OzTypes.new bool nil}
             {Arbiter getType($)}}
         then
            {Arbiter unifyVal(Ctrl false Val)}
         else
            PN  = {Arbiter getPrintName($)}
            Val = {GetPrintData Arbiter}
         in
            {Ctrl.rep
             error(coord: {@body.1 getCoord($)}
                   msg:   'Non-boolean arbiter in boolean case statement'
                   kind:  SATypeError
                   body:  [hint(l:'Name' m:pn(PN))
                           hint(l:'Value' m:oz(Val))])}
         end

         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth saDescend(Ctrl Top)
         % arbiter value known, hence no need to save arbiter value
         Env  = {GetGlobalEnv @globalVars}
      in
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth saDescendAndCommit(Ctrl Top)
         SAStatement, saBody(Ctrl Top @body)
      end
   end

   class SAPatternCase
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show patternCase(@clauses {Map @globalVars fun {$ V} {V getPrintName($)} end})}
\endif
         skip
      end
      meth saDescend(Ctrl Top)
         % descend with global environment
         % will be saved and restored in clauses
         {ForAll @clauses
          proc {$ C} {C saDescendWith(Ctrl false @arbiter)} end}
         {@alternative saDescendWith(Ctrl false @arbiter)}
      end
      meth applyEnvSubst(Ctrl Top)
         {@arbiter applyEnvSubst(Ctrl Top)}
         {ForAll @clauses
          proc {$ C} {C applyEnvSubst(Ctrl false)} end}
         {@alternative applyEnvSubst(Ctrl false)}
      end
   end

   class SAPatternClause
      meth sa(Ctrl Top)
% \ifdef DEBUGSA
         {Show patternClause(@body)}
% \endif
         {@pattern sa(Ctrl false)}
      end
      meth saDescendWith(Ctrl Top Arbiter)
         ArbV  = {Arbiter getVariable($)}
         Env   = {GetGlobalEnv {Add ArbV @globalVars}} % also save arbiter !!
      in
         {@pattern sa(Ctrl Top)}

         {Ctrl setErrorMsg('pattern never matches')}
         {Ctrl setUnifier(Arbiter @pattern)}

         {Arbiter unify(Ctrl false @pattern)}

         {Ctrl resetUnifier}
         {Ctrl resetErrorMsg}

         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth applyEnvSubst(Ctrl Top)
         {@pattern applyEnvSubst(Ctrl Top)}
      end
   end

   class SARecordPattern
      from SAConstructionOrPattern

      meth makePatternScheme(?VarScheme ?NameScheme)
         VLab NLab VArgs NArgs
      in
         % methods do not exist
         {@label makePatternScheme(@globalVars ?VLab ?NLab)}
         {@args makePatternScheme(@globalVars ?VArgs ?NArgs)}
      end
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

      meth sa(Ctrl Top)
\ifdef DEBUGSA
         {Show equationPattern}
\endif
         {@right sa(Ctrl Top)}                            % analyse right hand side
         {@left unify(Ctrl Top @right)}                   % l -> r
      end

      meth reachable(Vs $)
\ifdef LOOP
         {Show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
\endif
         {@right reachable({@left reachable(Vs $)} $)}
      end

      % unify: _ x Token U Construction U ValueNode

      meth unify(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyEP(RHS)}
\endif
         {@right unify(Ctrl Top RHS)}
      end

      meth applyEnvSubst(Ctrl Top)
         {@left applyEnvSubst(Ctrl Top)}
         {@right applyEnvSubst(Ctrl Top)}
      end
   end

   class SAAbstractElse
      from SADefault
   end

   class SAElseNode
      from SAAbstractElse
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'else'}
\endif
      end
      meth saDescend(Ctrl Top)
         Env = {GetGlobalEnv @globalVars}
      in
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth saDescendWithValue(Ctrl Top Arbiter Val)
         ArbV  = {Arbiter getVariable($)}
         Env   = {GetGlobalEnv {Add ArbV @globalVars}}
      in
         {Arbiter unifyVal(Ctrl Top Val)}
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth saDescendWith(Ctrl Top Arbiter)
         ArbV  = {Arbiter getVariable($)}
         Env   = {GetGlobalEnv {Add ArbV @globalVars}} % also save arbiter !!
      in
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth saDescendAndCommit(Ctrl Top)
         SAStatement, saBody(Ctrl Top @body)
      end
   end
   class SANoElse
      from SAAbstractElse
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show noElse}
\endif
      end
      meth saDescendWithValue(Ctrl Top Arbiter Val)
         skip
      end
      meth applyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
      end
      meth saDescendWith(Ctrl Top Arbiter)
         skip
      end
      meth saDescendAndCommit(Ctrl Top)
         skip
      end
   end

   class SAThreadNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show threadNode}
\endif
      end
      meth saDescend(Ctrl Top)
         Env = {GetGlobalEnv @globalVars}
      in
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
   end

   class SATryNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'try'}
\endif
      end
      meth saDescend(Ctrl Top)
         Env1 Env2
      in
         % check try clause
         Env1 = {GetGlobalEnv @globalVars}
         SAStatement, saBody(Ctrl false @tryBody)
         {InstallGlobalEnv Env1}

         % check catch clause

         % the main reason to copy the global environment
         % here a second time (and not reuse the first one) is
         % that during GetGlobalEnv the types of all reachable
         % variables are cloned (possible optimization: compute
         % reachable variables only once and _only_ clone types here)
         Env2 = {GetGlobalEnv @globalVars}
         SAStatement, saBody(Ctrl false @catchBody)
         {InstallGlobalEnv Env2}
      end
   end

   class SALockNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show lockNode}
\endif
      end
      meth saDescend(Ctrl Top)
         SAStatement, saBody(Ctrl false @body)
      end
      meth applyEnvSubst(Ctrl Top)
         {@lockVar applyEnvSubst(Ctrl Top)}
      end
   end

   class SAClassNode
      from SAAbstraction
      feat
         isComplex:false

      meth getDesignator($)
         @designator
      end
      meth saSimple(Ctrl Top)
         TestClass NrClass
         DummyClass = class $ end
      in
         value <- {New Core.classToken init(DummyClass)}

         isVirtualToplevel <- {Ctrl isVirtualToplevel($)}

\ifdef ANALYSEINHERITANCE

         {AllUpTo @parents
          DetTypeTests.'class' ?NrClass ?TestClass} % do type test, return exc

\ifdef DEBUG
         {Show classNode({@designator getPrintName($)}
                         {Map @parents fun {$ X} {X getPrintName($)} end})}
\endif
         case
            TestClass
         then
            PTs = {Map @parents fun {$ X} {X getValue($)} end}
            NoDet PsDet
         in
            {AllUpTo @parents DetTests.det ?NoDet ?PsDet}

            SAClassNode, inheritProperties(Ctrl PTs)
            SAClassNode, inheritAttributes(Ctrl PTs PsDet)
            SAClassNode, inheritFeatures(Ctrl PTs PsDet)
            SAClassNode, inheritMethods(Ctrl PTs PsDet)

\ifdef INHERITANCE
            case PsDet
            then skip else
               {Ctrl.rep
                warn(coord: @coord
                     kind:  SAGenWarn
                     msg:   'insufficient information in inheritance'
                     body:  [hint(l:'Parent'
                                  m:pn({{Nth @parents NoDet}
                                        getPrintName($)}))])}
            end
\endif

         else
            NoCls = {GetPrintData {Nth @parents NrClass}}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'inheriting from non-class ' # oz(NoCls))}
         end

\endif

         {@designator unify(Ctrl Top @value)}

\ifdef DEBUGSA
         {Show lookedAhead({@designator getPrintName($)} @value)}
\endif
      end

      meth inheritProperties(Ctrl PTs)
         NrAtom TestAtom
      in

\ifdef DEBUGSA
         {Show properties(@properties)}
\endif

         {AllUpTo @properties DetTypeTests.atom ?NrAtom ?TestAtom}

         % type test
         case TestAtom then
            % new determined properties
            Pro  = {Filter {Map @properties GetData}
                    TypeTests.atom}
            % properties of det parents
            PPro = {Filter {Map PTs fun {$ P}
                                       case {DetTests.det P}
                                       then {P getProperties($)}
                                       else unit end
                                    end}
                    fun {$ X} X\=unit end}
            TestFinal NrFinal
         in
            {SomeUpTo PPro
             fun {$ P} {Member final P} end ?NrFinal ?TestFinal}

            case TestFinal then
               Cls = {Nth @parents NrFinal}
            in
               {Ctrl.rep
                error(coord: @coord
                      kind:  SATypeError
                      msg:   'inheritance from final class '
                      # pn({Cls getPrintName($)}))}
            else
               % type & det test
               {@value setProperties({UnionAll Pro|PPro})}
            end
         else
            Prop = {Nth @properties NrAtom}
         in
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-atomic class property '
                   # pn({Prop getPrintName($)}))}

         end
      end
      meth inheritAttributes(Ctrl PTs PsDet)
         Att  = {Map @attributes FirstOrId}
      in
\ifdef DEBUGSA
         {Show attributes(Att)}
\endif

         % type test
         case
            {All Att DetTypeTests.feature}
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
                     {@value setAttributes({UnionAll AData|PAtt})}
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
                      body:  [hint(l:'Attributes found'
                                   m:{SetToVS {Ozify AData}})])}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'illegal class attribute specified')}
         end
      end
      meth inheritFeatures(Ctrl PTs PsDet)
         Fea = {Map @features FirstOrId}
      in
\ifdef DEBUGSA
         {Show features(Fea)}
\endif

         % type test
         case
            {All Fea DetTypeTests.feature}
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
                     {@value setFeatures({UnionAll FData|PFea})}
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
                      body:  [hint(l:'Features found'
                                   m:{SetToVS {Ozify FData}})])}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'illegal class feature specified')}
         end
      end
      meth inheritMethods(Ctrl PTs PsDet)
         Met  = {Map @methods fun {$ M} {M getPattern($)} end}
      in
\ifdef DEBUGSA
         {Show methods(PTs PMet Met)}
\endif
         % type test
         case
            {All Met
             fun {$ L#(R#O)}
                {DetTypeTests.literal L}
                andthen {All R DetTypeTests.feature}
                andthen (O==unit orelse {All O DetTypeTests.feature})
             end}
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
                     {@value setMethods(TotalMet)}
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
                      body:  [hint(l:'Method names'
                                   m:{SetToVS {Ozify MethNames}})])}
            end
         else
            {Ctrl.rep
             error(coord: @coord
                   kind:  SATypeError
                   msg:   'non-literal method labels or features specified')}
         end
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show classDef({@designator getPrintName($)} Top)}
\endif
      end
      meth saDescend(Ctrl Top)
         {Ctrl pushSelf(self)}

         % descend with global environment
         % will be saved in methods
         SAClassNode, SaBody(@methods Ctrl Top)

         {Ctrl popSelf}
      end
      meth SaBody(Methods Ctrl Top)
         case Methods of M|Mr then
            {M sa(Ctrl Top)}
            {M saDescend(Ctrl Top)}
            SAClassNode, SaBody(Mr Ctrl Top)
         [] nil then skip
         end
      end
      meth applyEnvSubst(Ctrl Top)

         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
         {@designator applyEnvSubst(Ctrl Top)}
         {ForAll @parents
          proc {$ P}
             {P applyEnvSubst(Ctrl Top)}
          end}
         {ForAll @properties
          proc {$ P} {P applyEnvSubst(Ctrl Top)} end}
         {ForAll @attributes
          proc {$ I}
             case I of F#T then
                {F applyEnvSubst(Ctrl Top)}
                {T applyEnvSubst(Ctrl Top)}
             else {I applyEnvSubst(Ctrl Top)} end
          end}
         {ForAll @features
          proc {$ I}
             case I of F#T then
                {F applyEnvSubst(Ctrl Top)}
                {T applyEnvSubst(Ctrl Top)}
             else {I applyEnvSubst(Ctrl Top)} end
          end}
         {ForAll @methods
          proc {$ M} {M preApplyEnvSubst(Ctrl Top)} end}
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
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show method}
\endif
      end
      meth saDescend(Ctrl Top)
         Env = {GetGlobalEnv @globalVars}
      in
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
      meth preApplyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
         {@label applyEnvSubst(Ctrl Top)}
         {ForAll @formalArgs
          proc {$ A} {A applyEnvSubst(Ctrl Top)} end}
      end
   end
   class SAMethodWithDesignator
      from SAMethod
      meth getPattern($)
         Fs R1 O1 R2 O2
      in
         Fs = {Map @formalArgs fun {$ M} {M getFormal($)} end}
         {Partition Fs fun {$ F} {Label F}==required end R1 O1}

         R2 = {Map R1 fun {$ R} R.1 end}
         O2 = case @isOpen then unit else {Map O1 fun {$ O} O.1 end} end

         @label # (R2 # O2)
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show methodWithDesignator}
\endif
      end
   end

   class SAMethFormal
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show methodFormal}
\endif
      end
      meth getFormal($)
         required(@feature)
      end
      meth applyEnvSubst(Ctrl Top)
         {@feature applyEnvSubst(Ctrl Top)}
      end
   end
   class SAMethFormalOptional
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show methodFormalOptional}
\endif
      end
      meth getFormal($)
         optional(@feature)
      end
      meth applyEnvSubst(Ctrl Top)
         {@feature applyEnvSubst(Ctrl Top)}
      end
   end
   class SAMethFormalWithDefault
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show methodFormalDefault}
\endif
      end
      meth getFormal($)
         optional(@feature)
      end
      meth applyEnvSubst(Ctrl Top)
         {@feature applyEnvSubst(Ctrl Top)}
      end
   end

   class SAObjectLockNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show objectLockNode}
\endif
      end
      meth saDescend(Ctrl Top)
         % descend with same environment
         SAStatement, saBody(Ctrl false @body)
      end
      meth applyEnvSubst(Ctrl Top)
         {Record.forAll self.expansionOccs
          proc {$ VO}
             case VO of undeclared then skip
             else {VO applyEnvSubst(Ctrl Top)} end
          end}
      end
   end

   class SAGetSelf
      meth sa(Ctrl Top)
\ifdef DEBUGSA
         {Show getSelf}
\endif
         {@destination setValue(@destination)}
      end
      meth applyEnvSubst(Ctrl Top)
         {@destination applyEnvSubst(Ctrl Top)}
      end
   end

   class SAFailNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'fail'}
\endif
      end
   end

   class SAIfNode
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'if'}
\endif
      end
      meth saDescend(Ctrl Top)
         % descend with global environment
         % will be saved and restored in clauses
         {ForAll @clauses
          proc {$ C} {C saDescend(Ctrl false)} end}
         {@alternative saDescend(Ctrl false)}
      end
      meth applyEnvSubst(Ctrl Top)
         {ForAll @clauses
          proc {$ C} {C applyEnvSubst(Ctrl false)} end}
         {@alternative applyEnvSubst(Ctrl false)}
      end
   end

   class SAChoicesAndDisjunctions
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show choices}
\endif
      end
      meth saDescend(Ctrl Top)
         % descend with global environment
         % will be saved and restored in clauses
         {ForAll @clauses
          proc {$ C} {C saDescend(Ctrl false)} end}
      end
      meth applyEnvSubst(Ctrl Top)
         {ForAll @clauses
          proc {$ C} {C applyEnvSubst(Ctrl false)} end}
      end
   end
   class SAOrNode
      from SAChoicesAndDisjunctions
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'or'}
\endif
      end
   end
   class SADisNode
      from SAChoicesAndDisjunctions
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'dis'}
\endif
      end
   end
   class SAChoiceNode
      from SAChoicesAndDisjunctions
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'choice'}
\endif
      end
   end

   class SAClause
      from SADefault
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show 'clause'}
\endif
      end
      meth saDescend(Ctrl Top)
         % shared local environment
         % for guard and body
         Env = {GetGlobalEnv @globalVars}
      in
         SAStatement, saBody(Ctrl false @guard)
         SAStatement, saBody(Ctrl false @body)
         {InstallGlobalEnv Env}
      end
   end

   class SAValueNode
      from SADefault
      attr type: unit
      meth init()
         type <- {OzValueToType @value}
      end
      meth getType($)
         @type
      end
   end

   class SAAtomNode
      meth getLastValue($)
         self
      end
      meth deref(VO)
         skip
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show atomNode(@value)}
\endif
      end

      meth reachable(Vs $)
         Vs
      end

      % unify: _ x Token U ValueNode

      meth unify(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyA(RHS)}
\endif
         case
            {Not {UnifyTypes self RHS Ctrl Top @coord}}
         then
            skip % do not continue on type error
         elsecase
            {TypeTests.token RHS}
         then
            {IssueUnificationFailure Ctrl Top @coord
             [line('atom = token')
              hint(l:'First value' m:oz(@value))
              hint(l:'Second value' m:oz({RHS getValue($)}))]}
         elsecase
            @value == {RHS getValue($)}
         then
            skip
         else
            {IssueUnificationFailure Ctrl Top @coord
             [hint(l:'First value' oz(@value))
              hint(l:'Second value' oz({RHS getValue($)}))]}
         end
      end

      meth makePatternScheme(GVs VL NL)
         VL = @value
         NL = @value
      end
   end

   class SAIntNode
      meth getLastValue($)
         self
      end
      meth deref(VO)
         skip
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show intNode(@value)}
\endif
      end

      meth reachable(Vs $)
         Vs
      end

      % unify: _ x Token U ValueNode

      meth unify(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyI(RHS)}
\endif

         case
            {Not {UnifyTypes self RHS Ctrl Top @coord}}
         then
            skip % do not continue on type error
         elsecase
            {TypeTests.token RHS}
         then
            {IssueUnificationFailure Ctrl Top @coord
             [line('integer = token')
              hint(l:'First value' m:oz(@value))
              hint(l:'Second value' m:oz({RHS getValue($)}))
             ]}
         elsecase
            @value == {RHS getValue($)}
         then
            skip
         else
            {IssueUnificationFailure Ctrl Top @coord
             [hint(l:'First value' m:oz(@value))
              hint(l:'Second value' m:oz({RHS getValue($)}))
             ]}
         end
      end

      meth makePatternScheme(GVs VL NL)
         VL = @value
         NL = @value
      end
   end

   class SAFloatNode
      meth getLastValue($)
         self
      end
      meth deref(VO)
         skip
      end
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show floatNode(@value)}
\endif
      end

      meth reachable(Vs $)
         Vs
      end

      % unify: _ x Token U ValueNode

      meth unify(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyF(RHS)}
\endif

         case
            {Not {UnifyTypes self RHS Ctrl Top @coord}}
         then
            skip % do not continue on type error
         elsecase
            {TypeTests.token RHS}
         then
            {IssueUnificationFailure Ctrl Top @coord
             [line('float = token')
              hint(l:'First value' m:oz(@value))
              hint(l:'Second value' m:oz({RHS getValue($)})) ]}
         elsecase
            @value == {RHS getValue($)}
         then
            skip
         else
            {IssueUnificationFailure Ctrl Top @coord
             [hint(l:'First value' m:oz(@value))
              hint(l:'Second value' m:oz({RHS getValue($)}))
             ]}
         end
      end

      meth makePatternScheme(GVs VL NL)
         VL = @value
         NL = @value
      end
   end

   class SAVariable
      attr
         lastValue : unit
         type: unit
      meth init()
         type <- {OzTypes.new value nil}
      end
      meth getType($)
         @type
      end
      meth setType(T)
         type <- T
      end
      meth outputDebugType($)
         {TypeToVS @type}
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
         {self ValToSubst(@printName nil Value)}
      end
      meth ValToSubst(PrintNameBase Seen Value)
         case
            {IsDet Value}
         then

\ifdef DEBUGSA
            {Show valToSubstInt(Value)}
\endif

            %--** procedures/class cannot have definition as value!!!

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
               setLastValue({New Core.nameToken init(@printName Value true)})

            elsecase
               {IsRecord Value}
            then
               RecArgs   = {Record.toListInd Value}
               Lab       = {Label Value}
               ConstrLab = {New Core.atomNode init(Lab unit)}
               ConstrArgs ConstrValArgs Constr
            in
               {self recordValToArgs(RecArgs
                                     (Value#self)|Seen PrintNameBase
                                     ?ConstrArgs
                                     ?ConstrValArgs)}

               Constr = {New Core.construction init(ConstrLab ConstrArgs true)}
               {Constr setValue({List.toRecord Lab ConstrValArgs})}
               {Constr makeType}

               SAVariable, setLastValue(Constr)

            elsecase
               {IsBuiltin Value}
            then
               BI      = {New Core.builtinToken init(Value)}
            in
               SAVariable, setLastValue(BI)

            elsecase
               {IsProcedure Value}
            then
               ProcToken = {New Core.procedureToken init(Value)}
            in
               ProcToken.abstractionTableID = Value
               SAVariable, setLastValue(ProcToken)

            elsecase
               {IsClass Value}
            then
               Cls = {New Core.classToken init(Value)}
               Meths = {Record.make m {Class.methodNames Value}}
            in
               {Record.forAll Meths fun {$} nil#unit end}
               {Cls setMethods(Meths)}
               SAVariable, setLastValue(Cls)

            elsecase
               {IsObject Value}
            then
               TheClass = {Class.get Value}
               Meths = {Record.make m {Class.methodNames TheClass}}
               Cls   = {New Core.classToken init(TheClass)}
            in
               {Record.forAll Meths fun {$} nil#unit end}
               {Cls setMethods(Meths)}
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
      meth recordValToArgs(RecArgs Seen PrintNameBase
                           ?ConstrArgs ?ConstrValArgs)

         case RecArgs
         of (F#X) | RAs
         then
            Assoc = {PLDotEQ X Seen}
            A = {New Core.atomNode init(F unit)}
            VO CAr CVAr
         in

            case
               Assoc == unit % not seen
            then
               PrintName = {String.toAtom {VS2S PrintNameBase#'.'#F}}
               V = {New Core.variable init(PrintName generated unit)}

            in
               {V ValToSubst(PrintName Seen X)}
               {V occ(unit ?VO)}
               {VO updateValue({V getLastValue($)})}
            else
               {Assoc occ(unit ?VO)}
               {VO updateValue({Assoc getLastValue($)})}
            end

            ConstrArgs = A#VO | CAr
            ConstrValArgs = F#VO | CVAr

            {self recordValToArgs(RAs Seen PrintNameBase CAr CVAr)}
         elseof
            nil
         then
            ConstrArgs = nil
            ConstrValArgs = nil
         end
      end
      meth reachable(Vs $)
\ifdef LOOP
         {Show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
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
      meth sa(Ctrl Top)
         skip
\ifdef DEBUGSA
         {Show varOccurrence({self getPrintName($)} @value)}
\endif
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

      meth updateValue(O)
\ifdef DEBUGSA
         {Show updating(O)}
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
               SAVariableOccurrence, updateValue(OLV)
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
               {Show notCopyingSame}
\endif
               {self setValue(O)}
            else
\ifdef DEBUGSA
               {Show copyingStruct({O getValue($)})}
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
      meth getType(T)
         {@variable getType(T)}
      end

      meth getPrintName($)
         {@variable getPrintName($)}
      end
      meth applyEnvSubst(Ctrl Top)
         L = SAVariableOccurrence, getLastValue($) % of @variable
      in
         SAVariableOccurrence, updateValue(L)
      end

      meth reachable(Vs $)
\ifdef LOOP
         {Show reachable({Map Vs fun {$ V} {V getPrintName($)} end})}
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

      meth unifyVal(Ctrl Top RHS)
\ifdef LOOP
         {Show unifyVO({self getPrintName($)} RHS)}
\endif
         LHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         case
            {Not {UnifyTypes self RHS Ctrl Top @coord}}
         then
            skip % do not continue on type error
         elsecase
            {LHS isVariableOccurrence($)}
         then
            SAVariableOccurrence, bind(Ctrl Top RHS)
         elsecase
            {LHS isConstruction($)}
         then
            {LHS unify(Ctrl Top RHS)}
         elsecase
            {TypeTests.token LHS}
         then
            case
               {TypeTests.token RHS}
            then
               % token = token

               case
                  {LHS getValue($)} == {RHS getValue($)}
               then
                  skip
               else
                  {IssueUnificationFailure Ctrl Top @coord
                   [line('incompatible tokens')
                    hint(l:'First value' m:oz({LHS getValue($)}))
                    hint(l:'Second value' m:oz({RHS getValue($)}))
                   ]}
               end
            else
               {RHS unify(Ctrl Top LHS)}
            end
         else
            % LHS is ValueNode
            {LHS unify(Ctrl Top RHS)}
         end
      end

      %% Bind: _ x VariableOccurrence U Token U Construction U ValueNode

      meth bind(Ctrl Top RHS)
\ifdef DEBUGSA
         {Show bind({self getPrintName($)} {self getType($)} {RHS getValue($)})}
\endif
         case
            {Not {UnifyTypes self RHS Ctrl Top @coord}}
         then
            skip % not continue on type error
         else
            % set new value for following occurrences
            {@variable setLastValue(RHS)}
         end
      end

      %% unify: _ x VariableOccurrence U Token U Construction U ValueNode

      meth unify(Ctrl Top TorC)
\ifdef LOOP
         case
            {TorC isVariableOccurrence($)}
         then
            {Show unifyV({self getPrintName($)} {TorC getPrintName($)})}
         else
            {Show unifyV({self getPrintName($)} TorC)}
         end
\endif

         LHS RHS
      in
         SAVariableOccurrence, getLastValue(LHS)

         case
            {Not {UnifyTypes LHS TorC Ctrl Top @coord}}
         then
            skip % do not continue on type error
         else
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

            SAVariableOccurrence, UnifyDeref(Ctrl Top LHS RHS)
         end
      end

      %% UnifyDeref: _ x VariableOccurrence U Token U Construction U ValueNode

      meth UnifyDeref(Ctrl Top LHS RHS)
\ifdef LOOP
         {Show unifyDR({self getPrintName($)} LHS RHS)}
\endif
         case
            LHS == RHS
         then
            skip                                % nothing to do
         else
            case
               {LHS isVariableOccurrence($)}
            then
               {LHS bind(Ctrl Top RHS)}
            elsecase
               {RHS isVariableOccurrence($)}
            then
               {RHS bind(Ctrl Top LHS)}
            elsecase
               {LHS isConstruction($)}
            then
               %--** here is some work on extension to ft unification
               case
                  {RHS isConstruction($)}
               then
                  {RHS bind(Ctrl Top LHS)}
               else
                  skip % and fail on unification
               end
               {LHS unify(Ctrl Top RHS)}
            elsecase
               {RHS isConstruction($)}
            then
               {RHS unify(Ctrl Top LHS)}
            elsecase
               {TypeTests.token LHS}
            then
               case
                  {TypeTests.token RHS}
               then
                  % both are tokens

                  case
                     {LHS getValue($)} == {RHS getValue($)}
                  then
                     skip
                  else
                     {IssueUnificationFailure Ctrl Top @coord
                      [line('incompatible tokens')
                       hint(l:'First value' m:oz({LHS getValue($)}))
                       hint(l:'Second value' m:oz({RHS getValue($)}))
                      ]}
                  end
               else
                  % RHS is ValueNode
                  {RHS unify(Ctrl Top LHS)}
               end
            else
               % LHS is ValueNode
               {LHS unify(Ctrl Top RHS)}
            end
         end
      end

      meth makePatternScheme(GVs VL NL)
         {Show makePatternSchemeVarOcc}
         case {@value isVariableOccurrence($)}
         then VL=_  NL=@variable
         else {@value makePatternScheme(GVs VL NL)}  % take care of recursion
         end
      end
   end

   class SAToken
      attr type: unit
      meth init()
         type <- {OzValueToType @value}
      end
      meth getType($)
         @type
      end
   end
in
   SA = sa(statement: SAStatement
           declaration: SADeclaration
           skipNode: SASkipNode
           equation: SAEquation
           construction: SAConstruction
           definition: SADefinition
           functionDefinition: SAFunctionDefinition
           clauseBody: SAClauseBody
           application: SAApplication
           boolCase: SABoolCase
           boolClause: SABoolClause
           patternCase: SAPatternCase
           patternClause: SAPatternClause
           recordPattern: SARecordPattern
           equationPattern: SAEquationPattern
           abstractElse: SAAbstractElse
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
           failNode: SAFailNode
           ifNode: SAIfNode
           choicesAndDisjunctions: SAChoicesAndDisjunctions
           orNode: SAOrNode
           disNode: SADisNode
           choiceNode: SAChoiceNode
           clause: SAClause
           valueNode: SAValueNode
           atomNode: SAAtomNode
           intNode: SAIntNode
           floatNode: SAFloatNode
           variable: SAVariable
           variableOccurrence: SAVariableOccurrence
           token: SAToken)
end
