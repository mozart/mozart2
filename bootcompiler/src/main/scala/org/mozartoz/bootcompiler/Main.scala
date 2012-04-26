package org.mozartoz.bootcompiler

import java.io.{ Console => _, _ }

import scala.collection.immutable.PagedSeq
import scala.util.parsing.combinator._
import scala.util.parsing.input._

import parser._
import ast._
import transform._
import symtab._
import util._

case class Config(
    fileName: String = "",
    outputStream: PrintStream = Console.out
)

object Main {
  def main(args: Array[String]) {
    // Define command-line options
    val optParser = new scopt.immutable.OptionParser[Config]("scopt", "2.x") {
      def options = Seq(
        opt("o", "output", "output file") {
          (v: String, c: Config) => c.copy(outputStream = new PrintStream(v))
        },
        arg("<file>", "input file") {
          (v: String, c: Config) => c.copy(fileName = v)
        }
      )
    }

    // Parse the options
    optParser.parse(args, Config()) map { config =>
      // OK, we're good to go
      import config._

      val reader = new PagedSeqReader(PagedSeq.fromReader(
          new BufferedReader(new FileReader(fileName))))
      val parser = new OzParser()

      parser.parse(reader) match {
        case parser.Success(rawCode, _) =>
          produce(rawCode, outputStream)
        case parser.NoSuccess(msg, _) =>
          Console.err.println(msg)
      }
    } getOrElse {
      // Bad command-line arguments
      optParser.showUsage
    }
  }

  def produce(rawCode: Statement, outputStream: PrintStream) {
    val prog = new Program(rawCode)
    applyTransforms(prog)

    prog.produceCC(new Output(outputStream))
  }

  def applyTransforms(prog: Program) {
    Namer(prog)
    Desugar(prog)
    Unnester(prog)
    Flattener(prog)
    CodeGen(prog)
  }
}
