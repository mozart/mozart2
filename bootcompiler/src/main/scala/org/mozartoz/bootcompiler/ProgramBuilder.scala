package org.mozartoz.bootcompiler

import ast._
import symtab._
import oz._
import transform._

/** Provides a method for building a program out of its parts */
object ProgramBuilder extends TreeDSL with TransformUtils {
  val treeCopy = new TreeCopier

  /** Builds a program from its parts
   *
   *  A program has three parts:
   *
   *  <ul>
   *    <li>Several builtin modules</li>
   *    <li>One or more base functors that define the Base environment</li>
   *    <li>A map from URLs to non-base functors that define the program</li>
   *  </ul>
   *
   *  The URL of the main non-base functor must be provided too.
   *
   *  The base functors must have the following structure:
   *  {{{
   *  functor
   *
   *  require
   *     BootModA at 'x-oz://boot/ModA'
   *     ...
   *
   *  prepare
   *     ...
   *
   *  exports
   *     'SomeVar':SomeVar
   *     ...
   *  end
   *  }}}
   *
   *  Boot modules are lookup up in the builtin modules map, and resolved
   *  statically. These two parts define the ''base declarations'' as so
   *  {{{
   *  local
   *     BootModA = <constant lookup up in the builtin modules map>
   *     ...
   *  in
   *     <contents of the prepare section above>
   *  end
   *  }}}
   *
   *  The program functors make up the program statement as follows:
   *  {{{
   *  local
   *     `Functor:<URL1>` = <content of File1.oz>
   *     `Functor:<URL2>` = <content of File2.oz>
   *     ...
   *  in
   *     {`Boot:RegisterModule` '<BootURL1>' <constant boot module 1>}
   *     {`Boot:RegisterModule` '<BootURL2>' <constant boot module 2>}
   *     ...
   *
   *     {`Boot:RegisterFunctor` '<URL1>' `Functor:<URL1>`}
   *     {`Boot:RegisterFunctor` '<URL2>' `Functor:<URL2>`}
   *     ...
   *
   *     {`Boot:Run` '<MainURL>'}
   *  end
   *  }}}
   *
   *  The whole program is assembled like this:
   *  {{{
   *  local
   *     <base declarations>
   *  in
   *     <program statement>
   *  end
   *  }}}
   */
  def build(prog: Program, bootModulesMap: Map[String, Expression],
      baseFunctors: List[Expression],
      programFunctors: List[(String, Expression)],
      mainFunctorURL: String) {

    def functorVar(url: String) =
      RawVariable("`Functor:"+url+"`")

    val bootModule = Constant(OzBuiltin(prog.builtins.getBootMM))
    val bootMM = RawVariable("$BootMM")

    val baseDeclarations =
      baseFunctors map (baseFunctorToBaseDeclarations(bootModulesMap, _))

    val programFunctorsDecls =
      for ((url, functorExpr) <- programFunctors) yield {
        functorVar(url) === functorExpr
      }

    val registerBootModulesStat = CompoundStatement {
      val registerProc = bootMM dot OzAtom("registerModule")
      for ((url, module) <- bootModulesMap.toList) yield {
        registerProc.call(OzAtom(url), module)
      }
    }

    val registerFunctorsStat = CompoundStatement {
      val registerProc = bootMM dot OzAtom("registerFunctor")
      for ((url, _) <- programFunctors) yield {
        registerProc.call(OzAtom(url), functorVar(url))
      }
    }

    val run = {
      val runProc = bootMM dot OzAtom("run")
      runProc.call(OzAtom(mainFunctorURL))
    }

    val wholeProgram = {
      RAWLOCAL (baseDeclarations:_*) IN {
        RAWLOCAL ((bootMM :: programFunctorsDecls):_*) IN {
          Constant(OzBuiltin(prog.builtins.getBootMM)).call(bootMM) ~
          registerBootModulesStat ~
          registerFunctorsStat ~
          run
        }
      }
    }

    prog.rawCode = wholeProgram
  }

  private def baseFunctorToBaseDeclarations(
      bootModulesMap: Map[String, Expression], baseFunctor: Expression) = {
    val FunctorExpression(_, baseRequire,
        Some(RawLocalStatement(baseDecls, baseStat)),
        Nil, None, baseExports) = baseFunctor

    val bootModulesDecls = for {
      imp @ FunctorImport(moduleVar, Nil, Some(url)) <- baseRequire
    } yield {
      atPos(imp) {
        BindStatement(moduleVar, bootModulesMap(url))
      }
    }

    val baseDeclsAsStats = baseDecls map {
      case stat:Statement => stat
      case v:RawVariable => atPos(v)(v === UnboundExpression())
    }

    RAWLOCAL (bootModulesDecls:_*) IN {
      statsAndStatToStat(baseDeclsAsStats, baseStat)
    }
  }
}
