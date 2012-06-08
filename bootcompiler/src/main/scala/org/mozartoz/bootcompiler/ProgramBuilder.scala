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
   *    <li>The actual statement of the program</li>
   *  </ul>
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
   *     BootModA = <constant lookup up in the builtin modules map
   *     ...
   *  in
   *     <contents of the prepare section above>
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
      baseFunctors: List[Expression], programStat: Statement) {

    val baseDeclarations =
      baseFunctors map (baseFunctorToBaseDeclarations(bootModulesMap, _))

    val wholeProgram = {
      RAWLOCAL (baseDeclarations:_*) IN {
        programStat
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
