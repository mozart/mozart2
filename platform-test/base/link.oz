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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
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

      OZ_BI_define(BIgetenv,1,1)
      {
        char *envVar;
        char *envValue;
        OZ_Term envVarName;
        envVarName = OZ_in(0);

        /* For the second version uncomment the next line */
        if (OZ_isVariable(envVarName)) {
           OZ_suspendOn(envVarName);
        }

        if (! OZ_isAtom(envVarName) ) {
          return OZ_typeError(0,"Atom");
        }

        envVar = OZ_atomToC(envVarName);

        envValue = getenv(envVar);
        if (envValue == 0) { /* not defined in environment */
           return OZ_raise(OZ_mkTupleC("getenv",1,envVarName));
        }
        OZ_result(OZ_atom(envValue));
        return PROCEED;
      } OZ_BI_end

     OZ_C_proc_interface oz_interface[] = {
       {"getenv",1,1,BIgetenv},
       {0,0,0,0}
     };
'

in

   functor $ prop once

   import
      OS

      Open

      Foreign

      Property

   export
      Return

   body
      Return=

      link(equal(local
                    L={Lock.new}
                 in
                    fun {$}
                       lock L then
                          File='/tmp/link_test_'#{OS.time}
                          Goodies
                          F={New Open.file init(name:File#'.c'
                                                flags:['create' write])}
                       in
                          {F write(vs:Code)}
                          {F close}
                          0={OS.system ('gcc -Wno-conversion -c -I '
                                        #{Property.get 'oz.home'}
                                        #'/include '#
                                        File#'.c -o '#File#'.o'
                                        #' 2>/dev/null'
                                       )}
                          0={OS.system ('ozdynld -o '#File#'.so '#
                                        File#'.o -lc')}
                          Goodies = {Foreign.load 'file:'#File#'.so'}
                          _={Goodies.getenv 'SHELL'}
                          _={OS.system
                             'rm -f '#File#'.c '#File#'.o '#File#'.so'}
                          true
                       end
                    end
                 end
                 true)
           keys: [link foreign])
   end
end
