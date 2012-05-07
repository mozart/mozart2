package org.mozartoz.bootcompiler
package ast

import scala.util.parsing.input.Positional

/** This class represents a node of the intermediate AST code.
 *  Each case subclass will represent a specific operation.
 */
abstract class Node extends Product with Cloneable with Positional {

  private[bootcompiler] def copyAttrs(tree: Node): this.type = {
    pos = tree.pos
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
