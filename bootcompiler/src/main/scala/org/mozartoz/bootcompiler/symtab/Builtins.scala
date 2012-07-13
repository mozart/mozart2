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
  def register(builtin: Builtin) {
    builtins += (builtin.moduleName, builtin.name) -> builtin
  }

  /** Lookups a builtin by its module name and name */
  private def builtinByName(moduleName: String, name: String) =
    builtins((moduleName, name))

  /** Maps the symbol representation of a unary operator to its builtin */
  lazy val unaryOpToBuiltin = Map(
      "~" -> builtinByName("Number", "~"),

      "@" -> builtinByName("Cell", "access"),
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

      ":=" -> builtinByName("Cell", "exchangeFun")
  )

  lazy val getBootMM = builtinByName("Boot", "getBootMM")

  lazy val createThread = builtinByName("Thread", "create")

  lazy val makeRecordDynamic = builtinByName("Record", "makeDynamic")
  lazy val label = builtinByName("Record", "label")

  lazy val hasFeature = builtinByName("Value", "hasFeature")

  lazy val newName = builtinByName("Name", "new")

  lazy val attrGet = builtinByName("Object", "attrGet")
  lazy val attrPut = builtinByName("Object", "attrPut")
  lazy val attrExchangeFun = builtinByName("Object", "attrExchangeFun")

  lazy val cellOrAttrGet = builtinByName("Object", "cellOrAttrGet")
  lazy val cellOrAttrPut = builtinByName("Object", "cellOrAttrPut")
  lazy val cellOrAttrExchangeFun = builtinByName("Object",
      "cellOrAttrExchangeFun")

  lazy val plus1 = builtinByName("Int", "+1")
  lazy val minus1 = builtinByName("Int", "-1")

  lazy val cellExchange = builtinByName("Cell", "exchangeFun")
  lazy val cellAccess = builtinByName("Cell", "access")
  lazy val cellAssign = builtinByName("Cell", "assign")

  lazy val arrayPut = builtinByName("Array", "put")
  lazy val arrayExchange = builtinByName("Array", "exchangeFun")

  lazy val raise = builtinByName("Exception", "raise")
}
