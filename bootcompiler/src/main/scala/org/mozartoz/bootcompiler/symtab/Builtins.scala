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
    register(Value.IsDet)

    register(Space.NewSpace)
    register(Space.AskSpace)
    register(Space.AskVerboseSpace)
    register(Space.MergeSpace)
    register(Space.CommitSpace)
    register(Space.CloneSpace)
    register(Space.ChooseSpace)

    register(Record.Label)
    register(Record.Width)
    register(Record.WaitOr)

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
      "System::Show", in = 1, out = 0)

  object CreateThread extends BuiltinSymbol("CreateThread",
      "ModThread::Create", in = 1, out = 0)

  object Space {
    object NewSpace extends BuiltinSymbol("NewSpace",
        "ModSpace::New", in = 1, out = 1)

    object AskSpace extends BuiltinSymbol("AskSpace",
        "ModSpace::Ask", in = 1, out = 1)

    object AskVerboseSpace extends BuiltinSymbol("AskVerboseSpace",
        "ModSpace::AskVerbose", in = 1, out = 1)

    object MergeSpace extends BuiltinSymbol("MergeSpace",
        "ModSpace::Merge", in = 1, out = 1)

    object CommitSpace extends BuiltinSymbol("CommitSpace",
        "ModSpace::Commit", in = 2, out = 0)

    object CloneSpace extends BuiltinSymbol("CloneSpace",
        "ModSpace::Clone", in = 1, out = 1)

    object ChooseSpace extends BuiltinSymbol("ChooseSpace",
        "ModSpace::Choose", in = 1, out = 1)
  }

  object Value {
    object == extends BuiltinSymbol("Value.'=='",
        "Value::EqEq", in = 2, out = 1)
    object \= extends BuiltinSymbol("Value.'\\='",
        "Value::NotEqEq", in = 2, out = 1)

    object Wait extends BuiltinSymbol("Wait",
        "Value::Wait", in = 1, out = 0)

    object IsDet extends BuiltinSymbol("IsDet",
        "Value::IsDet", in = 1, out = 1)

    object dot extends BuiltinSymbol("Value.'.'",
        "Value::Dot", in = 2, out = 1)
  }

  object Number {
    object ~ extends BuiltinSymbol("Number.'~'",
        "Number::Negate", in = 1, out = 1)

    object + extends BuiltinSymbol("Number.'+'",
        "Number::Add", in = 2, out = 1)
    object - extends BuiltinSymbol("Number.'-'",
        "Number::Subtract", in = 2, out = 1)
    object * extends BuiltinSymbol("Number.'*'",
        "Number::Multiply", in = 2, out = 1)
    object / extends BuiltinSymbol("Float.'/'",
        "Float::Divide", in = 2, out = 1)
    object div extends BuiltinSymbol("Int.'div'",
        "Int::Div", in = 2, out = 1)
    object mod extends BuiltinSymbol("Int.'mod'",
        "Int::Mod", in = 2, out = 1)

    object < extends BuiltinSymbol("Number.'<'",
        "Value::LowerThan", in = 2, out = 1)
    object =< extends BuiltinSymbol("Number.'=<'",
        "Value::LowerEqual", in = 2, out = 1)
    object > extends BuiltinSymbol("Number.'>'",
        "Value::GreaterThan", in = 2, out = 1)
    object >= extends BuiltinSymbol("Number.'>='",
        "Value::GreaterEqual", in = 2, out = 1)
  }

  object Record {
    object Label extends BuiltinSymbol("Label",
        "Record::Label", in = 1, out = 1)
    object Width extends BuiltinSymbol("Width",
        "Record::Width", in = 1, out = 1)
    object WaitOr extends BuiltinSymbol("WaitOr",
        "Record::WaitOr", in = 1, out = 1)
  }
}
