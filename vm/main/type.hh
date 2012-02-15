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

#ifndef __TYPE_H
#define __TYPE_H

#include <string>

using namespace std;

class Type {
public:
  Type(string name, bool copiable = false, bool transient = false) :
    _name(name), _copiable(copiable), _transient(transient) {
  }

  const string& getName() const { return _name; }

  virtual void* getInterface(void* intfID) {
    // TODO
    return nullptr;
  }

  bool isCopiable() const { return _copiable; }
  bool isTransient() const { return _transient; }
private:
  const string _name;

  const bool _copiable;
  const bool _transient;
};

template<class T>
struct Interface;
template<class...>
struct ImplementedBy{};
struct NoAutoWait{};

template <class T>
class Implementation {
};
struct Copiable{};
struct Transient{};
template<class>
struct StoredAs{};
template<class>
struct StoredWithArrayOf{};
template<class>
struct BasedOn{};

#endif // __TYPE_H
