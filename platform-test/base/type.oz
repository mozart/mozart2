%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {$ IMPORT}
   \insert 'lib/import.oz'
in
   type([misc(proc {$}
                 {Type.ofValue a}=atom
                 {Type.ofValue 1}=int
                 {Type.ofValue 1.0}=float
                 {Type.ofValue a(1)}=tuple
                 {Type.ofValue a(a:1)}=record
              end
              keys:[module])

         isString(proc {$}
                     {IsString a false}
                     {IsString [10 2378] false}
                     {IsString [a b c] false}

                     {IsString "test" true}
                     {IsString nil true}

                  end
                  keys:[module string])

         isStringSusp(proc {$}
                         X Y Sync in
                         thread {IsString [10 X] Y} Sync=unit end
                         {IsFree Y true} X=1 Y=true
                         {Wait Sync}
                      end
                      keys:[module string])

         isStringSuspInt(proc {$}
                            X Y Sync in
                            thread {IsString X Y} Sync=unit end
                            {IsFree Y true} X=1 Y=false
                            {Wait Sync}
                         end
                         keys:[module type string])


         isStringSuspAtom(proc {$}
                             X Y Sync in
                             thread {IsString [10 X] Y} Sync=unit end
                             {IsFree Y true} X=a Y=false
                             {Wait Sync}
                          end
                          keys:[module type string])
        ])
end
