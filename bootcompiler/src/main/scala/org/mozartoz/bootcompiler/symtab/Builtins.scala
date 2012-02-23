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

  val unaryOpToBuiltin = Map(
      "~" -> Number.~
  )

  val binaryOpToBuiltin = Map(
      "==" -> Value.==,
      "\\=" -> Value.\=,

      "+" -> Number.+,
      "-" -> Number.-,
      "*" -> Number.*,
      "/" -> Number./,
      "div" -> Number.div,
      "mod" -> Number.mod,

      "<" -> Number.<,
      "=<" -> Number.=<,
      ">" -> Number.>,
      ">=" -> Number.>=
  )

  object Show extends BuiltinSymbol("Show", 1)

  object CreateThread extends BuiltinSymbol("CreateThread", 1)

  object Value {
    object == extends BuiltinSymbol("Value.'=='", 3)
    object \= extends BuiltinSymbol("Value.'\\='", 3)
  }

  object Number {
    object ~ extends BuiltinSymbol("Number.'~'", 2)

    object + extends BuiltinSymbol("Number.'+'", 3)
    object - extends BuiltinSymbol("Number.'-'", 3)
    object * extends BuiltinSymbol("Number.'*'", 3)
    object / extends BuiltinSymbol("Number.'/'", 3)
    object div extends BuiltinSymbol("Number.'div'", 3)
    object mod extends BuiltinSymbol("Number.'mod'", 3)

    object < extends BuiltinSymbol("Number.'<'", 3)
    object =< extends BuiltinSymbol("Number.'=<'", 3)
    object > extends BuiltinSymbol("Number.'>'", 3)
    object >= extends BuiltinSymbol("Number.'>='", 3)
  }
}
