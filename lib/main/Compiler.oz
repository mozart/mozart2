%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   StandardEnv = \insert 'compiler-Env.oz'
in
   functor prop once
   import
      Property.{get condGet}
      System   %--**.{gcDo printName valueToVirtualString get printError eq}
      Foreign   %--**.{pointer}
      Parser from 'x-oz-boot:Parser'
      Error   %--**.{formatExc formatPos formatLine formatGeneric format dispatch msg}
      ErrorRegistry.put
      FS.{include var subset value reflect isIn}
      FD.{int is less distinct distribute}
      Search.{SearchOne = 'SearchOne'}
\ifndef OZM
      Gump
\endif
   export
      engine:               CompilerEngine
      compilerClass:        CompilerEngine   %--** deprecated
      parseOzFile:          ParseOzFile
      parseOzVirtualString: ParseOzVirtualString
      genericInterface:     GenericInterface
      quietInterface:       QuietInterface
      evalExpression:       EvalExpression
      virtualStringToValue: VirtualStringToValue
      assemble:             DoAssemble
   body
      \insert 'compiler/InsertAll.oz'
   end
end
