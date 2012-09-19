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

#include <unordered_set>
#include <memory>
#include "core-forward-decl.hh"
#include "store-decl.hh"

namespace mozart {

/**
 * The returned value of 'ozProtect'. This can be thought as a rebindable
 * `StableNode* const&`, but it can be implicitly cast to a `void*` referring to
 * the address of this reference.
 */
class ProtectedNode {
public:
  StableNode& operator*() const noexcept { return **_node; }
  StableNode& operator->() const noexcept { return **_node; }
  operator void*() const noexcept { return _node; }

  explicit ProtectedNode(void* ptr) noexcept
    : _node(static_cast<StableNode**>(ptr)) {}

private:
  friend class ProtectedNodesContainer;

  explicit ProtectedNode(StableNode** pp_node) : _node(pp_node) {}

  StableNode** _node;
};

/**
 * A container of StableNodes should are protected from being garbage collected.
 * Nodes in this set will stay alive until explicitly unprotected.
 */
class ProtectedNodesContainer {
public:
  inline ProtectedNode protect(VM vm, RichNode node);
  inline ProtectedNode protect(VM vm, StableNode& node);
  inline ProtectedNode protect(VM vm, UnstableNode& node);
  inline ProtectedNode protect(VM vm, UnstableNode&& node);
  inline void unprotect(ProtectedNode pp_node);

  inline void gCollect(GC gc);

private:
  inline ProtectedNode protect(VM vm, StableNode* node_ptr);

  std::unordered_set<StableNode**> _nodes;
};

/**
 * Protect a node from being freed. Returns a double pointer to a stable node
 * which can be stored externally.
 *
 * The returned type is a double pointer, because the node itself may be moved
 * around by the GC, and thus the value of a single pointer may change. But the
 * double pointer will be immutable.
 *
 * Assuming the returned value is `pp_node`, the following are guaranteed:
 *
 * 1. `**pp_node` is valid until calling `ozUnprotect(vm, pp_node)`.
 * 2. Before the GC, the node and the returned double pointer refer to the same
 *    node, i.e. `node.isSameNode(**pp_node) == true`.
 */
template <typename T>
inline ProtectedNode ozProtect(VM vm, T&& node);

/**
 * Reverse the operation of ozProtect, so that the node can be freed by the GC.
 * The input must be a return type of ozProtect.
 */
inline void ozUnprotect(VM vm, ProtectedNode pp_node);

}

#endif
