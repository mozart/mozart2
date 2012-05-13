package org.mozartoz.bootcompiler

import ast._
import symtab._
import oz._
import transform._

object ProgramBuilder extends TreeDSL with TransformUtils {
  val treeCopy = new TreeCopier

  def build(prog: Program, bootModulesMap: Map[String, Expression],
      baseFunctor: Expression, programStat: Statement) {

    val FunctorExpression(_, baseRequire,
        Some(LocalStatement(baseDecls, baseStat)),
        Nil, None, baseExports) = baseFunctor

    val bootModulesDecls = for {
      imp @ FunctorImport(moduleVar, Nil, Some(url)) <- baseRequire
    } yield {
      atPos(imp) {
        BindStatement(moduleVar, bootModulesMap(url))
      }
    }

    val baseDeclarations = {
      val baseDeclsAsStats = baseDecls map (_.asInstanceOf[Statement])

      LOCAL (bootModulesDecls:_*) IN {
        statsAndStatToStat(baseDeclsAsStats, baseStat)
      }
    }

    val wholeProgram = {
      LOCAL (baseDeclarations) IN {
        programStat
      }
    }

    prog.rawCode = wholeProgram
  }
}
