package org.mozartoz.bootcompiler
package oz

sealed trait OzValue {
  def syntax(): String

  override def toString() = syntax()
}

sealed trait OzFeature extends OzValue {
  def feature_<(that: OzFeature) = {
    (this, that) match {
      case (OzInt(l), OzInt(r)) => l < r
      case (OzAtom(l), OzAtom(r)) => l.compareTo(r) < 0
      case (l:BuiltinName, r:BuiltinName) => l.tag.compareTo(r.tag) < 0

      case _ => typeRank(this) < typeRank(that)
    }
  }

  private def typeRank(feature: OzFeature): Int = {
    feature match {
      case _:OzInt => 1
      case _:OzAtom => 2
      case _:BuiltinName => 3
    }
  }
}

sealed trait OzNumber extends OzValue

case class OzInt(value: Long) extends OzNumber with OzFeature {
  def syntax() = value.toString()
}

case class OzFloat(value: Double) extends OzNumber {
  def syntax() = value.toString()
}

sealed trait OzLiteral extends OzValue with OzFeature

case class OzAtom(value: String) extends OzLiteral {
  def syntax() = "'" + ast.escapePseudoChars(value, '\'') + "'"
}

sealed abstract class BuiltinName(val tag: String) extends OzLiteral {
  def syntax() = tag
}

case class True() extends BuiltinName("true")
case class False() extends BuiltinName("false")
case class UnitVal() extends BuiltinName("unit")

case class OzArity(label: OzLiteral,
    features: List[OzFeature]) extends OzValue {
  def syntax() = "<Arity/" + toTuple.syntax() + ">"

  val width = features.size

  val isTupleArity = {
    features.zipWithIndex forall {
      case (OzInt(feature), index) if feature == index+1 => true
      case _ => false
    }
  }

  val isConsArity =
    isTupleArity && (width == 2) && (label == OzAtom("|"))

  lazy val toTuple = OzTuple(label, features)
}

case class OzRecordField(feature: OzFeature, value: OzValue) {
  def syntax() = feature.syntax() + ":" + value.syntax()
}

case class OzRecord(label: OzLiteral,
    fields: List[OzRecordField]) extends OzValue {
  def syntax() = {
    val untilFirstField = label.syntax() + "(" + fields.head.syntax()

    fields.tail.foldLeft(untilFirstField) {
      (prev, field) => prev + " " + field.syntax()
    } + ")"
  }

  lazy val arity = OzArity(label, fields map (_.feature))

  def isTuple = arity.isTupleArity
  def isCons = arity.isConsArity
}

object OzTuple extends ((OzLiteral, List[OzValue]) => OzRecord) {
  def apply(label: OzLiteral, fields: List[OzValue]) = {
    val recordFields =
      for ((value, index) <- fields.zipWithIndex)
        yield OzRecordField(OzInt(index+1), value)
    OzRecord(label, recordFields)
  }

  def unapply(record: OzRecord) = {
    if (record.isTuple) Some((record.label, record.fields map (_.value)))
    else None
  }
}

object OzCons extends ((OzValue, OzValue) => OzRecord) {
  def apply(head: OzValue, tail: OzValue) =
    OzTuple(OzAtom("|"), List(head, tail))

  def unapply(record: OzRecord) = {
    if (record.isCons) Some((record.fields(0).value, record.fields(1).value))
    else None
  }
}

object OzSharp extends (List[OzValue] => OzRecord) {
  def apply(fields: List[OzValue]) =
    OzTuple(OzAtom("#"), fields)

  def unapply(record: OzRecord) = record match {
    case OzTuple(OzAtom("#"), fields) => Some(fields)
    case _ => None
  }
}
