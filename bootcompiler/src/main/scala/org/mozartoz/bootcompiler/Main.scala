package org.mozartoz.bootcompiler

import java.io.{ Console => _, _ }

import scala.collection.mutable.ListBuffer
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
    baseModule: String = "",
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
        opt("b", "base", "path to the base functor") {
          (v: String, c: Config) => c.copy(baseModule = v)
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
        val baseFunctor = parseExpression(readerForFile(baseModule))
        val programStat = parseStatement(readerForFile(fileName))

        val program = buildProgram(moduleDefs, baseFunctor, programStat)

        produce(program, outputStream)
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

  private def parseStatement(reader: PagedSeqReader) =
    new ParserWrapper().parseStatement(reader)

  private def parseExpression(reader: PagedSeqReader) =
    new ParserWrapper().parseExpression(reader)

  class ParserWrapper {
    private val parser = new OzParser()

    def parseStatement(reader: PagedSeqReader) =
      processResult(parser.parseStatement(reader))

    def parseExpression(reader: PagedSeqReader) =
      processResult(parser.parseExpression(reader))

    private def processResult[A](result: parser.ParseResult[A]): A = {
      result match {
        case parser.Success(rawCode, _) =>
          rawCode

        case parser.NoSuccess(msg, next) =>
          Console.err.println(
              "Parse error (line %d, col %d)\n".format(
                  next.pos.line, next.pos.column) +
              msg + "\n" +
              next.pos.longString)
          sys.exit(2)
      }
    }
  }

  private def readerForFile(fileName: String) = {
    new PagedSeqReader(PagedSeq.fromReader(
        new BufferedReader(new FileReader(fileName))))
  }

  private def readerForResource(resourceName: String) = {
    new PagedSeqReader(PagedSeq.fromSource(io.Source.fromInputStream(
        getClass.getResourceAsStream(resourceName))))
  }

  private def buildProgram(moduleDefs: List[String], baseFunctor: Expression,
      programStat: Statement): Program = {
    val prog = new Program(SkipStatement())

    val bootModulesMap = loadModuleDefs(prog, moduleDefs)
    ProgramBuilder.build(prog, bootModulesMap, baseFunctor, programStat)

    prog
  }

  def produce(prog: Program, outputStream: () => PrintStream) {
    applyTransforms(prog)

    if (prog.hasErrors) {
      for ((message, pos) <- prog.errors) {
        Console.err.println(
            "Error at line %d, column %d\n".format(pos.line, pos.column) +
            message + "\n" +
            pos.longString)
      }

      sys.exit(2)
    } else {
      prog.produceCC(new Output(outputStream()))
    }
  }

  private def loadModuleDefs(prog: Program, moduleDefs: List[String]) = {
    JSON.globalNumberParser = (_.toInt)

    val result = new scala.collection.mutable.HashMap[String, Expression]

    for (moduleDef <- moduleDefs) {
      val file = new File(moduleDef)

      if (file.isFile())
        result ++= loadModuleDef(prog, file)
      else {
        val pattern = """.*-builtin\.json$""".r
        for {
          f <- file.listFiles()
          if (pattern.findFirstIn(f.getName).isDefined)
        } {
          result ++= loadModuleDef(prog, f)
        }
      }
    }

    Map.empty ++ result
  }

  private def loadModuleDef(prog: Program, moduleDef: File) = {
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
    } yield {
      val exportFields = new ListBuffer[RecordField]

      for {
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

        exportFields += RecordField(
            Constant(OzAtom(biName)), Constant(OzBuiltin(builtinSym)))
      }

      val moduleURL = "x-oz://boot/" + modName
      val moduleExport = Record(Constant(OzAtom("export")), exportFields.toList)

      moduleURL -> moduleExport
    }
  }

  private def applyTransforms(prog: Program) {
    Namer(prog)
    DesugarFunctor(prog)
    Desugar(prog)
    ConstantFolding(prog)
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
