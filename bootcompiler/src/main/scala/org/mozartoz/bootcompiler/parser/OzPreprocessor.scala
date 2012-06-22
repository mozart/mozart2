package org.mozartoz.bootcompiler
package parser

import java.io.File

import scala.util.parsing.input._
import scala.util.parsing.combinator.token._

trait OzPreprocessor {
  val lexical = new OzLexical
  import lexical._

  /** Preprocessor */
  class Preprocessor(in: Reader[Token], val file: File,
      stack: List[(Reader[Token], File)] = Nil,
      _offset: Int = 0) extends Reader[Token] {
    private val (_first, _rest0, _pos, _atEnd) =
      preprocess(in, file, stack, _offset)

    private lazy val _rest = _rest0()

    def first = _first
    def rest = _rest
    def pos = _pos
    def atEnd = _atEnd
  }

  private def preprocess(in: Reader[Token], file: File,
      stack: List[(Reader[Token], File)],
      offset: Int): (Token, () => Reader[Token], Position, Boolean) = {
    if (in.atEnd) {
      if (stack.isEmpty) {
        // Totally the end
        (in.first, () => in,
            new PreprocessorPosition(offset)(in.pos, file), true)
      } else {
        // Get out of one file
        preprocess(stack.head._1, stack.head._2, stack.tail, offset)
      }
    } else {
      in.first match {
        // TODO Process a preprocessor token

        case _ =>
          def rest() =
            new Preprocessor(in.rest, file, stack, offset+1)
          (in.first, rest,
              new PreprocessorPosition(offset)(in.pos, file), false)
      }
    }
  }

  private case class PreprocessorPosition(offset: Int)(
      underlying: Position, val file: File) extends Position {
    def line = underlying.line
    def column = underlying.column

    protected def lineContents: String = "" // cheat

    override def toString =
      "line %d, column %d (in file %s)".format(line, column, file.getName)

    override def longString = underlying.longString

    override def <(that: Position) = that match {
      case PreprocessorPosition(thatOffset) =>
        this.offset < thatOffset
      case _ =>
        super.<(that)
    }
  }
}
