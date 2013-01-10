package org.mozartoz.bootcompiler

import java.io.BufferedOutputStream

import bytecode._
import oz._
import symtab._

class Serializer(program: Program, output: BufferedOutputStream) {
  val nodeToIndex = new scala.collection.mutable.HashMap[OzValue, Int]
  val indexCounter = new util.Counter(1)

  // Top-level

  def serialize() {
    val topLevelCodeArea = OzCodeArea(program.topLevelAbstraction.codeArea)
    val topLevelValue = OzAbstraction(topLevelCodeArea, Nil)
    giveIndex(topLevelValue)

    writeSize(nodeToIndex.size)
    writeSize(nodeToIndex(topLevelValue))
    for ((value, index) <- nodeToIndex.toSeq.sortBy(_._2))
      writeValue(index, value)
    writeSize(0)

    output.close()
  }

  // Give indices to nodes

  private def giveIndex(value: OzValue) {
    nodeToIndex.getOrElseUpdate(value, {
      giveIndicesInside(value)
      indexCounter.next()
    })
  }

  private def giveIndicesInside(value: OzValue) {
    value match {
      case OzCons(head, tail) =>
        giveIndex(head)
        giveIndex(tail)

      case OzTuple(label, fields) =>
        giveIndex(label)
        fields foreach giveIndex

      case OzArity(label, features) =>
        giveIndex(label)
        features foreach giveIndex

      case rec @ OzRecord(_, _) =>
        giveIndex(rec.arity)
        rec.values foreach giveIndex

      case OzCodeArea(codeArea) =>
        giveIndex(codeArea.debugData)
        codeArea.constants foreach giveIndex

      case OzPatMatConjunction(parts) =>
        parts foreach giveIndex

      case pat @ OzPatMatOpenRecord(_, _) =>
        giveIndex(pat.arity)
        pat.values foreach giveIndex

      case OzAbstraction(codeArea, globals) =>
        giveIndex(codeArea)
        globals foreach giveIndex

      case _ => ()
    }
  }

  // Writing of nodes

  private def writeValue(index: Int, value: OzValue) {
    writeSize(index)

    value match {
      case OzInt(intValue) =>
        writeByte(1)
        writeString(intValue.toString)

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
        writeByte(6)
        writeRef(head)
        writeRef(tail)

      case OzTuple(label, fields) =>
        writeByte(7)
        writeRef(label)
        writeRefs(fields)

      case OzArity(label, features) =>
        writeByte(8)
        writeRef(label)
        writeRefs(features)

      case rec @ OzRecord(_, _) =>
        writeByte(9)
        writeRef(rec.arity)
        writeRefs(rec.values)

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
        writeByte(14)
        writeRefs(parts)

      case pat @ OzPatMatOpenRecord(_, _) =>
        writeByte(15)
        writeRef(pat.arity)
        writeRefs(pat.values)

      case OzAbstraction(codeArea, globals) =>
        writeByte(16)
        writeRandomUUID()
        writeRef(codeArea)
        writeRefs(globals)
    }
  }

  private def writeCodeArea(codeArea: CodeArea) {
    val codeBlock = for {
      opCode <- codeArea.opCodes.toList
      byteCodeElem <- opCode.encoding
      byte <- Seq(byteCodeElem >> 8 & 0xff, byteCodeElem & 0xff)
    } yield byte.toByte

    writeByte(11)

    writeRandomUUID()

    writeSize(codeBlock.size / 2)
    output.write(codeBlock.toArray)

    writeSize(codeArea.abstraction.arity)
    writeSize(codeArea.computeXCount())
    writeAtom(codeArea.abstraction.name)
    writeRef(codeArea.debugData)

    writeSize(codeArea.constants.size)
    codeArea.constants foreach writeRef
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

  private def writeRef(value: OzValue) {
    writeSize(nodeToIndex(value))
  }

  private def writeRefs(values: Seq[OzValue]) {
    writeSize(values.size)
    values foreach writeRef
  }

  private def writeRandomUUID() {
    def writeLong(value: Long) {
      for (i <- (0 until 64 by 8).reverse)
        output.write(((value >> i) & 0xff).asInstanceOf[Int])
    }

    val uuid = java.util.UUID.randomUUID()
    writeLong(uuid.getMostSignificantBits)
    writeLong(uuid.getLeastSignificantBits)
  }
}

object Serializer {
  val charset = java.nio.charset.Charset.forName("UTF-8")

  def serialize(program: Program, output: BufferedOutputStream) {
    new Serializer(program, output).serialize()
  }
}
