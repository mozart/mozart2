package org.mozartoz.bootcompiler
package util

import java.io.PrintStream

/** Provides implicit conversions for writing code */
object Output {
  implicit def string2modformat(self: String) = new {
    def % (args: Any*) =
      self format (args:_*)
  }
}

/** Simple wrapper around a [[java.io.PrintStream]] for writing code
 *
 *  @constructor creates a new wrapper for a [[java.io.PrintStream]]
 *  @param underlying underlying [[java.io.PrintStream]]
 */
class Output(val underlying: PrintStream) {
  import Output._

  /** Prints a value on the underlying stream */
  def print(x: Any) = underlying.print(x)

  /** Prints a value and a line feed on the underlying stream */
  def println(x: Any) = underlying.println(x)

  /** Prints a line feed on the underlying stream */
  def println() = underlying.println()

  /** Prints a value on the underlying stream
   *
   *  This operator can be chained, as C++ streams.
   */
  def << (x: Any): this.type = {
    print(x)
    this
  }
}
