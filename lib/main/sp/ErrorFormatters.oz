%%%
%%% Authors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Martin Henz <henz@iscs.nus.edu.sg>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Benjamin Lorenz <lorenz@ps.uni-sb.de>
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
   System(printName)

export
   kernel:  KernelFormatter
   object:  ObjectFormatter
   failure: FailureFormatter
   recordC: RecordCFormatter
   system:  SystemFormatter
   ap:      APFormatter
   dp:      DPFormatter
   os:      OSFormatter
   foreign: ForeignFormatter
   url:     URLFormatter
   module:  ModuleFormatter

prepare
   BugReport = 'Please send bug report to bugs@mozart-oz.org'

   fun {LayoutDot R F X Op}
      if {IsDet R}
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

   fun {LayoutComma C M}
      [hint(l:'In statement' m:'C, '#oz(M))
       hint(l:'Class value' m:oz(C))]
   end

   fun {LayoutBin X Y Z Op}
      [hint(l:'In statement' m:oz(X) # ' ' # Op # ' ' # oz(Y) # ' = ' # oz(Z))]
   end

   fun {IsNotNL X}
      X \= &\n
   end

   fun {ToLower Xs}
      {Map {VirtualString.toString Xs} Char.toLower}
   end

   local
      fun {DoFormatTypes Text S}
         case S of nil then nil
         else First Rest in
            {List.takeDropWhile S.2 IsNotNL First Rest}
            case Text of '' then
               hint(m:{ToLower First})
            else
               hint(l:Text m:{ToLower First})
            end|{DoFormatTypes '' Rest}
         end
      end
   in
      fun {FormatTypes T}
         {DoFormatTypes 'Expected type' &\n|{Atom.toString T}}
      end
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
         if S \= nil then
            unit|{DoFormatHint &\n|{VirtualString.toString S}}
         else nil
         end
      end
   end

   fun {Plural N}
      if N == 1 then '' else 's' end
   end

define

   %%
   %% kernel related errors
   %%

   fun {KernelFormatter E}
      case E
      of kernel(type A Xs T P S) then
         % expected A:procedure or atom, Xs: list, T: atom, P:int, S: virtualString
         LayOut = case A # Xs
                  of '.' # [R F X] then
                     Ls = {LayoutDot R F X '.'}
                  in
                     {Append Ls {FormatHint S}}
                  elseof '^' # [R F X] then
                     Ls = {LayoutDot R F X '^'}
                  in
                     {Append Ls {FormatHint S}}
                  elseof ',' # [C M] then
                     Ls = {LayoutComma C M}
                  in
                     {Append Ls {FormatHint S}}
                  elseof '+1' # [X Y] then
                     Ls =
                     [hint(l:'In statement' m:oz(X) # ' + 1 = ' # oz(Y))
                      hint(l:'Possible origin' m:'1 + ' # oz(X) # ' = ' # oz(Y))]
                  in
                     {Append Ls {FormatHint S}}
                  elseof fdTellConstraint # [X Y] then
                     Ls = [hint(l:'In statement' m:oz(X) # ' :: ' # oz(Y))]
                  in
                     {Append Ls {FormatHint S}}
                  else
                     if
                        {Member A ['+' '-' '*' '/' '<' '>' '=<' '>=' '\\=']}
                     then
                        Ls = case Xs of [X Y Z] then
                                {LayoutBin X Y Z A}
                             else
                                [hint(l:'In statement' m:apply(A Xs))]
                             end
                     in
                        {Append Ls {FormatHint S}}
                     else
                        Ls = [hint(l:'In statement' m:apply(A Xs))]
                     in
                        {Append Ls {FormatHint S}}
                     end
                  end
      in
         error(kind: 'type error'
               items: {Append
                       {FormatTypes T}
                       if P\=0 then
                          hint(l:'At argument' m:P) | LayOut
                       else LayOut end})

      elseof kernel(instantiation A Xs T P S) then
         %% expected A: procedure or atom, Xs: list, T: atom,
         %% P:int, S:virtualString
         LayOut = {Append
                   [hint(l:'In statement' m:apply(A Xs))]
                   {FormatHint S}}
      in
         error(kind: 'instantiation error'
               items: {Append
                       {FormatTypes T}
                       if P\=0 then
                          hint(l:'At argument' m:P) | LayOut
                       else LayOut end})

      elseof kernel(apply X Xs) then
         %% expected X: procedure or atom, Xs: list
         error(kind: 'error in application'
               msg: 'Application of non-procedure and non-object'
               items: [hint(l:'In statement' m:apply(X Xs))])

      elseof kernel('.' R F) then
         %% expected R: chunk or record, F: feature
         error(kind: 'Error: illegal field selection'
               items: {LayoutDot R F _ '.'})

      elseof kernel(recordConstruction L As) then
         %% expected L: literal, As: property list
         error(kind: 'Error: duplicate fields'
               msg: 'Duplicate fields in record construction'
               items: [hint(l:'Label' m:oz(L))
                       hint(l:'Feature-field Pairs' m:list(As ' '))])

      elseof kernel(recordPattern L As) then
         %% expected L: literal, As: feature list
         error(kind: 'Error: duplicate fields'
               msg: 'Duplicate fields in record pattern'
               items: [hint(l:'Label' m:oz(L))
                       hint(l:'Features' m:list(As ' '))])

      elseof kernel(arity P Xs) then
         %% expected P: procedure or object, Xs: list
         N = if {IsProcedure P} then {Procedure.arity P} else 1 end
         M = {Length Xs}
      in
         error(kind: 'Error: illegal number of arguments'
               items: [hint(l:'In statement' m:apply(P Xs))
                       hint(l:'Expected'
                            m: N # ' argument' # {Plural N})
                       hint(l:'Found'
                            m: M # ' argument' # {Plural M})])

      elseof kernel(noElse File Line) then
         error(kind: 'Error: conditional failed'
               msg: 'Missing else clause'
               items: [pos(File Line unit)])

      elseof kernel(noElse File Line A) then
         %% expected A: Oz term
         error(kind: 'Error: conditional failed'
               msg: 'Missing else clause'
               items: [hint(l:'Matching' m:oz(A))
                       pos(File Line unit)])

      elseof kernel(boolCaseType File Line A) then
         error(kind: 'Error: boolean conditional failed'
               msg: 'Non-boolean value found'
               items: [hint(l:'Value found' m:oz(A))
                       pos(File Line unit)])

         %%
         %% ARITHMETICS
         %%
      elseof kernel(div0 X) then
         error(kind: 'division by zero error'
               items: [hint(l:'In statement' m:oz(X) # ' div 0' # ' = _')])

      elseof kernel(mod0 X) then
         error(kind: 'division by zero error'
               items: [hint(l:'In statement' m:oz(X) # ' mod 0' # ' = _')])

         %%
         %% ARRAYS AND DICTIONARIES
         %%
      elseof kernel(dict D K) then
         %% expected D: dictionary, K: feature
         L={Dictionary.keys D}
      in
         error(kind: 'Error: Dictionary'
               msg: 'Key not found'
               items:
                  hint(l:'Dictionary' m:oz(D))
               |  hint(l:'Key found'  m:oz(K))
               |  hint(l:'Legal keys' m:oz(L))
               %% we cannot use Dictionary.member because, due to concurrence,
               %% the answer could be incoherent with the list returned by
               %% Dictionary.keys
               |  if {Member K L} then
                     [line('it looks like the key concurrently appeared in the')
                      line('dictionary after the exception was raised')]
                  else nil end)

      elseof kernel(array A I) then
         %% expected A: array, I: int
         error(kind: 'Error: Array'
               msg: 'Index out of range'
               items: [hint(l:'Array' m:oz(A))
                       hint(l:'Index Found' m:I)
                       hint(l:'Legal Range'
                            m:{Array.low A} # ' - ' # {Array.high A})])

      elseof kernel('BitArray.new' L H) then
         %% expected L: int, H: int
         error(kind: 'Error: BitArray'
               msg: 'Illegal boundaries to BitArray.new'
               items: [hint(l: 'Lower bound' m: L)
                       hint(l: 'Upper bound' m: H)])

      elseof kernel('BitArray.index' B I) then
         %% expected B: Bitarray, I: int
         error(kind: 'Error: BitArray'
               msg: 'Index out of range'
               items: [hint(l: 'Bit array' m: oz(B))
                       hint(l: 'Index found' m: I)
                       hint(l: 'Legal Range'
                            m: {BitArray.low B}#' - '#{BitArray.high B})])

      elseof kernel('BitArray.binop' B1 B2) then
         %% expected B1: BitArray, B2: BitArray

         error(kind: 'Error: BitArray'
               msg: 'Incompatible bounds in binary operation on BitArrays'
               items: [hint(l: 'First bit array' m: oz(B1))
                       hint(l: 'First bounds'
                            m: {BitArray.low B1}#' - '#{BitArray.high B1})
                       hint(l: 'Second bit array' m: oz(B2))
                       hint(l: 'Second bounds'
                            m: {BitArray.low B2}#' - '#{BitArray.high B2})])

         %%
         %% REPRESENTATION FAULT
         %%
      elseof kernel(stringNoFloat S) then
         %% expected S: string
         error(kind: 'Error: representation fault'
               msg: 'Conversion to float failed'
               items: [hint(l:'String' m:'\"' # S # '\"')])

      elseof kernel(stringNoInt S) then
         %% expected S: string
         error(kind: 'Error: representation fault'
               msg: 'Conversion to integer failed'
               items: [hint(l:'String' m:'\"' # S # '\"')])

      elseof kernel(stringNoAtom S) then
         %% expected S: string
         error(kind: 'Error: representation fault'
               msg: 'Conversion to atom failed'
               items: [hint(l:'String' m:'\"' # S # '\"')])

      elseof kernel(stringNoValue S) then
         %% expected S: string
         error(kind: 'Error: representation fault'
               msg: 'Conversion to Oz value failed'
               items: [hint(l:'String'  m:'\"' # S # '\"')])

      elseof kernel(globalState What) then
         %% expected What: atom
         Msg  = case What
                of     array  then 'Assignment to global array'
                elseof dict   then 'Assignment to global dictionary'
                elseof cell   then 'Assignment to global cell'
                elseof io     then 'Input/Output'
                elseof object then 'Assignment to global object'
                elseof 'lock' then 'Request of global lock'
                else What end
      in
         error(kind: 'Error: space hierarchy'
               msg: Msg # ' from local space')

      elseof kernel(spaceMerged S) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Space already merged'
               items: [hint(l:'Space' m:oz(S))])

      elseof kernel(spaceDistributor) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Space already contains distributable thread')

      elseof kernel(spaceAdmissible S) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Space is not admissible for current space'
               items: [hint(l:'Space' m:oz(S))])

      elseof kernel(spaceIllegalAlt S) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Illegal alternative selection'
               items: [hint(l:'Space' m:oz(S))])

      elseof kernel(spaceNoChoice S) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'No distributor left'
               items: [hint(l:'Space' m:oz(S))])

      elseof kernel(spaceAltOrder S) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Range of alternatives must be ordered'
               items: [hint(l:'Space' m:oz(S))])

      elseof kernel(spaceAltRange S R N) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg: 'Requested alternative(s) out of range'
               items: [hint(l:'Space' m:oz(S))
                       hint(l:'Requested alternative'  m:R)
                       hint(l:'Number of alternatives' m:N)])

      elseof kernel(spaceSituatedness Cs) then
         %% expected S: space
         error(kind: 'Error: Space'
               msg:  'Situatedness violation'
               items: [hint(l:'Culprits' m:oz(Cs))])

      elseof kernel(portClosed P) then
         %% expected P: port
         error(kind: 'Error: Port'
               msg: 'Port already closed'
               items: [hint(l:'Port' m:oz(P))])

      elseof kernel(terminate) then
         error(kind: 'Thread'
               msg: 'Thread terminated')

      elseof kernel(block X) then
         %% expected X: variable
         error(kind: 'Error: Thread'
               msg: 'Purely sequential thread blocked'
               items: [hint(l: 'Thread' m:oz({Thread.this}))
                       hint(l:'Variable' m:oz(X))])

      elseof kernel(weakDictionary WeakDict Key) then
         error(kind: 'Error: WeakDictionary'
               msg: 'Key not found'
               items: [hint(l: 'Dictionary' m: oz(WeakDict))
                       hint(l: 'Key' m: oz(Key))])

      else
         error(kind: 'Kernel'
               items: [line(oz(E))])

      end
   end

   %%
   %% objects
   %%

   local
      fun {FormatConf FCs}
         case FCs of nil then nil
         [] F#Cs|FCr then
            hint(m:(oz(F)#' defined by: '#
                    oz({Map Cs System.printName})))|{FormatConf FCr}
         end
      end
   in
      fun {ObjectFormatter E}
         T = 'Error: object system'
      in
         case E
         of object('<-' O A V) then
            error(kind: T
                  msg: 'Assignment to undefined attribute'
                  items: [hint(l:'In statement' m:oz(A) # ' <- ' # oz(V))
                          hint(l:'Expected one of'
                               m:oz({OoExtensions.getAttrNames O}))])
         elseof object('@' O A) then
            error(kind: T
                  msg: 'Access of undefined attribute'
                  items: [hint(l:'In statement' m:'_ = @' # oz(A))
                          hint(l:'Expected one of'
                               m:oz({OoExtensions.getAttrNames O}))])
         elseof object(ooExch O A V) then
            error(kind: T
                  msg: 'Exchange of undefined attribute'
                  items: [hint(l:'In statement'
                               m:'_ = ' # oz(A) # ' <- ' # oz(V))
                          hint(l:'Attribute' m:oz(A))
                          hint(l:'Expected one of'
                               m:oz({OoExtensions.getAttrNames O}))])
         elseof object(conflicts N 'meth':Ms 'attr':As 'feat':Fs) then
            MMs = case {FormatConf Ms} of nil then nil
                  [] M|Mr then {AdjoinAt M l 'Methods'}|Mr
                  end
            MAs = case {FormatConf As} of nil then nil
                  [] A|Ar then {AdjoinAt A l 'Attributes'}|Ar
                  end
            MFs = case {FormatConf Fs} of nil then nil
                  [] F|Fr then {AdjoinAt F l 'Features'}|Fr
                  end
         in
            error(kind: T
                  msg: 'Unresolved conflicts in class definition'
                  items: (hint(l:'Class definition' m:N)|
                          {Append MMs {Append MAs MFs}}))
         elseof object(lookup C R) then
            error(kind: T
                  msg: 'Undefined method'
                  items:
                     [hint(l:'Class'   m:oz(C))
                      hint(l:'Message' m:oz(R))
                      line('Method undefined and no otherwise method given')])
         elseof object(final CParent CChild) then
            error(kind: T
                  msg: 'Inheritance from final class'
                  items: [hint(l:'Final class used as parent' m:oz(CParent))
                          hint(l:'Class to be created' m:oz(CChild))
                          line('remove prop final from parent class '#
                               'or change inheritance relation')])
         elseof object(inheritanceFromNonClass CParent CChild) then
            error(kind: T
                  msg: 'Inheritance from non-class'
                  items: [hint(l:'Non-class used as parent' m:oz(CParent))
                          hint(l:'Class to be created' m:oz(CChild))])
         elseof object(illegalProp Ps) then
            error(kind: T
                  msg: 'Illegal property value in class definition'
                  items: [hint(l:'Illegal values' m:oz(Ps))
                          hint(l:'Expected one of'
                               m:oz([final locking sited]))])
         elseof object(arityMismatch File Line M O) then
            error(kind: T
                  msg: 'Arity mismatch in object or method application'
                  items: [hint(l:'Message' m:oz(M))
                          hint(l:'Object' m:oz(O))
                          pos(File Line unit)])
         elseof object(slaveNotFree) then
            error(kind: T
                  msg: 'Method becomeSlave'
                  items: [hint(l:'Slave is not free')])
         elseof object(slaveAlreadyFree) then
            error(kind: T
                  msg: 'Method free'
                  items: [hint(l:'Slave is already free')])
         elseof object(locking O) then
            error(kind: T
                  msg: 'Attempt to lock unlockable object'
                  items: [hint(l:'Object' m:oz(O))])
         elseof object(nonLiteralMethod L) then
            error(kind: T
                  msg: 'Method label is not a literal'
                  items: [hint(l:'Method' m:oz(L))])
         else
            error(kind: T
                  items: [line(oz(E))])
         end
      end
   end

   %%
   %% failure
   %%

   fun {FailureFormatter E}
      error(kind: 'failure')
   end

   %%
   %% record constraints
   %%

   fun {RecordCFormatter E}
      T = 'Error: records'
   in
      case E
      of record(width A Xs P S) then
         %% expected Xs: list, P: int, S: virtualString
         error(kind: T
               items: (hint(l:'At argument' m:P)|
                       hint(l:'Statement' m:apply(A Xs))|
                       {FormatHint S}))
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% system programming
   %%

   fun {SystemFormatter E}
      T = 'system error'
   in
      case E
      of system(limitInternal S) then
         %% expected S: virtualString
         error(kind: T
               items: [hint(l:'Internal System Limit' m:S)])

      elseof system(limitExternal S) then
         %% expected S: virtualString
         error(kind: T
               items: [hint(l:'External system limit' m:S)])

      elseof system(fallbackInstalledTwice A) then
         %% expected A: atom
         error(kind: T
               items: [hint(l:'Fallback procedure installed twice' m:A)])

      elseof system(fallbackNotInstalled A) then
         %% expected A: atom
         error(kind: T
               items: [hint(l:'Fallback procedure not installed' m:A)])

      elseof system(inconsistentFastcall) then
         error(kind: T
               msg: 'Internal inconsistency'
               items: [line('Inconsistency in optimized application')
                       line('Maybe due to previous toplevel failure')])

      elseof system(onceOnlyFunctor) then
         error(kind: T
               msg: ('Procedure definition with flag `once\' '#
                     'executed more than once'))

      elseof system(fatal S) then
         %% expected S: virtualString
         error(kind: T
               msg: 'Fatal exception'
               itms: [line(S)
                      line(BugReport)])

      elseof system(getProperty Feature) then
         error(kind: T
               msg: 'Undefined property or property not readable'
               items: [hint(l:'Property' m:Feature)])

      elseof system(condGetProperty Feature) then
         error(kind: T
               msg: 'Property not readable'
               items: [hint(l:'Property' m:Feature)])

      elseof system(putProperty Feature) then
         error(kind: T
               msg: 'Property not writable'
               items: [hint(l:'Property' m:Feature)])

      elseof system(putProperty Feature Type) then
         error(kind: T
               msg: 'Type error in property record'
               items: [hint(l:'Record feature' m:Feature)
                       hint(l:'Expected type' m:Type)])

      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% OS module
   %%

   fun {OSFormatter E}
      T = 'error in OS module'
   in
      case E
      of os(os SysCall N S) then
         %% expected SysCall: virtualString, N: int, S: virtualString
         error(kind: T
               msg: 'Operating system error'
               items: [hint(l:'System call' m:SysCall)
                       hint(l:'Error number' m:N)
                       hint(l:'Description' m:S)])
      elseof os(host SysCall N S) then
         %% expected SysCall: virtualString, N: int, S: virtualString
         error(kind: T
               msg: 'Network Error'
               items: [hint(l:'System call' m:SysCall)
                       hint(l:'Error number' m:N)
                       hint(l:'Description' m:S)])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% application programming
   %%

   fun {APFormatter E}
      T = 'Error: application programming'
   in
      case E
      of ap(usage Msg) then
         error(kind: T
               msg: Msg)
      elseof ap(spec env Var) then
         error(kind: T
               msg: 'environment variable '#Var#' not set'
               items: [hint(l: 'Hint'
                            m: ('Have you started a CGI script '#
                                'from the command line?'))])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% distributed programming
   %%

   fun {DPFormatter E}
      T = 'Error: distributed programming'
   in
      case E
      of dp(generic _ Msg Hints) then
         error(kind: T
               msg: Msg
               items: {Map Hints fun {$ L#M} hint(l:L m:oz(M)) end})
      elseof dp(modelChoose) then
         error(kind: T
               msg: ('Cannot change distribution model: '#
                     'distribution layer already started'))
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% Foreign interface
   %%

   fun {ForeignFormatter E}
      T = 'Error: native code interface'
   in
      case E
      of foreign(cannotFindInterface F) then
         error(kind: T
               msg: 'Cannot find interface'
               items: [hint(l:'File name' m:F)])
      elseof foreign(dlOpen F M) then
         error(kind: T
               msg: 'Cannot dynamically link object file'
               items: [hint(l:'File name' m:F)
                       hint(l:'dlerror'   m:M)])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% URL/Resolver library
   %%

   fun {URLFormatter E}
      T = 'error in URL support'
   in
      case E
      of url(O U) then
         error(kind: T
               msg: 'Cannot locate file'
               items: [hint(l:'File name' m:U)
                       hint(l:'Operation' m:O)])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end

   %%
   %% module manager
   %%

   fun {ModuleFormatter E}
      T = 'Error: module manager'
   in
      case E
      of module(alreadyInstalled Url) then
         error(kind: T
               msg: 'Module already installed'
               items: [hint(l:'Module URL' m:Url)])
      [] module(notFound Kind Url) then K in
         K = case Kind
             of system   then 'Unknown system module'
             [] native   then 'Could not load native functor at URL'
             [] load     then 'Could not load functor at URL'
             [] localize then 'Could not load functor at URL'
             end
         error(kind: T
               msg: 'Could not link module'
               items: [hint(l:K m:Url)])
      [] module(urlSyntax Url) then
         error(kind: T
               msg: 'Illegal URL syntax'
               items: [hint(l:'URL' m:Url)])
      [] module(typeMismatch Url _ _) then
         error(kind: T
               msg: 'Type mismatch'
               items: [hint(l:'URL' m:Url)])
      else
         error(kind: T
               items: [line(oz(E))])
      end
   end
end
