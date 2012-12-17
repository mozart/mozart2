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
#include "opcodes.hh"

namespace mozart {

namespace builtins {

typedef RichNode In;
typedef UnstableNode& Out;

struct ParamInfo {
  enum Kind { pkIn, pkOut };

  Kind kind;
};

template <class T>
struct ParamTypeToKind {};

template <>
struct ParamTypeToKind<In> {
  static constexpr ParamInfo::Kind value = ParamInfo::pkIn;
};

template <>
struct ParamTypeToKind<Out> {
  static constexpr ParamInfo::Kind value = ParamInfo::pkOut;
};

struct SpecializedBuiltinEntryPoint {
public:
  SpecializedBuiltinEntryPoint(): _pointer(nullptr) {}

  template <class... Args>
  SpecializedBuiltinEntryPoint(void (*pointer)(VM, Args...)):
    _pointer((void (*)()) pointer) {}

  template <class... Args>
  void operator()(VM vm, Args&&... args) {
    typedef void (*type)(VM, Args...);
    type pointer = (type) _pointer;
    return pointer(vm, std::forward<Args>(args)...);
  }
private:
  void (*_pointer)();
};

typedef void (*GenericBuiltinEntryPoint)(VM vm, UnstableNode* args[]);

namespace internal {

/////////////////////////
// Builtin entry point //
/////////////////////////

template <class T, size_t arity, size_t i = 0, class... Args>
struct BuiltinEntryPointGeneric {
  static_assert(i == sizeof...(Args), "i != sizeof...(Args)");

  static void call(VM vm, UnstableNode* args[], Args&&... argsDone) {
    return BuiltinEntryPointGeneric<T, arity, i+1, Args..., UnstableNode&>::call(
      vm, args, std::forward<Args>(argsDone)..., *args[i]);
  }
};

template <class T, size_t arity, class... Args>
struct BuiltinEntryPointGeneric<T, arity, arity, Args...> {
  static void call(VM vm, UnstableNode* args[], Args&&... argsDone) {
    return T::call(vm, std::forward<Args>(argsDone)...);
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
  static void entryPoint(VM vm, Args... args) {
    return T::call(vm, args...);
  }

  static void genericEntryPoint(VM vm, UnstableNode* args[]) {
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

/////////////////////
// ExtractInlineAs //
/////////////////////

/**
 * Metafunction that tests whether T has a member "getInlineAsOpCodeInternal"
 * Taken from
 * http://cplusplus.co.il/2009/09/11/substitution-failure-is-not-an-error-1/
 */
template<typename T>
struct HasGetInlineAsOpCodeInternal {
  struct Fallback {
    int getInlineAsOpCodeInternal;
  };

  struct Derived : T, Fallback {};

  template<typename C, C>
  struct ChT;

  template<typename C>
  static char (&f(ChT<int Fallback::*, &C::getInlineAsOpCodeInternal>*))[1];

  template<typename C>
  static char (&f(...))[2];

  static constexpr bool value = sizeof(f<Derived>(0)) == 2;
};

template <class T, bool hasInlineAsOpCode>
struct ExtractInlineAs {
  static constexpr nativeint get() {
    return -1;
  }
};

template <class T>
struct ExtractInlineAs<T, true> {
  static constexpr nativeint get() {
    return T::getInlineAsOpCodeInternal();
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
              GenericBuiltinEntryPoint genericEntryPoint,
              nativeint opCode):
    _name(name), _arity(arity), _entryPoint(entryPoint),
    _genericEntryPoint(genericEntryPoint), _inlineAsOpCode(opCode),
    _codeBlock(nullptr) {

    _params = StaticArray<ParamInfo>(new ParamInfo[arity], arity);
  }

  const std::string& getName() {
    return _name;
  }

  inline
  atom_t getNameAtom(VM vm);

  size_t getArity() {
    return _arity;
  }

  ParamInfo& getParams(size_t i) {
    return _params[i];
  }

  StaticArray<ParamInfo> getParamArray() {
    return _params;
  }

  nativeint getInlineAs() {
    return _inlineAsOpCode;
  }

  void callBuiltin(VM vm, UnstableNode* args[]) {
    return _genericEntryPoint(vm, args);
  }

  template <class... Args>
  void callBuiltin(VM vm, Args&&... args) {
    assert(sizeof...(args) == _arity);
    return _entryPoint(vm, std::forward<Args>(args)...);
  }

  inline
  void getCallInfo(RichNode self, VM vm, size_t& arity,
                   ProgramCounter& start, size_t& Xcount,
                   StaticArray<StableNode>& Gs,
                   StaticArray<StableNode>& Ks);

private:
  inline
  void buildCodeBlock(VM vm, RichNode self);

private:
  std::string _name;
  size_t _arity;
  StaticArray<ParamInfo> _params;

  // Entry points
  SpecializedBuiltinEntryPoint _entryPoint;
  GenericBuiltinEntryPoint _genericEntryPoint;

  nativeint _inlineAsOpCode;

  // CodeArea-like data
  ByteCode* _codeBlock;
  ProtectedNode _selfValue;
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
  template <size_t ar, size_t i, class... Args>
  struct ParamsInitializer {};

  template <size_t ar>
  struct ParamsInitializer<ar, ar> {
    static void initParams(StaticArray<ParamInfo> params) {}
  };

  template <size_t ar, size_t i, class T, class... Args>
  struct ParamsInitializer<ar, i, T, Args...> {
    static void initParams(StaticArray<ParamInfo> params) {
      params[i].kind = ParamTypeToKind<T>::value;
      ParamsInitializer<ar, i+1, Args...>::initParams(params);
    }
  };

  template <class Signature>
  struct ExtractArity {};

  template <class... Args>
  struct ExtractArity<void (*)(VM vm, Args...)> {
    static const size_t arity = sizeof...(Args);

    static void initParams(StaticArray<ParamInfo> params) {
      ParamsInitializer<arity, 0, Args...>::initParams(params);
    }
  };
public:
  Builtin(const std::string& name): BaseBuiltin(
    name, arity(), getEntryPoint(), getGenericEntryPoint(),
    getInlineAsInternal()) {

    ExtractArity<decltype(&Self::call)>::initParams(
      this->getParamArray());
  }
public:
  static constexpr size_t arity() {
    return ExtractArity<decltype(&Self::call)>::arity;
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

  static constexpr nativeint getInlineAsInternal() {
    return internal::ExtractInlineAs<Self,
      internal::HasGetInlineAsOpCodeInternal<Self>::value>::get();
  }
};

//////////////////////////
// Markers for builtins //
//////////////////////////

template <ByteCode opCode>
struct InlineAs {
  static constexpr ByteCode getInlineAsOpCodeInternal() {
    return opCode;
  }
};

}

}

#endif // __BUILTINS_DECL_H
