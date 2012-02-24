package org.mozartoz.bootcompiler
package bytecode

sealed abstract class OpCodeArg {
  def encoding: Int

  def code = encoding.toString()
}

case class ImmInt(value: Int) extends OpCodeArg {
  override def encoding = value

  override def toString() = value.toString()
}

sealed abstract class Register(letter: String) extends OpCodeArg {
  val index: Int

  override def encoding = index

  override def toString() = "%s(%d)" format (letter, index)
}

trait XOrYReg extends Register
trait XOrGReg extends Register
trait XOrKReg extends Register

case class XReg(index: Int) extends Register("X")
    with XOrYReg with XOrGReg with XOrKReg

case class YReg(index: Int) extends Register("Y") with XOrYReg
case class GReg(index: Int) extends Register("G") with XOrGReg
case class KReg(index: Int) extends Register("K") with XOrKReg
