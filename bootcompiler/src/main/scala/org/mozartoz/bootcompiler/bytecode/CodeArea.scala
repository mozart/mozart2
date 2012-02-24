package org.mozartoz.bootcompiler
package bytecode

import scala.collection.mutable._

import symtab._
import util._

class CodeArea {
  val opCodes = new ArrayBuffer[OpCode]

  private val registerAllocs = new HashMap[Symbol, Register]

  def isDefined = !opCodes.isEmpty

  def size = opCodes.map(_.size).sum

  def dump() {
    for (opCode <- opCodes)
      println(opCode.code)
  }

  private val YCounter = new RegCounter(YReg)
  private val KCounter = new RegCounter(KReg)

  def registerFor(symbol: VariableSymbol): YReg = {
    registerFor(symbol:Symbol).asInstanceOf[YReg]
  }

  def registerFor(symbol: BuiltinSymbol): KReg = {
    registerFor(symbol:Symbol).asInstanceOf[KReg]
  }

  def registerFor(symbol: Symbol) = {
    registerAllocs.getOrElseUpdate(symbol, {
      (symbol: @unchecked) match {
        case _:VariableSymbol => YCounter.next()
        case _:BuiltinSymbol => KCounter.next()
      }
    })
  }

  def += (opCode: OpCode) =
    opCodes += opCode
}
