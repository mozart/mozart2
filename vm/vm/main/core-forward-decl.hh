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

#ifndef __CORE_FORWARD_DECL_H
#define __CORE_FORWARD_DECL_H

#ifndef __MOZART_H
#ifndef MOZART_GENERATOR
#error Illegal inclusion chain. You must include "mozart.hh".
#endif
#endif

#include <utility>
#include <cstdlib>
#include <cstdint>
#include <ostream>
#include <functional>

#define MOZART_NORETURN __attribute__((noreturn))

namespace mozart {

namespace internal {
  /**
   * Utility function used to ensure that static_assert() is evaluated upon
   * template instantiation, not before.
   */
  template <class T>
  struct LateStaticAssert {
    static const bool value = false;
  };
}

typedef intptr_t nativeint;
typedef char nchar;
#define MOZART_STR(S) u8##S

struct unit_t {
};

const unit_t unit = unit_t();

class AtomImpl;

template <size_t atom_type>
struct basic_atom_t {
public:
  basic_atom_t(): _impl(nullptr) {}

  /** Explicit conversion from another atom type */
  template <size_t other_atom_type>
  explicit basic_atom_t(const basic_atom_t<other_atom_type>& from):
    _impl(from._impl) {}
private:
  friend class AtomTable;

  explicit basic_atom_t(const AtomImpl* impl): _impl(impl) {}
public:
  inline
  size_t length() const;

  inline
  const nchar* contents() const;

  inline
  bool equals(const basic_atom_t<atom_type>& rhs) const;

  inline
  int compare(const basic_atom_t<atom_type>& rhs) const;
private:
  template <size_t other_atom_type>
  friend struct basic_atom_t;

  const AtomImpl* _impl;
};

template <size_t atom_type>
inline
bool operator==(const basic_atom_t<atom_type>& lhs,
                const basic_atom_t<atom_type>& rhs) {
  return lhs.equals(rhs);
}

template <size_t atom_type>
inline
bool operator!=(const basic_atom_t<atom_type>& lhs,
                const basic_atom_t<atom_type>& rhs) {
  return !lhs.equals(rhs);
}

template <class C, size_t atom_type>
inline
std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                  const basic_atom_t<atom_type>& atom);

typedef basic_atom_t<1> atom_t;
typedef basic_atom_t<2> unique_name_t;

class TypeInfo;

class Node;
class StableNode;
class UnstableNode;

class VirtualMachine;
typedef VirtualMachine* VM;

class GraphReplicator;
typedef GraphReplicator* GR;

class GarbageCollector;
typedef GarbageCollector* GC;

class SpaceCloner;
typedef SpaceCloner* SC;

class NodeDictionary;

class Space;

/**
 * Reference to a Space
 * It is close to a Space*, except that it handles dereferencing transparently
 */
struct SpaceRef {
public:
  SpaceRef() {}

  SpaceRef(Space* space) : space(space) {}

  inline
  Space* operator->();

  Space& operator*() {
    return *operator->();
  }

  operator Space*() {
    return operator->();
  }
private:
  Space* space;
};

typedef std::function<void(VM)> VMCleanupProc;

/** Node of a linked list of things to do on cleanup
 *  Cleanup is done after every GC and on VM termination
 */
struct VMCleanupListNode {
  VMCleanupProc handler;
  VMCleanupListNode* next;
};

namespace internal {
  struct AlternativeToInt {
    operator nativeint() { return 0; }
  };

  struct AlternativeToInt64 {
    operator nativeint() { return 0; }
  };

  typedef typename std::conditional<
    std::is_same<int, nativeint>::value,
    AlternativeToInt, int>::type intIfDifferentFromNativeInt;

  typedef typename std::conditional<
    std::is_same<std::int64_t, nativeint>::value,
    AlternativeToInt64, std::int64_t>::type int64IfDifferentFromNativeInt;
}

}

// new operators must be declared outside of any namespace

inline
void* operator new (size_t size, mozart::VM vm);

inline
void* operator new[] (size_t size, mozart::VM vm);

#endif // __CORE_FORWARD_DECL_H
