%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% This defines a function `GetBuiltinInfo' that returns information
%% about the builtin with a given name A.  This information is either:
%%
%%    noBuiltin
%%       if A does not denote a known builtin.
%%
%%    builtin(types: [procedure] det: [procedure]...)
%%       if A denotes a known builtin with argument types as given.
%%       The following features may or may not be contained in the
%%       record, as appropriate:
%%
%%          inlineFun: B
%%             if this feature is present and B is true, than A may
%%             be called using one the `inlineFun...' instructions.
%%             This feature cannot be present at the same time as
%%             as inlineRel feature.
%%          eqeq: B
%%             if this feature is present and B is true, then A may
%%             be called using the `inlineEqEq' instruction.
%%             The inlineFun feature must be present and true for
%%             this feature to take effect.
%%          inlineRel: B
%%             if this feature is present and B is true, than A may
%%             be called using one the `inlineRel...' instructions.
%%             This feature cannot be present at the same time as
%%             as inlineFun feature.
%%          rel: A2
%%             if this feature is present, then A2 is the name of
%%             another builtin that may be used in a shallowTest
%%             instruction instead of this builtin.
%%          doesNotReturn: B
%%             if this feature is present and B is true, then any
%%             statement following the call to A is not executed.
%%          destroysArguments: B
%%             if this feature is present and B is true, then after
%%             the builtin application the contents of the argument
%%             registers is not guaranteed.
%%
%% This function really should be a builtin itself so that it becomes
%% easier to keep this information up-to-date when the emulator is
%% modified.
%%

