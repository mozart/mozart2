%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

declare
fun
\ifdef NEWCOMPILER
   instantiate
\endif
   {NewCompiler IMPORT}
   \insert 'Standard.env'
   = IMPORT.'Standard'
   \insert 'CP.env'
   = IMPORT.'CP'
   \insert 'WP.env'
   = IMPORT.'WP'
   \insert 'Browser.env'
   = IMPORT.'Browser'
in
   local
      \insert 'compiler/InsertAll.oz'

      CompilerInterfaceTk = {NewCompilerInterfaceTk Tk TkTools Open Browse}
      CompilerInterfaceEmacs = {NewCompilerInterfaceEmacs Open OS}
      CompilerInterfaceQuiet = {NewCompilerInterfaceQuiet}

      local
         class TextFile from Open.file Open.text
            prop final
            meth readQuery($) S in
               Open.text, getS(?S)
               case S == false then ""
               else S#'\n'#TextFile, readQuery($)
               end
            end
         end

         SetOPICompiler = {`Builtin` setOPICompiler 1}
         GetOPICompiler = {`Builtin` getOPICompiler 1}
         FileExists = {`Builtin` ozparser_fileExists 2}

         proc {CompilerReadEvalLoop} File VS in
            File = {New TextFile init(name: stdin flags: [read])}
            {File readQuery(?VS)}
            {File close()}
            {{GetOPICompiler} feedVirtualString(VS)}
            {CompilerReadEvalLoop}
         end
      in
         proc {StartCompiler Env} Compiler OZRC in
            Compiler = {New CompilerInterfaceEmacs init()}
            {Compiler mergeEnv(Env)}
            {SetOPICompiler Compiler}

            % Try to load some ozrc file:
            OZRC = {OS.getEnv 'OZRC'}
            case OZRC \= false then
               {Compiler feedFile(OZRC)}
            elsecase {FileExists '~/.ozrc'} then
               {Compiler feedFile('~/.ozrc')}
            else
               skip
            end

            {CompilerReadEvalLoop}
         end
      end

      Compiler = compiler(start: StartCompiler
                          interface: interface(tk: CompilerInterfaceTk
                                               emacs: CompilerInterfaceEmacs
                                               quiet: CompilerInterfaceQuiet))
   in
      \insert 'Compiler.env'
   end
end
