%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
%%%
%%% Copyright:
%%%   Erik Klintskog, 1998
%%%
%%% Last change:
%%%   $Date$Author:
%%%   $Revision:
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
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
   Remote(manager)
   System
   TestMisc(localHost)
   DP
export
   Return
define
   proc {Start}
      PP = pp(_ _ _ _)
      RM = pp(_ _ _ _)

      MyStream

      PP.1 = {NewPort MyStream}

      Dist = [2 3 4 1 2 3 4 2
              1 2 1 2 3 2 1 2
              3 4 3 2 1 1 2 3 1]

      CC = {NewCell _}

      proc{GCdo}
         Pa2   Pa3   Pa4
      in
         {Send PP.2 gcDo(Pa2)}
         {Send PP.3 gcDo(Pa3)}
         {Send PP.4 gcDo(Pa4)}
         {Wait Pa2}
         {Wait Pa3}
         {Wait Pa4}
         {System.gcDo}
      end

      proc{RRsend RR L}
         H = RR.1
      in
         {Assign CC RR.2#_}
         {For 2 4 1 proc{$ P}
                       Cntrl in
                       {Send PP.P newEntity(RR.2 Cntrl)}
                       {Wait Cntrl}
                    end}
         {Send PP.(L.1) H(RR.2 L.2)}
         if {Access CC}.2 == ok then
         skip
         else
            raise {Access CC}.2 end
         end
         {GCdo}
      end

      proc{Watch X}
         thread
            if {List.member permFail {DP.getFaultStream X}} then
               {Send PP.1 siteFault(siteDown)}
            end
         end
      end

      thread
         try
            {ForAll MyStream
             proc{$ X}
                case X of entity(R L) then
                   {Access CC}.1 = R
                   if L == nil then
                      {Access CC}.2 = ok
                   else
                      {Send PP.(L.1) entity(R L.2)}
                   end
                elseof  gcDo(A) then
                   A = unit
                elseof silentDeath then
                   raise hell end
                elseof siteFault(M) then
                   raise M end
                end
             end}
         catch EXP then
            if (EXP == hell) then   skip
            else   {Access CC}.2 = EXP end
         end
      end

      proc {StartManagers}
         {For 2 4 1
          proc{$ Nr}
             RM.Nr={New Remote.manager
                    init(host:TestMisc.localHost)}
             {RM.Nr ping}
             {RM.Nr apply(url:'' functor
                                 import
                                    System
                                    Property(put)
                                 define
                                    {Property.put 'close.time' 1000}
                                    local
                                       MyStream
                                       MemCell = {NewCell apa}
                                    in
                                       PP.Nr = {NewPort MyStream}
                                       thread
                                          try
                                             {ForAll MyStream
                                              proc{$ X}
                                                 case X of entity(R L) then
                                                    {Access MemCell} = R
                                                    {Send PP.(L.1)
                                                     entity(R L.2)}
                                                 elseof newEntity(E C) then
                                                    {Assign MemCell E}
                                                    C = unit
                                                 elseof gcDo(A) then
                                                    {System.gcDo}
                                                    A = unit
                                                 end
                                              end}
                                          catch M then
                                             {Send PP.1 siteFault(M)}
                                          end
                                       end
                                    end
                                 end
                         )}
             {RM.Nr ping}
             {Wait PP.Nr}
             {Watch PP.Nr}
          end}
      end
   in
      {StartManagers}

      %% atom
      {RRsend entity#apa  Dist}
      %% list
      {RRsend entity#[apa bapa rapa skrapa]  Dist}
      %% string
      {RRsend entity#"apan bapa rapar sa att det i marken skrapar"  Dist}
      %% name
      {RRsend entity#{NewName}  Dist}
      %% lock
      {RRsend entity#{NewLock}  Dist}
      %% cell
      {RRsend entity#{NewCell apa}  Dist}
      %% port
      {RRsend entity#{NewPort _ $}  Dist}
      %% proc
      {RRsend entity#proc{$ D } A = 2 in  D=A*2 end  Dist}
      %% sited proc
      {RRsend entity#proc sited{$ D } A = 2 in  D=A*2 end  Dist}
      %% object
      {RRsend entity#{New class $
                              feat a
                              meth init self.a = 6 end
                           end
                       init}
        Dist}
      %% sited object
      {RRsend entity#{New class $
                              prop sited
                              meth init skip end
                           end
                       init}
        Dist}
      %% class
      {RRsend entity#class $
                         feat a
                         meth init self.a = 6 end
                      end
       Dist}
      %% sited class
      {RRsend entity#class $
                         prop sited
                         meth init skip end
                      end
        Dist}
      %% dictionaries
      {RRsend entity#{Dictionary.new} Dist}

      %% close managers
      {For 2 4 1 proc{$ Nr}
                        /* {Fault.deinstall PP.Nr
                      watcher('cond':permHome) Watch}*/
                    {RM.Nr close}
                 end}
      {Send PP.1 silentDeath}
   end

   Return = dp([equality(Start keys:[remote])])
end
