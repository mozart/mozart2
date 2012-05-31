package org.mozartoz.bootcompiler
package ast

import symtab._

trait FormalArg extends Node

trait RawDeclarationOrVar extends Node
trait RawDeclaration extends RawDeclarationOrVar

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
