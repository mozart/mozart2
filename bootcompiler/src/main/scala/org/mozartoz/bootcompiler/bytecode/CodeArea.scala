package org.mozartoz.bootcompiler
package bytecode

import scala.collection.mutable._

import oz._
import ast._
import symtab._
import util._

class CodeArea(val abstraction: Abstraction) {
  val opCodes = new ArrayBuffer[OpCode]

  private val symbolRegisterAllocs = new HashMap[Symbol, YOrGReg]
  private val constantRegisterAllocs = new HashMap[OzValue, KReg]

  private val YCounter = new RegCounter(YReg)

  val constants = new ArrayBuffer[OzValue]

  def isDefined = !opCodes.isEmpty

  def size = opCodes.map(_.size).sum

  override def toString() = "<CodeArea %s>" format (abstraction.fullName)

  def dump(includeByteCode: Boolean = true) {
    println("constants:")
    for ((constant, index) <- constants.zipWithIndex)
      println("  K(%d) = %s" format (index, constant))

    if (includeByteCode) {
      println()
      for (opCode <- opCodes)
        println(opCode.code)
    }
  }

  def registerFor(symbol: Symbol): YOrGReg = {
    symbolRegisterAllocs.getOrElseUpdate(symbol, {
      if (symbol.isGlobal) GReg(symbol.owner.globals.indexOf(symbol))
      else YCounter.next()
    })
  }

  def registerFor(value: OzValue): KReg = {
    constantRegisterAllocs.getOrElseUpdate(value, {
      constants += value
      KReg(constants.size - 1)
    })
  }

  def registerFor(expr: VarOrConst): Register = expr match {
    case variable:Variable =>
      registerFor(variable.symbol)

    case constant:Constant =>
      registerFor(constant.value)
  }

  def += (opCode: OpCode) =
    opCodes += opCode

  class Hole(index: Int) {
    def fillWith(opCode: OpCode) {
      opCodes(index) = opCode
    }
  }

  def addHole(size: Int = 1) = {
    val index = opCodes.size
    opCodes += OpHole(size)
    new Hole(index)
  }

  def counting(body: => Unit) = {
    val before = opCodes.size
    body
    (before until opCodes.size) map (i => opCodes(i).size) sum
  }

  def computeXCount() = {
    var maxX = 0

    for {
      opCode <- opCodes
      XReg(index) <- opCode.arguments
    } {
      maxX = maxX max index
    }

    maxX + 1
  }

  val ccCodeArea = "codeArea" + abstraction.id.toString()
  val ccCreateMethodName = "createCodeArea" + abstraction.id.toString()

  def produceCC(out: Output) {
    import Output._

    out << """
       |/*
       |""".stripMargin

    Console.withOut(out.underlying) {
      abstraction.dump(includeByteCode = false)
    }

    out << """
       |*/
       |
       |void Program::%s() {
       |  ByteCode codeBlock[] = {
       |""".stripMargin % ccCreateMethodName

    for (opCode <- opCodes)
      out << "    %s,\n" % opCode.code

    out << """
       |  };
       |
       |  %s = new (vm) UnstableNode;
       |  *%s = CodeArea::build(vm, %d, codeBlock, sizeof(codeBlock), %d);
       |""".stripMargin % (ccCodeArea, ccCodeArea,
           constants.size, computeXCount())

    if (!constants.isEmpty) {
      out << """
         |  ArrayInitializer initializer = *%s;
         |  UnstableNode temp;
         |""".stripMargin % ccCodeArea

      for ((constant, index) <- constants.zipWithIndex) {
        produceCCInitConstant(out, constant)
        out << "  initializer.initElement(vm, %d, temp);\n" % (
            index, index)
      }
    }

    out << """
       |}
       |""".stripMargin
  }

  private def produceCCInitConstant(out: Output, constant: OzValue) {
    import Output._

    out << "  temp = ";

    constant match {
      case _:OzArity | _:OzRecord =>
        produceCCForConstant(out, constant)

      case _ =>
        out << "build(vm, "
        produceCCForConstant(out, constant)
        out << ")"
    }

    out << ";\n"
  }

  private def produceCCForConstant(out: Output, constant: OzValue) {
    import Output._

    constant match {
      case OzBuiltin(builtin) =>
        out << "::%s::builtin()" % builtin.ccFullName

      case OzCodeArea(codeArea) =>
        out << "*%s" % codeArea.ccCodeArea

      case OzInt(value) =>
        out << value.toString()

      case OzFloat(value) =>
        out << value.toString()

      case OzAtom(value) =>
        out << "MOZART_STR(\"%s\")" % (value map {
          case '\\' => "\\\\"
          case c => c
        } mkString "")

      case True() =>
        out << "true"

      case False() =>
        out << "false"

      case UnitVal() =>
        out << "unit"

      case OzArity(label, features) =>
        out << "buildArity(vm, "
        produceCCForConstant(out, label)

        for (feature <- features) {
          out << ", "
          produceCCForConstant(out, feature)
        }

        out << ")"

      case OzCons(head, tail) =>
        out << "buildCons(vm, "
        produceCCForConstant(out, head)
        out << ", "
        produceCCForConstant(out, tail)
        out << ")"

      case OzTuple(label, fields) =>
        out << "buildTuple(vm, "
        produceCCForConstant(out, label)

        for (field <- fields) {
          out << ", "
          produceCCForConstant(out, field)
        }

        out << ")"

      case record @ OzRecord(label, fields) =>
        out << "buildRecord(vm, "
        produceCCForConstant(out, record.arity)

        for (OzRecordField(feature, value) <- fields) {
          out << ", "
          produceCCForConstant(out, value)
        }

        out << ")"

      case OzPatMatWildcard() =>
        out << "PatMatCapture::build(vm, -1)"

      case OzPatMatCapture(symbol) =>
        out << "PatMatCapture::build(vm, %d)" % symbol.captureIndex
    }
  }
}
