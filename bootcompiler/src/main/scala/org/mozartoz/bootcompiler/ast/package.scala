package org.mozartoz.bootcompiler

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

  implicit def pair2recordField(pair: (Expression, Expression)) =
    RecordField(pair._1, pair._2)

  implicit def expr2recordField(expr: Expression) =
    RecordField(AutoFeature(), expr)
}
