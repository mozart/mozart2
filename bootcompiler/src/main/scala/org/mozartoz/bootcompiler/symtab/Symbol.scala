package org.mozartoz.bootcompiler
package symtab

object Symbol {
  private var _lastID = 0

  private def nextID() = synchronized {
    _lastID += 1
    _lastID
  }

  def newSynthetic(name: String, formal: Boolean = false): VariableSymbol =
    new VariableSymbol(name, formal = formal, synthetic = true)

  def newSynthetic(): VariableSymbol =
    newSynthetic("`x$" + (_lastID+1).toString() + "`")
}

sealed abstract class Symbol(val name: String) {
  val id = Symbol.nextID()

  private var _owner: Abstraction = NoAbstraction
  def owner = _owner

  def setOwner(owner: Abstraction): this.type = {
    _owner = owner
    this
  }

  val isDefined = true
  val isFormal = false
  val isCapture = false
  val isSynthetic = false
  val isGlobal = false

  def fullName = name + "~" + id

  override def toString() = fullName
}

class VariableSymbol(name: String, formal: Boolean = false,
    capture: Boolean = false, synthetic: Boolean = false,
    global: Boolean = false) extends Symbol(name) {
  override val isFormal = formal
  override val isCapture = capture
  override val isSynthetic = synthetic
  override val isGlobal = global

  var captureIndex: Long = -1

  def copyAsGlobal() =
    new VariableSymbol(name, formal = false, capture = false,
        synthetic = true, global = true)
}

object NoSymbol extends Symbol("<NoSymbol>") {
  override val isDefined = false
}
