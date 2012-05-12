package org.mozartoz.bootcompiler
package symtab

import oz._

import scala.collection.mutable.HashMap

class Builtins {
  val builtinByName = new HashMap[String, Builtin]
  val baseEnvironment = new HashMap[String, OzValue]

  lazy val topLevelEnvironment = Map.empty ++ baseEnvironment

  lazy val unaryOpToBuiltin = Map(
      //"~" -> builtinByName("Number.'~'"),

      "@" -> builtinByName("Cell.access")
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

      "." -> builtinByName("Value.'.'"),

      ":=" -> builtinByName("Cell.exchangeFun")
  )

  lazy val createThread = builtinByName("Thread.create")

  lazy val makeRecordDynamic = builtinByName("Record.makeDynamic")

  lazy val plus1 = builtinByName("Int.'+1'")
  lazy val minus1 = builtinByName("Int.'-1'")

  lazy val cellExchange = builtinByName("Cell.exchangeFun")
  lazy val cellAccess = builtinByName("Cell.access")
  lazy val cellAssign = builtinByName("Cell.assign")
}
