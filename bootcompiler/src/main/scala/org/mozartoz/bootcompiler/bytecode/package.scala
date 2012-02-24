package org.mozartoz.bootcompiler

package object bytecode {
  implicit def int2immediate(value: Int) =
    ImmInt(value)
}
