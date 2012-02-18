package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.ListBuffer

import ast._

class Program(var rawCode: Statement) {
  def isRawCode = rawCode ne null

  val builtins = new Builtins

  val topLevelAbstraction = new Abstraction(NoAbstraction, "<TopLevel>")

  val abstractions = new ListBuffer[Abstraction]
  abstractions += topLevelAbstraction

  def dump() {
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
