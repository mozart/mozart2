package org.mozartoz.bootcompiler
package bytecode

import util._

class RegCounter[A <: Register](index2reg: Int => A) {
  private val underlying = new Counter(start = 0)

  def next() = index2reg(underlying.next())
}
