package org.mozartoz.bootcompiler
package bytecode

import scala.collection.mutable._

import symtab._
import util._

class CodeArea {
  val opCodes = new ArrayBuffer[OpCode]

  private val registerAllocs = new HashMap[Any, Register]

  def isDefined = !opCodes.isEmpty

  def size = opCodes.map(_.size).sum

  def dump() {
    for (opCode <- opCodes)
      println(opCode.code)
  }

  private val YCounter = new RegCounter(YReg)
  private val KCounter = new RegCounter(KReg)

  def registerFor(symbol: VariableSymbol): YOrGReg =
    innerRegisterFor(symbol).asInstanceOf[YOrGReg]

  def registerFor(symbol: BuiltinSymbol): KReg =
    innerRegisterFor(symbol).asInstanceOf[KReg]

  def registerFor(symbol: Symbol) =
    innerRegisterFor(symbol)

  def registerFor(codeArea: CodeArea) =
    innerRegisterFor(codeArea).asInstanceOf[KReg]

  private def innerRegisterFor(key: Any) = {
    registerAllocs.getOrElseUpdate(key, {
      (key: @unchecked) match {
        case sym:VariableSymbol =>
          if (sym.isGlobal) GReg(sym.owner.globals.indexOf(sym))
          else YCounter.next()
        case _:BuiltinSymbol | _:CodeArea => KCounter.next()
      }
    })
  }

  def += (opCode: OpCode) =
    opCodes += opCode

  class Hole(index: Int) {
    def fillWith(opCode: OpCode) {
      opCodes(index) = opCode
    }
  }

  def addHole() = {
    val index = opCodes.size
    opCodes += OpHole()
    new Hole(index)
  }

  def counting(body: => Unit) = {
    val before = opCodes.size
    body
    opCodes.size - before
  }
}
