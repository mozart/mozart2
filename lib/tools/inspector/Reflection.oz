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
   BrowserSupport(varSpace) at 'x-oz://boot/Browser'
   FD
   FS
   RecordC
export
   'label'   : Wrapper
   'reflect' : ValueReflect
define
   SpaceOfVar = BrowserSupport.varSpace

   %% Identify wrapped Reflection Constructs
   Wrapper = {NewName}

   %% Make Reflection Globally Visible
   Reflect

   %%
   %% Reflection Helpers
   %%
   local
      TopSpace
   in
      fun {IsTop X}
         {SpaceOfVar TopSpace} == {SpaceOfVar X}
      end
   end

   %%
   %% Type specific Reflection
   %%

   fun {ReflectDrop InRs NewRs}
      NewRs = InRs
      '<?>'
   end

   fun {ReflectFree X InRs NewRs}
      NewRs = InRs
      if {IsTop X} then X else Wrapper(free nil) end
   end

   fun {ReflectFuture X InRs NewRs}
      NewRs = InRs
      if {IsTop X} then X else Wrapper(future nil) end
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
      if {IsTop X} then X else Wrapper(fd {FD.reflect.dom X}) end
   end

   fun {ReflectFS X InRs NewRs}
      NewRs = InRs
      if {IsTop X}
      then X
      elseif {FS.value.is X}
      then Wrapper(fsval {FS.reflect.card x})
      else Wrapper(fsvar {FS.reflect.lowerBound X}#{FS.reflect.upperBound X})
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

   %%
   %% Major Reflection Function
   %%
   local
      fun {IsAtomic X}
         case X
         of det(int)        then true
         [] det(float)      then true
         [] det(atom)       then true
         [] det(name)       then true
         [] det(byteString) then true
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
                   of free      then {ReflectFree X InRs NewRs}
                   [] future    then {ReflectFuture X InRs NewRs}
                   [] det(Type) then
                      case Type
                      of tuple  then {ReflectRecord X InRs NewRs}
                      [] record then {ReflectRecord X InRs NewRs}
                      [] _      then {ReflectDrop InRs NewRs}
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
   %% Reflection Entry
   %%
   fun {ValueReflect X}
      if {System.onToplevel} then X else {Reflect X nil _} end
   end
end
