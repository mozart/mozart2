// Copyright © 2011, Université catholique de Louvain
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

#ifndef __BOOSTENV_H
#define __BOOSTENV_H

#include "boostenv-decl.hh"

#include "modos.hh"

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

nativeint BoostBasedVM::registerFile(std::FILE* file) {
  nativeint result = 0;
  while (openedFiles.count(result) != 0)
    result++;

  openedFiles[result] = file;
  return result;
}

void BoostBasedVM::unregisterFile(nativeint fd) {
  openedFiles.erase(fd);
}

std::FILE* BoostBasedVM::getFile(nativeint fd) {
  auto iter = openedFiles.find(fd);

  if (iter != openedFiles.end())
    return iter->second;
  else
    return nullptr;
}

OpResult BoostBasedVM::getFile(nativeint fd, std::FILE*& result) {
  result = getFile(fd);
  if (result == nullptr)
    return raise(vm, u"system", u"invalidfd", fd);
  return OpResult::proceed();
}

OpResult BoostBasedVM::getFile(RichNode fd, std::FILE*& result) {
  nativeint intfd = 0;
  MOZART_GET_ARG(intfd, fd, u"filedesc");

  return getFile(intfd, result);
}

///////////////
// Utilities //
///////////////

namespace internal {
  inline
  OpResult ozListLengthEx(VM vm, RichNode list, size_t& accumulator) {
    using namespace patternmatching;

    OpResult res = OpResult::proceed();
    UnstableNode tail;

    if (matchesCons(vm, res, list, wildcard(), capture(tail))) {
      accumulator++;
      return ozListLengthEx(vm, tail, accumulator);
    } else if (matches(vm, res, list, vm->coreatoms.nil)) {
      return OpResult::proceed();
    } else {
      return matchTypeError(vm, res, list, u"list");
    }
  }

  template <class T>
  inline
  OpResult ozListForEach(VM vm, RichNode list, size_t index,
                         const char16_t* expectedType,
                         std::function<OpResult (VM, size_t, T)> f) {
    using namespace patternmatching;

    OpResult res = OpResult::proceed();
    T head;
    UnstableNode tail;

    if (matchesCons(vm, res, list, capture(head), capture(tail))) {
      MOZART_CHECK_OPRESULT(f(vm, index, head));
      return ozListForEach(vm, tail, index+1, expectedType, f);
    } else if (matches(vm, res, list, vm->coreatoms.nil)) {
      return OpResult::proceed();
    } else {
      return matchTypeError(vm, res, list, expectedType);
    }
  }
}

OpResult ozListLength(VM vm, RichNode list, size_t& result) {
  result = 0;
  return internal::ozListLengthEx(vm, list, result);
}

OpResult ozStringToBuffer(VM vm, RichNode value, size_t size, char* buffer) {
  MOZART_CHECK_OPRESULT(internal::ozListForEach<char>(
    vm, value, 0, u"string",
    [size, buffer] (VM vm, size_t i, char c) -> OpResult {
      assert(i < size);
      buffer[i] = c;
      return OpResult::proceed();
    }));

  return OpResult::proceed();
}

OpResult ozStringToStdString(VM vm, RichNode value, std::string& result) {
  std::stringbuf buffer;

  MOZART_CHECK_OPRESULT(internal::ozListForEach<char>(
    vm, value, 0, u"string", [&buffer] (VM vm, size_t i, char c) -> OpResult {
      buffer.sputc(c);
      return OpResult::proceed();
    }));

  result = buffer.str();
  return OpResult::proceed();
}

OpResult stdStringToOzString(VM vm, std::string& value, UnstableNode& result) {
  UnstableNode res = trivialBuild(vm, vm->coreatoms.nil);

  for (auto iter = value.rbegin(); iter != value.rend(); ++iter) {
    res = buildCons(vm, *iter, std::move(res));
  }

  result = std::move(res);
  return OpResult::proceed();
}

OpResult raiseOSError(VM vm, int errnum) {
  const char* message = std::strerror(errnum);
  size_t len = std::strlen(message);

  auto umessage = std::unique_ptr<char16_t[]>(new char16_t[len+1]);
  for (size_t i = 0; i <= len; i++)
    umessage[i] = (char16_t) message[i];

  return raise(vm, u"system", errnum, umessage.get());
}

OpResult raiseLastOSError(VM vm) {
  return raiseOSError(vm, errno);
}

} }

#endif // __BOOSTENV_H
