%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

require
   BootName(newUnique: NewUniqueName) at 'x-oz://boot/Name'
   BootObject(getClass: GetClass)     at 'x-oz://boot/Object'

export
   master:  MasterObject
   slave:   SlaveObject
   reflect: ReflectObject

prepare

   local
      Slaves   = {NewName}
      AddSlave = {NewName}
      DelSlave = {NewName}
   in
      class MasterObject
         attr !Slaves: nil
         meth init
            Slaves <- nil
         end
         meth getSlaves($)
            @Slaves
         end
         meth !AddSlave(S)
            OldSlaves
         in
            OldSlaves = (Slaves <- S|OldSlaves)
         end
         meth DoDel(Ss DS $)
            S|Sr=Ss
         in
            if S==DS then Sr else S|MasterObject,DoDel(Sr DS $) end
         end
         meth !DelSlave(S)
            OldSlaves NewSlaves
         in
            OldSlaves = (Slaves <- NewSlaves)
            NewSlaves = MasterObject,DoDel(OldSlaves S $)
         end
      end

      class SlaveObject
         attr
            Master:unit
         meth becomeSlave(M)
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {M AddSlave(self)}
               NewMaster = M
            else
               NewMaster = OldMaster
               {Exception.raiseError object(slaveNotFree)}
            end
         end
         meth isFree($)
            @Master==unit
         end
         meth free
            OldMaster NewMaster
         in
            OldMaster = (Master <- NewMaster)
            if OldMaster==unit then
               {Exception.raiseError object(slaveAlreadyFree)}
            else
               {OldMaster DelSlave(self)}
               NewMaster = unit
            end
         end
      end
   end

   local
      PRIVATE      = {NewName}
      `ooAttr`     = {NewUniqueName 'ooAttr'}
      `ooFreeFeat` = {NewUniqueName 'ooFreeFeat'}
   in
      class ReflectObject

         meth GetAttr(As $)
            case As of nil then nil
            [] A|Ar then (A|@A)|{self GetAttr(Ar $)}
            end
         end

         meth GetFeat(Fs $)
            case Fs of nil then nil
            [] F|Fr then (F|self.F)|{self GetFeat(Fr $)}
            end
         end

         meth toChunk($)
            C = {GetClass self}
         in
            {Chunk.new
             c(PRIVATE:
                  o('class': C
                    'attr':  {self GetAttr({Arity C.`ooAttr`} $)}
                    'feat':  {self GetFeat({Arity C.`ooFreeFeat`} $)}))}
         end

         meth SetAttr(AXs)
            case AXs of nil then skip
            [] AX|AXr then A|X=AX in A<-X {self SetAttr(AXr)}
            end
         end

         meth SetFeat(FXs)
            case FXs of nil then skip
            [] FX|FXr then F|X=FX in self.F=X {self SetFeat(FXr)}
            end
         end

         meth fromChunk(Ch)
            o('class':C 'attr':A 'feat':F) = Ch.PRIVATE
         in
            C={GetClass self}
            {self SetAttr(A)}
            {self SetFeat(F)}
         end

         meth clone($)
            C = {GetClass self}
            O = {New C SetAttr({self GetAttr({Arity C.`ooAttr`} $)})}
         in
            {O SetFeat({self GetFeat({Arity C.`ooFreeFeat`} $)})}
            O
         end
      end
   end

end
