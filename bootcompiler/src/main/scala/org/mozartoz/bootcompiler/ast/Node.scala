package org.mozartoz.bootcompiler
package ast

import scala.util.parsing.input.Positional

/** Node of an Oz AST
 *
 *  There are two important subclasses of `Node`:
 *  [[org.mozartz.bootcompiler.ast.Statement]] and
 *  [[org.mozartz.bootcompiler.ast.Expression]], with obvious meanings.
 */
abstract class Node extends Product with Positional {

  /** Copy the attributes of a node into this `Node`. */
  private[bootcompiler] def copyAttrs(tree: Node): this.type = {
    pos = tree.pos
    this
  }

  /** Returns a pretty-printed representation of this `Node`
   *
   *  @param indent indentation to use when writing a line feed
   */
  def syntax(indent: String = ""): String

  override def toString = syntax()

  /** Pre-order walk of the subtree rooted at this `Node`
   *
   *  At each node, the `handler` is called. If it returns `true`, then the
   *  walk dives into the children of this `Node`. Otherwise, it does not.
   *
   *  @param handler handler callback
   */
  def walkBreak(handler: Node => Boolean): Unit = {
    if (handler(this)) {
      def inner(element: Any): Unit = {
        element match {
          case node:Node => node.walk(handler)
          case seq:Seq[_] => seq foreach inner
          case _ => ()
        }
      }

      productIterator foreach inner
    }
  }

  /** Pre-order walk of the subtree rooted at this `Node`
   *
   *  At each node, the `handler` is called.
   *
   *  @param handler handler callback
   */
  def walk[U](handler: Node => U): Unit = {
    walkBreak { node =>
      handler(node)
      true
    }
  }
}
