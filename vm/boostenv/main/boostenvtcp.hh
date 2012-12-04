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

#ifndef __BOOSTENVTCP_H
#define __BOOSTENVTCP_H

#include "boostenvtcp-decl.hh"

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

///////////////////
// TCPConnection //
///////////////////

TCPConnection::TCPConnection(BoostBasedVM& environment):
  BaseSocketConnection(environment), _resolver(environment.io_service) {
}

void TCPConnection::startAsyncConnect(std::string host, std::string service,
                                      const ProtectedNode& statusNode) {
  pointer self = shared_from_this();

  auto resolveHandler = [=] (const boost::system::error_code& error,
                             protocol::resolver::iterator endpoints) {
    if (!error) {
      auto connectHandler = [=] (const boost::system::error_code& error,
                                 protocol::resolver::iterator selected_endpoint) {
        if (!error) {
          _environment.postVMEvent([=] () {
            _environment.bindAndReleaseAsyncIOFeedbackNode(
              statusNode, build(_environment.vm, self));
          });
        } else {
          _environment.postVMEvent([=] () {
            _environment.raiseAndReleaseAsyncIOFeedbackNode(
              statusNode, MOZART_STR("socket"), MOZART_STR("connect"), error.value());
          });
        }
      };

      boost::asio::async_connect(socket(), endpoints, connectHandler);
    } else {
      _environment.postVMEvent([=] () {
        _environment.raiseAndReleaseAsyncIOFeedbackNode(
          statusNode, MOZART_STR("socket"), MOZART_STR("resolve"), error.value());
      });
    }
  };

  protocol::resolver::query query(host, service);
  _resolver.async_resolve(query, resolveHandler);
}

/////////////////
// TCPAcceptor //
/////////////////

TCPAcceptor::TCPAcceptor(BoostBasedVM& environment,
                         const tcp::endpoint& endpoint):
  _environment(environment), _acceptor(environment.io_service, endpoint) {
}

void TCPAcceptor::startAsyncAccept(const ProtectedNode& connectionNode) {
  TCPConnection::pointer connection = TCPConnection::create(_environment);

  auto handler = [=] (const boost::system::error_code& error) {
    if (!error) {
      _environment.postVMEvent([=] () {
        _environment.bindAndReleaseAsyncIOFeedbackNode(
          connectionNode, build(_environment.vm, connection));
      });
    } else if (error == boost::asio::error::operation_aborted) {
      _environment.postVMEvent([=] () {
        _environment.releaseAsyncIONode(connectionNode);
      });
    } else {
      // Try again
      startAsyncAccept(connectionNode);
    }
  };

  acceptor().async_accept(connection->socket(), handler);
}

boost::system::error_code TCPAcceptor::cancel() {
  boost::system::error_code error;
  _acceptor.cancel(error);
  return error;
}

boost::system::error_code TCPAcceptor::close() {
  boost::system::error_code error;
  _acceptor.close(error);
  return error;
}

} }

#endif

#endif // __BOOSTENVTCP_H
