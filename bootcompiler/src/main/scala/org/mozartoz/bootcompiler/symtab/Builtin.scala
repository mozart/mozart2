package org.mozartoz.bootcompiler
package symtab

object Builtin {
  object ParamKind extends Enumeration {
    val In, Out = Value
  }

  type ParamKind = ParamKind.Value
}

class Builtin(val name: String, val ccFullName: String,
    val paramKinds: List[Builtin.ParamKind],
    val inlineAs: Option[Int]) {

  override def toString() = name

  val arity = paramKinds.size

  val inlineable = inlineAs.isDefined
  def inlineOpCode = inlineAs.get
}
