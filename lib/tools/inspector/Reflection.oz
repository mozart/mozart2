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
   System(eq onToplevel)
   BrowserSupport(getsBoundB varSpace) at 'x-oz://boot/Browser'
   FD
   FS
   RecordC
   Space
export
   'label'     : Wrapper
   'reflect'   : ReflectValue
   'unreflect' : UnreflectValue
   'manager'   : Manager
define
   %% Identify wrapped Reflection Constructs
   Wrapper = {NewName}

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
   %% Reflection Function Prototype
   %%
   local
      fun {ReflDrop InRs NewRs}
         NewRs = InRs
         '<?>'
      end
      %% Create Record Reflection
      fun {MakeReflRec Reflect}
         fun {$ X InRs NewRs}
            As = {Record.arity X}
            RX = {Record.make {Record.label X} As}
         in
            NewRs = {FoldL As
                     proc {$ InRs F NewRs}
                        RX.F = {Reflect X.F InRs NewRs}
                     end
                     InRs}
            RX
         end
      end
      %% Create KindedRecord Reflection
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
            if {RecordC.hasLabel X} then {Record.label X} else '_' end
         end
      in
         fun {MakeReflKindRec Reflect}
            fun {$ X InRs NewRs}
               As = {ComputeArity X}
               RX = {Record.make {ComputeLabel X} As}
            in
               NewRs = {FoldL As
                        proc {$ InRs F NewRs}
                           RX.F = {Reflect X.F InRs NewRs}
                        end
                        InRs}
               RX
            end
         end
      end
   in
      proc {MakeReflect ReflBS ReflVar ReflFut ReflFD ReflFS Reflect}
         ReflRec     = {MakeReflRec Reflect}
         ReflKindRec = {MakeReflKindRec Reflect}
      in
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
                      [] det(Type) then
                         case Type
                         of byteString then {ReflBS X InRs NewRs}
                         [] tuple      then {ReflRec X InRs NewRs}
                         [] record     then {ReflRec X InRs NewRs}
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
      end
   end

   %%
   %% Unreflection Function Prototype
   %%
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
      %% Create Record Unreflection
      fun {MakeUnreflectRecord Unreflect}
         fun {$ X InRs NewRs}
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
      end
   in
      proc {MakeUnreflect UnreflectWrapped Unreflect}
         UnreflectRecord = {MakeUnreflectRecord Unreflect}
      in
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
                      then {UnreflectRecord X InRs NewRs}
                      else NewRs = InRs X
                      end
               RX
            end
         end
      end
   end

   %%
   %% Unification Start Service
   %%
   local
      Stream Prt
   in
      Prt = {Port.new Stream}
      thread {ForAll Stream proc {$ fire(Passed)} Passed = unit end} end
      proc {Notify Passed}
         {Port.send Prt fire(Passed)}
      end
   end

   %%
   %% Unification Test for Reflection Manager
   %%
   local
      local
         fun {ReflBS X InRs NewRs}
            NewRs = InRs
            Wrapper(bs {ByteString.toString X})
         end
         fun {ReflVar X InRs NewRs}
            NewRs = InRs
            if {IsTop X} then X else Wrapper(free nil) end
         end
         fun {ReflFut X InRs NewRs}
            NewRs = InRs
            if {IsTop X} then X else Wrapper(future nil) end
         end
         fun {ReflFD X InRs NewRs}
            NewRs = InRs
            if {IsTop X} then X else Wrapper(fd {FD.reflect.dom X}) end
         end
         fun {ReflFS X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            elseif {FS.value.is X}
            then Wrapper(fsval {FS.reflect.card x})
            else Wrapper(fsvar
                         {FS.reflect.lowerBound X}#{FS.reflect.upperBound X})
            end
         end
         fun {UnreflectWrapped X InRs NewRs}
            InRs = NewRs
            case X
            of Wrapper(bs Info)     then {ByteString.make Info}
            [] Wrapper(free _)      then _
            [] Wrapper(future _)    then !!_
            [] Wrapper(fd Info)     then {FD.int Info}
            [] Wrapper(fsval Info)  then {FS.value.make Info}
            [] Wrapper(fsvar LB#UB) then {FS.var.bounds LB UB}
            end
         end
      in
         UnifyReflect   = {MakeReflect ReflBS ReflVar ReflFut ReflFD ReflFS}
         UnifyUnreflect = {MakeUnreflect UnreflectWrapped}
      end
   in
      proc {SecureUnify X Y}
         XRs RX RY Passed
      in
         RX = {UnifyReflect X nil XRs}
         RY = {UnifyReflect Y XRs _}
         {Space.new proc {$ LY}
                       XRs LX
                    in
                       LX = {UnifyUnreflect RX nil XRs}
                       LY = {UnifyUnreflect RY XRs _}
                       LY = LX
                       {Notify Passed}
                    end _}
         {Wait Passed}
         X = Y
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
         if {IsFuture X}
         then {Value.waitQuiet X}
         elseif {IsDet X}
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
   %% Global Reflection Function
   %%
   local
      local
         fun {ReflBS X InRs NewRs}
            Id = {MakeId}
         in
            NewRs = InRs
            {Manager register(byteS Id {ByteString.toString X})}
            Wrapper(Id)
         end
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
         fun {ReflFS X InRs NewRs}
            NewRs = InRs
            if {IsTop X}
            then X
            elseif {FS.value.is X}
            then Wrapper(fsval {FS.reflect.card x})
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
         Reflect = {MakeReflect ReflBS ReflVar ReflFut ReflFD ReflFS}
      end
   in
      fun {ReflectValue X}
         if {System.onToplevel} then X else {Reflect X nil _} end
      end
   end

   %%
   %% Global Unreflection Function
   %%
   local
      local
         fun {UnreflectWrapped X InRs NewRs}
            InRs = NewRs
            case X of Wrapper(Id) then {Manager getvalue(Id $)} end
         end
      in
         Unreflect = {MakeUnreflect UnreflectWrapped}
      end
   in
      fun {UnreflectValue X}
         {Unreflect X nil _}
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

      fun {MakeValue Type Info}
         case Type
         of free   then _
         [] future then local X in (!!X)#X end
         [] fd     then {FD.int Info}
         [] fsval  then {FS.value.make Info}
         [] fsvar  then case Info of LB#UB then {FS.var.bounds LB UB} end
         [] byteS  then {ByteString.make Info}
         end
      end

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
            Value = {MakeValue Type Info}
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
            thread {SecureUnify OldValue NewValue} end
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
