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

void Pickler::pickle(RichNode value) {
  // TODO: deduplication of builtins
  UnstableNode statelessArity = buildStatelessArity();
  auto statelessTypes = RichNode(statelessArity).as<Arity>();

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
  for (nativeint i = 1; i <= count; i++)
    redirections[(size_t) i] = i;

  writeValues(nodes);
  writeArities(nodes);
  writeOthers(nodes);

  vm->deleteStaticArray(redirections, count+1);

  nativeint eof = 0;
  writeSize(eof);
}

void Pickler::writeValues(VMAllocatedList<PickleNode>& nodes) {
  NodeDictionary existingFeatures;
  auto iter = nodes.removable_begin();
  auto end = nodes.removable_end();

  while (iter != end) {
    if (iter->node.isFeature()) {
      UnstableNode* redir = nullptr;
      if (existingFeatures.lookupOrCreate(vm, iter->node, redir)) {
        redirections[(size_t) iter->index] = RichNode(*redir).as<SmallInt>().value();
      } else {
        writeValue(iter->index, iter->node, *iter->refs);
        redir->copy(vm, build(vm, iter->index));
      }
      iter = nodes.remove(vm, iter);
    } else if (iter->node.type().getStructuralBehavior() == sbValue) {
      writeValue(iter->index, iter->node, *iter->refs);
      iter = nodes.remove(vm, iter);
    } else {
      ++iter;
    }
  }

  existingFeatures.removeAll(vm);
}

