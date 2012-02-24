package org.mozartoz.bootcompiler
package bytecode

import scala.collection.mutable._

import ast._
import symtab._
import util._

class CodeArea {
  val opCodes = new ArrayBuffer[OpCode]

  private val registerAllocs = new HashMap[Any, Register]

  def isDefined = !opCodes.isEmpty

  def size = opCodes.map(_.size).sum

  def dump() {
    println("constants: " + (constants mkString " "))
    println()
    for (opCode <- opCodes)
      println(opCode.code)
  }

  private val YCounter = new RegCounter(YReg)

  val constants = new ArrayBuffer[Any]

  def registerFor(symbol: VariableSymbol): YOrGReg =
    innerRegisterFor(symbol).asInstanceOf[YOrGReg]

  def registerFor(symbol: BuiltinSymbol): KReg =
    innerRegisterFor(symbol).asInstanceOf[KReg]

  def registerFor(symbol: Symbol) =
    innerRegisterFor(symbol)

  def registerFor(codeArea: CodeArea) =
    innerRegisterFor(codeArea).asInstanceOf[KReg]

  def registerFor(constant: Constant) =
    innerRegisterFor(constant).asInstanceOf[KReg]

  private def innerRegisterFor(key: Any) = {
    registerAllocs.getOrElseUpdate(key, {
      key match {
        case sym:VariableSymbol =>
          if (sym.isGlobal) GReg(sym.owner.globals.indexOf(sym))
          else YCounter.next()

        case _:BuiltinSymbol | _:CodeArea | _:Constant =>
          constants += key
          KReg(constants.size - 1)
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
