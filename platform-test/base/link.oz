%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Christian Schulte, 1997, 1998
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

local
   Code =
      '
      #include <stdlib.h>
      #include <stdio.h>
      #include "oz.h"

      OZ_C_proc_begin(goodies_getenv,2)
      {
        char *envVar;
        char *envValue;
        OZ_Term envVarName;
        envVarName = OZ_getCArg(0);

        /* For the second version uncomment the next line */
        #ifdef XX
        if (OZ_isVariable(envVarName)) {
                                         OZ_Suspension susp = OZ_makeSelfSuspension();
                                         OZ_addSuspension(envVarName,susp);
                                         return PROCEED;
                                       }
           #endif

           if (! OZ_isAtom(envVarName) ) {
                                           fprintf(stderr,"Error: getenv: arg 1 must be an atom");
                                           return FAILED;
                                         };

              envVar = OZ_atomToC(envVarName);

              envValue = getenv(envVar);
              if (envValue == 0) /* not defined in environment --> fail */
                                       return FAILED;

                                       return OZ_unify(OZ_getCArg(1),OZ_atom(envValue));
      }
      OZ_C_proc_end
      '

in

   functor $ prop once

   import
      OS

      Open

      Foreign

      System

   export
      Return

   body
      Return=

      link(equal(local
                    L={Lock.new}
                 in
                    fun {$}
                       lock L then
                          try
                             File='/tmp/link_test_'#{OS.time}
                             Goodies
                             F={New Open.file init(name:File#'.c'
                                                   flags:['create' write])}
                          in
                             {F write(vs:Code)}
                             {F close}
                             0={OS.system ('gcc -Wno-conversion -c -I '#
                                           {System.get home}#'/include '#
                                           File#'.c -o '#File#'.o'#
                                           ' 2>/dev/null')}
                             0={OS.system ('ozdynld -o '#File#'.so '#
                                           File#'.o -lc')}
                             Goodies = {Foreign.require
                                        File#'.so'
                                        goodies(getenv: 2)}
                             _={Goodies.getenv 'SHELL'}

                             _={OS.system 'rm -f '#File#'.c'}
                             _={OS.system 'rm -f '#File#'.o'}
                             _={OS.system 'rm -f '#File#'.so'}
                             true
                          catch _ then false
                          end
                       end
                    end
                 end
                 true)
           keys: [link foreign])
   end
end
