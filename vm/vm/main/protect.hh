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

#ifndef __PROTECT_H
#define __PROTECT_H

#include "protect-decl.hh"
#include "vm-decl.hh"

namespace mozart {

inline ProtectedNode ProtectedNodesContainer::protect(VM vm, StableNode* node_ptr) {
  StableNode** ptr = new StableNode*(node_ptr);
  _nodes.insert(ptr);
  return ProtectedNode(ptr);
}

inline ProtectedNode ProtectedNodesContainer::protect(VM vm, RichNode node) {
  return protect(vm, node.getStableRef(vm));
}

inline ProtectedNode ProtectedNodesContainer::protect(VM vm, StableNode& node) {
  return protect(vm, &node);
}

inline ProtectedNode ProtectedNodesContainer::protect(VM vm, UnstableNode& node) {
  StableNode* node_ptr = new (vm) StableNode;
  node_ptr->init(vm, node);
  return protect(vm, node_ptr);
}

inline ProtectedNode ProtectedNodesContainer::protect(VM vm, UnstableNode&& node) {
  StableNode* node_ptr = new (vm) StableNode;
  node_ptr->init(vm, std::move(node));
  return protect(vm, node_ptr);
}

inline void ProtectedNodesContainer::unprotect(ProtectedNode pp_node) {
  if (_nodes.erase(pp_node._node)) {
    delete pp_node._node;
  }
}

inline void ProtectedNodesContainer::gCollect(GC gc) {
  for (auto node : _nodes) {
    gc->copyStableRef(*node, *node);
  }
}

template <typename T>
ProtectedNode ozProtect(VM vm, T&& node)
{
  return vm->_protectedNodes.protect(vm, std::forward<T>(node));
}

void ozUnprotect(VM vm, ProtectedNode pp_node)
{
  vm->_protectedNodes.unprotect(pp_node);
}

}

#endif