local
   BuiltinTable =
   table('*': builtin(types: [number number number]
                      det:   [det det any(det)]
                      inlineFun: true)

         '+': builtin(types: [number number number]
                      det:   [det det any(det)]
                      inlineFun: true)

         '+1': builtin(types: [number number]
                       det:   [det any(det)]
                       inlineFun: true)

         ',': builtin(types: ['class' record]
                      det:   [det det])

         '-': builtin(types: [number number number]
                      det:   [det det any(det)]
                      inlineFun: true)

         '-1': builtin(types: [number number]
                       det:   [det any(det)]
                       inlineFun: true)

         '.': builtin(types: [recordCOrChunk feature value]
                      det:   [detOrKinded det any]
                      inlineFun: true)

         '/': builtin(types: [float float float]
                      det:   [det det any(det)]
                      inlineFun: true)

         '<': builtin(types: [comparable comparable bool]
                      det:   [det det any(det)]
                      inlineFun: true rel: '<Rel')

         '<-': builtin(types: [feature value]
                       det:   [det any]
                       inlineRel: true)

         '<Rel': builtin(types: [comparable comparable]
                         det:   [det det]
                         inlineRel: true)

         '=': builtin(types: [value value]
                      det:   [any any])

         '=<': builtin(types: [comparable comparable bool]
                       det:   [det det any(det)]
                       inlineFun: true rel: '=<Rel')

         '=<Rel': builtin(types: [comparable comparable]
                          det:   [det det]
                          inlineRel: true)

         '==': builtin(types: [value value bool]
                       det:   [det det any(det)]
                       inlineFun: true eqeq: true)

         '>': builtin(types: [comparable comparable bool]
                      det:   [det det any(det)]
                      inlineFun: true rel: '>Rel')

         '>=': builtin(types: [comparable comparable bool]
                       det:   [det det any(det)]
                       inlineFun: true rel: '>=Rel')

         '>=Rel': builtin(types: [comparable comparable]
                          det:   [det det]
                          inlineRel: true)

         '>Rel': builtin(types: [comparable comparable]
                         det:   [det det]
                         inlineRel: true)

         '@': builtin(types: [feature value]
                      det:   [det any]
                      inlineFun: true)

         'Abs': builtin(types: [number number]
                        det: [det any(det)]
                        inlineFun: true)

         'Access': builtin(types: [cell value]
                           det: [det any]
                           inlineFun: true)

         'Acos': builtin(types: [float float]
                         det: [det any(det)]
                         inlineFun: true)

         'Adjoin': builtin(types: [record record record]
                           det: [det det any(det)]
                           inlineFun: true)

         'AdjoinAt': builtin(types: [record feature value record]
                             det: [det det any any(det)])

         'AdjoinList': builtin(types: [record list(pair(feature value)) record]
                               det: [det det any(det)])

         'Alarm': builtin(types: [int value]
                          det: [det any])

         'And': builtin(types: [bool bool bool]
                        det: [det det any(det)]
                        inlineFun: true)

         'Arity': builtin(types: [record list(feature)]
                          det: [det any(det)]
                          inlineFun: true)

         'Array.high': builtin(types: [array int]
                               det: [det any(det)]
                               inlineFun: true)

         'Array.low': builtin(types: [array int]
                              det: [det any(det)]
                              inlineFun: true)

         'Asin': builtin(types: [float float]
                         det: [det any(det)]
                         inlineFun: true)

         'Assign': builtin(types: [cell value]
                           det: [det any]
                           inlineRel: true)

         'Atan': builtin(types: [float float]
                         det: [det any(det)]
                         inlineFun: true)

         'Atan2': builtin(types: [float float float]
                          det: [det det any(det)]
                          inlineFun: true)

         'AtomToString': builtin(types: [atom string]
                                 det: [det any(det)]
                                 inlineFun: true)

         'Ceil': builtin(types: [float float]
                         det: [det any(det)]
                         inlineFun: true)

         'Char.isAlNum': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isAlpha': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isCntrl': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isDigit': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isGraph': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isLower': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isPrint': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isPunct': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isSpace': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isUpper': builtin(types: [char bool]
                                 det: [det any(det)])

         'Char.isXDigit': builtin(types: [char bool]
                                  det: [det any(det)])

         'Char.toAtom': builtin(types: [char atom]
                                det: [det any(det)])

         'Char.toLower': builtin(types: [char char]
                                 det: [det any(det)])

         'Char.toUpper': builtin(types: [char char]
                                 det: [det any(det)])

         'Char.type': builtin(types: [char atom]
                              det: [det any(det)])

         'CondSelect': builtin(types: [recordCOrChunk feature value value]
                               det: [detOrKinded det any any]
                               inlineFun: true)

         'Cos': builtin(types: [float float]
                        det: [det any(det)]
                        inlineFun: true)

         'Delay': builtin(types: [int]
                          det: [det]
                          destroysArguments: true)

         'Dictionary.clone': builtin(types: [dictionary dictionary]
                                     det: [det any(det)])

         'Dictionary.condGet': builtin(types: [dictionary feature value value]
                                       det: [det det any any]
                                       inlineFun: true)

         'Dictionary.entries': builtin(types: [dictionary
                                               list(pair(feature value))]
                                       det: [det any(det)])

         'Dictionary.get': builtin(types: [dictionary feature value]
                                   det: [det det any]
                                   inlineFun: true)

         'Dictionary.items': builtin(types: [dictionary list(value)]
                                     det: [det any(det)])

         'Dictionary.keys': builtin(types: [dictionary list(feature)]
                                    det: [det any(det)])

         'Dictionary.member': builtin(types: [dictionary feature bool]
                                      det: [det det any(det)]
                                      inlineFun: true)

         'Dictionary.put': builtin(types: [dictionary feature value]
                                   det: [det det any]
                                   inlineRel: true)

         'Dictionary.remove': builtin(types: [dictionary feature]
                                      det: [det det]
                                      inlineRel: true)

         'Exchange': builtin(types: [cell value value]
                             det: [det any any]
                             inlineRel: true)

         'Exp': builtin(types: [float float]
                        det: [det any(det)]
                        inlineFun: true)

         'FloatToInt': builtin(types: [float int]
                               det: [det any(det)]
                               inlineFun: true)

         'FloatToString': builtin(types: [float string]
                                  det: [det any(det)])

         'Floor': builtin(types: [float float]
                          det: [det any(det)]
                          inlineFun: true)

         'Get': builtin(types: [array int value]
                        det: [det det any]
                        inlineFun: true)

         'HasFeature': builtin(types: [recordCOrChunk feature bool]
                               det: [detOrKinded det any(det)]
                               inlineFun: true)

         'IntToFloat': builtin(types: [int float]
                               det: [det any(det)]
                               inlineFun: true)

         'IntToString': builtin(types: [int string]
                                det:   [det any(det)])

         'IsArray': builtin(types: [value bool]
                            det:   [det any(det)]
                            inlineFun: true)

         'IsAtom': builtin(types: [value bool]
                           det:   [det any(det)]
                           inlineFun: true rel: 'isAtomRel')

         'IsBool': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isBoolRel')

         'IsCell': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isCellRel')

         'IsChar': builtin(types: [value bool]
                           det: [det any(det)])

         'IsChunk': builtin(types: [value bool]
                            det: [det any(det)]
                            inlineFun: true rel: 'isChunkRel')

         'IsDet': builtin(types: [value bool]
                        det: [any any(det)]
                        inlineFun: true rel: 'IsDetRel')

         'IsDetRel': builtin(types: [value]
                             det: [any(det)]
                             inlineRel: true)

         'IsDictionary': builtin(types: [value bool]
                                 det: [det any(det)]
                                 inlineFun: true)

         'IsFloat': builtin(types: [value bool]
                            det: [det any(det)]
                            inlineFun: true rel: 'isFloatRel')

         'IsFree': builtin(types: [value bool]
                           det: [any(det) any(det)]
                           inlineFun: true rel: 'IsFreeRel')

         'IsFreeRel': builtin(types: [value]
                              det: [any(det)]
                              inlineRel: true)

         'IsInt': builtin(types: [value bool]
                          det: [det any(det)]
                          inlineFun: true rel: 'isIntRel')

         'IsKinded': builtin(types: [value bool]
                             det: [any any(det)]
                             inlineFun: true rel: 'IsKindedRel')

         'IsKindedRel': builtin(types: [value]
                                det: [any(det)]
                                inlineRel: true)

         'IsLiteral': builtin(types: [value bool]
                              det: [det any(det)]
                              inlineFun: true rel: 'isLiteralRel')

         'IsLock': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isLockRel')

         'IsName': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isNameRel')

         'IsNumber': builtin(types: [value bool]
                             det: [det any(det)]
                             inlineFun: true rel: 'isNumberRel')

         'IsObject': builtin(types: [value bool]
                             det: [det any(det)]
                             inlineFun: true rel: 'isObjectRel')

         'IsPort': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isPortRel')

         'IsProcedure': builtin(types: [value bool]
                                det: [det any(det)]
                                inlineFun: true rel: 'isProcedureRel')

         'IsRecord': builtin(types: [value bool]
                             det: [det any(det)]
                             inlineFun: true rel: 'isRecordRel')

         'IsRecordC': builtin(types: [value bool]
                              det: [detOrKinded any(det)]
                              inlineFun: true rel: 'isRecordCRel')

         'IsSpace': builtin(types: [value bool]
                            det: [det any(det)])

         'IsString': builtin(types: [value bool]
                             det: [det any(det)])

         'IsTuple': builtin(types: [value bool]
                            det: [det any(det)]
                            inlineFun: true rel: 'isTupleRel')

         'IsUnit': builtin(types: [value bool]
                           det: [det any(det)]
                           inlineFun: true rel: 'isUnitRel')

         'IsVirtualString': builtin(types: [value bool]
                                    det: [det any(det)])

         'Label': builtin(types: [recordC literal]
                          det: [detOrKinded any(det)]
                          inlineFun: true)

         'Log': builtin(types: [float float]
                        det: [det any(det)]
                        inlineFun: true)

         'MakeTuple': builtin(types: [literal int tuple]
                              det: [det det any(det)]
                              inlineFun: true)

         'Max': builtin(types: [comparable comparable comparable]
                        det: [det det any(det)]
                        inlineFun: true)

         'Min': builtin(types: [comparable comparable comparable]
                        det: [det det any(det)]
                        inlineFun: true)

         'New': builtin(types: ['class' record 'object']
                        det: [det det any(det)])

         'NewArray': builtin(types: [int int value array]
                             det: [det det any(det) any(det)])

         'NewCell': builtin(types: [value cell]
                            det: [any(det) any(det)])

         'NewChunk': builtin(types: [record chunk]
                             det: [det any(det)])

         'NewDictionary': builtin(types: [dictionary]
                                  det: [any(det)])

         'NewLock': builtin(types: ['lock']
                            det: [any(det)])

         'NewName': builtin(types: [name]
                            det: [any(det)])

         'NewUniqueName': builtin(types: [atom name]
                                  det: [det any(det)])

         'NewPort': builtin(types: [list(value) port]
                            det: [any(det) any(det)])

         'Not': builtin(types: [bool bool]
                        det: [det any(det)]
                        inlineFun: true)

         'Or': builtin(types: [bool bool bool]
                       det: [det det any(det)]
                       inlineFun: true)

         'Port.close': builtin(types: [port]
                               det: [det])
         'Print': builtin(types: [virtualString]
                          det: [any]
                          inlineRel: true)

         'ProcedureArity': builtin(types: [procedure int]
                                   det: [det any(det)]
                                   inlineFun: true)

         'Put': builtin(types: [array int value]
                        det: [det det any]
                        inlineRel: true)

         'Round': builtin(types: [float float]
                          det: [det any(det)]
                          inlineFun: true)

         'Send': builtin(types: [port value]
                         det: [det any(det)])

         'Show': builtin(types: [value]
                         det: [any]
                         inlineRel: true)

         'Sin': builtin(types: [float float]
                        det: [det any(det)]
                        inlineFun: true)

         'Space.ask': builtin(types: [space tuple]
                              det: [det any(det)])

         'Space.askVerbose': builtin(types: [space tuple]
                                     det: [det any(det)])

         'Space.clone': builtin(types: [space space]
                                det: [det any(det)])

         'Space.commit': builtin(types: [space value]
                                 det: [det det]
                                 destroysArguments: true)

         'Space.inject': builtin(types: [space 'unary procedure']
                                 det: [det det]
                                 destroysArguments: true)

         'Space.merge': builtin(types: [space value]
                                det: [det any])

         'Space.new': builtin(types: ['unary procedure' space]
                              det: [det any(det)]
                              destroysArguments: true)

         'Sqrt': builtin(types: [float float]
                         det: [det any(det)]
                         inlineFun: true)

         'String.isAtom': builtin(types: [string bool]
                                  det: [det any(det)])

         'String.isFloat': builtin(types: [string bool]
                                   det: [det any(det)])

         'String.isInt': builtin(types: [string bool]
                                 det: [det any(det)])

         'StringToAtom': builtin(types: [string atom]
                                 det: [det any(det)])

         'StringToFloat': builtin(types: [string float]
                                  det: [det any(det)])

         'StringToInt': builtin(types: [string int]
                                det: [det any(det)])

         'System.valueToVirtualString': builtin(types: [value int int
                                                        virtualString]
                                                det: [any det det any(det)])

         'Tan': builtin(types: [float float]
                        det: [det any(det)]
                        inlineFun: true)

         'TellRecord': builtin(types: [literal record]
                               det: [det any])

         'Thread.getPriority': builtin(types: ['thread' atom]
                                       det: [det any(det)])

         'Thread.id': builtin(types: ['thread' int]
                              det: [det any(det)])

         'Thread.injectException': builtin(types: ['thread' value]
                                           det: [det det])

         'Thread.is': builtin(types: [value bool]
                              det: [det any(det)])

         'Thread.isSuspended': builtin(types: ['thread' bool]
                                       det: [det any(det)])

         'Thread.preempt': builtin(types: ['thread']
                                   det: [det])

         'Thread.resume': builtin(types: ['thread']
                                  det: [det])

         'Thread.setPriority': builtin(types: ['thread' atom]
                                       det: [det det])

         'Thread.state': builtin(types: ['thread' atom]
                                 det: [det any(det)])

         'Thread.suspend': builtin(types: ['thread']
                                   det: [det])

         'Thread.terminate': builtin(types: ['thread']
                                     det: [det])

         'Thread.this': builtin(types: ['thread']
                                det: [any(det)])

         'Type.ofValue': builtin(types: [value atom]
                                 det: [det any(det)]
                                 inlineFun: true)

         'Value.status': builtin(types: [value tuple]
                                 det: [any any(det)]
                                 inlineFun: true)

         'Wait': builtin(types: [value]
                         det: [any(det)]
                         inlineRel: true)

         'WaitOr': builtin(types: [value value]
                           det: [any any])

         'Width': builtin(types: [record int]
                          det: [det any(det)]
                          inlineFun: true)

         'WidthC': builtin(types: [recordC int]
                           det: [detOrKinded any])

         '\\=': builtin(types: [value value bool]
                        det: [det det any(det)]
                        inlineFun: true eqeq: true)

         '^': builtin(types: [recordC feature value]
                      det: [detOrKinded det any]
                      inlineFun: true)

         'builtin': builtin(types: [atom int procedure]
                            det: [det det any(det)])

         'div': builtin(types: [int int int]
                        det: [det det any(det)]
                        inlineFun: true)

         'fPow': builtin(types: [float float float]
                         det: [det det any(det)]
                         inlineFun: true)

         'getClass': builtin(types: [value value]
                             det: [det any(det)]
                             inlineFun: true)

         'getFalse': builtin(types: [bool]
                             det: [any(det)])

         'getOONames': builtin(types: [name name name name name]
                               det: [any(det) any(det) any(det) any(det)
                                     any(det)])

         'getSelf': builtin(types: ['object']
                            det: [any(det)])

         'getTrue': builtin(types: [bool]
                            det: [any(det)])

         'getUnit': builtin(types: ['unit']
                            det: [any(det)])

         'isAtomRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isBoolRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isCellRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isChunkRel': builtin(types: [value]
                               det: [det]
                               inlineRel: true)

         'isFloatRel': builtin(types: [value]
                               det: [det]
                               inlineRel: true)

         'isIntRel': builtin(types: [value]
                             det: [det]
                             inlineRel: true)

         'isLiteralRel': builtin(types: [value]
                                 det: [det]
                                 inlineRel: true)

         'isLockRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isNameRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isNumberRel': builtin(types: [value]
                                det: [det]
                                inlineRel: true)

         'isObjectRel': builtin(types: [value]
                                det: [det]
                                inlineRel: true)

         'isPortRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'isProcedureRel': builtin(types: [value]
                                   det: [det]
                                   inlineRel: true)

         'isRecordCRel': builtin(types: [value]
                                 det: [detOrKinded]
                                 inlineRel: true)

         'isRecordRel': builtin(types: [value]
                                det: [det]
                                inlineRel: true)

         'isTupleRel': builtin(types: [value]
                               det: [det]
                               inlineRel: true)

         'isUnitRel': builtin(types: [value]
                              det: [det]
                              inlineRel: true)

         'getTclNames': builtin(types: [value value value]
                                det: [any(det) any(det) any(det)])

         'makeClass': builtin(types: [dictionary record record dictionary bool
                                      'class']
                              det: [det det det det det any(det)])

         'mod': builtin(types: [int int int]
                        det: [det det any(det)]
                        inlineFun: true)

         'monitorArity': builtin(types: [recordC value list(feature)]
                                 det: [detOrKinded any any])

         'newObject': builtin(types: ['class' 'object']
                              det: [det any(det)]
                              inlineFun: true)

         'onToplevel': builtin(types: [bool]
                               det: [any(det)])

         'ooExch': builtin(types: [feature value value]
                           det: [det any any]
                           inlineFun: true)

         'ooGetLock': builtin(types: ['lock']
                              det: [any(det)]
                              inlineRel: true)

         'raise': builtin(types: [value]
                          det: [det]
                          doesNotReturn: true)

         'raiseError': builtin(types: [value]
                               det: [det]
                               doesNotReturn: true)

         'record': builtin(types: [literal list(pair(feature value)) record]
                           det: [det det any(det)])

         'send': builtin(types: [record 'class' 'object']
                         det: [det det det])

         'setDefaultExceptionHandler': builtin(types: ['unary procedure']
                                               det: [det])

         'setMethApplHdl': builtin(types: ['binary procedure']
                                   det: [det])

         'setSelf': builtin(types: ['object']
                            det: [det])

         'tellRecordSize': builtin(types: [literal int record]
                                   det: [det det any])

         'virtualStringLength': builtin(types: [virtualString int int]
                                        det: [any any any(det)])

         '~': builtin(types: [number number]
                      det: [det any(det)]
                      inlineFun: true))
