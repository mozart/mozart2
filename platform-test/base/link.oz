%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
      #include "mozart.h"

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
#if defined(__cplusplus)
extern "C" {
#endif
     OZ_C_proc_interface *oz_init_module(void) {
       return oz_interface;
     }
#if defined(__cplusplus)
}
#endif
'
in

   functor

   import
      OS
      Open
      Property
      Module

   export
      Return

   define
      %% Somehow, OZTOOL and OZTOOLINC should be available through
      %% a more general interface. they are also used in Gump.
      %% In fact, the definitions below are copied from
      %% mozart/share/tools/gump/Main.oz
      %%
      OZHOME = {Property.get 'oz.home'}
      %% {OZTOOL} returns a vs naming the oztool executable
      fun {OZTOOL}
         case {Property.condGet 'oz.exe.oztool' unit} of unit
         then case {OS.getEnv 'OZTOOL'} of false then oztool
              elseof X then X end
         elseof X then X end
      end
      %% {OZTOOLINC} returns a vs consisting of -Idir elements
      fun {OZTOOLINC}
         case {Property.condGet 'oz.inc.oztool' unit} of unit
         then case {OS.getEnv 'OZTOOL_INCLUDES'} of false
              then '-I'#OZHOME#'/include'
              elseof X then X end
         elseof X then X end
      end

      Return=

      link(equal(local
                    L={Lock.new}
                 in
                    fun {$}
                       lock L then
                          File   = '/tmp/link_test_'#{OS.time}
                          FileSO = File#'.so-'#{Property.get 'platform.name'}
                          Goodies
                          F={New Open.file init(name:File#'.c'
                                                flags:['create' write])}
                          M={New Module.manager init}
                          Oztool={OZTOOL}
                          Oztoolinc={OZTOOLINC}
                       in
                          {F write(vs:Code)}
                          {F close}
                          0={OS.system (Oztool#' c++ '#Oztoolinc
                                        #' -c '#File#'.c -o '#File#'.o'
                                        #' 2>/dev/null'
                                       )}
                          0={OS.system (Oztool#' ld -o '#FileSO#' '#
                                        File#'.o -lc')}
                          Goodies={M link(url:File#'.so{native}' $)}
                          _={Goodies.getenv 'SHELL'}
                          _={OS.system
                             'rm -f '#File#'.c '#File#'.o '#FileSO}
                          true
                       end
                    end
                 end
                 true)
           keys: [link native])
   end
end
