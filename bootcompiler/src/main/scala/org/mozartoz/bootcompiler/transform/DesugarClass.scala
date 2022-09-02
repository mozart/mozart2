package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import ast._
import oz._
import symtab._

/** Desugars class definitions */
object DesugarClass extends Transformer with TreeDSL {
  case class MethodInfo(symbol: Symbol, label: Expression, proc: Expression)

  def ooFreeFlag = baseEnvironment("`ooFreeFlag`")
  def ooFallback = baseEnvironment("`ooFallback`")
  def OoExtensions = baseEnvironment("OoExtensions")

  var selfSymbol: Option[Symbol] = None

  private def withSelf[A](newSelf: Symbol)(f: => A) = {
    val oldSelf = selfSymbol
    selfSymbol = Some(newSelf)
    try f
    finally selfSymbol = oldSelf
  }

  override def transformStat(statement: Statement) = statement match {
    case LockObjectStatement(body) if selfSymbol.isDefined =>
      val getObjLock = OoExtensions dot OzAtom("getObjLock")
      val lock = getObjLock callExpr (selfSymbol.get)
      transformStat {
        atPos(statement) {
          LockStatement(lock, body)
        }
      }

    case LockObjectStatement(body) if !selfSymbol.isDefined =>
      program.reportError(
          "Illegal use of lock-object outside of class definition",
          statement)

      // Some dummy statement
      transformStat(atPos(statement)(
          LockStatement(UnboundExpression(), body)))

    case BinaryOpStatement(lhs, "<-", rhs) if selfSymbol.isDefined =>
      transformStat {
        atPos(statement) {
          builtins.attrPut call (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOpStatement(lhs, "<-", rhs) if !selfSymbol.isDefined =>
      program.reportError("Illegal use of <- outside of class definition",
          statement)

      // Some dummy statement
      transformStat(atPos(statement)(BinaryOpStatement(lhs, ":=", rhs)))

    case BinaryOpStatement(lhs, ":=", rhs) if selfSymbol.isDefined =>
      transformStat {
        atPos(statement) {
          builtins.catAssignOO call (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOpStatement(lhs, ",", rhs) if selfSymbol.isDefined =>
      transformStat {
        atPos(statement) {
          val applyProc = (lhs dot ooFallback dot OzAtom("apply"))
          applyProc call (rhs, Self(), lhs)
        }
      }

    case BinaryOpStatement(lhs, ",", rhs) if !selfSymbol.isDefined =>
      program.reportError("Illegal use of , outside of class definition",
          statement)

      // Some dummy statement
      transformStat(atPos(statement)(BinaryOpStatement(lhs, ":=", rhs)))

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case LockObjectExpression(body) if selfSymbol.isDefined =>
      val getObjLock = OoExtensions dot OzAtom("getObjLock")
      val lock = getObjLock callExpr (selfSymbol.get)
      transformExpr {
        atPos(expression) {
          LockExpression(lock, body)
        }
      }

    case LockObjectExpression(body) if !selfSymbol.isDefined =>
      program.reportError(
          "Illegal use of lock-object outside of class definition",
          expression)

      // Some dummy statement
      transformExpr(atPos(expression)(
          LockExpression(UnboundExpression(), body)))

    case clazz @ ClassExpression(name, parents, features, attributes,
        properties, methods) =>
      val methodsInfo = makeMethods(name, methods)

      transformExpr(atPos(clazz) {
        LOCAL ((methodsInfo map (info => Variable(info.symbol))):_*) IN {
          val createMethodProcs = CompoundStatement(for {
            MethodInfo(symbol, _, proc) <- methodsInfo
          } yield {
            symbol === proc
          })

          val newName = Constant(OzAtom(name))
          val newParents = transformParents(parents)
          val newFeatures = transformFeatOrAttr("feat", features)
          val newAttributes = transformFeatOrAttr("attr", attributes)
          val newProperties = transformProperties(properties)
          val newMethods = transformMethods(methodsInfo)

          val newFullClass = OoExtensions dot OzAtom("class")

          createMethodProcs ~>
          newFullClass.callExpr(newParents, newMethods, newAttributes,
              newFeatures, newProperties, newName)
        }
      })

    case Self() if selfSymbol.isDefined =>
      treeCopy.Variable(expression, selfSymbol.get)

    case Self() if !selfSymbol.isDefined =>
      program.reportError("Illegal use of self outside of class definition",
          expression)

      // Some dummy expression
      treeCopy.Constant(expression, OzAtom("self"))

    case UnaryOp("@", rhs) if selfSymbol.isDefined =>
      transformExpr {
        atPos(expression) {
          builtins.catAccessOO callExpr (selfSymbol.get, rhs)
        }
      }

    case BinaryOp(lhs, "<-", rhs) if selfSymbol.isDefined =>
      transformExpr {
        atPos(expression) {
          builtins.attrExchangeFun callExpr (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOp(lhs, "<-", rhs) if !selfSymbol.isDefined =>
      program.reportError("Illegal use of <- outside of class definition",
          expression)

      transformExpr {
        atPos(expression) {
          BinaryOp(lhs, ":=", rhs)
        }
      }

    case BinaryOp(lhs, ":=", rhs) if selfSymbol.isDefined =>
      transformExpr {
        atPos(expression) {
          builtins.catExchangeOO callExpr (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOp(lhs, ",", rhs) if selfSymbol.isDefined =>
      transformExpr {
        atPos(expression) {
          val applyProc = (lhs dot ooFallback dot OzAtom("apply"))
          applyProc callExpr (rhs, Self(), lhs)
        }
      }

    case BinaryOp(lhs, ",", rhs) if !selfSymbol.isDefined =>
      program.reportError("Illegal use of , outside of class definition",
          expression)

      // Some dummy expression
      transformExpr(atPos(expression)(BinaryOp(lhs, ":=", rhs)))

    case _ =>
      super.transformExpr(expression)
  }

  def transformParents(parents: List[Expression]): Expression = {
    exprListToListExpr(parents)
  }

  def transformFeatOrAttr(label: String,
      featOrAttrs: List[FeatOrAttr]): Expression = {
    val specs = for {
      featOrAttr @ FeatOrAttr(name, value) <- featOrAttrs
    } yield {
      val newValue = value getOrElse ooFreeFlag
      treeCopy.RecordField(featOrAttr, name, newValue)
    }

    Record(OzAtom(label), specs)
  }

  def transformProperties(properties: List[Expression]) = {
    exprListToListExpr(properties)
  }

  def transformMethods(methods: List[MethodInfo]): Expression = {
    val newMethods = for {
      MethodInfo(symbol, name, _) <- methods
    } yield {
      sharp(List(name, symbol))
    }

    sharp(newMethods)
  }

  def makeMethods(className: String,
      methods: List[MethodDef]): List[MethodInfo] = {
    for {
      method @ MethodDef(MethodHeader(name, _, _), _, _) <- methods
    } yield {
      val procName = "%s,%s" format (className, name.toString())
      val symbol = new Symbol(procName)
      val proc = makeProcForMethod(procName, method)

      MethodInfo(symbol, name, proc)
    }
  }

  def makeProcForMethod(name: String, method: MethodDef): Expression = {
    val MethodDef(MethodHeader(_, params, open), messageVar, body) = method

    val selfParam = new Symbol("self", formal = true)
    val msgParam = new Symbol("<M>", formal = true)

    val paramVars = new ListBuffer[Variable]
    var resultVar: Option[Variable] = None

    val fetchParamStats = new ListBuffer[Statement]
    var nextFeature: Long = 1

    for (MethodParam(feature, name, default) <- params) {
      val actualFeature = feature match {
        case AutoFeature() =>
          val actual = treeCopy.Constant(feature, OzInt(nextFeature))
          nextFeature += 1
          actual

        case _ =>
          feature
      }

      val paramVar = (name: @unchecked) match {
        case paramVar:Variable =>
          paramVars += paramVar
          Some(paramVar)

        case NestingMarker() =>
          if (resultVar.isDefined) {
            program.reportError("Duplicate nesting marker", name)
            None
          } else {
            val resVar = Variable.newSynthetic("<Result>")
            resultVar = Some(resVar)
            paramVars += resVar
            Some(resVar)
          }

        case UnboundExpression() =>
          None
      }

      if (paramVar.isDefined) {
        val getIt = (paramVar.get === (msgParam dot actualFeature))

        fetchParamStats += {
          if (default.isEmpty) getIt
          else {
            IF (builtins.hasFeature callExpr (msgParam, actualFeature)) THEN {
              getIt
            } ELSE {
              paramVar.get === default.get
            }
          }
        }
      }
    }

    if (messageVar.isDefined) {
      paramVars += messageVar.get.asInstanceOf[Variable]
      fetchParamStats += {
        messageVar.get === msgParam
      }
    }

    atPos(method) {
      PROC (name, List(selfParam, msgParam)) {
        LOCAL (paramVars.toSeq:_*) IN {
          withSelf(selfParam) {
            transformStat {
              CompoundStatement(fetchParamStats.toList) ~ {
                if (resultVar.isDefined) {
                  resultVar.get === body.asInstanceOf[Expression]
                } else {
                  body.asInstanceOf[Statement]
                }
              }
            }
          }
        }
      }
    }
  }
}
