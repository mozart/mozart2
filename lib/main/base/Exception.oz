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
   `RaiseDebugCheck` `RaiseDebugExtend`
in


Raise = `Raise`

local
   GetErrors = {`Builtin` 'SystemGetErrors' 1}
in
   fun {`RaiseDebugCheck` T1}
      R = errors('thread':_ location:_ hints:_ depth:_ width:_ debug:_)
   in
      {GetErrors R}
      R.debug andthen
      {IsDet T1} andthen
      {IsRecord T1} andthen
      {HasFeature T1 debug} andthen
      {IsDet T1.debug} andthen
      {IsRecord T1.debug}
   end
end

local
   GetErrors       = {`Builtin` 'SystemGetErrors' 1}
   ThreadThis      = {`Builtin` 'Thread.this' 1}
   ThreadTaskStack = {`Builtin` 'Thread.taskStack' 4}
   ThreadLocation  = {`Builtin` 'Thread.location' 2}
in
   proc {`RaiseDebugExtend` T1 T2}
      L        = {Label T1.debug}
      This     = {ThreadThis}
      errors('thread':N location:_ hints:_ depth:_ width:_ debug:_)
               = {GetErrors}
      Stack    = {ThreadTaskStack This N false}
      Location = {ThreadLocation This}
   in
      {`Raise` {AdjoinAt
                T1
                debug
                {Adjoin T1.debug
                 L(stack:Stack loc:Location info:T2)}}}
   end
end

local
   fun {FailureX D}
      {Type.ask.record D}
      failure(debug:failure(info:D))
   end

   fun {PredefX E}
      {Type.ask.record E}
      system(E debug:{Label E})
   end

   fun {PredefXD E D}
      K
   in
      {Type.ask.record E}
      {Type.ask.record D}
      K = {Label E}
      system(E debug:K(info:D))
   end

   fun {ErrorXD E D}
      K
   in
      {Type.ask.record E}
      {Type.ask.record D}
      K = {Label E}
      error(E debug:K(info:D))
   end

   fun {ErrorX E}
      {Type.ask.record E}
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
