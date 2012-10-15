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
  _environment(environment), _resolver(environment.io_service),
  _socket(environment.io_service) {
}

void TCPConnection::startAsyncConnect(std::string host, std::string service,
                                      const ProtectedNode& statusNode) {
  pointer self = shared_from_this();

  auto resolveHandler = [=] (const boost::system::error_code& error,
                             tcp::resolver::iterator endpoints) {
    if (!error) {
      auto connectHandler = [=] (const boost::system::error_code& error,
                                 tcp::resolver::iterator selected_endpoint) {
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

  tcp::resolver::query query(host, service);
  _resolver.async_resolve(query, resolveHandler);
}

void TCPConnection::startAsyncRead(const ProtectedNode& tailNode,
                                   const ProtectedNode& statusNode) {
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    readHandler(error, bytes_transferred, tailNode, statusNode);
  };

  boost::asio::async_read(_socket, boost::asio::buffer(_readData), handler);
}

void TCPConnection::startAsyncReadSome(const ProtectedNode& tailNode,
                                       const ProtectedNode& statusNode) {
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    readHandler(error, bytes_transferred, tailNode, statusNode);
  };

  _socket.async_read_some(boost::asio::buffer(_readData), handler);
}

void TCPConnection::startAsyncWrite(const ProtectedNode& statusNode) {
  auto handler = [=] (const boost::system::error_code& error,
                      size_t bytes_transferred) {
    _environment.postVMEvent([=] () {
      if (!error) {
        _environment.bindAndReleaseAsyncIOFeedbackNode(
          statusNode, bytes_transferred);
      } else {
        _environment.raiseAndReleaseAsyncIOFeedbackNode(
          statusNode, MOZART_STR("socket"), MOZART_STR("write"), error.value());
      }
    });
  };

  boost::asio::async_write(_socket, boost::asio::buffer(_writeData), handler);
}

void TCPConnection::readHandler(const boost::system::error_code& error,
                                size_t bytes_transferred,
                                const ProtectedNode& tailNode,
                                const ProtectedNode& statusNode) {
  _environment.postVMEvent([=] () {
    if (!error) {
      VM vm = _environment.vm;

      UnstableNode head(vm, *tailNode);
      for (size_t i = bytes_transferred; i > 0; i--)
        head = buildCons(vm, _readData[i-1], std::move(head));

      _environment.bindAndReleaseAsyncIOFeedbackNode(
        statusNode, MOZART_STR("succeeded"), bytes_transferred, std::move(head));
    } else {
      _environment.raiseAndReleaseAsyncIOFeedbackNode(
        statusNode, MOZART_STR("socket"), MOZART_STR("read"), error.value());
    }

    _environment.releaseAsyncIONode(tailNode);
  });
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
