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

#ifndef __DATATYPE_DECL_H
#define __DATATYPE_DECL_H

#include "core-forward-decl.hh"

#include "store-decl.hh"
#include "uuid-decl.hh"
#include "typeinfo-decl.hh"

namespace mozart {

//////////////
// DataType //
//////////////

/**
 * Base class for all data types of the VM Object Model
 *
 * It uses CRTP, so subclasses should be declared as:
 * class SomeDataType: public DataType<SomeDataType> { ... };
 */
template <class T>
class DataType {
public:
  static Type type() {
    return TypeInfoOf<T>::type();
  }

  template <class... Args>
  static UnstableNode build(VM vm, Args&&... args) {
    return UnstableNode::build<T>(vm, std::forward<Args>(args)...);
  }
};

//////////////
// WithHome //
//////////////

class WithHome {
public:
  WithHome(SpaceRef home): _home(home) {}

  inline
  WithHome(VM vm);

  inline
  WithHome(VM vm, GR gr, SpaceRef fromHome);

  Space* home() {
    return _home;
  }
protected:
  inline
  bool isHomedInCurrentSpace(VM vm);
private:
  SpaceRef _home;
};

/////////////////////
// Trivial markers //
/////////////////////

template<class T>
struct Interface{};

template<class...>
struct ImplementedBy{};

struct NoAutoWait{};
struct NoAutoReflectiveCalls{};

struct Copyable{};

struct Transient{};

template<class>
struct StoredAs{};

template<class>
struct StoredWithArrayOf{};

struct WithValueBehavior{};

struct WithStructuralBehavior{};

template<unsigned char>
struct WithVariableBehavior{};

template<class>
struct BasedOn{};

struct NoAutoGCollect{};

struct NoAutoSClone{};

}

#endif // __DATATYPE_DECL_H
