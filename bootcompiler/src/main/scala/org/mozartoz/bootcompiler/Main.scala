package org.mozartoz.bootcompiler

import java.io.{ Console => _, _ }

import scala.collection.immutable.PagedSeq
import scala.util.parsing.combinator._
import scala.util.parsing.input._
import scala.util.parsing.json._

import oz._
import parser._
import ast._
import transform._
import symtab._
import util._

case class Config(
    fileName: String = "",
    outputStream: () => PrintStream = () => Console.out,
    moduleDefs: List[String] = Nil
)

object Main {
  def main(args: Array[String]) {
    // Define command-line options
    val optParser = new scopt.immutable.OptionParser[Config]("scopt", "2.x") {
      def options = Seq(
        opt("o", "output", "output file") {
          (v: String, c: Config) => c.copy(
              outputStream = () => new PrintStream(v))
        },
        opt("m", "module", "module definition file") {
          (v: String, c: Config) => c.copy(moduleDefs = v :: c.moduleDefs)
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

      try {
        val reader = new PagedSeqReader(PagedSeq.fromReader(
            new BufferedReader(new FileReader(fileName))))
        val parser = new OzParser()

        parser.parse(reader) match {
          case parser.Success(rawCode, _) =>
            produce(rawCode, outputStream, moduleDefs)
          case parser.NoSuccess(msg, _) =>
            Console.err.println(msg)
            sys.exit(2)
        }
      } catch {
        case th: Throwable =>
          th.printStackTrace()
          sys.exit(2)
      }
    } getOrElse {
      // Bad command-line arguments
      optParser.showUsage
      sys.exit(1)
    }
  }

  def produce(rawCode: Statement, outputStream: () => PrintStream,
      moduleDefs: List[String]) {
    val prog = new Program(rawCode)
    loadModuleDefs(prog, moduleDefs)
    loadBaseEnvironment(prog)
    applyTransforms(prog)

    prog.produceCC(new Output(outputStream()))
  }

  private def loadModuleDefs(prog: Program, moduleDefs: List[String]) {
    JSON.globalNumberParser = (_.toInt)

    for (moduleDef <- moduleDefs) {
      val file = new File(moduleDef)

      if (file.isFile())
        loadModuleDef(prog, file)
      else {
        val pattern = """.*-builtin\.json$""".r
        for {
          f <- file.listFiles()
          if (pattern.findFirstIn(f.getName).isDefined)
        } {
          loadModuleDef(prog, f)
        }
      }
    }
  }

  private def loadModuleDef(prog: Program, moduleDef: File) {
    class CC[T] {
      def unapply(a: Any): Option[T] = Some(a.asInstanceOf[T])
    }

    object M extends CC[Map[String, Any]]
    object L extends CC[List[Any]]
    object S extends CC[String]
    object D extends CC[Double]
    object B extends CC[Boolean]

    val modules = JSON.parseFull(readFileToString(moduleDef)).toList

    for {
      M(module) <- modules
      S(modName) = module("name")
      L(builtins) = module("builtins")
      M(builtin) <- builtins
      S(biFullCppName) = builtin("fullCppName")
      S(biName) = builtin("name")
      B(inlineable) = builtin("inlineable")
      L(params) = builtin("params")
    } {
      val inlineAs =
        if (inlineable) Some(builtin("inlineOpCode").asInstanceOf[Int])
        else None

      val paramKinds = for {
        M(param) <- params
        S(paramKind) = param("kind")
      } yield {
        Builtin.ParamKind.withName(paramKind)
      }

      val fullName = modName + "." + (
          if (biName.charAt(0).isLetter) biName
          else "'" + biName + "'")

      val builtinSym = new Builtin(
          fullName, biFullCppName, paramKinds, inlineAs)

      prog.builtins.builtinByName.put(fullName, builtinSym)
    }
  }

  private def loadBaseEnvironment(prog: Program) {
    val in = getClass.getResourceAsStream("/BaseEnvironment.txt")
    val source = io.Source.fromInputStream(in)
    val UsefulLine = """(\w+)\s*=\s*([^\s].*)""".r

    for (line <- source.getLines()) {
      line match {
        case UsefulLine(key, fullName) =>
          val builtin = prog.builtins.builtinByName(fullName)
          prog.builtins.baseEnvironment.put(key, OzBuiltin(builtin))

        case _ => // ignore
      }
    }
  }

  private def applyTransforms(prog: Program) {
    Namer(prog)
    Desugar(prog)
    PatternMatcher(prog)
    Unnester(prog)
    Flattener(prog)
    CodeGen(prog)
  }

  private def readFileToString(file: File) = {
    val source = io.Source.fromFile(file)
    try source.mkString
    finally source.close()
  }
}
