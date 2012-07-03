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

#ifndef __TYPE_DECL_H
#define __TYPE_DECL_H

#include <string>
#include <ostream>

#include "core-forward-decl.hh"

#include "store-decl.hh"
#include "uuid-decl.hh"
#include "utf-decl.hh"

namespace mozart {

//////////
// Type //
//////////

enum StructuralBehavior {
  sbValue,      // Simple, non-aggregate value
  sbStructural, // Aggregate value compared with structural equality
  sbTokenEq,    // Data with token equality
  sbVariable    // Variable with binding opportunity
};

class Type {
public:
  Type(std::string name, const UUID& uuid,
       bool copyable, bool transient, bool feature,
       StructuralBehavior structuralBehavior,
       unsigned char bindingPriority) :
    _name(name), _uuid(uuid), _hasUUID(!(uuid.is_nil())),
    _copyable(copyable), _transient(transient), _feature(feature),
    _structuralBehavior(structuralBehavior),
    _bindingPriority(bindingPriority) {

    assert(!_feature || _hasUUID);
  }

  const std::string& getName() const { return _name; }

  bool hasUUID() const {
    return _hasUUID;
  }

  const UUID& getUUID() const {
    return _uuid;
  }

  virtual void* getInterface(void* intfID) {
    // TODO
    return nullptr;
  }

  bool isCopyable() const { return _copyable; }
  bool isTransient() const { return _transient; }
  bool isFeature() const { return _feature; }

  StructuralBehavior getStructuralBehavior() const {
    return _structuralBehavior;
  }

  unsigned char getBindingPriority() const {
    return _bindingPriority;
  }

  virtual void printReprToStream(VM vm, RichNode self, std::ostream& out,
                                 int depth = 10) const {
    out << "<" << _name << ">";
  }

  virtual void gCollect(GC gc, RichNode from, StableNode& to) const = 0;
  virtual void gCollect(GC gc, RichNode from, UnstableNode& to) const = 0;

  virtual void sClone(SC sc, RichNode from, StableNode& to) const = 0;
  virtual void sClone(SC sc, RichNode from, UnstableNode& to) const = 0;

  virtual int compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {
    assert(lhs.type() == this && rhs.type() == this);
    assert(isFeature());
    assert(false);
    return 0;
  }
private:
  const std::string _name;
  const UUID _uuid;
  const bool _hasUUID;

  const bool _copyable;
  const bool _transient;
  const bool _feature;

  const StructuralBehavior _structuralBehavior;
  const unsigned char _bindingPriority;
};

template <class T>
struct RawType {
  static const T rawType;
};

template <class T>
const T RawType<T>::rawType;

//////////////
// Features //
//////////////

inline
int compareFeatures(VM vm, RichNode lhs, RichNode rhs) {
  assert(lhs.isFeature() && rhs.isFeature());

  const Type* lhsType = lhs.type();
  const Type* rhsType = rhs.type();

  if (lhsType == rhsType) {
    return lhsType->compareFeatures(vm, lhs, rhs);
  } else {
    if (lhsType->getUUID() < rhsType->getUUID())
      return -1;
    else
      return 1;
  }
}

//////////////////
// << for nodes //
//////////////////

class repr {
public:
  repr(VM vm, RichNode value, int depth = 10):
    vm(vm), value(value), depth(depth) {}

  std::ostream& operator()(std::ostream& out) const {
    if (depth <= 0)
      out << "...";
    else
      value.type()->printReprToStream(vm, value, out, depth-1);
    return out;
  }
private:
  mutable VM vm;
  mutable RichNode value;
  mutable int depth;
};

inline
std::ostream& operator<<(std::ostream& out, const repr& nodeRepr) {
  return nodeRepr(out);
}

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

#endif // __TYPE_DECL_H
