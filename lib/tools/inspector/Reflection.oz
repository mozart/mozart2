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
export
   'label'     : Wrapper
   'reflect'   : ReflectValue
   'unreflect' : UnreflectValue
   'manager'   : Manager
define
   SpaceOfVar = BrowserSupport.varSpace

   %% Identify wrapped Reflection Constructs
   Wrapper = {NewName}

   %% Id Generator Service
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
            OldValue = {Dictionary.get Vars Id}
            NewValue = if {IsWrapped Value}
                       then ReflectionManager, getValue(Value $)
                       else {UnreflectValue Value}
                       end
         in
            {GetBind OldValue} = NewValue
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
         thread
%           {ForAll S O}
            {ForAll S proc {$ M#X}
                         {O M} X = unit
                      end}
         end
         proc {$ M}
            X = {Port.sendRecv P M}
         in
            {Wait X}
         end
      end
   in
      Manager = {NewSyncServer {New ReflectionManager create}}
   end

   %%
   %% Watching Stuff
   %%
   local
      proc {WaitTouched X}
         if {IsFuture X}
         then {Value.waitQuiet X}
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
   %% (Un-)Reflection Helpers
   %%
   local
      TopSpace
   in
      fun {IsTop X}
         {SpaceOfVar TopSpace} == {SpaceOfVar X}
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
   %% Type specific Reflection
   %%
   Reflect

   local
      fun {ReflectDrop InRs NewRs}
         NewRs = InRs
         '<?>'
      end
      fun {ReflectByteString X InRs NewRs}
         Id = {MakeId}
      in
         NewRs = InRs
         {Manager register(byteS Id {ByteString.toString X})}
         Wrapper(Id)
      end
      fun {ReflectFree X InRs NewRs}
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
      fun {ReflectFuture X InRs NewRs}
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
      fun {ReflectRecord X InRs NewRs}
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
      fun {ReflectFD X InRs NewRs}
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

      fun {ReflectFS X InRs NewRs}
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
         fun {ReflectKindRec X InRs NewRs}
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
   in
      %%
      %% Major Reflection Function
      %%
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
                   of free      then {ReflectFree X InRs NewRs}
                   [] future    then {ReflectFuture X InRs NewRs}
                   [] det(Type) then
                      case Type
                      of byteString then {ReflectByteString X InRs NewRs}
                      [] tuple      then {ReflectRecord X InRs NewRs}
                      [] record     then {ReflectRecord X InRs NewRs}
                      [] _          then {ReflectDrop InRs NewRs}
                      end
                   [] kinded(Type) then
                      case Type
                      of int    then {ReflectFD X InRs NewRs}
                      [] fset   then {ReflectFS X InRs NewRs}
                      [] record then {ReflectKindRec X InRs NewRs}
                      end
                   end
            RX
         end
      end
   end

   %%
   %% Type Specific Unreflection
   %%
   Unreflect

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
      fun {UnreflectWrapped X InRs NewRs}
         InRs = NewRs
         case X of Wrapper(Id) then {Manager getvalue(Id $)} end
      end
      fun {UnreflectRecord X InRs NewRs}
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
   in
      %%
      %% Major Unreflection Function
      %%
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

   %%
   %% Reflection Entry
   %%
   fun {ReflectValue X}
      if {System.onToplevel} then X else {Reflect X nil _} end
   end

   %%
   %% Unreflection Entry
   %%
   fun {UnreflectValue X}
      {Unreflect X nil _}
   end
end
