%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   LambdaIn = ('% some input to test the classes LambdaScanner/LambdaParser\n'#
               'define f = lambda y.lambda z.(add y z);\n'#
               'define c = 17;\n'#
               'f c 7;\n'#
               '((f) c) 7\n')

   ExamplesDirectory = 'gump/examples/'
in
   functor
   import
      Compiler(evalExpression)
      GumpScanner
      GumpParser
      System
      Module
   export
      Return
   define
      fun {MakeScanner}
         {Compiler.evalExpression
          '\\switch +gump\n'#
          '\\gumpscannerprefix lambda\n'#
          '\\insert '#ExamplesDirectory#'LambdaScanner.ozg\n'#
          'in LambdaScanner\n'
          env('GumpScanner': GumpScanner
              'System': System
              'Module': Module) _}
      end

      fun {MakeParser}
         {Compiler.evalExpression
          '\\switch +gump\n'#
          '\\switch +gumpparseroutputsimplified +gumpparserverbose\n'#
          '\\gumpparserexpect 0\n'#
          '\\insert '#ExamplesDirectory#'LambdaParser.ozg\n'#
          'in LambdaParser\n'
          env('GumpParser': GumpParser
              'System': System) _}
      end

      Return =
      gump([scanner(equal(proc {$ Res}
                             LambdaScanner = {MakeScanner}
                             MyScanner = {New LambdaScanner init()}
                             fun {GetTokens} T V in
                                {MyScanner getToken(?T ?V)}
                                case T of 'EOF' then nil
                                else T#V|{GetTokens}
                                end
                             end
                          in
                             {MyScanner scanVirtualString(LambdaIn)}
                             Res = {GetTokens}
                             {MyScanner close()}
                          end
                          ['define'#unit id#f '='#unit lambda#unit
                           id#y '.'#unit lambda#unit id#z '.'#unit '('#unit
                           id#add id#y id#z ')'#unit ';'#unit 'define'#unit
                           id#c '='#unit int#17 ';'#unit id#f id#c int#7
                           ';'#unit '('#unit '('#unit id#f ')'#unit id#c
                           ')'#unit int#7])
                    keys: [tools gump scanner])
            parser(equal(fun {$}
                            LambdaScanner = {MakeScanner}
                            LambdaParser = {MakeParser}
                            MyScanner = {New LambdaScanner init()}
                            MyParser = {New LambdaParser init(MyScanner)}
                            Definitions Terms Status
                         in
                            {MyScanner scanVirtualString(LambdaIn)}
                            {MyParser
                             parse(program(?Definitions ?Terms) ?Status)}
                            {MyScanner close()}
                            Status#Definitions#Terms
                         end
                         true#
                         [definition(f lambda(y lambda(z apply(apply(id(add 2)
                                                                     id(y 2))
                                                               id(z 2)))))
                          definition(c int(17))]#
                         [apply(apply(id(f 4) id(c 4)) int(7))
                          apply(apply(id(f 5) id(c 5)) int(7))])
                   keys: [tools gump scanner parser])])
   end
end
