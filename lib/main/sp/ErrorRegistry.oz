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

   BugReport = 'Please send bug report to oz@ps.uni-sb.de'

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

in

   functor

   import
      Error(formatGeneric
            formatAppl
            formatTypes
            formatHint
            format
            dispatch
            info)

   export
      put:     NewFormatter
      get:     GetFormatter
      exists:  ExFormatter

   define

      %%
      %% kernel related errors
      %%

      fun {KernelFormatter Exc}

         E = {Error.dispatch Exc}

      in

         case E
         of kernel(type A Xs T P S)
         % expected A:procedure or atom, Xs: list, T: atom, P:int, S: virtualString
         then
            LayOut = case A # Xs
                     of '.' # [R F X] then
                        Ls = {LayoutDot R F X '.'}
                     in
                        {Append Ls {Error.formatHint S}}

                     elseof '^' # [R F X] then
                        Ls = {LayoutDot R F X '^'}
                     in
                        {Append Ls {Error.formatHint S}}

                     elseof ',' # [C M] then
                        Ls = {LayoutComma C M}
                     in
                        {Append Ls {Error.formatHint S}}

                     elseof '+1' # [X Y] then
                        Ls =
                        [hint(l:'In statement' m:oz(X) # ' + 1 = ' # oz(Y))
                         hint(l:'Possible origin' m:'1 + ' # oz(X) # ' = ' # oz(Y))]
                     in
                        {Append Ls {Error.formatHint S}}

                     elseof fdTellConstraint # [X Y] then
                        Ls = [hint(l:'In statement' m:oz(X) # ' :: ' # oz(Y))]
                     in
                        {Append Ls {Error.formatHint S}}

                     else
                        if
                           {Member A ['+' '-' '*' '/' '<' '>' '=<' '>=' '\\=']}
                        then
                           Ls = case Xs of [X Y Z] then
                                   {LayoutBin X Y Z A}
                                else
                                   [hint(l:'In statement' m:{Error.formatAppl A Xs})]
                                end
                        in
                           {Append Ls {Error.formatHint S}}

                        else
                           Ls = [hint(l:'In statement' m:{Error.formatAppl A Xs})]
                        in
                           {Append Ls {Error.formatHint S}}
                        end
                     end

         in

            {Error.format
             'type error'
             unit
             {Append
              {Error.formatTypes T}
              if P\=0 then
                 hint(l:'At argument' m:P) | LayOut
              else LayOut end}
             Exc}

         elseof kernel(instantiation A Xs T P S) then

         % expected A: procedure or atom, Xs: list, T: atom, P:int, S:virtualString

            LayOut = {Append
                      [hint(l:'In statement' m:{Error.formatAppl A Xs})]
                      {Error.formatHint S}}
         in
            {Error.format
             'instantiation error'
             unit
             {Append
              {Error.formatTypes T}
              if P\=0 then
                 hint(l:'At argument' m:P) | LayOut
              else LayOut end}
             Exc}

         elseof kernel(apply X Xs) then

         % expected X: procedure or atom, Xs: list

            {Error.format
             'error in application'
             'Application of non-procedure and non-object'
             [hint(l:'In statement' m:{Error.formatAppl X Xs})]
             Exc}

         elseof kernel('.' R F) then

         % expected R: chunk or record, F: feature

            {Error.format
             'Error: illegal field selection'
             unit
             {LayoutDot R F _ '.'}
             Exc}

         elseof kernel(recordConstruction L As) then

         % expected L: literal, As: property list

            {Error.format
             'Error: duplicate fields'
             'Duplicate fields in record construction'
             [hint(l:'Label' m:oz(L))
              hint(l:'Feature-field Pairs' m:list(As ' '))]
             Exc}

         elseof kernel(recordPattern L As) then

         % expected L: literal, As: feature list

            {Error.format
             'Error: duplicate fields'
             'Duplicate fields in record pattern'
             [hint(l:'Label' m:oz(L))
              hint(l:'Features' m:list(As ' '))]
             Exc}

         elseof kernel(arity P Xs) then

         % expected P: procedure or object, Xs: list

            local
               N = if {IsProcedure P} then {Procedure.arity P} else 1 end
               M = {Length Xs}
            in
               {Error.format
                'Error: illegal number of arguments'
                unit
                [hint(l:'In statement' m:{Error.formatAppl P Xs})
                 hint(l:'Expected'
                      m: N # ' argument' # if N == 1 then '' else 's' end)
                 hint(l:'Found'
                      m: M # ' argument' # if M == 1 then '' else 's' end)]
                Exc}
            end

         elseof kernel(noElse File Line) then

            {Error.format
             'Error: conditional failed'
             'Missing else clause'
             [pos(File Line unit)]
             Exc}

         elseof kernel(noElse File Line A) then

         % expected A: Oz term

            {Error.format
             'Error: conditional failed'
             'Missing else clause'
             [hint(l:'Matching' m:oz(A))
              pos(File Line unit)]
             Exc}

         elseof kernel(boolCaseType File Line) then

            {Error.format
             'Error: boolean conditional failed'
             'Non-boolean value found'
             [pos(File Line unit)]
             Exc}

            %%
            %% ARITHMETICS
            %%

         elseof kernel(div0 X) then

            {Error.format
             'division by zero error'
             unit
             [hint(l:'In statement' m:oz(X) # ' div 0' # ' = _')]
             Exc}

         elseof kernel(mod0 X) then

            {Error.format
             'division by zero error'
             unit
             [hint(l:'In statement' m:oz(X) # ' mod 0' # ' = _')]
             Exc}

            %%
            %% ARRAYS AND DICTIONARIES
            %%

         elseof kernel(dict D K) then

         % expected D: dictionary, K: feature

            Ks = {Dictionary.keys D}
         in
            {Error.format
             'Error: Dictionary'
             'Key not found'
             [hint(l:'Dictionary' m:oz(D))
              hint(l:'Key found'  m:oz(K))
              hint(l:'Legal keys' m:oz(Ks))]
             Exc}

         elseof kernel(array A I) then

         % expected A: array, I: int

            {Error.format
             'Error: Array'
             'Index out of range'
             [hint(l:'Array' m:oz(A))
              hint(l:'Index Found' m:I)
              hint(l:'Legal Range' m:{Array.low A} # ' - ' # {Array.high A})]
             Exc}

         elseof kernel('BitArray.new' L H) then

         % expected L: int, H: int

            {Error.format
             'Error: BitArray'
             'Illegal boundaries to BitArray.new'
             [hint(l: 'Lower bound' m: L)
              hint(l: 'Upper bound' m: H)]
             Exc}

         elseof kernel('BitArray.index' B I) then

         % expected B: Bitarray, I: int

            {Error.format
             'Error: BitArray'
             'Index out of range'
             [hint(l: 'Bit array' m: oz(B))
              hint(l: 'Index found' m: I)
              hint(l: 'Legal Range'
                   m: {BitArray.low B}#' - '#{BitArray.high B})]
             Exc}

         elseof kernel('BitArray.binop' B1 B2) then

         % expected B1: BitArray, B2: BitArray

            {Error.format
             'Error: BitArray'
             'Incompatible bounds in binary operation on BitArrays'
             [hint(l: 'First bit array' m: oz(B1))
              hint(l: 'First bounds'
                   m: {BitArray.low B1}#' - '#{BitArray.high B1})
              hint(l: 'Second bit array' m: oz(B2))
              hint(l: 'Second bounds'
                   m: {BitArray.low B2}#' - '#{BitArray.high B2})]
             Exc}

            %%
            %% REPRESENTATION FAULT
            %%

         elseof kernel(stringNoFloat S) then

         % expected S: string

            {Error.format
             'Error: representation fault'
             'Conversion to float failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoInt S) then

         % expected S: string

            {Error.format
             'Error: representation fault'
             'Conversion to integer failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoAtom S) then

         % expected S: string

            {Error.format
             'Error: representation fault'
             'Conversion to atom failed'
             [hint(l:'String' m:'\"' # S # '\"')]
             Exc}

         elseof kernel(stringNoValue S) then

         % expected S: string

            {Error.format
             'Error: representation fault'
             'Conversion to Oz value failed'
             [hint(l:'String'  m:'\"' # S # '\"')]
             Exc}

         elseof kernel(globalState What) then

         % expected What: atom

            Msg  = case What
                   of     array  then 'Assignment to global array'
                   elseof dict   then 'Assignment to global dictionary'
                   elseof cell   then 'Assignment to global cell'
                   elseof io     then 'Input/Output'
                   elseof object then 'Assignment to global object'
                   elseof 'lock' then 'Request of global lock'
                   else What end
         in
            {Error.format
             'Error: space hierarchy'
             Msg # ' from local space'
             nil
             Exc}

         elseof kernel(spaceMerged S) then

         % expected S: space

            {Error.format
             'Error: Space'
             'Space already merged'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceSuper S) then

         % expected S: space

            {Error.format
             'Error: Space'
             'Merge of superordinated space'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceParent S) then

         % expected S: space

            {Error.format
             'Error: Space'
             'Current space must be parent space'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(spaceNoChoice S) then

         % expected S: space

            {Error.format
             'Error: Space'
             'No choices left'
             [hint(l:'Space' m:oz(S))]
             Exc}

         elseof kernel(portClosed P) then

         % expected P: port

            {Error.format
             'Error: Port'
             'Port already closed'
             [hint(l:'Port' m:oz(P))]
             Exc}

         elseof kernel(terminate) then

            none

         elseof kernel(block T) then

         % expected T: thread

            {Error.format
             'Error: Thread'
             'Purely sequential thread blocked'
             [hint(l:'Thread' m:oz(T))]
             Exc}

         else
            {Error.formatGeneric 'Kernel' Exc}
         end
      end

      %%
      %% objects
      %%

      fun {ObjectFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'error in object system'
      in

         case E
         of object('<-' State A V) then
            {Error.format
             T unit
             [hint(l:'In statement' m:oz(A) # ' <- ' # oz(V))
              hint(l:'Attribute does not exist' m:oz(A))
              hint(l:'Expected Attribute(s)' m:list({Arity State} ' '))]
             Exc}

         elseof object('@' State A) then
            {Error.format
             T unit
             [hint(l:'In statement' m:'@' # oz(A) # ' = _')
              hint(l:'Attribute does not exist' m:oz(A))
              hint(l:'Expected attribute(s)' m:list({Arity State} ' '))]
             Exc}
         elseof object(sharing C1 C2 A L) then
            {Error.format T
             'Classes not ordered by inheritance'
             [hint(l:'Classes' m:C1 # ' and ' # C2)
              hint(l:'Shared ' # A m:oz(L) # ' (is not redefined)')]
             Exc}
         elseof object(order (A#B)|Xr) then
            fun {Rel A B} A # ' < ' # B end
         in
            {Error.format T
             'Classes cannot be ordered'
             hint(l:'Relation found' m:{Rel A B})
             | {Map Xr fun {$ A#B} hint(m:{Rel A B}) end}
             Exc}
         elseof object(lookup C R) then
            L1 = hint(l:'Class'   m:oz(C))
            L2 = hint(l:'Message' m:oz(R))
            H  = {Error.formatHint 'Method undefined and no otherwise method given'}
         in
            {Error.format T
             'Method lookup in message sending'
             L1|L2|H
             Exc}
         elseof object(final CParent CChild) then
            L2 = hint(l:'Final class used as parent' m:CParent)
            L3 = hint(l:'Class to be created' m:CChild)
            H  = {Error.formatHint 'remove prop final from parent class or change inheritance relation'}
         in
            {Error.format T
             'Inheritance from final class'
             L2|L3|H
             Exc}
         elseof object(inheritanceFromNonClass
                       CParent CChild) then
            {Error.format T
             'Inheritance from non-class'
             [hint(l:'Non-class used as parent' m:oz(CParent))
              hint(l:'Class to be created' m:CChild)]
             Exc}

         elseof object(arityMismatchDefaultMethod L)
         then
            {Error.format T
             'Arity mismatch for method with defaults'
             [hint(l:'Unexpected feature' m:oz(L))]
             Exc}

         elseof object(slaveNotFree)
         then

            {Error.format T
             'Method becomeSlave'
             [hint(l:'Slave is not free')]
             Exc}

         elseof object(slaveAlreadyFree) then

            {Error.format T
             'Method free'
             [hint(l:'Slave is already free')]
             Exc}

         elseof object(locking O) then
            {Error.format T
             'Attempt to lock unlockable object'
             [hint(l:'Object' m:oz(O))]
             Exc}

         elseof object(fromFinalClass C O) then
            {Error.format T 'Final class not allowed'
             [hint(l:'Final class' m:C)
              hint(l:'Operation'   m:O)]
             Exc}

         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% failure
      %%

      fun {FailureFormatter Exc}
         I = {Error.info Exc}
         T = 'failure'
      in

         case I
         of unit then

            {Error.formatGeneric T Exc}

         elseof 'fail' then

            {Error.format
             T
             unit
             [hint(l:'Tell' m:'fail')]
             Exc}

         elseof apply(A Xs) then

         % expected A: atom, Xs: list

            {Error.format
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
                [hint(l:'In statement' m:{Error.formatAppl A Xs})]
             end
             Exc}

         elseof eq(X Y) then

            {Error.format
             T unit
             [hint(l:'Tell' m:oz(X) # ' = ' # oz(Y))]
             Exc}

         elseof tell(X Y) then

            {Error.format
             T unit
             [hint(l:'Tell' m:oz(X) # ' = ' # oz(Y))
              hint(l:'Store' m:oz(X))]
             Exc}

         else

            {Error.format
             T unit
             [hint(l:'??? ' m:oz(I))]
             Exc}
         end
      end

      %%
      %% record constraints
      %%

      fun {RecordCFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'Error: records'
      in
         case E
         of record(width A Xs P S) then

         % expected Xs: list, P: int, S: virtualString

            {Error.format
             T unit
             hint(l:'At argument' m:P)
             | hint(l:'Statement' m:{Error.formatAppl A Xs})
             | {Error.formatHint S}
             Exc}

         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% system
      %%

      fun {SystemFormatter Exc}

         E = {Error.dispatch Exc}
         T = 'system error'
      in

         case E
         of system(limitInternal S) then

         % expected S: virtualString

            {Error.format T
             unit
             [hint(l:'Internal System Limit' m:S)]
             Exc}

         elseof system(limitExternal S) then

         % expected S: virtualString

            {Error.format T
             unit
             [hint(l:'External system limit' m:S)]
             Exc}

         elseof system(fallbackInstalledTwice A) then

         % expected A: atom

            {Error.format
             T unit
             [hint(l:'Fallback procedure installed twice' m:A)]
             Exc}

         elseof system(fallbackNotInstalled A) then

         % expected A: atom

            {Error.format
             T unit
             [hint(l:'Fallback procedure not installed' m:A)]
             Exc}

         elseof system(inconsistentFastcall) then

            {Error.format T
             'Internal inconsistency'
             [hint(l:'Inconsistency in optimized application')
              hint(l:'Maybe due to previous toplevel failure')]
             Exc}

         elseof system(onceOnlyFunctor) then

            {Error.format T
             'Procedure definition with flag `once\' executed more than once'
             nil
             Exc}

         elseof system(fatal S) then

         % expected S: virtualString

            {Error.format
             T
             'Fatal exception'
             [line(S)
              line(BugReport)]
             Exc}

         elseof system(getProperty Feature) then

            {Error.format
             T
             'Undefined property or property not readable'
             [hint(l:'Property' m:Feature)]
             Exc}

         elseof system(condGetProperty Feature) then

            {Error.format
             T
             'Property not readable'
             [hint(l:'Property' m:Feature)]
             Exc}

         elseof system(putProperty Feature) then

            {Error.format
             T
             'Property not writable'
             [hint(l:'Property' m:Feature)]
             Exc}

         elseof system(putProperty Feature Type) then

            {Error.format
             T
             'Type error in property record'
             [hint(l:'Record feature' m:Feature)
              hint(l:'Expected type' m:Type)]
             Exc}

         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% open programming
      %%

      fun {OSFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'error in OS module'
      in
         case E
         of os(K SysCall N S) then

         % expected K: atom, SysCall: virtualString, N: int, S: virtualString

            case K
            of os then
               {Error.format T
                'Operating system error'
                [
                 hint(l:'System call' m:SysCall)
                 hint(l:'Error number' m:N)
                 hint(l:'Description' m:S)]
                Exc}
            [] host then
               {Error.format T
                'Network Error'
                [
                 hint(l:'System call' m:SysCall)
                 hint(l:'Error number' m:N)
                 hint(l:'Description' m:S)]
                Exc}
            else
               {Error.formatGeneric T Exc}
            end
         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% application programming
      %%

      fun {APFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'Error: application programming'
      in
         case E
         of ap(usage Msg) then
            {Error.format T
             Msg
             nil
             Exc}
         else
            {Error.formatGeneric T Exc}
         end
      end


      %%
      %% Register dp formatter
      %%

      fun {DpFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'Error: distributed programming'
      in
         case E
         of dp(generic Id Msg Hints) then
            {Error.format
             Msg
             unit
             {Map Hints fun {$ L#M} hint(l:L  m:oz(M)) end}
             Exc}
         elseof dp(modelChoose) then
            {Error.format
             'Cannot change distribution model: distribution layer already started'
             unit
             nil
             Exc}
         elseof dp(connection(wrongModel V)) then
            {Error.format
             'Ticket presupposes wrong distribution model'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         elseof dp(connection(illegalTicket V)) then
            {Error.format
             'Illegal ticket for connection'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         elseof dp(connection(refusedTicket V)) then
            {Error.format
             'Ticket refused for connection'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         elseof dp(connection(ticketToDeadSite V)) then
            {Error.format
             'Ticket refused: refers to dead site'
             unit
             [hint(l:'Ticket' m:V)]
             Exc}
         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% Foreign interface
      %%

      fun {ForeignFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'Error: native code interface'
      in
         case E
         of foreign(cannotFindInterface F) then
            {Error.format T
             'Cannot find interface'
             [hint(l:'File name' m:F)]
             Exc}
         elseof foreign(dlOpen F M) then
            {Error.format T
             'Cannot dynamically link object file'
             [hint(l:'File name' m:F)
              hint(l:'dlerror'   m:M)]
             Exc}
         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% URL/Resolver library
      %%

      fun {URLFormatter Exc}
         E = {Error.dispatch Exc}
         T = 'error in URL support'
      in
         case E
         of url(O U) then
            {Error.format T
             'Cannot locate file'
             [hint(l:'File name' m:U)
              hint(l:'Operation' m:O)]
             Exc}
         else
            {Error.formatGeneric T Exc}
         end
      end

      %%
      %% Error registry proper
      %%

      ErrorFormatter = {NewDictionary}

      proc {NewFormatter Key P}
         {Dictionary.put
          ErrorFormatter
          Key
          P}
      end

      fun {GetFormatter Key}
         {Dictionary.get
          ErrorFormatter
          Key}
      end

      fun {ExFormatter Key}
         {Dictionary.member ErrorFormatter Key}
      end

      {NewFormatter kernel  KernelFormatter}
      {NewFormatter object  ObjectFormatter}
      {NewFormatter failure FailureFormatter}
      {NewFormatter recordC RecordCFormatter}
      {NewFormatter system  SystemFormatter}
      {NewFormatter ap      APFormatter}
      {NewFormatter dp      DpFormatter}
      {NewFormatter os      OSFormatter}
      {NewFormatter foreign ForeignFormatter}
      {NewFormatter url     URLFormatter}

   in skip end

end
