package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.HashMap

class Builtins {
  val builtinByName = new HashMap[String, BuiltinSymbol]
  val baseEnvironment = new HashMap[String, BuiltinSymbol]

  lazy val topLevelEnvironment = Map.empty ++ baseEnvironment

  lazy val unaryOpToBuiltin = Map(
      "~" -> builtinByName("Number.'~'")
  )

  lazy val binaryOpToBuiltin = Map(
      "==" -> builtinByName("Value.'=='"),
      "\\=" -> builtinByName("Value.'\\='"),

      "+" -> builtinByName("Number.'+'"),
      "-" -> builtinByName("Number.'-'"),
      "*" -> builtinByName("Number.'*'"),
      "/" -> builtinByName("Float.'/'"),
      "div" -> builtinByName("Int.div"),
      "mod" -> builtinByName("Int.mod"),

      /*"<" -> builtinByName("Value.'<'"),
      "=<" -> builtinByName("Value.'=<'"),
      ">" -> builtinByName("Value.'>'"),
      ">=" -> builtinByName("Value.'>='"),*/

      "." -> builtinByName("Value.'.'")
  )

  lazy val createThread = builtinByName("Thread.create")

  lazy val plus1 = builtinByName("Int.'+1'")
  lazy val minus1 = builtinByName("Int.'-1'")
}
