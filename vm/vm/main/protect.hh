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

#include "mozartcore.hh"

namespace mozart {

namespace internal {

template <typename T>
ProtectedNode ProtectedNodesContainer::protect(VM vm, T&& node) {
  /* Yes, it must always be a *new* StableNode, otherwise protecting twice
   * the same node fails!
   */
  auto result = std::make_shared<StableNode*>(
    new (vm) StableNode(vm, std::forward<T>(node)));
  _nodes.emplace_front(result);
  return ProtectedNode(std::move(result));
}

void ProtectedNodesContainer::gCollect(GC gc) {
  /* Elements that are still referenced somewhere are garbage-collected, and
   * the StableNode* is updated to point to the GCed node.
   *
   * Elements that are not referenced anymore are erased from the list of
   * protected nodes.
   */

  auto previous = _nodes.before_begin();
  auto current = _nodes.begin();

  while (current != _nodes.end()) {
    auto locked = current->lock();
    if (locked) {
      gc->copyStableRef(*locked, *locked);
      previous = current++;
    } else {
      _nodes.erase_after(previous);
      current = previous;
      ++current;
    }
  }
}

} // namespace internal

} // namespace mozart

#endif
