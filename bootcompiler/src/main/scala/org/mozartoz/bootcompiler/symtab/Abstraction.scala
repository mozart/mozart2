package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.{ ArrayBuffer, Map }

import ast._
import bytecode._

object Abstraction {
  private var _lastID = 0
  private def nextID() = {
    _lastID += 1
    _lastID
  }
}

class Abstraction(val owner: Abstraction, val name: String) {
  val id = Abstraction.nextID()

  val formals = new ArrayBuffer[Symbol]
  val locals = new ArrayBuffer[Symbol]
  val globals = new ArrayBuffer[Symbol]

  val flags = new ArrayBuffer[String]

  var body: Statement = _

  private val _freeVarToGlobal = Map[Symbol, Symbol]()

  val codeArea = new CodeArea(this)

  def arity = formals.size

  def acquire(symbol: Symbol) {
    symbol.setOwner(this)
    if (symbol.isFormal) formals += symbol
    else if (symbol.isGlobal) globals += symbol
    else locals += symbol
  }

  def fullName: String =
    if (owner == NoAbstraction) name
    else owner.fullName + "::" + name

  def newAbstraction(name: String) =
    new Abstraction(this, name)

  def freeVarToGlobal(symbol: Symbol) = {
    require(symbol.owner ne this)
    _freeVarToGlobal.getOrElseUpdate(symbol, {
      val global = symbol.copyAsGlobal()
      acquire(global)
      global
    })
  }

  def dump(includeByteCode: Boolean = true) {
    println(fullName + ": P/" + arity.toString())
    println("  formals: " + (formals mkString " "))
    println("  locals: " + (locals mkString " "))
    println("  globals: " + (globals mkString " "))

    println()
    println(body)

    if (codeArea.isDefined) {
      println()
      codeArea.dump(includeByteCode)
    }
  }
}

object NoAbstraction extends Abstraction(null, "<NoAbstraction>") {
  override val owner = this
}
