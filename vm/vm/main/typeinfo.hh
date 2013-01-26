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

#ifndef __TYPEINFO_H
#define __TYPEINFO_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////
// TypeInfo //
//////////////

atom_t TypeInfo::getTypeAtom(VM vm) const {
  return vm->getAtom(MOZART_STR("value"));
}

UnstableNode TypeInfo::serialize(VM vm, SE s, RichNode from) const {
  return mozart::build(vm, from.type()->getTypeAtom(vm));
}

GlobalNode* TypeInfo::globalize(VM vm, RichNode from) const {
  return GlobalNode::make(vm, from, MOZART_STR("default"));
}

//////////
// repr //
//////////

void repr::init(VM vm, RichNode value, int depth, int width) {
  this->vm = vm;
  this->value = value;
  this->depth = depth;
  this->width = width;
}

template <typename T>
auto repr::init(VM vm, T&& value, int depth, int width)
  -> typename std::enable_if<!std::is_convertible<T, RichNode>::value>::type {

  unstableValue = build(vm, std::forward<T>(value));
  init(vm, RichNode(unstableValue), depth, width);
}

template <typename T>
void repr::init(VM vm, T&& value) {
  init(vm, std::forward<T>(value),
       vm->getPropertyRegistry().config.errorsDepth,
       vm->getPropertyRegistry().config.errorsWidth);
}

}

#endif // MOZART_GENERATOR

#endif // __TYPEINFO_H
