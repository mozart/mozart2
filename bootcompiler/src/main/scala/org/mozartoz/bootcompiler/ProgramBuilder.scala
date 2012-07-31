package org.mozartoz.bootcompiler

import ast._
import symtab._
import oz._
import transform._

/** Provides a method for building a program out of its parts */
object ProgramBuilder extends TreeDSL with TransformUtils {
  val treeCopy = new TreeCopier

  /** Builds a program that registers a user-defined module (i.e., a functor)
   *
   *  Given a URL <url> and a functor <functor>, the whole program is
   *  straightforward:
   *  {{{
   *  {<BootMM>.registerFunctor '<url>' <functor>}
   *  }}}
   */
  def buildModuleProgram(prog: Program, url: String, functor: Expression) {
    val registerProc = getBootMMProc(prog, "registerFunctor")
    prog.rawCode = registerProc.call(OzAtom(url), functor)
  }

  /** Builds a program that creates the base environment
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
   *  The program statement registers boot modules and the base module in the
   *  boot manager:
   *  {{{
   *  {<BootMM>.registerModule 'x-oz://boot/ModA' <constant Boot ModA>}
   *  ...
   *  {<BootMM>.registerModule 'x-oz://system/Base' base(<exports>)}
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
  def buildBaseEnvProgram(prog: Program,
      bootModulesMap: Map[String, Expression],
      baseFunctors: List[Expression]) {

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
      registerProc.call(OzAtom("x-oz://system/Base.ozf"), baseModule)
    }

    val registerBaseThingsStat = {
      registerBootModulesStat ~
      registerBaseModuleStat
    }

    val wholeProgram = {
      bases.foldRight(registerBaseThingsStat) {
        case ((statement, _), inner) =>
          RAWLOCAL (statement) IN {
            inner
          }
      }
    }

    prog.rawCode = wholeProgram
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

  /** Builds a linker program
   *
   *  The statement that is built is straightforward:
   *  {{{
   *  {<BootMM>.run '<mainURL>'}
   *  }}}
   */
  def buildLinkerProgram(prog: Program, urls: List[String], mainURL: String) {
    val runProc = getBootMMProc(prog, "run")
    prog.rawCode = runProc.call(OzAtom(mainURL))
  }

  private def getBootMMProc(prog: Program, proc: String): Expression = {
    getBootMM(prog) dot OzAtom(proc)
  }

  private def getBootMM(prog: Program): Expression = {
    Constant(OzBuiltin(prog.builtins.getBootMM)).callExpr()
  }
}
