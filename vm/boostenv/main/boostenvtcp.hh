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

#ifndef MOZART_BOOSTENVTCP_H
#define MOZART_BOOSTENVTCP_H

#include "boostenvtcp-decl.hh"

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

///////////////////
// TCPConnection //
///////////////////

TCPConnection::TCPConnection(BoostVM& boostVM):
  BaseSocketConnection(boostVM), _resolver(boostVM.env.io_service) {
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
          boostVM.postVMEvent([=] () {
            boostVM.bindAndReleaseAsyncIOFeedbackNode(
              statusNode, build(boostVM.vm, self));
          });
        } else {
          boostVM.postVMEvent([=] () {
            boostVM.raiseAndReleaseAsyncIOFeedbackNode(
              statusNode, "socket", "connect", error.value());
          });
        }
      };

      boost::asio::async_connect(socket(), endpoints, connectHandler);
    } else {
      boostVM.postVMEvent([=] () {
        boostVM.raiseAndReleaseAsyncIOFeedbackNode(
          statusNode, "socket", "resolve", error.value());
      });
    }
  };

  protocol::resolver::query query(host, service);
  _resolver.async_resolve(query, resolveHandler);
}

/////////////////
// TCPAcceptor //
/////////////////

TCPAcceptor::TCPAcceptor(BoostVM& boostVM,
                         const tcp::endpoint& endpoint):
  boostVM(boostVM), _acceptor(boostVM.env.io_service, endpoint) {
}

void TCPAcceptor::startAsyncAccept(const ProtectedNode& connectionNode) {
  TCPConnection::pointer connection = TCPConnection::create(boostVM);

  auto handler = [=] (const boost::system::error_code& error) {
    if (!error) {
      boostVM.postVMEvent([=] () {
        boostVM.bindAndReleaseAsyncIOFeedbackNode(
          connectionNode, build(boostVM.vm, connection));
      });
    } else if (error == boost::asio::error::operation_aborted) {
      boostVM.postVMEvent([=] () {
        boostVM.releaseAsyncIONode(connectionNode);
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

#endif // MOZART_BOOSTENVTCP_H
