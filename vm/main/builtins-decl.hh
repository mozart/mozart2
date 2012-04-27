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

struct SpecializedBuiltinEntryPoint {
public:
  SpecializedBuiltinEntryPoint(): _pointer(nullptr) {}

  template <class... Args>
  SpecializedBuiltinEntryPoint(OpResult (*pointer)(VM, Args...)):
    _pointer((void (*)()) pointer) {}

  template <class... Args>
  OpResult operator()(VM vm, Args&&... args) {
    typedef OpResult (*type)(VM, Args...);
    type pointer = (type) _pointer;
    return pointer(vm, std::forward<Args>(args)...);
  }
private:
  void (*_pointer)();
};

typedef OpResult (*GenericBuiltinEntryPoint)(VM vm, UnstableNode* args[]);

namespace internal {

/////////////////////////
// Builtin entry point //
/////////////////////////

template <class T, size_t arity, size_t i = 0, class... Args>
struct BuiltinEntryPointGeneric {
  static_assert(i == sizeof...(Args), "i != sizeof...(Args)");

  static OpResult call(VM vm, UnstableNode* args[], Args&&... argsDone) {
    return BuiltinEntryPointGeneric<T, arity, i+1, Args..., UnstableNode&>::call(
      vm, args, std::forward<Args>(argsDone)..., *args[i]);
  }
};

template <class T, size_t arity, class... Args>
struct BuiltinEntryPointGeneric<T, arity, arity, Args...> {
  static OpResult call(VM vm, UnstableNode* args[], Args&&... argsDone) {
    return T::builtin()(vm, std::forward<Args>(argsDone)...);
  }
};

template <class T, size_t arity, size_t i = 0, class... Args>
struct BuiltinEntryPoint {
private:
  typedef BuiltinEntryPoint<T, arity, i+1, UnstableNode&, Args...> Next;
public:
  static SpecializedBuiltinEntryPoint getEntryPoint() {
    return Next::getEntryPoint();
  }

  static GenericBuiltinEntryPoint getGenericEntryPoint() {
    return Next::getGenericEntryPoint();
  }
};

template <class T, size_t arity, class... Args>
struct BuiltinEntryPoint<T, arity, arity, Args...> {
private:
  static OpResult entryPoint(VM vm, Args... args) {
    return T::builtin()(vm, args...);
  }

  static OpResult genericEntryPoint(VM vm, UnstableNode* args[]) {
    return BuiltinEntryPointGeneric<T, arity>::call(vm, args);
  }
public:
  static SpecializedBuiltinEntryPoint getEntryPoint() {
    return &entryPoint;
  }

  static GenericBuiltinEntryPoint getGenericEntryPoint() {
    return &genericEntryPoint;
  }
};

}

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
  BaseBuiltin(const std::string& name, size_t arity,
              SpecializedBuiltinEntryPoint entryPoint,
              GenericBuiltinEntryPoint genericEntryPoint):
    _name(name), _arity(arity), _entryPoint(entryPoint),
    _genericEntryPoint(genericEntryPoint) {}

  const std::string& getName() {
    return _name;
  }

  size_t getArity() {
    return _arity;
  }

  OpResult call(VM vm, UnstableNode* args[]) {
    return _genericEntryPoint(vm, args);
  }

  template <class... Args>
  OpResult call(VM vm, Args&&... args) {
    assert(sizeof...(args) == _arity);
    return _entryPoint(vm, std::forward<Args>(args)...);
  }
private:
  std::string _name;
  size_t _arity;
  SpecializedBuiltinEntryPoint _entryPoint;
  GenericBuiltinEntryPoint _genericEntryPoint;
};

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
  Builtin(const std::string& name): BaseBuiltin(
    name, arity(), getEntryPoint(), getGenericEntryPoint()) {}
public:
  static constexpr size_t arity() {
    return ExtractArity<decltype(&Self::operator())>::arity;
  }

  static Self& builtin() {
    return rawBuiltin;
  }
private:
  static SpecializedBuiltinEntryPoint getEntryPoint() {
    constexpr size_t ar = arity(); // work around a limitation of the compiler
    return internal::BuiltinEntryPoint<Self, ar>::getEntryPoint();
  }

  static GenericBuiltinEntryPoint getGenericEntryPoint() {
    constexpr size_t ar = arity(); // work around a limitation of the compiler
    return internal::BuiltinEntryPoint<Self, ar>::getGenericEntryPoint();
  }
private:
  static Self rawBuiltin;
};

template <class Self>
Self Builtin<Self>::rawBuiltin;

//////////////////////////
// Markers for builtins //
//////////////////////////

template <size_t opCode>
struct InlineAs {};

}

}

#endif // __BUILTINS_DECL_H
