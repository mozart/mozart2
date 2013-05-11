package org.mozartoz.bootcompiler

import scala.util.parsing.input.{ Position, NoPosition, Positional }

import oz._

/** Classes representing the AST of Oz code
 *
 *  Provides general utilities for working with ASTs.
 */
package object ast {
  // Utils

  def escapePseudoChars(name: String, delim: Char) = {
    val result = new StringBuffer
    name foreach { c =>
      if (c == '\\' || c == delim)
        result append '\\'
      result append c
    }
    result.toString
  }

  /** Gives a position to a subtree
   *
   *  The position `pos` is given to `node` and all its subtrees that do not
   *  yet have a position. If a subtree has a position, its children are not
   *  explored.
   *
   *  This method is mostly useful for synthesized AST subtrees, as in
   *  {{{
   *  val synthesized = atPos(oldTree.pos) {
   *    buildTheTree()
   *  }
   *  }}}
   *
   *  @tparam A type of node
   *  @param pos position to give to the subtree
   *  @param node root of the subtree to give a position to
   *  @return the node `node`
   */
  def atPos[A <: Node](pos: Position)(node: A): A = {
    node walkBreak { subNode =>
      if (subNode.pos ne NoPosition) false
      else {
        subNode.setPos(pos)
        true
      }
    }

    node
  }

  /** Gives a position to a subtree
   *
   *  This is similar to the other overload of `atPos()`, except that it takes
   *  a [[scala.util.parsing.input.Positional]]. The position is extracted from
   *  the given positional.
   */
  def atPos[A <: Node](positional: Positional)(node: A): A =
    atPos(positional.pos)(node)

  /** Builds an Oz List expression from a list of expressions */
  def exprListToListExpr(elems: List[Expression]): Expression = {
    if (elems.isEmpty) Constant(OzAtom("nil"))
    else cons(elems.head, exprListToListExpr(elems.tail))
  }

  /** Builds an Oz Cons pair */
  def cons(head: Expression, tail: Expression) = atPos(head) {
    Record(Constant(OzAtom("|")),
        List(withAutoFeature(head), withAutoFeature(tail)))
  }

  /** Builds an Oz #-tuple */
  def sharp(fields: List[Expression]) = {
    if (fields.isEmpty) Constant(OzAtom("#"))
    else {
      atPos(fields.head) {
        Record(Constant(OzAtom("#")), fields map withAutoFeature)
      }
    }
  }

  /** Equips an expression with an AutoFeature */
  def withAutoFeature(expr: Expression): RecordField = atPos(expr) {
    RecordField(AutoFeature(), expr)
  }
}
