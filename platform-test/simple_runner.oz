%%%
%%% Authors:
%%%   Benoit Daloze
%%%
%%% Copyright:
%%%   Benoit Daloze, 2014
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%
functor
import
   Application
   System(showInfo:Info)
   Pickle
   Module
   Compiler
define
   fun {CompileFile File}
      BatchCompiler = {New Compiler.engine init}
      UI = {New Compiler.interface init(BatchCompiler auto)}
      R
   in
      {Info 'Compiling '#File#' ...'}
      {BatchCompiler enqueue(setSwitch(showdeclares false))}
      {BatchCompiler enqueue(setSwitch(threadedqueries false))}
      {BatchCompiler enqueue(setSwitch(expression true))}
      {BatchCompiler enqueue(feedFile(File return(result:R)))}
      {UI sync()}
      if {UI hasErrors($)} then
	 {Application.exit 1}
	 unit
      else
	 R
      end
   end

   proc {NewLine}
      {Info ''}
   end

   fun {TestProcedure TestDesc}
      Test = TestDesc.1
   in
      if {IsProcedure Test} then
	 case {Procedure.arity Test}
	 of 0 then Test
	 [] 1 then proc {$} {Test} = true end
	 end
      else
	 equal(F Expected) = Test
      in
	 proc {$}
	    {F} = Expected
	 end
      end
   end

   TestFiles = {Application.getArgs plain}

   for File in TestFiles do
      CompiledFunctor = if {List.last File} == &f then
			   {Pickle.load File}
			else
			   {CompileFile File}
			end
      Applied = {Module.apply [CompiledFunctor]}.1
      Return = Applied.return
      TestCase = {Label Return}
      Tests = if {IsList Return.1} then Return.1 else [Return] end
   in
      {Info 'Testing '#TestCase}

      for Test in Tests do
	 {Info {Label Test}}
	 %{Show Test.keys}
	 ActualTest = {TestProcedure Test}
      in
	 {ActualTest}
	 {Info '  OK'}
      end
      {NewLine}
   end
end
