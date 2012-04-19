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

#include "mozart.hh"

#include <iostream>

namespace mozart {

namespace builtins {

/////////////////////////
// Unification-related //
/////////////////////////

OpResult equals(VM vm, UnstableNode* args[]) {
  return Value::EqEq::entryPoint(vm, args);
}

OpResult notEquals(VM vm, UnstableNode* args[]) {
  return Value::NotEqEq::entryPoint(vm, args);
}

//////////////////
// Value status //
//////////////////

OpResult wait(VM vm, UnstableNode* args[]) {
  return Value::Wait::entryPoint(vm, args);
}

OpResult waitOr(VM vm, UnstableNode* args[]) {
  return Record::WaitOr::entryPoint(vm, args);
}

OpResult isDet(VM vm, UnstableNode* args[]) {
  return Value::IsDet::entryPoint(vm, args);
}

////////////////
// Arithmetic //
////////////////

OpResult add(VM vm, UnstableNode* args[]) {
  return Number::Add::entryPoint(vm, args);
}

OpResult subtract(VM vm, UnstableNode* args[]) {
  return Number::Subtract::entryPoint(vm, args);
}

OpResult multiply(VM vm, UnstableNode* args[]) {
  return Number::Multiply::entryPoint(vm, args);
}

OpResult divide(VM vm, UnstableNode* args[]) {
  return Float::Divide::entryPoint(vm, args);
}

OpResult div(VM vm, UnstableNode* args[]) {
  return Int::Div::entryPoint(vm, args);
}

OpResult mod(VM vm, UnstableNode* args[]) {
  return Int::Mod::entryPoint(vm, args);
}

/////////////
// Records //
/////////////

OpResult label(VM vm, UnstableNode* args[]) {
  return Record::Label::entryPoint(vm, args);
}

OpResult width(VM vm, UnstableNode* args[]) {
  return Record::Width::entryPoint(vm, args);
}

OpResult dot(VM vm, UnstableNode* args[]) {
  return Value::Dot::entryPoint(vm, args);
}

/////////////
// Threads //
/////////////

OpResult createThread(VM vm, UnstableNode* args[]) {
  return ModThread::Create::entryPoint(vm, args);
}

///////////////////
// Miscellaneous //
///////////////////

OpResult show(VM vm, UnstableNode* args[]) {
  return System::Show::entryPoint(vm, args);
}

////////////
// Spaces //
////////////

OpResult newSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::New::entryPoint(vm, args);
}

OpResult askSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::Ask::entryPoint(vm, args);
}

OpResult askVerboseSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::AskVerbose::entryPoint(vm, args);
}

OpResult mergeSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::Merge::entryPoint(vm, args);
}

OpResult commitSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::Commit::entryPoint(vm, args);
}

OpResult cloneSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::Clone::entryPoint(vm, args);
}

OpResult chooseSpace(VM vm, UnstableNode* args[]) {
  return ModSpace::Choose::entryPoint(vm, args);
}

}

}
