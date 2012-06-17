// Copyright © 2012, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef __CONS_H
#define __CONS_H

#include "mozartcore.hh"
#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart {

//////////
// Cons //
//////////

#include "Cons-implem.hh"

// Constructors ----------------------------------------------------------------

Implementation<Cons>::Implementation(VM vm, LString<nchar>&& string) {
  assert(!string.isErrorOrEmpty());
  _string = std::move(string);
}

Implementation<Cons>::Implementation(VM vm, RichNode head, RichNode tail) {
  _head.init(vm, head);
  _tail.init(vm, tail);
}

Implementation<Cons>::Implementation(VM vm, GR gr, Self from) {
  _string = newLString(vm, from->_string);
  if (!isString()) {
    gr->copyStableNode(_head, from->_head);
    gr->copyStableNode(_tail, from->_tail);
  }
}

// Cons properties -------------------------------------------------------------

OpResult Implementation<Cons>::getHead(VM vm, UnstableNode& result) {
  if (!isString()) {
    result.copy(vm, _head);

  } else {
    // Extract the first character.
    auto decodeRes = fromUTF(_string.string());
    if (decodeRes.second <= 0)
      return raiseUnicodeError(vm, (UnicodeErrorReason) decodeRes.second);
    result.make<SmallInt>(vm, decodeRes.first);
  }

  return OpResult::proceed();
}

OpResult Implementation<Cons>::getTail(VM vm, UnstableNode& result) {
  if (!isString()) {
    result.copy(vm, _tail);

  } else {
    // Slice the rest and return.
    nativeint stride = getUTFStride(_string.string());
    if (stride <= 0)
      return raiseUnicodeError(vm, (UnicodeErrorReason) stride);

    _string.withSubstring(stride, [&](const LString<nchar>& newString) {
      result = buildString(vm, newString.unsafeAlias());
    });
  }

  return OpResult::proceed();
}

OpResult Implementation<Cons>::getStableHeadAndTail(VM vm,
                                                    StableNode*& head,
                                                    StableNode*& tail) {
  if (!isString()) {
    head = &_head;
    tail = &_tail;
    return OpResult::proceed();
  }

  auto decodeRes = fromUTF(_string.string());
  if (decodeRes.second <= 0)
    return raiseUnicodeError(vm, (UnicodeErrorReason) decodeRes.second);

  head = new (vm) StableNode;
  tail = new (vm) StableNode;

  head->make<SmallInt>(vm, decodeRes.first);
  _string.withSubstring(decodeRes.second, [&, tail](const LString<nchar>& newString) {
    auto unstableTail = buildString(vm, newString.unsafeAlias());
    tail->init(vm, unstableTail);
  });
  return OpResult::proceed();
}

// RecordLike interface --------------------------------------------------------

OpResult Implementation<Cons>::getValueAt(Self self, VM vm,
                                          nativeint feature,
                                          UnstableNode& result) {
  if (feature == 1)
    return getHead(vm, result);
  else
    return getTail(vm, result);
}

OpResult Implementation<Cons>::label(Self self, VM vm,
                                     UnstableNode& result) {
  result = Atom::build(vm, vm->coreatoms.pipe);
  return OpResult::proceed();
}

OpResult Implementation<Cons>::width(Self self, VM vm, size_t& result) {
  result = 2;
  return OpResult::proceed();
}

OpResult Implementation<Cons>::arityList(Self self, VM vm,
                                         UnstableNode& result) {
  result = buildCons(vm, 1, buildCons(vm, 2, vm->coreatoms.nil));
  return OpResult::proceed();
}

OpResult Implementation<Cons>::clone(Self self, VM vm,
                                     UnstableNode& result) {
  result = buildCons(vm, Unbound::build(vm), Unbound::build(vm));
  return OpResult::proceed();
}

