package org.mozartoz.bootcompiler
package symtab

object Symbol {
  private var _lastID = 0

  private def nextID() = synchronized {
    _lastID += 1
    _lastID
  }

  def newSynthetic() =
    new VariableSymbol("`x$" + (_lastID+1).toString() + "`", synthetic = true)
}

sealed abstract class Symbol(val name: String) {
  val id = Symbol.nextID()

  private var _owner: Abstraction = NoAbstraction
  def owner = _owner

  def setOwner(owner: Abstraction) {
    _owner = owner
  }

  val isDefined = true
  val isBuiltin = false
  val isFormal = false
  val isSynthetic = false

  def fullName = name + "~" + id

  override def toString() = fullName
}

class VariableSymbol(name: String, formal: Boolean = false,
    synthetic: Boolean = false) extends Symbol(name) {
  override val isFormal = formal
  override val isSynthetic = synthetic
}

class BuiltinSymbol(name: String,
    val arity: Int) extends Symbol(name) {
  override val isBuiltin = true
}

object NoSymbol extends Symbol("<NoSymbol>") {
  override val isDefined = false
}
