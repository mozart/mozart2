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

  lazy val debugData = {
    implicit def pair2recordField(pair: (OzFeature, OzValue)) =
      OzRecordField(pair._1, pair._2)

    val pos = abstraction.pos
    val fileName = FilePosition.fileNameOf(pos, "")

    OzRecord(OzAtom("d"), List(
        OzAtom("column") -> OzInt(pos.column),
        OzAtom("file") -> OzAtom(fileName),
        OzAtom("line") -> OzInt(pos.line)
    ))
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
       |  atom_t printName = vm->getAtom(%s);
       |  UnstableNode debugData = build(vm, """.stripMargin % (
           stringToMozartStr(abstraction.name))

    produceCCForConstant(out, debugData)

    out << """);
       |
       |  %s = CodeArea::build(vm, %d, codeBlock, sizeof(codeBlock), %d, %d,
       |                       printName, debugData);
       |""".stripMargin % (
           ccCodeArea, constants.size, abstraction.arity, computeXCount())

    if (!constants.isEmpty) {
      out << """
         |  auto kregs = RichNode(%s).as<CodeArea>().getElementsArray();
         |""".stripMargin % ccCodeArea

      for ((constant, index) <- constants.zipWithIndex) {
        out << "  kregs[%d].init(vm, " % index
        produceCCForConstant(out, constant)
        out << ");\n"
      }
    }

    out << """
       |}
       |""".stripMargin
  }

  private def produceCCForConstant(out: Output, constant: OzValue) {
    import Output._

    constant match {
      case OzBuiltin(builtin) =>
        out << "vm->findBuiltin(%s, %s)" % (
            stringToMozartStr(builtin.moduleName),
            stringToMozartStr(builtin.name))

      case OzCodeArea(codeArea) =>
        out << "%s" % codeArea.ccCodeArea

      case OzInt(value) =>
        out << value.toString()

      case OzFloat(value) =>
        out << value.toString()

      case OzAtom(value) =>
        out << stringToMozartStr(value)

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

      case OzPatMatConjunction(parts) =>
        out << "buildPatMatConjunction(vm"
        for (part <- parts) {
          out << ", "
          produceCCForConstant(out, part)
        }
        out << ")"

      case record @ OzPatMatOpenRecord(label, fields) =>
        out << "buildPatMatOpenRecord(vm, "
        produceCCForConstant(out, record.arity)

        for (OzRecordField(feature, value) <- fields) {
          out << ", "
          produceCCForConstant(out, value)
        }

        out << ")"
    }
  }

  private def stringToMozartStr(string: String) = {
    "MOZART_STR(\"%s\")" format (string map {
      case '\\' => "\\\\"
      case '"' => "\\\""
      case '\u0007' => "\\a"
      case '\u0008' => "\\b"
      case '\u0009' => "\\t"
      case '\u000A' => "\\n"
      case '\u000B' => "\\v"
      case '\u000C' => "\\f"
      case '\u000D' => "\\r"
      case c => c
    } mkString "")
  }
}