OpResult Implementation<Cons>::waitOr(Self self, VM vm,
                                      UnstableNode& result) {
  // No need to wait for strings.
  if (isString()) {
    result.make<SmallInt>(vm, 1);
    return OpResult::proceed();
  }

  UnstableNode tempHead(vm, _head);
  UnstableNode tempTail(vm, _tail);

  RichNode head = tempHead;
  RichNode tail = tempTail;

  // If there is a field which is bound, then return its feature
  if (!head.isTransient()) {
    result = SmallInt::build(vm, 1);
    return OpResult::proceed();
  } else if (!tail.isTransient()) {
    result = SmallInt::build(vm, 2);
    return OpResult::proceed();
  }

  // Create the control variable
  UnstableNode unstableControlVar = Variable::build(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.ensureStable(vm);

  // Add the control variable to the suspension list of both fields
  DataflowVariable(head).addToSuspendList(vm, controlVar);
  DataflowVariable(tail).addToSuspendList(vm, controlVar);

  // Wait for the control variable
  return OpResult::waitFor(vm, controlVar);
}

// resolveIsString -------------------------------------------------------------

inline
bool Implementation<Cons>::internalGetConsStuff(StableNode*& head,
                                                StableNode*& tail,
                                                LString<nchar>*& endStr) {
  head = &_head;
  tail = &_tail;
  endStr = &_string;
  return isString();
}

// Change the internal representation of this Cons object into a String. Returns
// 'proceed()' if the conversion is successful.
OpResult Implementation<Cons>::resolveIsString(Self self, VM vm) {
  if (isString())
    return OpResult::proceed();
  else if (isCons())
    return raiseTypeError(vm, NSTR("String"), self);

  std::vector<char32_t> buffer;
  LString<nchar>* endStr = nullptr;

  StableNode* headPtr = &_head;
  StableNode* tailPtr = &_tail;

  while (true) {
    UnstableNode tempHead (vm, *headPtr);
    RichNode head = tempHead;

    nativeint c;
    MOZART_CHECK_OPRESULT(IntegerValue(head).intValue(vm, c));
    if (c < 0 || c >= 0x110000)
      return raiseUnicodeError(vm, UnicodeErrorReason::outOfRange, self);
    else if (0xd800 <= c && c < 0xe000)
      return raiseUnicodeError(vm, UnicodeErrorReason::surrogate, self);

    buffer.push_back((char32_t) c);

    UnstableNode tempTail (vm, *tailPtr);
    RichNode tail = tempTail;

    if (tail.is<Atom>()) {
      if (tail.as<Atom>().value() == vm->coreatoms.nil)
        break;

    } else if (tail.is<Cons>()) {
      bool tailIsString = tail.as<Cons>().internalGetConsStuff(headPtr, tailPtr, endStr);
      if (tailIsString)
        break;
      else
        continue;
    }

    return raiseTypeError(vm, NSTR("String"), self);
  }

  LString<char32_t> leadStrUTF32 (buffer.data(), buffer.size());
  FreeableLString<nchar> leadStr = toUTF<nchar>(vm, leadStrUTF32);
  if (leadStr.isErrorOrEmpty()) {
    return raiseUnicodeError(vm, leadStr.error(), self);
  }

  if (endStr != nullptr && !endStr->isErrorOrEmpty()) {
    nativeint newLength = leadStr.length() + endStr->length();
    _string = FreeableLString<nchar>(vm, newLength, [&, endStr](nchar* newStr) {
      memcpy(newStr, leadStr.string(), leadStr.bytesCount());
      memcpy(newStr + leadStr.length(), endStr->string(), endStr->bytesCount());
    });
    free(std::move(leadStr));
  } else {
    _string = std::move(leadStr);
  }

  return OpResult::proceed();
}

// Miscellaneous methods -------------------------------------------------------

bool Implementation<Cons>::equals(Self self, VM vm, Self right,
                                  WalkStack& stack) {
  // If both sides are not 'string', push the comparison to the stack.
  if (!isString() && !right->isString()) {
    stack.push(vm, &_tail, &right->_tail);
    stack.push(vm, &_head, &right->_head);
    return true;
  }

  // Now try to resolve both sides as 'string'.
  resolveIsString(self, vm);
  right->resolveIsString(right, vm);

  // If both sides are really 'string', do value-based comparison.
  if (isString() && right->isString()) {
    return _string == right->_string;
  }

  // Otherwise, we still need to extract the head and tail parts, and push onto
  // the stack.
  StableNode* leftHead, *leftTail, *rightHead, *rightTail;
  OpResult res = getStableHeadAndTail(vm, leftHead, leftTail);
  if (!res.isProceed())
    return false;
  res = right->getStableHeadAndTail(vm, rightHead, rightTail);
  if (!res.isProceed())
    return false;

  stack.push(vm, leftTail, rightTail);
  stack.push(vm, leftHead, rightHead);
  return true;
}

void Implementation<Cons>::printReprToStream(Self self, VM vm,
                                             std::ostream& out, int depth) {
  if (!isString()) {
    out << repr(vm, _head, depth) << "|" << repr(vm, _tail, depth);
  } else {
    auto utf8Result = toUTF<char>(vm, _string);
    out << '"' << utf8Result << '"';
    free(std::move(utf8Result));
  }
}

// VirtualString interface -----------------------------------------------------

OpResult Implementation<Cons>::isVirtualString(Self self, VM vm, bool& result) {
  OpResult res = resolveIsString(self, vm);
  if (res.isProceed()) {
    result = true;
    return res;
  } else if (res.kind() == OpResult::orRaise) {
    result = false;
    return OpResult::proceed();
  } else {
    return res;
  }
}

OpResult Implementation<Cons>::toString(Self self, VM vm,
                                        std::basic_ostream<nchar>& sink) {
  MOZART_CHECK_OPRESULT(resolveIsString(self, vm));
  sink << _string;
  return OpResult::proceed();
}

OpResult Implementation<Cons>::vsLength(Self self, VM vm, nativeint& result) {
  MOZART_CHECK_OPRESULT(resolveIsString(self, vm));
  result = codePointCount(_string);
  return OpResult::proceed();
}

OpResult Implementation<Cons>::vsChangeSign(Self self, VM vm,
                                            RichNode replacement,
                                            UnstableNode& result) {
  result.copy(vm, self);
  return OpResult::proceed();
}

// StringLike interface --------------------------------------------------------

OpResult Implementation<Cons>::unsafeGetString(Self self, VM vm,
                                               LString<nchar>& result) {
  MOZART_CHECK_OPRESULT(resolveIsString(self, vm));
  result = _string.unsafeAlias();
  return OpResult::proceed();
}

}

#endif

#endif


