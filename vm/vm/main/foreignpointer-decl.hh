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

#ifndef __FOREIGNPOINTER_DECL_H
#define __FOREIGNPOINTER_DECL_H

#include "mozartcore-decl.hh"

#include <typeinfo>

namespace mozart {

////////////////////
// ForeignPointer //
////////////////////

#ifndef MOZART_GENERATOR
#include "ForeignPointer-implem-decl.hh"
#endif

/**
 * Shared pointer to some external memory
 */
class ForeignPointer: public DataType<ForeignPointer> {
public:
  typedef SelfType<ForeignPointer>::Self Self;
public:
  template <class T>
  ForeignPointer(VM vm, const std::shared_ptr<T>& p):
    _pointer(std::static_pointer_cast<void>(p)), _pointerType(typeid(T)) {}

  ForeignPointer(VM vm, GR gr, Self from):
    _pointer(std::move(from->_pointer)), _pointerType(from->_pointerType) {}
public:
  template <class T>
  std::shared_ptr<T> value() {
    assert(typeid(T) == _pointerType);
    return std::static_pointer_cast<T>(_pointer);
  }

  std::shared_ptr<void> getVoidPointer() {
    return _pointer;
  }

  const std::type_info& pointerType() {
    return _pointerType;
  }

  template <class T>
  bool isPointer() {
    return typeid(T) == _pointerType;
  }
private:
  std::shared_ptr<void> _pointer;
  const std::type_info& _pointerType;
};

#ifndef MOZART_GENERATOR
#include "ForeignPointer-implem-decl-after.hh"
#endif

}

#endif // __FOREIGNPOINTER_DECL_H
