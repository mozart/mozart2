package org.mozartoz.bootcompiler

import java.io.BufferedOutputStream

import bytecode._
import oz._
import symtab._

class Serializer(program: Program, output: BufferedOutputStream) {
  val alreadyWrittenNodes = new scala.collection.mutable.HashMap[OzValue, Int]

  // Top-level

  def serialize() {
    writeCodeArea(program.topLevelAbstraction.codeArea)
    writeByte(0)
    output.close()
  }

  // Writing of nodes

  private def writeValue(value: OzValue) {
    value match {
      case OzInt(intValue) =>
        writeByte(1)
        writeSize(intValue.toInt)

      case OzFloat(floatValue) =>
        writeByte(2)
        writeString(floatValue.toString)

      case True() =>
        writeByte(3)
        writeByte(1)

      case False() =>
        writeByte(3)
        writeByte(0)

      case UnitVal() =>
        writeByte(4)

      case OzAtom(atom) =>
        writeByte(5)
        writeAtom(atom)

      case OzCons(head, tail) =>
        val headRef = makeRef(head)
        val tailRef = makeRef(tail)
        writeByte(6)
        writeRef(headRef)
        writeRef(tailRef)

      case OzTuple(label, fields) =>
        val labelRef = makeRef(label)
        val fieldsRefs = fields map makeRef
        writeByte(7)
        writeSize(fieldsRefs.size)
        writeRef(labelRef)
        fieldsRefs foreach writeRef

      case OzArity(label, features) =>
        val labelRef = makeRef(label)
        val featuresRefs = features map makeRef
        writeByte(8)
        writeSize(featuresRefs.size)
        writeRef(labelRef)
        featuresRefs foreach writeRef

      case rec @ OzRecord(_, _) =>
        val arityRef = makeRef(rec.arity)
        val fieldsRefs = rec.values map makeRef
        writeByte(9)
        writeSize(fieldsRefs.size)
        writeRef(arityRef)
        fieldsRefs foreach writeRef

      case OzBuiltin(builtin) =>
        writeByte(10)
        writeAtom(builtin.moduleName)
        writeAtom(builtin.name)

      case OzCodeArea(codeArea) =>
        writeCodeArea(codeArea)

      case OzPatMatWildcard() =>
        writeByte(12)

      case OzPatMatCapture(symbol) =>
        writeByte(13)
        writeSize(symbol.captureIndex.toInt)

      case OzPatMatConjunction(parts) =>
        val partsRefs = parts map makeRef
        writeByte(14)
        writeSize(partsRefs.size)
        partsRefs foreach writeRef

      case pat @ OzPatMatOpenRecord(_, _) =>
        val arityRef = makeRef(pat.arity)
        val fieldsRefs = pat.values map makeRef
        writeByte(15)
        writeSize(fieldsRefs.size)
        writeRef(arityRef)
        fieldsRefs foreach writeRef
    }
  }

  private def writeCodeArea(codeArea: CodeArea) {
    val codeBlock = for {
      opCode <- codeArea.opCodes.toList
      byteCodeElem <- opCode.encoding
      byte <- Seq(byteCodeElem >> 8 & 0xff, byteCodeElem & 0xff)
    } yield byte.toByte

    val debugDataRef = makeRef(codeArea.debugData)
    val constantsRefs = codeArea.constants.toList map makeRef

    writeByte(11)

    writeSize(codeBlock.size / 2)
    output.write(codeBlock.toArray)

    writeSize(constantsRefs.size)
    writeSize(codeArea.abstraction.arity)
    writeSize(codeArea.computeXCount())
    writeAtom(codeArea.abstraction.name)
    writeRef(debugDataRef)

    constantsRefs foreach writeRef
  }

  // Low-level write procs

  private def writeSize(size: Int) {
    output.write(size >> 24 & 0xff)
    output.write(size >> 16 & 0xff)
    output.write(size >> 8 & 0xff)
    output.write(size & 0xff)
  }

  private def writeByte(b: Int) {
    output.write(b)
  }

  private def writeString(str: String) {
    val bytes = str.getBytes(Serializer.charset)
    writeSize(bytes.length)
    output.write(bytes)
  }

  private def writeAtom(atom: String) {
    writeString(atom)
  }

  private def makeRef(node: OzValue): Int = {
    alreadyWrittenNodes.getOrElseUpdate(node, {
      writeValue(node)
      alreadyWrittenNodes.size
    })
  }

  private def writeRef(ref: Int) {
    writeSize(ref)
  }
}

object Serializer {
  val charset = java.nio.charset.Charset.forName("UTF-8")

  def serialize(program: Program, output: BufferedOutputStream) {
    new Serializer(program, output).serialize()
  }
}
