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

#ifndef __FLOAT_DECL_H
#define __FLOAT_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

#ifndef MOZART_GENERATOR
#include "Float-implem-decl.hh"
#endif

class Float: public DataType<Float>,
  StoredAs<double>, WithValueBehavior {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("float"));
  }

  explicit Float(double value) : _value(value) {}

  static void create(double& self, VM, double value) {
    self = value;
  }

  inline
  static void create(double& self, VM vm, GR gr, Float from);

  double value() const { return _value; }

  inline
  bool equals(VM vm, RichNode right);

public:
  // Comparable interface

  inline
  int compare(VM vm, RichNode right);

public:
  // Numeric inteface

  bool isNumber(VM vm) {
    return true;
  }

  bool isInt(VM vm) {
    return false;
  }

  bool isFloat(VM vm) {
    return true;
  }

  inline
  UnstableNode opposite(VM vm);

  inline
  UnstableNode add(VM vm, RichNode right);

  inline
  UnstableNode add(RichNode self, VM vm, nativeint right);

  inline
  UnstableNode addValue(VM vm, double b);

  inline
  UnstableNode subtract(VM vm, RichNode right);

  inline
  UnstableNode subtractValue(VM vm, double b);

  inline
  UnstableNode multiply(VM vm, RichNode right);

  inline
  UnstableNode multiplyValue(VM vm, double b);

  inline
  UnstableNode divide(VM vm, RichNode right);

  inline
  UnstableNode divideValue(VM vm, double b);

  inline
  UnstableNode div(RichNode self, VM vm, RichNode right);

  inline
  UnstableNode mod(RichNode self, VM vm, RichNode right);

public:
  // VirtualString inteface

  bool isVirtualString(VM vm) {
    return true;
  }

  inline
  void toString(VM vm, std::basic_ostream<nchar>& sink);

  inline
  nativeint vsLength(VM vm);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << value();
  }
private:
  const double _value;
};

#ifndef MOZART_GENERATOR
#include "Float-implem-decl-after.hh"
#endif

}

#endif // __FLOAT_DECL_H
