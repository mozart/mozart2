package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.HashMap

class Builtins {
  lazy val topLevelEnvironment = makeTopLevelEnvironment()

  private def makeTopLevelEnvironment() = {
    val registry = new HashMap[String, Symbol]

    def register(builtin: Symbol) {
      registry += builtin.name -> builtin
    }

    register(Show)

    Map.empty ++ registry
  }

  object Show extends BuiltinSymbol("Show", 1)

  object CreateThread extends BuiltinSymbol("CreateThread", 1)
}
