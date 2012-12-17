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

#include "boostenvutils.hh"
#include "boostenvtcp.hh"
#include "boostenvpipe.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

ProtectedNode BoostBasedVM::allocAsyncIONode(StableNode* node) {
  _asyncIONodeCount++;
  return vm->protect(*node);
}

void BoostBasedVM::releaseAsyncIONode(const ProtectedNode& node) {
  assert(_asyncIONodeCount > 0);
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

///////////////
// Utilities //
///////////////

atom_t systemStrToAtom(VM vm, const char* str) {
  size_t len = std::strlen(str);

  auto ustr = std::unique_ptr<nchar[]>(new nchar[len+1]);
  for (size_t i = 0; i <= len; i++)
    ustr[i] = (nchar) str[i];

  return vm->getAtom(len, ustr.get());
}

atom_t systemStrToAtom(VM vm, const std::string& str) {
  size_t len = str.length();

  auto ustr = std::unique_ptr<nchar[]>(new nchar[len+1]);
  for (size_t i = 0; i <= len; i++)
    ustr[i] = (nchar) str[i];

  return vm->getAtom(len, ustr.get());
}

template <typename T>
void raiseOSError(VM vm, const nchar* function, nativeint errnum, T&& message) {
  raiseSystem(vm, MOZART_STR("os"),
              MOZART_STR("os"), function, errnum, std::forward<T>(message));
}

void raiseOSError(VM vm, const nchar* function, int errnum) {
  raiseOSError(vm, function, errnum,
               systemStrToAtom(vm, std::strerror(errnum)));
}

void raiseLastOSError(VM vm, const nchar* function) {
  raiseOSError(vm, function, errno);
}

void raiseOSError(VM vm, const nchar* function, boost::system::error_code& ec) {
  raiseOSError(vm, function, ec.value(), systemStrToAtom(vm, ec.message()));
}

void raiseOSError(VM vm, const nchar* function,
                  const boost::system::system_error& error) {
  raiseOSError(vm, function, error.code().value(),
               systemStrToAtom(vm, error.what()));
}

} }

#endif

#if !defined(MOZART_GENERATOR) && !defined(MOZART_BUILTIN_GENERATOR)
namespace mozart { namespace boostenv { namespace builtins {
#include "boostenvbuiltins.hh"
} } }
#endif

#endif // __BOOSTENV_H
