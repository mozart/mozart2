package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.ArrayBuffer

import ast._

object Abstraction {
  private var _lastID = 0
  private def nextID() = {
    _lastID += 1
    _lastID
  }
}

class Abstraction(val owner: Abstraction, val name: String) {
  val id = Abstraction.nextID()

  val formals = new ArrayBuffer[VariableSymbol]
  val locals = new ArrayBuffer[VariableSymbol]

  val flags = new ArrayBuffer[String]

  var body: Statement = _

  def arity = formals.size

  def acquire(symbol: VariableSymbol) {
    symbol.setOwner(this)
    if (symbol.isFormal) formals += symbol
    else locals += symbol
  }

  def fullName: String =
    if (owner == NoAbstraction) name
    else owner.fullName + "::" + name

  def newAbstraction(name: String) =
    new Abstraction(this, name)

  def dump() {
    println(fullName + ": P/" + arity.toString())
    println("  formals: " + (formals mkString " "))
    println("  locals: " + (locals mkString " "))
    println(body)
  }
}

object NoAbstraction extends Abstraction(null, "<NoAbstraction>") {
  override val owner = this
}
