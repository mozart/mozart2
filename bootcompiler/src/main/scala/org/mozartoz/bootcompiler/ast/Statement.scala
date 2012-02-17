package org.mozartoz.bootcompiler
package ast

abstract class Statement extends Element {

}

case class TokenStatement(token: Any) extends Statement {
  override def toString() = token.toString()
}
