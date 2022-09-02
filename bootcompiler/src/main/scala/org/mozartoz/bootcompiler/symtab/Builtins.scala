package org.mozartoz.bootcompiler
package symtab

import oz._

import scala.collection.mutable.HashMap

/** Management of the builtins available to a program
 *
 *  The available builtins must be registered externally with `register`
 *  before naming.
 */
class Builtins {
  /** Map from (moduleName, builtinName) to builtins */
  private val builtins = new HashMap[(String, String), Builtin]

  /** Registers a builtin */
  def register(builtin: Builtin): Unit = {
    builtins += (builtin.moduleName, builtin.name) -> builtin
  }

  /** Lookups a builtin by its module name and name */
  private def builtinByName(moduleName: String, name: String) =
    builtins((moduleName, name))

  /** Maps the symbol representation of a unary operator to its builtin */
  lazy val unaryOpToBuiltin = Map(
      "~" -> builtinByName("Number", "~"),

      "@" -> builtinByName("Value", "catAccess"),
      "!!" -> builtinByName("Value", "readOnly")
  )

  /** Maps the symbol representation of a binary operator to its builtin */
  lazy val binaryOpToBuiltin = Map(
      "==" -> builtinByName("Value", "=="),
      "\\=" -> builtinByName("Value", "\\="),

      "+" -> builtinByName("Number", "+"),
      "-" -> builtinByName("Number", "-"),
      "*" -> builtinByName("Number", "*"),
      "/" -> builtinByName("Float", "/"),
      "div" -> builtinByName("Int", "div"),
      "mod" -> builtinByName("Int", "mod"),

      "=<" -> builtinByName("Value", "=<"),
      "<" -> builtinByName("Value", "<"),
      ">=" -> builtinByName("Value", ">="),
      ">" -> builtinByName("Value", ">"),

      "." -> builtinByName("Value", "."),

      ":=" -> builtinByName("Value", "catExchange")
  )

  lazy val waitNeeded = builtinByName("Value", "waitNeeded")

  lazy val dotAssign = builtinByName("Value", "dotAssign")
  lazy val dotExchange = builtinByName("Value", "dotExchange")

  lazy val catAccess = builtinByName("Value", "catAccess")
  lazy val catAssign = builtinByName("Value", "catAssign")
  lazy val catExchange = builtinByName("Value", "catExchange")

  lazy val catAccessOO = builtinByName("Value", "catAccessOO")
  lazy val catAssignOO = builtinByName("Value", "catAssignOO")
  lazy val catExchangeOO = builtinByName("Value", "catExchangeOO")

  lazy val attrGet = builtinByName("Object", "attrGet")
  lazy val attrPut = builtinByName("Object", "attrPut")
  lazy val attrExchangeFun = builtinByName("Object", "attrExchangeFun")

  lazy val createThread = builtinByName("Thread", "create")

  lazy val makeRecordDynamic = builtinByName("Record", "makeDynamic")
  lazy val label = builtinByName("Record", "label")

  lazy val hasFeature = builtinByName("Value", "hasFeature")

  lazy val newName = builtinByName("Name", "new")

  lazy val plus1 = builtinByName("Int", "+1")
  lazy val minus1 = builtinByName("Int", "-1")

  lazy val raise = builtinByName("Exception", "raise")
  lazy val raiseError = builtinByName("Exception", "raiseError")
  lazy val fail = builtinByName("Exception", "fail")

  lazy val getProperty = builtinByName("Property", "get")

  lazy val dictionaryPut = builtinByName("Dictionary", "put")
}
