package org.mozartoz.bootcompiler
package ast

/** This class represents a node of the intermediate AST code.
 *  Each case subclass will represent a specific operation.
 */
abstract class Node extends Product with Cloneable {

  /** The corresponding position in the source file */
  private var _pos: Position = NoPosition

  def pos: Position = _pos

  def setPos(p: Position): this.type = {
    _pos = p
    this
  }

  def setDefaultPos(p: Position): this.type = {
    if (!pos.isDefined)
      setPos(p)
    this
  }

  def syntax(indent: String = ""): String

  override def toString = syntax()

  /** Clone this instruction. */
  override def clone: Node =
    super.clone.asInstanceOf[Node]

  def walk[U](handler: Node => U) {
    handler(this)

    def inner(element: Any) {
      element match {
        case node:Node => node.walk(handler)
        case seq:Seq[_] => seq foreach inner
        case _ => ()
      }
    }

    productIterator foreach inner
  }
}
