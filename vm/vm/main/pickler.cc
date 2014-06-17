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

#include "mozart.hh"

namespace mozart {

/////////////
// Pickler //
/////////////

UnstableNode Pickler::buildTypesRecord(VM vm) {
  // Maps the atom returned by serialize() to the pickle type id
  auto& atoms = vm->coreatoms;
  return buildRecord(vm,
    buildArity(vm, "pickleTypesRecord",
      atoms.abstraction,
      atoms.arity,
      atoms.atom,
      atoms.bool_,
      atoms.builtin,
      atoms.chunk,
      atoms.codearea,
      atoms.cons,
      atoms.float_,
      atoms.int_,
      atoms.name,
      atoms.namedname,
      atoms.patmatcapture,
      atoms.patmatconjunction,
      atoms.patmatopenrecord,
      atoms.patmatwildcard,
      atoms.record,
      atoms.tuple,
      atoms.unicodeString,
      atoms.uniquename,
      atoms.unit
    ),
    16, 8, 5, 3, 10,
    17, 11, 6, 2, 1,
    19, 20, 13, 14, 15,
    12, 9, 7, 21, 18,
    4);
}

void Pickler::pickle(RichNode value) {
  auto typesRecord = RichNode(*vm->getPickleTypesRecord()).as<Record>();
  auto statelessTypes = RichNode(*typesRecord.getArity()).as<Arity>();

  SerializationCallback cb(vm);
  UnstableNode topLevelIndex = OptVar::build(vm);
  cb.copy(topLevelIndex, value);

  bool futures = false;
  nativeint count = 0;
  VMAllocatedList<NodeBackup> nodeBackups;
  VMAllocatedList<PickleNode> nodes;
  UnstableNode resources = buildNil(vm);

  // Replace serialized nodes by Serialized(index)
  // and add them to the nodes list
  while (!cb.todoFrom.empty()) {
    RichNode from = cb.todoFrom.pop_front(vm);
    RichNode to = cb.todoTo.pop_front(vm);

    if (from.is<Serialized>()) {
      UnstableNode n = mozart::build(vm, from.as<Serialized>().n());
      DataflowVariable(to).bind(vm, n);
    } else {
      ++count;
      StableNode* refs = new (vm) StableNode(vm, from.type()->serialize(vm, &cb, from));
      nodes.push_front(vm, { count, from, refs });

      if (!futures) {
        UnstableNode type = RecordLike(*refs).label(vm);
        size_t _offset;
        if (isFuture(from)) {
          futures = true;
        } else if (!statelessTypes.lookupFeature(vm, type, _offset)) {
          resources = buildCons(vm, from, std::move(resources));
        }
      }

      nodeBackups.push_front(vm, from.makeBackup());
      from.reinit(vm, Serialized::build(vm, count));

      UnstableNode n = mozart::build(vm, count);
      DataflowVariable(to).bind(vm, n);
    }
  }

  // Restore nodes
  while (!nodeBackups.empty()) {
    nodeBackups.front().restore();
    nodeBackups.remove_front(vm);
  }

  if (futures) {
    for (auto& pickleNode : nodes) {
      if (isFuture(pickleNode.node)) {
        DataflowVariable(pickleNode.node).markNeeded(vm);
      }
    }

    for (auto& pickleNode : nodes) {
      if (isFuture(pickleNode.node)) {
        RichNode future = pickleNode.node;
        nodes.clear(vm);
        waitFor(vm, future);
      }
    }
  } else if (!RichNode(resources).is<Atom>()) {
    nodes.clear(vm);

    raiseError(vm, "dp",
      "generic",
      "pickle:resources",
      "Resources found during pickling",
      buildList(vm,
        buildSharp(vm, "Resources", resources),
        buildSharp(vm, "Filename", "UNKNOWN FILENAME")));
  }

  // header
  writeSize(count);
  writeSize(topLevelIndex);

  redirections = vm->newStaticArray<nativeint>(count+1);
  for (nativeint i = 1; i <= count; i++) {
    // For some very weird reasons, g++ 4.7.3 produces segfaulting code
    // for this with a (size_t) cast with optimizations enabled.
    redirections[(int) i] = i;
  }

  writeValues(nodes);
  writeArities(nodes);
  writeOthers(nodes);

  vm->deleteStaticArray(redirections, count+1);

  nativeint eof = 0;
  writeSize(eof);
}

void Pickler::writeValues(VMAllocatedList<PickleNode>& nodes) {
  NodeDictionary existingFeatures;
  NodeDictionary existingBuiltins;
  auto iter = nodes.removable_begin();
  auto end = nodes.removable_end();

  while (iter != end) {
    RichNode node = iter->node;
    if (node.isFeature()) {
      if (!findFeature(existingFeatures, iter->index, node))
        writeNode(iter->index, node, *iter->refs);
      iter = nodes.remove(vm, iter);
    } else if (node.is<BuiltinProcedure>()) {
      if (!findBuiltin(existingBuiltins, iter->index, *iter->refs))
        writeNode(iter->index, node, *iter->refs);
      iter = nodes.remove(vm, iter);
    } else if (node.type().getStructuralBehavior() == sbValue) {
      writeNode(iter->index, node, *iter->refs);
      iter = nodes.remove(vm, iter);
    } else {
      ++iter;
    }
  }

  existingFeatures.removeAll(vm);
}

void Pickler::writeArities(VMAllocatedList<PickleNode>& nodes) {
  NodeDictionary existingsArities;
  auto iter = nodes.removable_begin();
  auto end = nodes.removable_end();

  while (iter != end) {
    RichNode node = iter->node;
    if (node.is<Arity>()) {
      if (!findArity(existingsArities, iter->index, node, *iter->refs))
        writeNode(iter->index, node, *iter->refs);
      iter = nodes.remove(vm, iter);
    } else {
      ++iter;
    }
  }

  existingsArities.removeAll(vm);
}

void Pickler::writeOthers(VMAllocatedList<PickleNode>& nodes) {
  while (!nodes.empty()) {
    auto& pickleNode = nodes.front();
    writeNode(pickleNode.index, pickleNode.node, *pickleNode.refs);
    nodes.remove_front(vm);
  }
}

bool Pickler::findFeature(NodeDictionary& existingFeatures,
                          nativeint index, RichNode node) {
  UnstableNode* redir = nullptr;
  if (existingFeatures.lookupOrCreate(vm, node, redir)) {
    redirections[(size_t) index] = RichNode(*redir).as<SmallInt>().value();
    return true;
  } else {
    redir->copy(vm, build(vm, index));
    return false;
  }
}

bool Pickler::findBuiltin(NodeDictionary& existingBuiltins,
                          nativeint index, RichNode refsTuple) {
  auto refs = refsTuple.as<Tuple>();
  RichNode moduleName = *refs.getElement(0);
  RichNode builtinName = *refs.getElement(1);

  UnstableNode* moduleDict = nullptr;
  if (existingBuiltins.lookupOrCreate(vm, moduleName, moduleDict)) {
    NodeDictionary& module = RichNode(*moduleDict).as<Dictionary>().getDict();
    UnstableNode* redir;
    if (module.lookupOrCreate(vm, builtinName, redir)) {
      redirections[(size_t) index] = RichNode(*redir).as<SmallInt>().value();
      return true;
    } else {
      redir->copy(vm, build(vm, index));
      return false;
    }
  } else {
    moduleDict->copy(vm, Dictionary::build(vm));
    UnstableNode idx = build(vm, index);
    RichNode(*moduleDict).as<Dictionary>().dictPut(vm, builtinName, idx);
    return false;
  }
}

bool Pickler::findArity(NodeDictionary& existingsArities,
                        nativeint index, RichNode node, RichNode refsTuple) {
  using namespace patternmatching;

  auto refs = refsTuple.as<Tuple>();
  RichNode ref = *refs.getElement(refs.getWidth()-1);
  UnstableNode labelRef = build(vm, redirections[(size_t) ref.as<SmallInt>().value()]);

  UnstableNode* redir = nullptr;
  if (existingsArities.lookupOrCreate(vm, labelRef, redir)) {
    RichNode head, tail, list = *redir;
    while (matchesCons(vm, list, capture(head), capture(tail))) {
      RichNode writtenIndex;
      if (matchesSharp(vm, head, capture(writtenIndex), node)) {
        redirections[(size_t) index] = writtenIndex.as<SmallInt>().value();
        return true;
      }
      list = tail;
    }
    redir->copy(vm, buildCons(vm, buildSharp(vm, index, node), std::move(*redir)));
    return false;
  } else {
    redir->copy(vm, buildList(vm, buildSharp(vm, index, node)));
    return false;
  }
}

void Pickler::writeNode(nativeint index, RichNode node, RichNode refsTuple) {
  UnstableNode type = RecordLike(refsTuple).label(vm), value;
  RichNode(*vm->getPickleTypesRecord()).as<Record>().lookupFeature(vm, type, value);
  nativeint id = RichNode(value).as<SmallInt>().value();

  writeSize(index);
  writeByte(id);

  switch (id) {
    case 1: // int
    case 2: // float
      writeAsVS(node);
      break;

    case 3: // bool
      writeByte(node.as<Boolean>().value());
      break;

    case 4: // unit
      break;

    case 5: // atom
      writeAtom(node);
      break;

    case 6: { // cons
      auto refs = refsTuple.as<Tuple>();
      writeRef(*refs.getElement(0));
      writeRef(*refs.getElement(1));
      break;
    }

    case 7: // tuple
    case 8: // arity
    case 9: // record
      writeRefsLastFirst(refsTuple);
      break;

    case 10: { // builtin
      auto refs = refsTuple.as<Tuple>();
      writeAtom(*refs.getElement(0));
      writeAtom(*refs.getElement(1));
      break;
    }

    case 11: { // codearea
      writeUUIDOf(node);
      auto refs = refsTuple.as<Tuple>();
      RichNode code = *refs.getElement(0);
      size_t codeSize = RecordLike(code).width(vm);
      writeSize(codeSize);
      for (size_t i = 0; i < codeSize; i++) {
        RichNode element = *code.as<Tuple>().getElement(i);
        ByteCode b = (ByteCode) element.as<SmallInt>().value();
        writeByte(b >> 8 & 0xff);
        writeByte(b & 0xff);
      }
      writeSize(*refs.getElement(1)); // arity
      writeSize(*refs.getElement(2)); // Xcount
      writeAtom(*refs.getElement(4)); // printName
      writeRef(*refs.getElement(5));  // debugData
      writeRefs(*refs.getElement(3)); // Ks
      break;
    }

    case 12: // patmatwildcard
      break;

    case 13: // patmatcapture
      writeSize(*refsTuple.as<Tuple>().getElement(0));
      break;

    case 14: // patmatconjunction
      writeRefs(refsTuple);
      break;

    case 15: // patmatopenrecord
      writeRefsLastFirst(refsTuple);
      break;

    case 16: // abstraction
      writeUUIDOf(node);
      writeRefsLastFirst(refsTuple);
      break;

    case 17: // chunk
      writeRef(*refsTuple.as<Tuple>().getElement(0));
      break;

    case 18: // uniquename
      writeAtom(*refsTuple.as<Tuple>().getElement(0));
      break;

    case 19: // name
      writeUUIDOf(node);
      break;

    case 20: // namedname
      writeUUIDOf(node);
      writeAtom(*refsTuple.as<Tuple>().getElement(0));
      break;

    case 21: { // unicodeString
      auto str = node.as<String>().value();
      writeStr(str.string, str.length);
      break;
    }

    default:
      raiseError(vm, "Unknown type to pickle", type);
  }
}

void Pickler::writeByte(unsigned char byte) {
  output.put(byte);
}

void Pickler::writeSize(size_t size) {
  output.put(size >> 24 & 0xff);
  output.put(size >> 16 & 0xff);
  output.put(size >> 8 & 0xff);
  output.put(size & 0xff);
}

void Pickler::writeSize(RichNode size) {
  writeSize(size.as<SmallInt>().value());
}

void Pickler::writeStr(const char* str, size_t len) {
  writeSize(len);
  output.write(str, len);
}

void Pickler::writeAtom(RichNode atom) {
  auto str = atom.as<Atom>().value();
  writeStr(str.contents(), str.length());
}

void Pickler::writeAsVS(RichNode node) {
  size_t size = ozVSLengthForBuffer(vm, node);
  std::string buffer;
  ozVSGet(vm, node, size, buffer);
  writeStr(buffer.data(), buffer.length());
}

void Pickler::writeRef(RichNode ref) {
  writeSize(redirections[(size_t) ref.as<SmallInt>().value()]);
}

void Pickler::writeNRefs(RichNode refs, size_t n) {
  writeSize(n);
  for (size_t i = 0; i < n; i++) {
    writeRef(*refs.as<Tuple>().getElement(i));
  }
}

void Pickler::writeRefs(RichNode refs) {
  writeNRefs(refs, RecordLike(refs).width(vm));
}

void Pickler::writeRefsLastFirst(RichNode refsTuple) {
  auto refs = refsTuple.as<Tuple>();
  size_t width = refs.getWidth();
  writeRef(*refs.getElement(width-1));
  writeNRefs(refsTuple, width-1);
}

void Pickler::writeUUIDOf(RichNode node) {
  UUID uuid = node.type()->globalize(vm, node)->uuid;
  char buffer[UUID::byte_count];
  uuid.toBytes(reinterpret_cast<unsigned char*>(buffer));
  output.write(buffer, UUID::byte_count);
}

} // namespace mozart
