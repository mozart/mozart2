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

    register(Value.Wait)
    register(Value.WaitOr)
    register(Value.IsDet)

    register(Space.NewSpace)
    register(Space.AskSpace)
    register(Space.AskVerboseSpace)
    register(Space.MergeSpace)
    register(Space.CommitSpace)
    register(Space.ChooseSpace)

    register(Record.Label)
    register(Record.Width)

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
      ">=" -> Number.>=,

      "." -> Value.dot
  )

  object Show extends BuiltinSymbol("Show",
      "show", in = 1, out = 0)

  object CreateThread extends BuiltinSymbol("CreateThread",
      "createThread", in = 1, out = 0)

  object Space {
    object NewSpace extends BuiltinSymbol("NewSpace",
        "newSpace", in = 1, out = 1)

    object AskSpace extends BuiltinSymbol("AskSpace",
        "askSpace", in = 1, out = 1)

    object AskVerboseSpace extends BuiltinSymbol("AskVerboseSpace",
        "askVerboseSpace", in = 1, out = 1)

    object MergeSpace extends BuiltinSymbol("MergeSpace",
        "mergeSpace", in = 1, out = 1)

    object CommitSpace extends BuiltinSymbol("CommitSpace",
        "commitSpace", in = 2, out = 0)

    object ChooseSpace extends BuiltinSymbol("ChooseSpace",
        "chooseSpace", in = 1, out = 1)
  }

  object Value {
    object == extends BuiltinSymbol("Value.'=='",
        "equals", in = 2, out = 1)
    object \= extends BuiltinSymbol("Value.'\\='",
        "notEquals", in = 2, out = 1)

    object Wait extends BuiltinSymbol("Wait", "wait", in = 1, out = 0)
    object WaitOr extends BuiltinSymbol("WaitOr", "waitOr", in = 1, out = 1)

    object IsDet extends BuiltinSymbol("IsDet",
        "isDet", in = 1, out = 1)

    object dot extends BuiltinSymbol("Value.'.'",
        "dot", in = 2, out = 1)
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

  object Record {
    object Label extends BuiltinSymbol("Label", "label", in = 1, out = 1)
    object Width extends BuiltinSymbol("Width", "width", in = 1, out = 1)
  }
}
