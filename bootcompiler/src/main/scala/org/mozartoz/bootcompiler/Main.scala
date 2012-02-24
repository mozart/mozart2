package org.mozartoz.bootcompiler

import java.io.{ FileReader, BufferedReader }

import scala.collection.immutable.PagedSeq
import scala.util.parsing.combinator._
import scala.util.parsing.input._

import parser._
import ast._
import transform._
import symtab._
import util._

object Main {
  def main(args: Array[String]) {
    println("Mozart-Oz bootstrap compiler")

    val fileName = args(0)
    val reader = new PagedSeqReader(PagedSeq.fromReader(
        new BufferedReader(new FileReader(fileName))))
    val parser = new OzParser()

    parser.parse(reader) match {
      case parser.Success(rawCode, _) => produce(rawCode)
      case parser.NoSuccess(msg, _) =>
        Console.err.println(msg)
    }
  }

  def produce(rawCode: Statement) {
    val prog = new Program(rawCode)
    applyTransforms(prog)
    prog.dump()

    prog.produceCC(new Output(Console.out))
  }

  def applyTransforms(prog: Program) {
    Namer(prog)
    Desugar(prog)
    Unnester(prog)
    Flattener(prog)
    CodeGen(prog)
  }
}
