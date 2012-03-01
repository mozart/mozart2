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

  object Show extends BuiltinSymbol("Show",
      "show", in = 1, out = 0)

  object CreateThread extends BuiltinSymbol("CreateThread",
      "createThread", in = 1, out = 0)

  object Value {
    object == extends BuiltinSymbol("Value.'=='",
        "equals", in = 2, out = 1)
    object \= extends BuiltinSymbol("Value.'\\='",
        "notEquals", in = 2, out = 1)
  }

  object Number {
    object ~ extends BuiltinSymbol("Number.'~'",
        "negate", in = 1, out = 1)

    object + extends BuiltinSymbol("Number.'+'",
        "add", in = 2, out = 1)
    object - extends BuiltinSymbol("Number.'-'",
        "subtract", in = 2, out = 1)
    object * extends BuiltinSymbol("Number.'*'",
        "multiply", in = 2, out = 1)
    object / extends BuiltinSymbol("Float.'/'",
        "divide", in = 2, out = 1)
    object div extends BuiltinSymbol("Int.'div'",
        "div", in = 2, out = 1)
    object mod extends BuiltinSymbol("Int.'mod'",
        "mod", in = 2, out = 1)

    object < extends BuiltinSymbol("Number.'<'",
        "lowerThan", in = 2, out = 1)
    object =< extends BuiltinSymbol("Number.'=<'",
        "lowerEqual", in = 2, out = 1)
    object > extends BuiltinSymbol("Number.'>'",
        "greaterThan", in = 2, out = 1)
    object >= extends BuiltinSymbol("Number.'>='",
        "greaterEqual", in = 2, out = 1)
  }
}
