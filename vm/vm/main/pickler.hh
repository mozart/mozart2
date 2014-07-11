// Copyright © 2014, Université catholique de Louvain
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

#ifndef MOZART_PICKLER_H
#define MOZART_PICKLER_H

#include "mozartcore.hh"

#include <ostream>

namespace mozart {

/////////////
// Pickler //
/////////////

class Pickler {
private:
  struct PickleNode {
    nativeint index;
    RichNode node;
    StableNode* refs;
  };

public:
  static UnstableNode buildTypesRecord(VM vm);

public:
  Pickler(VM vm, std::ostream& output):
    vm(vm), output(output) {}

  void pickle(RichNode value, RichNode temporaryReplacement);

private:
  void writeValues(VMAllocatedList<PickleNode>& nodes);
  void writeArities(VMAllocatedList<PickleNode>& nodes);
  void writeOthers(VMAllocatedList<PickleNode>& nodes);

  bool findFeature(NodeDictionary& existingFeatures,
                   nativeint index, RichNode node);
  bool findBuiltin(NodeDictionary& existingBuiltins,
                   nativeint index, RichNode refsTuple);
  bool findArity(NodeDictionary& existingsArities,
                 nativeint index, RichNode node, RichNode refsTuple);

  void writeNode(nativeint index, RichNode node, RichNode refs);
  void writeByte(unsigned char byte);
  void writeSize(size_t size);
  void writeSize(RichNode ref);
  void writeStr(const char* str, size_t len);
  void writeAtom(RichNode atom);
  void writeAsVS(RichNode node);
  void writeRef(RichNode ref);
  void writeNRefs(RichNode refs, size_t n);
  void writeRefs(RichNode refs);
  void writeRefsLastFirst(RichNode refsTuple);
  void writeUUIDOf(RichNode node);

private:
  bool isFuture(RichNode node) {
    return node.is<ReadOnly>() || node.is<ReadOnlyVariable>();
  }

private:
  VM vm;
  std::ostream& output;
  StaticArray<nativeint> redirections;
};

/////////////////
// Entry point //
/////////////////

inline
void pickle(VM vm, RichNode value, RichNode temporaryReplacement, std::ostream& output) {
  Pickler(vm, output).pickle(value, temporaryReplacement);
}

inline
void pickle(VM vm, RichNode value, std::ostream& output) {
  auto temporaryReplacement = Atom::build(vm, vm->coreatoms.nil);
  pickle(vm, value, temporaryReplacement, output);
}

}

#endif // MOZART_PICKLER_H
