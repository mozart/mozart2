package org.mozartoz.bootcompiler
package ast

import symtab._

trait SymbolNode extends Node {
  var symbol: Symbol = NoSymbol

  def withSymbol(sym: Symbol): this.type = {
    symbol = sym
    this
  }

  override def copyAttrs(tree: Node): this.type = {
    super.copyAttrs(tree)

    tree match {
      case symTree:SymbolNode => symbol = symTree.symbol
      case _ => ()
    }

    this
  }
}

trait FormalArg extends Node with SymbolNode

trait Declaration extends Node

trait InfixSyntax extends Node {
  val left: Node
  val right: Node
  protected val opSyntax: String

  def syntax(indent: String) = {
    val untilOp = left.syntax(indent) + opSyntax
    val rightIndent = indent + " "*untilOp.length
    untilOp + right.syntax(rightIndent)
  }
}
