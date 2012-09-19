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

#ifndef __BOOSTENVTCP_DECL_H
#define __BOOSTENVTCP_DECL_H

#include <mozart.hh>

#include <memory>

#include <boost/asio.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

namespace mozart { namespace boostenv {

class BoostBasedVM;

///////////////////
// TCPConnection //
///////////////////

class TCPConnection: public std::enable_shared_from_this<TCPConnection> {
private:
  typedef boost::asio::ip::tcp tcp;

public:
  typedef std::shared_ptr<TCPConnection> pointer;

  static pointer create(BoostBasedVM& environment) {
    return pointer(new TCPConnection(environment));
  }

public:
  tcp::socket& socket() {
    return _socket;
  }

  std::vector<char>& getReadData() {
    return _readData;
  }

  std::vector<char>& getWriteData() {
    return _writeData;
  }

  inline
  void startAsyncConnect(std::string host, std::string service,
                         const ProtectedNode& statusNode);

  inline
  void startAsyncRead(const ProtectedNode& tailNode,
                      const ProtectedNode& statusNode);

  inline
  void startAsyncReadSome(const ProtectedNode& tailNode,
                          const ProtectedNode& statusNode);

  inline
  void startAsyncWrite(const ProtectedNode& statusNode);

private:
  inline
  TCPConnection(BoostBasedVM& environment);

private:
  inline
  void readHandler(const boost::system::error_code& error,
                   size_t bytes_transferred,
                   const ProtectedNode& tailNode,
                   const ProtectedNode& statusNode);

private:
  BoostBasedVM& _environment;
  tcp::resolver _resolver;
  tcp::socket _socket;

  std::vector<char> _readData;
  std::vector<char> _writeData;
};

/////////////////
// TCPAcceptor //
/////////////////

class TCPAcceptor: public std::enable_shared_from_this<TCPAcceptor> {
private:
  typedef boost::asio::ip::tcp tcp;

public:
  typedef std::shared_ptr<TCPAcceptor> pointer;

  static pointer create(BoostBasedVM& environment,
                        const tcp::endpoint& endpoint) {
    return pointer(new TCPAcceptor(environment, endpoint));
  }

public:
  tcp::acceptor& acceptor() {
    return _acceptor;
  }

  inline
  void startAsyncAccept(const ProtectedNode& connectionNode);

  inline
  boost::system::error_code cancel();

  inline
  boost::system::error_code close();

private:
  inline
  TCPAcceptor(BoostBasedVM& environment, const tcp::endpoint& endpoint);

private:
  BoostBasedVM& _environment;
  tcp::acceptor _acceptor;
};

} }

#endif // __BOOSTENVTCP_DECL_H
