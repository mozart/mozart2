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

#ifndef __SPACE_H
#define __SPACE_H

#include "space-decl.hh"

namespace mozart {

Space* SpaceRef::operator->() {
  Space* result = space;
  while (result->status() == Space::ssReference)
    result = result->_reference;
  return result;
}

Space::Space(GC gc, Space* from) {
  assert(from->_status != ssReference && from->_status != ssGCed);

  if (from->_isTopLevel)
    _parent = nullptr;
  else
    gc->gcSpace(from->_parent, _parent);

  _isTopLevel = from->_isTopLevel;
  _status = from->_status;

  for (auto iter = from->script.begin(); iter != from->script.end(); ++iter) {
    ScriptEntry& entry = script.append(gc->vm);
    gc->gcUnstableNode(iter->left, entry.left);
    gc->gcUnstableNode(iter->right, entry.right);
  }
}

}

#endif // __SPACE_H
