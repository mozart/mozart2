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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

class CompilerInterfaceGeneric
   prop locking
   attr Compiler: unit Port: unit ServerThread: unit
   meth init(CompilerObject Serve)
      lock Ms in
         CompilerInterfaceGeneric, exit()
         Compiler <- CompilerObject
         Port <- {NewPort Ms}
         {CompilerObject register(@Port)}
         thread
            ServerThread <- {Thread.this}
            {self Serve(Ms)}
         end
      end
   end
   meth exit()
      lock
         case @Compiler == unit then skip
         else
            {Thread.terminate @ServerThread}
            {@Compiler unregister(@Port)}
            Compiler <- unit
            Port <- unit
            ServerThread <- unit
         end
         {self reset()}
      end
   end
   meth reset()
      skip
   end
   meth getCompiler($)
      @Compiler
   end
   meth getPort($)
      @Port
   end

   meth enqueue(M)
      {@Compiler enqueue(M)}
   end
end
