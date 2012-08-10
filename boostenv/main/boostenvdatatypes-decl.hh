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

#ifndef __BOOSTENVDATATYPES_DECL_H
#define __BOOSTENVDATATYPES_DECL_H

#include <mozart.hh>

#include "boostenvtcp-decl.hh"

namespace mozart {

/////////////////////
// OzTCPConnection //
/////////////////////

class OzTCPConnection;

#ifndef MOZART_GENERATOR
#include "OzTCPConnection-implem-decl.hh"
#endif

class OzTCPConnection: public DataType<OzTCPConnection> {
public:
  typedef SelfType<OzTCPConnection>::Self Self;
public:
  OzTCPConnection(VM vm, std::shared_ptr<boostenv::TCPConnection> p):
    _pointer(p) {}

  OzTCPConnection(VM vm, GR gr, Self from):
    _pointer(std::move(from->_pointer)) {}
public:
  std::shared_ptr<boostenv::TCPConnection> value() {
    return _pointer;
  }
private:
  std::shared_ptr<boostenv::TCPConnection> _pointer;
};

#ifndef MOZART_GENERATOR
#include "OzTCPConnection-implem-decl-after.hh"
#endif

#ifndef MOZART_GENERATOR
namespace patternmatching {
  template <>
  struct PrimitiveTypeToOzType<std::shared_ptr<boostenv::TCPConnection> > {
    typedef OzTCPConnection result;
  };
}
#endif

///////////////////
// OzTCPAcceptor //
///////////////////

class OzTCPAcceptor;

#ifndef MOZART_GENERATOR
#include "OzTCPAcceptor-implem-decl.hh"
#endif

class OzTCPAcceptor: public DataType<OzTCPAcceptor> {
public:
  typedef SelfType<OzTCPAcceptor>::Self Self;
public:
  OzTCPAcceptor(VM vm, std::shared_ptr<boostenv::TCPAcceptor> p):
    _pointer(p) {}

  OzTCPAcceptor(VM vm, GR gr, Self from):
    _pointer(std::move(from->_pointer)) {}
public:
  std::shared_ptr<boostenv::TCPAcceptor> value() {
    return _pointer;
  }
private:
  std::shared_ptr<boostenv::TCPAcceptor> _pointer;
};

#ifndef MOZART_GENERATOR
#include "OzTCPAcceptor-implem-decl-after.hh"
#endif

#ifndef MOZART_GENERATOR
namespace patternmatching {
  template <>
  struct PrimitiveTypeToOzType<std::shared_ptr<boostenv::TCPAcceptor> > {
    typedef OzTCPAcceptor result;
  };
}
#endif

}

#endif // __BOOSTENVDATATYPES_DECL_H