void Pickler::writeArities(VMAllocatedList<PickleNode>& nodes) {
  using namespace patternmatching;

  NodeDictionary existingsArities;
  auto iter = nodes.removable_begin();
  auto end = nodes.removable_end();

  while (iter != end) {
    if (iter->node.is<Arity>()) {
      auto refs = RichNode(*iter->refs).as<Tuple>();
      RichNode ref = *refs.getElement(refs.getWidth()-1);
      UnstableNode labelRef = build(vm, redirections[(size_t) ref.as<SmallInt>().value()]);

      UnstableNode* redir = nullptr;
      if (existingsArities.lookupOrCreate(vm, labelRef, redir)) {
        RichNode head, tail, list = *redir;
        while (matchesCons(vm, list, capture(head), capture(tail))) {
          RichNode index;
          if (matchesSharp(vm, head, capture(index), iter->node)) {
            redirections[(size_t) iter->index] = index.as<SmallInt>().value();
            break;
          }
          list = tail;
        }
        if (matches(vm, list, vm->coreatoms.nil)) { // not found
          writeValue(iter->index, iter->node, *iter->refs);
          redir->copy(vm, buildCons(vm, buildSharp(vm, iter->index, iter->node), std::move(*redir)));
        }
      } else {
        writeValue(iter->index, iter->node, *iter->refs);
        redir->copy(vm, buildList(vm, buildSharp(vm, iter->index, iter->node)));
      }
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
    writeValue(pickleNode.index, pickleNode.node, *pickleNode.refs);
    nodes.remove_front(vm);
  }
}

void Pickler::writeValue(nativeint index, RichNode node, RichNode refsTuple) {
  UnstableNode label = RecordLike(refsTuple).label(vm);
  atom_t type = RichNode(label).as<Atom>().value();
  auto& atoms = vm->coreatoms;

  writeSize(index);

  if (type == atoms.int_) {
    writeByte(1);
    writeAsStr(repr(vm, node));
  }
  else if (type == atoms.float_) {
    writeByte(2);
    writeAsStr(repr(vm, node));
  }
  else if (type == atoms.bool_) {
    writeByte(3);
    writeByte(node.as<Boolean>().value());
  }
  else if (type == atoms.unit) {
    writeByte(4);
  }
  else if (type == atoms.atom) {
    writeByte(5);
    writeAtom(node);
  }
  else if (type == atoms.cons) {
    auto refs = refsTuple.as<Tuple>();
    writeByte(6);
    writeRef(*refs.getElement(0));
    writeRef(*refs.getElement(1));
  }
  else if (type == atoms.tuple) {
    writeByte(7);
    writeRefsLastFirst(refsTuple);
  }
  else if (type == atoms.arity) {
    writeByte(8);
    writeRefsLastFirst(refsTuple);
  }
  else if (type == atoms.record) {
    writeByte(9);
    writeRefsLastFirst(refsTuple);
  }
  else if (type == atoms.builtin) {
    writeByte(10);
    auto refs = refsTuple.as<Tuple>();
    writeAtom(*refs.getElement(0));
    writeAtom(*refs.getElement(1));
  }
  else if (type == atoms.codearea) {
    writeByte(11);
    writeUUIDOf(node);
    auto refs = refsTuple.as<Tuple>();
    RichNode code(*refs.getElement(0));

    size_t codeSize = RecordLike(code).width(vm);
    writeSize(codeSize);
    for (size_t i = 0; i < codeSize; i++) {
      RichNode element(*code.as<Tuple>().getElement(i));
      ByteCode b = (ByteCode) element.as<SmallInt>().value();
      writeByte(b >> 8 & 0xff);
      writeByte(b & 0xff);
    }
    writeSize(*refs.getElement(1));
    writeSize(*refs.getElement(2));
    writeAtom(*refs.getElement(4));
    writeRef(*refs.getElement(5));
    writeRefs(*refs.getElement(3));
  }
  else if (type == atoms.patmatwildcard) {
    writeByte(12);
  }
  else if (type == atoms.patmatcapture) {
    writeByte(13);
    writeSize(*refsTuple.as<Tuple>().getElement(0));
  }
  else if (type == atoms.patmatconjunction) {
    writeByte(14);
    writeRefs(refsTuple);
  }
  else if (type == atoms.patmatopenrecord) {
    writeByte(15);
    writeRefsLastFirst(refsTuple);
  }
  else if (type == atoms.abstraction) {
    writeByte(16);
    writeUUIDOf(node);
    writeRefsLastFirst(refsTuple);
  }
  else if (type == atoms.chunk) {
    writeByte(17);
    writeRef(*refsTuple.as<Tuple>().getElement(0));
  }
  else if (type == atoms.uniquename) {
    writeByte(18);
    writeAtom(*refsTuple.as<Tuple>().getElement(0));
  }
  else if (type == atoms.name) {
    writeByte(19);
    writeUUIDOf(node);
  }
  else if (type == atoms.namedname) {
    writeByte(20);
    writeUUIDOf(node);
    writeAtom(*refsTuple.as<Tuple>().getElement(0));
  }
  else if (type == atoms.unicodeString) {
    writeByte(21);
    writeAsStr(node.as<String>().value());
  }
  else {
    raiseError(vm, "Unknown type to pickle", type.contents());
  }
}

void Pickler::writeByte(unsigned char byte) {
  output.put(byte);
}

void Pickler::writeSize(nativeint size) {
  output.put(size >> 24 & 0xff);
  output.put(size >> 16 & 0xff);
  output.put(size >> 8 & 0xff);
  output.put(size & 0xff);
}

void Pickler::writeSize(RichNode size) {
  writeSize(size.as<SmallInt>().value());
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

void Pickler::writeAtom(RichNode atom) {
  writeAsStr(atom.as<Atom>().value().contents());
}

void Pickler::writeUUIDOf(RichNode node) {
  UUID uuid = node.type()->globalize(vm, node)->uuid;
  char buffer[UUID::byte_count];
  uuid.toBytes(reinterpret_cast<unsigned char*>(buffer));
  output.write(buffer, UUID::byte_count);
}

UnstableNode Pickler::buildStatelessArity() {
  auto& atoms = vm->coreatoms;
  return buildArity(vm, "statelessTypes",
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
  );
}

} // namespace mozart
