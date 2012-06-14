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

#ifndef __BOOSTENV_DECL_H
#define __BOOSTENV_DECL_H

#include <mozart.hh>

#include <ctime>
#include <cstdio>
#include <cerrno>

#include <boost/thread.hpp>

#include <boost/uuid/uuid.hpp>
#include <boost/uuid/random_generator.hpp>

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

class BoostBasedVM: public VirtualMachineEnvironment {
public:
  BoostBasedVM();

  static BoostBasedVM& forVM(VM vm) {
    return static_cast<BoostBasedVM&>(vm->getEnvironment());
  }

// Run and preemption

public:
  void run();
private:
  static void preemptionThreadProc(VM vm);

  inline
  static std::int64_t getReferenceTime();

// UUID generation

public:
  UUID genUUID();
private:
  inline
  static std::uint64_t bytes2uint64(const std::uint8_t* bytes);

// Internal file descriptors management

public:
  inline
  nativeint registerFile(std::FILE* file);

  inline
  void unregisterFile(nativeint fd);

  inline
  std::FILE* getFile(nativeint fd);

  inline
  OpResult getFile(nativeint fd, std::FILE*& result);

  inline
  OpResult getFile(RichNode fd, std::FILE*& result);

// Reference to the virtual machine

private:
  VirtualMachine virtualMachine;
public:
  const VM vm;

  typedef boost::random::mt19937 random_generator_t;
  random_generator_t random_generator;
private:
  boost::uuids::random_generator uuidGenerator;
private:
  std::map<nativeint, std::FILE*> openedFiles;
public:
  nativeint fdStdin;
  nativeint fdStdout;
  nativeint fdStderr;
};

///////////////
// Utilities //
///////////////

inline
OpResult ozListLength(VM vm, RichNode list, size_t& result);

inline
OpResult ozStringToBuffer(VM vm, RichNode value, size_t size, char* buffer);

inline
OpResult ozStringToStdString(VM vm, RichNode value, std::string& result);

inline
OpResult stdStringToOzString(VM vm, std::string& value, UnstableNode& result);

inline
OpResult raiseOSError(VM vm, int errnum);

inline
OpResult raiseLastOSError(VM vm);

} }

#endif // __BOOSTENV_DECL_H
