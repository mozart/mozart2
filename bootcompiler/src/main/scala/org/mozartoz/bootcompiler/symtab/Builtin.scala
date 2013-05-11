package org.mozartoz.bootcompiler
package symtab

/** Companion object for Builtin */
object Builtin {
  /** Parameter kind */
  object ParamKind extends Enumeration {
    val In, Out = Value
  }

  /** Parameter kind */
  type ParamKind = ParamKind.Value
}

/** Builtin procedure of the host VM */
class Builtin(val moduleName: String, val name: String,
    val paramKinds: List[Builtin.ParamKind],
    val inlineAs: Option[Int]) {

  override def toString() =
    moduleName + "." + (if (name.charAt(0).isLetter) name else "'" + name + "'")

  val arity = paramKinds.size

  val inlineable = inlineAs.isDefined
  def inlineOpCode = inlineAs.get
}
