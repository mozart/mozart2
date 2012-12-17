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

#ifndef __PROTECT_DECL_H
#define __PROTECT_DECL_H

#include <forward_list>
#include <memory>
#include "core-forward-decl.hh"
#include "store-decl.hh"

namespace mozart {

/**
 * The returned value of 'vm->protect()', a node protected from GC.
 * This really is a std::shared_ptr<StableNode*>, but for convenience the
 * * and -> operators dereference twice to get at the StableNode&.
 * A ProtectedNode can be implictly converted back and forth to a genuine
 * std::shared_ptr<StableNode*>.
 */
class ProtectedNode {
public:
  ProtectedNode() {}
  ProtectedNode(std::nullptr_t): _node(nullptr) {}

  ProtectedNode(std::shared_ptr<StableNode*>&& from): _node(std::move(from)) {}
  ProtectedNode(const std::shared_ptr<StableNode*>& from): _node(from) {}

  operator std::shared_ptr<StableNode*>() const {
    return { _node };
  }

  StableNode& operator*() const {
    return **_node;
  }

  StableNode* operator->() const {
    return *_node;
  }

  operator bool() const {
    return (bool) _node;
  }

  void reset() {
    _node.reset();
  }

private:
  std::shared_ptr<StableNode*> _node;
};

namespace internal {

/**
 * A container of StableNodes that are protected from being garbage collected.
 * Nodes in this set will stay alive until their reference count drops to zero.
 */
class ProtectedNodesContainer {
public:
  template <typename T>
  inline
  ProtectedNode protect(VM vm, T&& node);

  inline
  void gCollect(GC gc);

private:
  std::forward_list<std::weak_ptr<StableNode*>> _nodes;
};

} // namespace internal

} // namespace mozart

#endif
