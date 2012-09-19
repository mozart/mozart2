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

#include "boostenvtcp.hh"
#include "boostenvdatatypes.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

ProtectedNode BoostBasedVM::allocAsyncIONode(StableNode* node) {
  _asyncIONodeCount++;
  return ozProtect(vm, *node);
}

void BoostBasedVM::releaseAsyncIONode(const ProtectedNode& node) {
  assert(_asyncIONodeCount > 0);

  ozUnprotect(vm, node);
  _asyncIONodeCount--;
}

ProtectedNode BoostBasedVM::createAsyncIOFeedbackNode(UnstableNode& readOnly) {
  StableNode* stable = new (vm) StableNode;
  stable->init(vm, Variable::build(vm));

  readOnly = ReadOnly::newReadOnly(vm, *stable);

  return allocAsyncIONode(stable);
}

template <class LT, class... Args>
void BoostBasedVM::bindAndReleaseAsyncIOFeedbackNode(
  const ProtectedNode& ref, LT&& label, Args&&... args) {

  UnstableNode rhs = buildTuple(vm, std::forward<LT>(label),
                                std::forward<Args>(args)...);
  DataflowVariable(*ref).bind(vm, rhs);
  releaseAsyncIONode(ref);
}

template <class LT, class... Args>
void BoostBasedVM::raiseAndReleaseAsyncIOFeedbackNode(
  const ProtectedNode& ref, LT&& label, Args&&... args) {

  UnstableNode exception = buildTuple(vm, std::forward<LT>(label),
                                      std::forward<Args>(args)...);
  bindAndReleaseAsyncIOFeedbackNode(
    ref, FailedValue::build(vm, RichNode(exception).getStableRef(vm)));
}

void BoostBasedVM::postVMEvent(std::function<void()> callback) {
  {
    boost::unique_lock<boost::mutex> lock(_conditionWorkToDoInVMMutex);
    _vmEventsCallbacks.push(callback);
  }

  vm->requestExitRun();
  _conditionWorkToDoInVM.notify_all();
}

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
    raise(vm, MOZART_STR("system"), MOZART_STR("invalidfd"), fd);
}

std::FILE* BoostBasedVM::getFile(RichNode fd) {
  return getFile(getArgument<nativeint>(vm, fd, MOZART_STR("filedesc")));
}

///////////////
// Utilities //
///////////////

namespace internal {
  template <class T>
  inline
  void ozListForEach(VM vm, RichNode list, size_t index,
                     const nchar* expectedType,
                     std::function<void (VM, size_t, T)> f) {
    using namespace patternmatching;

    T head;
    UnstableNode tail;

    if (matchesCons(vm, list, capture(head), capture(tail))) {
      f(vm, index, head);
      ozListForEach(vm, tail, index+1, expectedType, f);
    } else if (matches(vm, list, vm->coreatoms.nil)) {
      // end
    } else {
      raiseTypeError(vm, expectedType, list);
    }
  }
}

void ozStringToBuffer(VM vm, RichNode value, size_t size, char* buffer) {
  internal::ozListForEach<char>(
    vm, value, 0, MOZART_STR("string"),
    [size, buffer] (VM vm, size_t i, char c) {
      assert(i < size);
      buffer[i] = c;
    });
}

void ozStringToBuffer(VM vm, RichNode value, std::vector<char>& buffer) {
  size_t size = ozListLength(vm, value);
  buffer.resize(size);

  internal::ozListForEach<char>(
    vm, value, 0, MOZART_STR("string"),
    [size, &buffer] (VM vm, size_t i, char c) {
      assert(i < size);
      buffer[i] = c;
    });
}

std::string ozStringToStdString(VM vm, RichNode value) {
  std::stringbuf buffer;

  internal::ozListForEach<char>(
    vm, value, 0, MOZART_STR("string"),
    [&buffer] (VM vm, size_t i, char c) {
      buffer.sputc(c);
    });

  return buffer.str();
}

UnstableNode stdStringToOzString(VM vm, const std::string& value) {
  UnstableNode res = build(vm, vm->coreatoms.nil);

  for (auto iter = value.rbegin(); iter != value.rend(); ++iter) {
    res = buildCons(vm, *iter, std::move(res));
  }

  return std::move(res);
}

std::unique_ptr<nchar[]> systemStrToMozartStr(const char* str) {
  size_t len = std::strlen(str);

  auto ustr = std::unique_ptr<nchar[]>(new nchar[len+1]);
  for (size_t i = 0; i <= len; i++)
    ustr[i] = (nchar) str[i];

  return ustr;
}

std::unique_ptr<nchar[]> systemStrToMozartStr(const std::string& str) {
  size_t len = str.length();

  auto ustr = std::unique_ptr<nchar[]>(new nchar[len+1]);
  for (size_t i = 0; i <= len; i++)
    ustr[i] = (nchar) str[i];

  return ustr;
}

void raiseOSError(VM vm, int errnum) {
  auto message = systemStrToMozartStr(std::strerror(errnum));
  raise(vm, MOZART_STR("system"), errnum, message.get());
}

void raiseLastOSError(VM vm) {
  raiseOSError(vm, errno);
}

void raiseSystemError(VM vm, const boost::system::system_error& error) {
  auto message = systemStrToMozartStr(error.what());
  raise(vm, MOZART_STR("system"), error.code().value(), message.get());
}

} }

#endif

#if !defined(MOZART_GENERATOR) && !defined(MOZART_BUILTIN_GENERATOR)
namespace mozart { namespace boostenv { namespace builtins {
#include "boostenvbuiltins.hh"
} } }
#endif

#endif // __BOOSTENV_H
