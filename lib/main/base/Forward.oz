%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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
   %% Exception handling
   `Raise` `RaiseError`
   %% Record construction
   `record`
   %% Run time library construction
   `runTimePut`
\ifndef OZM
   `runTimeDict` = {NewDictionary}
\endif
in

`Raise`      = {`Builtin` 'raise'      1}
`RaiseError` = {`Builtin` 'raiseError' 1}
`record`     = {`Builtin` 'record'     3}

local
   DictionaryMember = {`Builtin` 'Dictionary.member' 3}
   DictionaryGet = {`Builtin` 'Dictionary.get' 3}
   DictionaryPut = {`Builtin` 'Dictionary.put' 3}
in
   proc {`runTimePut` X V}
      case {DictionaryMember `runTimeDict` X} then
         {DictionaryGet `runTimeDict` X V}
      else
         {DictionaryPut `runTimeDict` X V}
      end
   end
end

{`runTimePut` 'Raise' `Raise`}
{`runTimePut` 'RaiseError' `RaiseError`}
{`runTimePut` 'record' `record`}
