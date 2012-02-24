package org.mozartoz.bootcompiler
package util

import java.io.PrintStream

object Output {
  implicit def string2modformat(self: String) = new {
    def % (args: Any*) =
      self format (args:_*)
  }
}

class Output(val underlying: PrintStream) {
  import Output._

  def print(x: Any) = underlying.print(x)
  def println(x: Any) = underlying.println(x)
  def println() = underlying.println()

  def << (x: Any): this.type = {
    print(x)
    this
  }

  def \\ : this.type = {
    println()
    this
  }

  def test() {
    this << "hello" % 3 << "salut" \\
  }
}
