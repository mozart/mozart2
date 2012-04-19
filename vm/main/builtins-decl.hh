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

#ifndef __BUILTINS_DECL_H
#define __BUILTINS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

namespace builtins {

typedef RichNode In;
typedef UnstableNode& Out;

////////////
// Module //
////////////

/**
 * Base class for classes representing builtin modules
 */
class Module {
public:
  Module(const std::string& name): _name(name) {}

  const std::string& getName() {
    return _name;
  }
private:
  std::string _name;
};

/////////////////
// BaseBuiltin //
/////////////////

/**
 * Abstract base class for classes representing builtin procedures
 */
class BaseBuiltin {
public:
  BaseBuiltin(const std::string& name, size_t arity):
    _name(name), _arity(arity) {}

  const std::string& getName() {
    return _name;
  }

  size_t getArity() {
    return _arity;
  }

  virtual OpResult call(VM vm, UnstableNode* args[]) = 0;
private:
  std::string _name;
  size_t _arity;
};

namespace internal {

/////////////////////////
// Builtin entry point //
/////////////////////////

template <class T, size_t arity, size_t i, class... Args>
class BuiltinEntryPointRec {
public:
  static_assert(i == sizeof...(Args), "i != sizeof...(Args)");

  static OpResult call(T& builtin, VM vm, UnstableNode* args[],
                       Args&&... argsDone) {
    return BuiltinEntryPointRec<T, arity, i+1, Args..., UnstableNode&>::call(
      builtin, vm, args, std::forward<Args>(argsDone)..., *args[i]);
  }
};

template <class T, size_t arity, class... Args>
class BuiltinEntryPointRec<T, arity, arity, Args...> {
public:
  static OpResult call(T& builtin, VM vm, UnstableNode* args[],
                       Args&&... argsDone) {
    return builtin(vm, std::forward<Args>(argsDone)...);
  }
};

template <class T, size_t arity>
class BuiltinEntryPoint {
public:
  static OpResult call(T& builtin, VM vm, UnstableNode* args[]) {
    return BuiltinEntryPointRec<T, arity, 0>::call(builtin, vm, args);
  }
};

}

/////////////
// Builtin //
/////////////

/**
 * Base class for classes representing builtin procedures
 * The Self type parameter must be the actual class of the builtin. So a
 * declaration of a builtin class will look like this:
 *   class SomeBuiltin: public Builtin<SomeBuiltin> { ... };
 */
template <class Self>
class Builtin: public BaseBuiltin {
private:
  template <class Signature>
  struct ExtractArity {};

  template <class Class, class... Args>
  struct ExtractArity<OpResult (Class::*)(VM vm, Args...)> {
    static const size_t arity = sizeof...(Args);
  };
public:
  Builtin(const std::string& name): BaseBuiltin(name, arity) {}

  OpResult call(VM vm, UnstableNode* args[]) {
    return internal::BuiltinEntryPoint<Self, arity>::call(
      *static_cast<Self*>(this), vm, args);
  }
public:
  static const size_t arity = ExtractArity<decltype(&Self::operator())>::arity;

  static OpResult entryPoint(VM vm, UnstableNode* args[]) {
    return builtin().call(vm, args);
  }

  static Self& builtin() {
    return rawBuiltin;
  }
private:
  static Self rawBuiltin;
};

template <class Self>
Self Builtin<Self>::rawBuiltin;

}

}

#endif // __BUILTINS_DECL_H
