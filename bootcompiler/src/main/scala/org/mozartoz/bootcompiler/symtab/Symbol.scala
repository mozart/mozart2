package org.mozartoz.bootcompiler
package symtab

import oz._

/** Companion object of [[org.mozartoz.bootcompiler.symtab.Symbol]] */
object Symbol {
  /** Counter for numeric IDs */
  private val nextID = (new util.Counter).next _
}

/** Symbol, i.e., identity of a variable */
sealed class Symbol(_name: String, formal: Boolean = false,
    capture: Boolean = false, synthetic: Boolean = false,
    global: Boolean = false) {

  // Identity

  /** Numeric ID for the symbol (useful for debugging) */
  val id = Symbol.nextID()

  /** Name */
  val name = if (_name.isEmpty) "`x$" + id.toString() + "`" else _name

  // Owning abstraction

  /** Abstraction that owns this symbol */
  private var _owner: Abstraction = NoAbstraction

  /** Abstraction that owns this symbol */
  def owner = _owner

  /** Sets the owning abstraction */
  def setOwner(owner: Abstraction): Unit = {
    _owner = owner
  }

  // Properties

  /** Returns true unless this symbol is NoSymbol */
  val isDefined = true

  /** Returns true if this symbol is a formal parameter */
  val isFormal = formal

  /** Returns true if this symbol is a capture in a pattern matching */
  val isCapture = capture

  /** Returns true if this symbol is synthetic (invented by the compiler) */
  val isSynthetic = synthetic

  /** Returns true if this symbol is a global variable */
  val isGlobal = global

  /** Full name (with numeric ID) */
  def fullName = name + "~" + id

  override def toString() = fullName

  // Pattern matching management

  /** Capture index (only meaningful if `isCapture == true`) */
  var captureIndex: Long = -1

  // Global variables management

  /** Copy this symbol as a global variable */
  def copyAsGlobal() =
    new Symbol(name, formal = false, capture = false,
        synthetic = true, global = true)

  // Constant folding

  /** If defined, the constant to which this symbol collapses to */
  var constant: Option[OzValue] = None

  /** Returns true if this symbol collapses to a constant */
  def isConstant = constant.isDefined

  /** Sets a constant that this symbol collapses to */
  def setConstant(value: OzValue) = constant = Some(value)
}

/** Dummy symbol */
object NoSymbol extends Symbol("<NoSymbol>") {
  override val isDefined = false
}
