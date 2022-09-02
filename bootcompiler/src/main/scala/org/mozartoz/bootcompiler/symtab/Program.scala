package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.{ ListBuffer, ArrayBuffer, HashMap }
import scala.util.parsing.input.{ Position, NoPosition, Positional }

import ast._
import util._

/** Program to be compiled */
class Program(val isBaseEnvironment: Boolean = false) {
  /** Before flattening, abstract syntax tree of the whole program */
  var rawCode: Statement = SkipStatement()

  /** Returns `true` if the program is currently represented as a full AST */
  def isRawCode = rawCode ne null

  /** Builtin manager */
  val builtins = new Builtins

  /** Variables declared by the base environment */
  val baseDeclarations = new ArrayBuffer[String]

  /** Map of base symbols (only in base environment mode) */
  val baseSymbols = new HashMap[String, Symbol]

  /** Implicit top-level abstraction */
  val topLevelAbstraction =
    new Abstraction(NoAbstraction, "<TopLevel>", NoPosition)

  /** The <Base> parameter of the top-level abstraction (only in normal mode)
   *  It contains the base environment
   */
  val baseEnvSymbol =
    if (isBaseEnvironment) NoSymbol
    else new Symbol("<Base>", synthetic = true, formal = true)
  if (!isBaseEnvironment)
    topLevelAbstraction.acquire(baseEnvSymbol)

  /** The <Result> parameter of the top-level abstraction */
  val topLevelResultSymbol =
    new Symbol("<Result>", synthetic = true, formal = true)
  topLevelAbstraction.acquire(topLevelResultSymbol)

  /** After flattening, list of the abstractions */
  val abstractions = new ListBuffer[Abstraction]
  abstractions += topLevelAbstraction

  /** Compile errors */
  val errors = new ArrayBuffer[(String, Position)]

  /** Returns `true` if at least one compile error was reported */
  def hasErrors = !errors.isEmpty

  /** Reports a compile error
   *  @param message error message
   *  @param pos position of the error
   */
  def reportError(message: String, pos: Position = NoPosition): Unit = {
    errors += ((message, pos))
  }

  /** Reports a compile error
   *  @param message error message
   *  @param positional positional that holds the position of the error
   */
  def reportError(message: String, positional: Positional): Unit = {
    reportError(message, positional.pos)
  }

  /** Dumps the program on standard error */
  def dump(): Unit = {
    if (isRawCode)
      println(rawCode)
    else {
      for (abstraction <- abstractions) {
        abstraction.dump()
        println()
      }
    }
  }
}
