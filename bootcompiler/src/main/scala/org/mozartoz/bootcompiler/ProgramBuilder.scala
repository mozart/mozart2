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

    val initialization = buildInitialization(prog, bootModulesMap,
        baseFunctors)

    val registerProgramFunctorsStat = CompoundStatement {
      val registerProc = getBootMMProc(prog, "registerFunctor")
      for ((url, functor) <- programFunctors) yield {
        val functorVar = RawVariable("$Functor")
        RAWLOCAL (functorVar) IN {
          (functorVar === functor) ~
          registerProc.call(OzAtom(url), functorVar)
        }
      }
    }

    val run = {
      val runProc = getBootMMProc(prog, "run")
      runProc.call(OzAtom(mainFunctorURL))
    }

    val program = {
      initialization ~
      registerProgramFunctorsStat ~
      run
    }

    prog.rawCode = program
  }

  private def buildInitialization(prog: Program,
      bootModulesMap: Map[String, Expression],
      baseFunctors: List[Expression]): Statement = {

    val bases = baseFunctors map (parseBaseEnv(bootModulesMap, _))

    for {
      (_, fields) <- bases
      RecordField(Constant(OzAtom(name)), _) <- fields
    } {
      prog.baseDeclarations += name
    }

    val registerBootModulesStat = CompoundStatement {
      val registerProc = getBootMMProc(prog, "registerModule")
      for ((url, module) <- bootModulesMap.toList) yield {
        registerProc.call(OzAtom(url), module)
      }
    }

    val registerBaseModuleStat = {
      val registerProc = getBootMMProc(prog, "registerModule")
      val baseModule = Record(OzAtom("base"), bases.flatMap(_._2))
      registerProc.call(OzAtom("x-oz://system/Base"), baseModule)
    }

    val registerBaseThingsStat = {
      registerBootModulesStat ~
      registerBaseModuleStat
    }

    bases.foldRight(registerBaseThingsStat) {
      case ((statement, _), inner) =>
        RAWLOCAL (statement) IN {
          inner
        }
    }
  }

  private def parseBaseEnv(bootModulesMap: Map[String, Expression],
      baseFunctor: Expression): (Statement, List[RecordField]) = {

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

    val statement = {
      RAWLOCAL (bootModulesDecls:_*) IN {
        statsAndStatToStat(baseDeclsAsStats, baseStat)
      }
    }

    val baseEnvRecordFields = for {
      FunctorExport(feature, value) <- baseExports
    } yield RecordField(feature, value)

    (statement, baseEnvRecordFields)
  }

  private def getBootMMProc(prog: Program, proc: String): Expression = {
    getBootMM(prog) dot OzAtom(proc)
  }

  private def getBootMM(prog: Program): Expression = {
    Constant(OzBuiltin(prog.builtins.getBootMM)).callExpr()
  }
}
