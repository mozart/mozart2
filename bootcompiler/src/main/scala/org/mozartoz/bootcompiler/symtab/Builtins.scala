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

  object Show extends BuiltinSymbol("Show", in = 1, out = 0)

  object CreateThread extends BuiltinSymbol("CreateThread", in = 1, out = 0)

  object Value {
    object == extends BuiltinSymbol("Value.'=='", in = 2, out = 1)
    object \= extends BuiltinSymbol("Value.'\\='", in = 2, out = 1)
  }

  object Number {
    object ~ extends BuiltinSymbol("Number.'~'", in = 1, out = 1)

    object + extends BuiltinSymbol("Number.'+'", in = 2, out = 1)
    object - extends BuiltinSymbol("Number.'-'", in = 2, out = 1)
    object * extends BuiltinSymbol("Number.'*'", in = 2, out = 1)
    object / extends BuiltinSymbol("Number.'/'", in = 2, out = 1)
    object div extends BuiltinSymbol("Number.'div'", in = 2, out = 1)
    object mod extends BuiltinSymbol("Number.'mod'", in = 2, out = 1)

    object < extends BuiltinSymbol("Number.'<'", in = 2, out = 1)
    object =< extends BuiltinSymbol("Number.'=<'", in = 2, out = 1)
    object > extends BuiltinSymbol("Number.'>'", in = 2, out = 1)
    object >= extends BuiltinSymbol("Number.'>='", in = 2, out = 1)
  }
}
