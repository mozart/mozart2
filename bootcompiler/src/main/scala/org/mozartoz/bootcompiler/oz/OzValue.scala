package org.mozartoz.bootcompiler
package oz

/** Compile-time constant */
sealed trait OzValue {
  def syntax(): String

  override def toString() = syntax()
}

/** Compile-time constant that can be used as a feature */
sealed trait OzFeature extends OzValue {
  /** Compare two features for their ordering in a record */
  def feature_<(that: OzFeature) = {
    (this, that) match {
      case (OzInt(l), OzInt(r)) => l < r
      case (OzAtom(l), OzAtom(r)) => l.compareTo(r) < 0
      case (l:BuiltinName, r:BuiltinName) => l.tag.compareTo(r.tag) < 0

      case _ => typeRank(this) < typeRank(that)
    }
  }

  /** Rank of a feature type */
  private def typeRank(feature: OzFeature): Int = {
    feature match {
      case _:OzInt => 1
      case _:OzAtom => 2
      case _:BuiltinName => 3
    }
  }
}

/** Oz number */
sealed trait OzNumber extends OzValue

/** Oz integer */
case class OzInt(value: Long) extends OzNumber with OzFeature {
  def syntax() = value.toString()
}

/** Oz float */
case class OzFloat(value: Double) extends OzNumber {
  def syntax() = value.toString()
}

/** Oz literal */
sealed trait OzLiteral extends OzValue with OzFeature

/** Oz atom */
case class OzAtom(value: String) extends OzLiteral {
  def syntax() = "'" + ast.escapePseudoChars(value, '\'') + "'"
}

/** Abstract base class for builtin names */
sealed abstract class BuiltinName(val tag: String) extends OzLiteral {
  def syntax() = tag
}

/** The `true` value */
case class True() extends BuiltinName("true")

/** The `false` value */
case class False() extends BuiltinName("false")

/** The `unit` value */
case class UnitVal() extends BuiltinName("unit")

/** Arity of a record */
case class OzArity(label: OzLiteral,
    features: List[OzFeature]) extends OzValue {
  def syntax() =
    "<Arity/" + (if (features.isEmpty) label else toTuple).syntax() + ">"

  /** Width of this arity, aka number of features */
  val width = features.size

  /** Returns true if this is the arity of a tuple */
  val isTupleArity = {
    features.zipWithIndex forall {
      case (OzInt(feature), index) if feature == index+1 => true
      case _ => false
    }
  }

  /** Returns true if this is the arity of a cons */
  val isConsArity =
    isTupleArity && (width == 2) && (label == OzAtom("|"))

  /** Returns an Oz tuple that represents this arity */
  lazy val toTuple = OzTuple(label, features)
}

/** Field of an Oz record */
case class OzRecordField(feature: OzFeature, value: OzValue) {
  def syntax() = feature.syntax() + ":" + value.syntax()
}

/** Oz record */
case class OzRecord(label: OzLiteral,
    fields: List[OzRecordField]) extends OzValue {
  require(!fields.isEmpty)

  def syntax() = {
    val untilFirstField = label.syntax() + "(" + fields.head.syntax()

    fields.tail.foldLeft(untilFirstField) {
      (prev, field) => prev + " " + field.syntax()
    } + ")"
  }

  /** Arity of this record */
  lazy val arity = OzArity(label, fields map (_.feature))

  /** Values in this record */
  lazy val values = fields map (_.value)

  /** Returns true if this is a tuple */
  def isTuple = arity.isTupleArity

  /** Returns true if this is a cons */
  def isCons = arity.isConsArity

  /** Map from features to values */
  private lazy val map = Map((fields map (x => x.feature -> x.value)):_*)

  /** Returns the value stored at the given `feature` in this record.
   *
   *  @return [[scala.None]] if the feature does not belong to this record
   */
  def select(feature: OzFeature): Option[OzValue] =
    map.get(feature)
}

/** Factory and pattern matching for Oz tuples */
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

/** Factory and pattern matching for Oz conses */
object OzCons extends ((OzValue, OzValue) => OzRecord) {
  def apply(head: OzValue, tail: OzValue) =
    OzTuple(OzAtom("|"), List(head, tail))

  def unapply(record: OzRecord) = {
    if (record.isCons) Some((record.fields(0).value, record.fields(1).value))
    else None
  }
}

/** Factory and pattern matching for #-tuples */
object OzSharp extends (List[OzValue] => OzRecord) {
  def apply(fields: List[OzValue]) =
    OzTuple(OzAtom("#"), fields)

  def unapply(record: OzRecord) = record match {
    case OzTuple(OzAtom("#"), fields) => Some(fields)
    case _ => None
  }
}

/** Factory for Oz lists */
object OzList extends (List[OzValue] => OzValue) {
  def apply(elems: List[OzValue]): OzValue =
    if (elems.isEmpty) OzAtom("nil")
    else OzCons(elems.head, OzList(elems.tail))
}

/** Oz value representing a builtin */
case class OzBuiltin(builtin: symtab.Builtin) extends OzValue {
  def syntax() = builtin.toString()
}

/** Oz code area */
case class OzCodeArea(codeArea: bytecode.CodeArea) extends OzValue {
  def syntax() = codeArea.toString()
}

/** Special value representing a wildcard in a pattern */
case class OzPatMatWildcard() extends OzValue {
  def syntax() = "_"
}

/** Special value representing a capture in a pattern */
case class OzPatMatCapture(variable: symtab.Symbol) extends OzValue {
  def syntax() = variable.toString()
}

/** Special value representing a pattern conjunction */
case class OzPatMatConjunction(parts: List[OzValue]) extends OzValue {
  def syntax() = {
    if (parts.isEmpty) "_"
    else {
      parts.tail.foldLeft(parts.head.syntax()) {
        (prev, part) => prev + " = " + part.syntax()
      }
    }
  }
}

/** Special value representing an open record pattern */
case class OzPatMatOpenRecord(label: OzLiteral,
    fields: List[OzRecordField]) extends OzValue {
  def syntax() = {
    if (fields.isEmpty) {
      label.syntax() + "(...)"
    } else {
      val untilFirstField = label.syntax() + "(" + fields.head.syntax()

      fields.tail.foldLeft(untilFirstField) {
        (prev, field) => prev + " " + field.syntax()
      } + " ...)"
    }
  }

  /** Arity of this record */
  lazy val arity = OzArity(label, fields map (_.feature))

  /** Sub-patterns in this pattern */
  lazy val values = fields map (_.value)
}

/** Oz abstraction */
case class OzAbstraction(codeArea: OzCodeArea,
    globals: List[OzValue]) extends OzValue {

  def syntax() = {
    val abstraction = codeArea.codeArea.abstraction
    "<P/" + abstraction.arity + " " + abstraction.fullName + ">"
  }
}
