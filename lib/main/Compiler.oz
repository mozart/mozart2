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

   functor $ prop once

   import
      System.{gcDo
              printName
              valueToVirtualString
              get
              property
              printError
              show
              eq}

      Foreign.{pointer
               staticLoad}

      Error.{formatExc
             formatPos
             formatLine
             msg}

      FS.{include
          var
          subset
          value
          reflect
          union
          diff
          cardRange
          disjoint}

      FD.{int
          is
          less
          distinct
          distribute}

      Search.{SearchOne = 'SearchOne'}

\ifndef OZM
      Gump
\endif


   export
      engine:               CompilerEngine
      compilerClass:        CompilerEngine   %--** deprecated
      genericInterface:     GenericInterface
      quietInterface:       QuietInterface
      evalExpression:       EvalExpression
      virtualStringToValue: VirtualStringToValue
      assemble:             DoAssemble

   body
      \insert 'compiler/InsertAll.oz'
   end
end
