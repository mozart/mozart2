package org.mozartoz.bootcompiler

import java.io.{ FileReader, BufferedReader }

import scala.util.parsing.combinator._
import scala.util.parsing.input.StreamReader

import parser._
import ast._
import transform._
import symtab._

object Main {
  def main(args: Array[String]) {
    println("Mozart-Oz bootstrap compiler")

    val fileName = args(0)
    val reader = StreamReader(new BufferedReader(new FileReader(fileName)))
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
  }

  def applyTransforms(prog: Program) {
    DeclarationExtractor(prog)
    Namer(prog)
  }
}
