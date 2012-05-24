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
   *    <li>A base functor that defines the Base environment</li>
   *    <li>The actual statement of the program</li>
   *  </ul>
   *
   *  The base functor must have the following structure:
   *  {{{
   *  functor
   *
   *  require
   *     BootModA at 'x-oz://boot/ModA'
   *     ...
   *
   *  define
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
   *     <contents of the define section above>
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
