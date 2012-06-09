package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import ast._
import oz._
import symtab._

/** Desugars class definitions */
object DesugarClass extends Transformer with TreeDSL {
  var ooFreeFlag: Option[Symbol] = None
  var ooFallback: Option[Symbol] = None
  var OoExtensions: Option[Symbol] = None

  case class MethodInfo(symbol: Symbol, label: Expression, proc: Expression)

  var selfSymbol: Option[Symbol] = None

  private def withSelf[A](newSelf: Symbol)(f: => A) = {
    val oldSelf = selfSymbol
    selfSymbol = Some(newSelf)
    try f
    finally selfSymbol = oldSelf
  }

  /* Find some symbols we need from the Base env */
  private def findThingsWeNeedInDecls(decls: List[Variable]) {
    for (Variable(symbol) <- decls) {
      symbol.name match {
        case "`ooFreeFlag`" => ooFreeFlag = Some(symbol)
        case "`ooFallback`" => ooFallback = Some(symbol)
        case "OoExtensions" => OoExtensions = Some(symbol)
        case _ => ()
      }
    }
  }

  override def transformStat(statement: Statement) = statement match {
    case LocalStatement(decls, _) =>
      findThingsWeNeedInDecls(decls)
      super.transformStat(statement)

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
          builtins.cellOrAttrPut call (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOpStatement(lhs, ",", rhs) if selfSymbol.isDefined =>
      transformStat {
        atPos(statement) {
          val applyProc = (lhs dot ooFallback.get dot OzAtom("apply"))
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
    case LocalExpression(decls, _) =>
      findThingsWeNeedInDecls(decls)
      super.transformExpr(expression)

    case clazz @ ClassExpression(name, parents, features, attributes,
        properties, methods) =>
      require(ooFreeFlag.isDefined && ooFallback.isDefined &&
          OoExtensions.isDefined)

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

          val newFullClass = OoExtensions.get dot OzAtom("class")

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
          builtins.cellOrAttrGet callExpr (selfSymbol.get, rhs)
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
          builtins.cellOrAttrExchangeFun callExpr (selfSymbol.get, lhs, rhs)
        }
      }

    case BinaryOp(lhs, ",", rhs) if selfSymbol.isDefined =>
      transformExpr {
        atPos(expression) {
          val applyProc = (lhs dot ooFallback.get dot OzAtom("apply"))
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
      val newValue = value getOrElse Variable(ooFreeFlag.get)
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
        LOCAL (paramVars:_*) IN {
          CompoundStatement(fetchParamStats.toList) ~ {
            withSelf(selfParam) {
              transformStat {
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
