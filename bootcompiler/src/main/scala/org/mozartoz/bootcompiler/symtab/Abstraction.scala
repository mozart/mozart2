package org.mozartoz.bootcompiler
package symtab

import scala.collection.mutable.ListBuffer

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

  val formals = new ListBuffer[VariableSymbol]
  val locals = new ListBuffer[VariableSymbol]

  val flags = new ListBuffer[String]

  var body: Statement = _

  def arity = formals.size

  def fullName: String =
    if (owner == NoAbstraction) name
    else owner.fullName + "::" + name

  private var _lastSyntheticNum = 0
  private def nextSyntheticName() = {
    _lastSyntheticNum += 1
    "`X$" + _lastSyntheticNum + "`"
  }

  def newAbstraction(name: String) =
    new Abstraction(this, name)

  def dump() {
    println(name + ": P/" + arity.toString())
    println("  formals: " + (formals mkString " "))
    println(body)
  }
}

object NoAbstraction extends Abstraction(null, "<NoAbstraction>") {
  override val owner = this
}
