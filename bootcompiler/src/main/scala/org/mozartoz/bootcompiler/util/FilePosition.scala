package org.mozartoz.bootcompiler
package util

import java.io.File

import scala.util.parsing.input._

trait FilePosition extends Position {
  def file: Option[File]

  def fileName = file map (_.getName) getOrElse FilePosition.NoFileName
}

object FilePosition {
  val NoFileName = "<unknown-file>"

  def fileOf(position: Position) = position match {
    case filePos: FilePosition => filePos.file
    case _ => None
  }

  def fileOf(positional: Positional): Option[File] =
    fileOf(positional.pos)

  def fileNameOf(position: Position) =
    fileOf(position) map (_.getName) getOrElse NoFileName

  def fileNameOf(positional: Positional): String =
    fileNameOf(positional.pos)
}
