package org.mozartoz.bootcompiler

package object ast {
  type Program = Statement

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
}
