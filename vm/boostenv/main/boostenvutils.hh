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

#ifndef __BOOSTENVUTILS_H
#define __BOOSTENVUTILS_H

#include "boostenvutils-decl.hh"

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

//////////////////////////
// BaseSocketConnection //
//////////////////////////

template <typename T, typename P>
BaseSocketConnection<T, P>::BaseSocketConnection(BoostBasedVM& environment):
  _environment(environment), _socket(environment.io_service) {
}

template <typename T, typename P>
void BaseSocketConnection<T, P>::startAsyncRead(
  const ProtectedNode& tailNode, const ProtectedNode& statusNode) {

  pointer self = this->shared_from_this();
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    self->readHandler(error, bytes_transferred, tailNode, statusNode);
  };

  boost::asio::async_read(_socket, boost::asio::buffer(_readData), handler);
}

template <typename T, typename P>
void BaseSocketConnection<T, P>::startAsyncReadSome(
  const ProtectedNode& tailNode, const ProtectedNode& statusNode) {

  pointer self = this->shared_from_this();
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    self->readHandler(error, bytes_transferred, tailNode, statusNode);
  };

  _socket.async_read_some(boost::asio::buffer(_readData), handler);
}

template <typename T, typename P>
void BaseSocketConnection<T, P>::startAsyncWrite(
  const ProtectedNode& statusNode) {

  pointer self = this->shared_from_this();
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    self->_environment.postVMEvent([=] () {
      if (!error) {
        self->_environment.bindAndReleaseAsyncIOFeedbackNode(
          statusNode, bytes_transferred);
      } else {
        self->_environment.raiseAndReleaseAsyncIOFeedbackNode(
          statusNode, MOZART_STR("socketOrPipe"), MOZART_STR("write"), error.value());
      }
    });
  };

  boost::asio::async_write(_socket, boost::asio::buffer(_writeData), handler);
}

template <typename T, typename P>
void BaseSocketConnection<T, P>::readHandler(
  const boost::system::error_code& error, size_t bytes_transferred,
  const ProtectedNode& tailNode, const ProtectedNode& statusNode) {

  pointer self = this->shared_from_this();
  _environment.postVMEvent([=] () {
    if (!error) {
      VM vm = _environment.vm;

      UnstableNode head(vm, *tailNode);
      for (size_t i = bytes_transferred; i > 0; i--)
        head = buildCons(vm, (nativeint) (unsigned char) _readData[i-1],
                         std::move(head));

      self->_environment.bindAndReleaseAsyncIOFeedbackNode(
        statusNode, MOZART_STR("succeeded"), bytes_transferred, std::move(head));
    } else {
      self->_environment.raiseAndReleaseAsyncIOFeedbackNode(
        statusNode, MOZART_STR("socketOrPipe"), MOZART_STR("read"), error.value());
    }

    _environment.releaseAsyncIONode(tailNode);
  });
}

} }

#endif

#endif // __BOOSTENVUTILS_H
