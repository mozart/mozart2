%%%
%%% Authors:
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
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

declare
   Exception Raise
in

%%
%% Run time library
%%
local
   RaiseDebugCheck = {`Builtin` 'Exception.raiseDebugCheck' 2}

   ThreadTaskStack = {`Builtin` 'Thread.taskStackError' 3}
   ThreadLocation  = {`Builtin` 'Thread.location'       2}

   proc {RaiseDebugExtend T1 T2}
      L        = {Label T1.debug}
      This     = {Thread.this}
      Stack    = {ThreadTaskStack This false}
      Location = {ThreadLocation This}
   in
      {Raise {AdjoinAt
              T1
              debug
              {Adjoin T1.debug
               L(stack:Stack loc:Location info:T2)}}}
   end
in
   {`runTimePut` 'RaiseDebugCheck' RaiseDebugCheck}
   {`runTimePut` 'RaiseDebugExtend' RaiseDebugExtend}
end


%%
%% Global
%%
Raise = `Raise`

local
   fun {FailureX D}
      failure(debug:failure(info:D))
   end

   fun {PredefX E}
      system(E debug:{Label E})
   end

   fun {PredefXD E D}
      K
   in
      K = {Label E}
      system(E debug:K(info:D))
   end

   fun {ErrorXD E D}
      K
   in
      K = {Label E}
      error(E debug:K(info:D))
   end

   fun {ErrorX E}
      error(E debug:{Label E})
   end

in

   Exception = exception('raise':       Raise
                         raiseError:    `RaiseError`
                         %%
                         %% wrapper functions
                         %%
                         error:         ErrorX
                         failure:       FailureX
                         system:        PredefX
                         errorDebug:    ErrorXD
                         systemDebug:   PredefXD)

end