in
   %%
   %% Do some consistency checks on the builtin table
   %%

   {Record.forAllInd BuiltinTable
    proc {$ Name Entry}
       try
          case {HasFeature Entry types} andthen {HasFeature Entry det} then
             case {Length Entry.types} == {Length Entry.det}
             then skip
             else raise bad(1) end
             end
          else raise bad(2) end
          end
          case {HasFeature Entry inlineFun} then
             case {HasFeature Entry eqeq} then
                case {IsBool Entry.eqeq} then skip
                else raise bad(3) end
                end
             else skip
             end
             case {HasFeature Entry inlineRel} then raise bad(4) end
             elsecase {IsBool Entry.inlineFun} then skip
             else raise bad(5) end
             end
          elsecase {HasFeature Entry eqeq} then raise bad(6) end
          elsecase {HasFeature Entry inlineRel} then
             case {IsBool Entry.inlineRel} then skip
             else raise bad(7) end
             end
          else skip
          end
          case {HasFeature Entry rel} then
             case {HasFeature Entry inlineFun} then
                case {HasFeature BuiltinTable Entry.rel} then
                   case {Length Entry.types} - 1 ==
                      {Length (BuiltinTable.(Entry.rel)).types} then skip
                   else raise bad(8) end
                   end
                else raise bad(9) end
                end
             else raise bad(10) end
             end
          else skip
          end
          case {HasFeature Entry doesNotReturn} then
             case {IsBool Entry.doesNotReturn} then skip
             else raise bad(11) end
             end
          else skip
          end
       catch bad(N) then
          {System.showInfo 'bad ('#N#') BuiltinTable entry for \''#Name#'\''}
       end
    end}

   %%
   %% Accessing the Builtin Table
   %%

   fun {GetBuiltinInfo Name}
      {CondSelect BuiltinTable Name noInformation}
   end
end
