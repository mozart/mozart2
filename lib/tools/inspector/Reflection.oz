%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 2001
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $
import
   System(eq onToplevel printName)
   BrowserSupport(getsBoundB varSpace) at 'x-oz://boot/Browser'
   Name(newUnique newNamed) at 'x-oz://boot/Name'
   CompilerSupport(isBuiltin nameVariable)
   at 'x-oz://boot/CompilerSupport'
   FD
   FS
   RecordC
export
   'reflect'   : ReflectValue
   'unreflect' : UnreflectValue
   'manager'   : Manager
define
   %% Identify Reflection Constructs
   Wrapper = {Name.newUnique 'generic.reflected.value'}

   %%
   %% (Un-)Reflection Helpers
   %%
   local
      TopSpace
   in
      fun {IsTop X}
         {BrowserSupport.varSpace TopSpace} == {BrowserSupport.varSpace X}
      end
   end

   fun {IsAtomic X}
      case X
      of det(int)   then true
      [] det(float) then true
      [] det(atom)  then true
      else false
      end
   end

   fun {IsMember X Rs}
      case Rs
      of (OX#RX)|Rr then
         if {System.eq X OX} then yes(RX) else {IsMember X Rr} end
      [] nil then no
      end
   end

   %%
   %% Id Generator Service
   %%
   local
      Stream Prt
   in
      Prt = {Port.new Stream}
      thread {ForAll Stream proc {$ name#Id} Id = {NewName} end} end
      proc {MakeId Id}
         {Port.sendRecv Prt name Id}
      end
   end

   %%
   %% Variable Watching
   %%
   local
      proc {WaitTouched X}
         if {IsDet X}
         then skip
         else {Wait {BrowserSupport.getsBoundB X}}
         end
      end
   in
      proc {WatchVar Id X}
         {WaitTouched X}
         {Manager tell(Id {ReflectValue X})}
         if {IsDet X}
         then skip
         else {WatchVar Id X}
         end
      end
   end

   %%
   %% Record Feature Name Service
   %%
   local
      Stream Prt
   in
      Prt = {Port.new Stream}
      thread {ForAll Stream proc {$ A#N} N = {Name.newNamed A} end} end
      proc {MakeFeature F N}
         if {IsName F}
         then {Port.sendRecv Prt {System.printName F} N}
         else N = F
         end
      end
   end

   %%
   %% Reflection Function
   %%
   local
      Reflect
   in
      local
         %% Basic Reflect Fallback
         fun {ReflDrop InRs NewRs}
            NewRs = InRs
            '<?>'
         end
         %% Record Reflection
         local
            fun {Pair X Y}
               X#Y
            end
         in
            fun {ReflRec X InRs NewRs}
               As  = {Record.arity X}
               RAs = {Map As MakeFeature}
               RX  = {Record.make {MakeFeature {Record.label X}} RAs}
            in
               NewRs = {FoldL {List.zip As RAs Pair}
                        proc {$ InRs F#RF NewRs}
                           RX.RF = {Reflect X.F InRs NewRs}
                        end
                        InRs}
               RX
            end
            %% KindedRecord Reflection
            local
               local
                  fun {MirrorArity Xs}
                     if {IsFree Xs}
                     then nil
                     elsecase Xs
                     of X|Xr then X|{MirrorArity Xr}
                     [] nil  then nil
                     end
                  end
               in
                  fun {ComputeArity X}
                     {MirrorArity {RecordC.monitorArity X _}}
                  end
               end
               fun {ComputeLabel X}
                  if {RecordC.hasLabel X}
                  then {MakeFeature {Record.label X}}
                  else '_'
                  end
               end
            in
               fun {ReflKindRec X InRs NewRs}
                  As  = {ComputeArity X}
                  RAs = {Map As MakeFeature}
                  RX  = {Record.make {ComputeLabel X} As}
               in
                  NewRs = {FoldL {List.zip As RAs Pair}
                           proc {$ InRs F#RF NewRs}
                              RX.RF = {Reflect X.F InRs NewRs}
                           end
                           InRs}
                  RX
               end
            end
         end
         %% Cell Reflection
         fun {ReflCell X InRs NewRs}
            Id = {MakeId}
         in
            {Manager register(cell Id {Reflect {Cell.access X} InRs NewRs})}
            Wrapper(Id)
         end
         %% Port Reflection
         fun {ReflPort X InRs NewRs}
            Id = {MakeId}
         in
            InRs=NewRs
            {Manager register(port Id nil)}
            Wrapper(Id)
         end
         %% Array Reflection
         fun {ReflArray X InRs NewRs}
            Id = {MakeId}
         in
            {Manager register(array Id
                              {Reflect {Array.toRecord array X} InRs NewRs})}
            Wrapper(Id)
         end
         %% Dictionary Reflection
         fun {ReflDict X InRs NewRs}
            Id = {MakeId}
         in
            {Manager
             register(dictionary Id
                      {Reflect {Dictionary.toRecord dictionary X} InRs NewRs})}
            Wrapper(Id)
         end
         %% Procedure Reflection
         fun {ReflProc X InRs NewRs}
            Id = {MakeId}
         in
            NewRs = InRs
            {Manager
             register(procedure Id {System.printName X}#{Procedure.arity X})}
            Wrapper(Id)
         end
         %% ByteString Reflection
         fun {ReflBS X InRs NewRs}
            Id = {MakeId}
         in
            NewRs = InRs
            {Manager register(bytestring Id {ByteString.toString X})}
            Wrapper(Id)
         end
         %% Variable Reflection
         fun {ReflVar X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            else
               Id = {MakeId}
            in
               {Manager register(free Id nil)}
               thread {WatchVar Id X} end
               Wrapper(Id)
            end
         end
         %% Future Reflection
         fun {ReflFut X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            else
               Id = {MakeId}
            in
               {Manager register(future Id nil)}
               thread {WatchVar Id X} end
               Wrapper(Id)
            end
         end
         %% Failed Reflection
         fun {ReflFailed X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            else '<Failed Value>'
            end
         end
         %% FD Reflection
         fun {ReflFD X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            else
               Id = {MakeId}
            in
               {Manager register(fd Id {FD.reflect.dom X})}
               thread {WatchVar Id X} end
               Wrapper(Id)
            end
         end
         %% FS Reflection
         fun {ReflFS X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            elseif {FS.value.is X}
            then X
            else
               Id = {MakeId}
            in
               {Manager register(fsvar Id
                                 {FS.reflect.lowerBound X}#
                                 {FS.reflect.upperBound X})}
               thread {WatchVar Id X} end
               Wrapper(Id)
            end
         end
      in
         %% Main Reflection
         fun {Reflect X Rs NewRs}
            Status = {Value.status X}
         in
            if {IsAtomic Status}
            then NewRs = Rs X
            elsecase {IsMember X Rs}
            of yes(RX) then NewRs = Rs RX
            [] no      then
               InRs RX
            in
               InRs = (X#RX)|Rs
               RX   = case Status
                      of free      then {ReflVar X InRs NewRs}
                      [] future    then {ReflFut X InRs NewRs}
                      [] failed    then {ReflFailed X InRs NewRs}
                      [] det(Type) then
                         case Type
                         of byteString then {ReflBS X InRs NewRs}
                         [] tuple      then {ReflRec X InRs NewRs}
                         [] record     then {ReflRec X InRs NewRs}
                         [] cell       then {ReflCell X InRs NewRs}
                         [] port       then {ReflPort X InRs NewRs}
                         [] array      then {ReflArray X InRs NewRs}
                         [] dictionary then {ReflDict X InRs NewRs}
                         [] procedure  then {ReflProc X InRs NewRs}
                         [] fset       then {ReflFS X InRs NewRs}
                         [] _          then {ReflDrop InRs NewRs}
                         end
                      [] kinded(Type) then
                         case Type
                         of int    then {ReflFD X InRs NewRs}
                         [] fset   then {ReflFS X InRs NewRs}
                         [] record then {ReflKindRec X InRs NewRs}
                         end
                      end
               RX
            end
         end
         %% Global Reflection Function
         fun {ReflectValue X}
            if {System.onToplevel} then X else {Reflect X nil _} end
         end
      end
   end

   %%
   %% Unreflection Function
   %%
   local
      Unreflect
   in
      local
         fun {IsWrapped Status X}
            Status == det(tuple) andthen {Label X} == Wrapper
         end
         fun {IsRecord Status}
            case Status
            of det(record) then true
            [] det(tuple)  then true
            [] _           then false
            end
         end
         %% Record Unreflection
         fun {UnreflectRec X InRs NewRs}
            As = {Record.arity X}
            RX = {Record.make {Record.label X} As}
         in
            NewRs = {FoldL As
                     proc {$ InRs F NewRs}
                        RX.F = {Unreflect X.F InRs NewRs}
                     end
                     InRs}
            RX
         end
         %% Lookup Reflected Value
         fun {UnreflectWrapped X InRs NewRs}
            InRs = NewRs
            case X of Wrapper(Id) then {Manager getvalue(Id $)} end
         end
      in
         %% Main Unreflection
         fun {Unreflect X Rs NewRs}
            Status = {Value.status X}
         in
            if {IsAtomic Status}
            then NewRs = Rs X
            elsecase {IsMember X Rs}
            of yes(RX) then NewRs = Rs RX
            [] no      then
               InRs RX
            in
               InRs = (X#RX)|Rs
               RX   = if {IsWrapped Status X}
                      then {UnreflectWrapped X InRs NewRs}
                      elseif {IsRecord Status}
                      then {UnreflectRec X InRs NewRs}
                      else NewRs = InRs X
                      end
               RX
            end
         end
         %% Global Unreflection Function
         fun {UnreflectValue X}
            {Unreflect X nil _}
         end
      end
   end

   %%
   %% Reflection Manager
   %%
   local
      Normal = {NewName}
      Future = {NewName}

      %% Get the "readable" part of the value
      %% Only meaningful for future pairs
      fun {GetValue V}
         case V
         of Normal(Value) then Value
         [] Future(FX#_)  then FX
         end
      end

      %% Get the "writable" part of the value
      %% Only meaningful for future pairs
      fun {GetBind V}
         case V
         of Normal(Value) then Value
         [] Future(_#FV)  then FV
         end
      end

      proc {UnreflectArray X ?A}
         case {Arity X} of Low|_ then
            A = {Array.new Low {Width X} + Low - 1 unit}
            {Record.forAllInd X proc {$ F Y} A.F := Y end}
         end
      end

      %% Node Creation
      fun {CreateNode Type Info}
         case Type
         of free       then _
         [] future     then local X in (!!X)#X end
         [] fd         then {FD.int Info}
         [] fsvar      then case Info of LB#UB then {FS.var.bounds LB UB} end
         [] bytestring then {ByteString.make Info}
         [] cell       then {Cell.new {UnreflectValue Info}}
         [] array      then {UnreflectArray {UnreflectValue Info}}
         [] dictionary then {Record.toDictionary {UnreflectValue Info}}
         [] procedure  then
            case Info of N#A then
               NV = case N of '' then '' else ' '#N end
            in
               {VirtualString.toAtom '<P/'#A#NV#'>'}
            end
         end
      end

      %% Recognize Reflected Values
      fun {IsWrapped V}
         {IsDet V} andthen {IsTuple V} andthen {Label V} == Wrapper
      end

      fun {GetId V}
         case V of Wrapper(Id) then Id end
      end

      class ReflectionManager
         prop
            final
         attr
            vars %% Variable Dictionary
         meth create
            @vars = {Dictionary.new}
         end
         meth register(Type Id Info)
            Value = {CreateNode Type Info}
         in
            {Dictionary.put @vars Id
             if Type == future then Future(Value) else Normal(Value) end}
         end
         meth tell(Id Value)
            Vars     = @vars
            OldValue = {GetBind {Dictionary.get Vars Id}}
            NewValue = if {IsWrapped Value}
                       then ReflectionManager, getValue(Value $)
                       else {UnreflectValue Value}
                       end
         in
            %% This is done on toplevel
            %% therefore all bindings should be undone it case of error.
            %% Thread is necessary to handle other tells while a previous
            %% Tells blocks due to futures.
            %% This is safe since failure is catched and therefore doesn't
            %% matter.
            thread try OldValue = NewValue catch _ then skip end end
         end
         meth getValue(Value $)
            {GetValue {Dictionary.get @vars {GetId Value}}}
         end
         meth getWrappedValue(Value $)
            'unit'(ReflectionManager, getValue(Value $))
         end
      end

      fun {NewSyncServer O}
         S P
      in
         P = {NewPort S}
         thread {ForAll S proc {$ M#X} {O M} X = unit end} end
         proc {$ M}
            {Wait {Port.sendRecv P M}}
         end
      end
   in
      Manager = {NewSyncServer {New ReflectionManager create}}
   end
end
