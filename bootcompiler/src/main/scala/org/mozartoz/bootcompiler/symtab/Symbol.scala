package org.mozartoz.bootcompiler
package symtab

object Symbol {
  private var _lastID = 0

  private def nextID() = synchronized {
    _lastID += 1
    _lastID
  }
}

sealed abstract class Symbol(val owner: Abstraction, val name: String) {
  val id = Symbol.nextID()

  val isDefined = true
  val isBuiltin = false
  val isSynthetic = false

  def fullName = name + "~" + id

  override def toString() = fullName
}

class VariableSymbol(owner: Abstraction, name: String,
    synthetic: Boolean = false) extends Symbol(owner, name) {
  override val isSynthetic = synthetic
}

class BuiltinSymbol(name: String,
    val arity: Int) extends Symbol(NoAbstraction, name) {
  override val isBuiltin = true
}

object NoSymbol extends Symbol(NoAbstraction, "<NoSymbol>") {
  override val isDefined = false
}
