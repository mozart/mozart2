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

#ifndef MOZART_TYPE_DECL_H
#define MOZART_TYPE_DECL_H

#include "core-forward-decl.hh"

namespace mozart {

enum StructuralBehavior {
  sbValue,      // Simple, non-aggregate value
  sbStructural, // Aggregate value compared with structural equality
  sbTokenEq,    // Data with token equality
  sbVariable    // Variable with binding opportunity
};

/**
 * Type of a node
 */
struct Type {
public:
  explicit constexpr Type(const TypeInfo* info): _info(info) {}

public:
  const TypeInfo* info() const {
    return _info;
  }

  const TypeInfo* operator->() const {
    return info();
  }

  inline
  bool isCopyable() const;

  inline
  bool isTransient() const;

  inline
  bool isFeature() const;

  inline
  StructuralBehavior getStructuralBehavior() const;

  inline
  unsigned char getBindingPriority() const;

private:
  const TypeInfo* _info;
};

static_assert(sizeof(Type) <= sizeof(char*),
              "Ouch! TypeInfo is bigger than a memory word");

inline
bool operator==(const Type& lhs, const Type& rhs) {
  return lhs.info() == rhs.info();
}

inline
bool operator!=(const Type& lhs, const Type& rhs) {
  return lhs.info() != rhs.info();
}

}

#endif // MOZART_TYPE_DECL_H
