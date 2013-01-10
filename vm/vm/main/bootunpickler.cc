// Copyright © 2012, Université catholique de Louvain
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

namespace {

///////////////////
// BootUnpickler //
///////////////////

class BootUnpickler {
public:
  BootUnpickler(VM vm, std::istream& input): vm(vm), input(input) {
  }

  /** Top-level unpickle function */
  UnstableNode unpickle() {
    size_t count = readSize();
    size_t resultIndex = readSize();

    nodes.resize(count+1);
    for (auto& node: nodes)
      node = OptVar::build(vm);

    while (true) {
      size_t index = readSize();
      if (index == 0)
        break;

      auto value = readValue();
      RichNode(nodes[index]).as<OptVar>().bind(vm, std::move(value));
    }

    return std::move(nodes[resultIndex]);
  }

  /** Read a value */
  UnstableNode readValue() {
    auto kind = readByte();
    switch (kind) {
      case 1: return readIntValue();
      case 2: return readFloatValue();
      case 3: return readBooleanValue();
      case 4: return readUnitValue();
      case 5: return readAtomValue();
      case 6: return readConsValue();
      case 7: return readTupleValue();
      case 8: return readArityValue();
      case 9: return readRecordValue();
      case 10: return readBuiltinValue();
      case 11: return readCodeAreaValue();
      case 12: return readPatMatWildcardValue();
      case 13: return readPatMatCaptureValue();
      case 14: return readPatMatConjunctionValue();
      case 15: return readPatMatOpenRecordValue();
      case 16: return readAbstractionValue();
      case 17: return readChunkValue();
      case 18: return readUniqueNameValue();
      case 19: return readNameValue();
      case 20: return readNamedNameValue();
      default: {
        assert(false && "invalid value kind");
        std::abort();
      }
    }
  }

private:
  UnstableNode readIntValue() {
    std::string str = readString();
    char* end = nullptr;
    long long intResult = std::strtoll(str.c_str(), &end, 10);
    assert(*end == '\0' && "bad integer string");
    return build(vm, (nativeint) intResult);
  }

  UnstableNode readFloatValue() {
    std::string str = readString();
    char* end = nullptr;
    double doubleResult = std::strtod(str.c_str(), &end);
    assert(*end == '\0' && "bad float string");
    return build(vm, doubleResult);
  }

  UnstableNode readBooleanValue() {
    return build(vm, readByte() != 0);
  }

  UnstableNode readUnitValue() {
    return build(vm, unit);
  }

  UnstableNode readAtomValue() {
    return build(vm, readAtom());
  }

  UnstableNode readConsValue() {
    auto head = readNode();
    auto tail = readNode();
    return buildCons(vm, head, tail);
  }

  UnstableNode readTupleValue() {
    auto label = readNode();
    size_t width = readSize();
    UnstableNode result = Tuple::build(vm, width, label);
    readNodes(RichNode(result).as<Tuple>().getElementsArray(), width);
    return result;
  }

  UnstableNode readArityValue() {
    auto label = readNode();
    size_t width = readSize();
    UnstableNode result = Arity::build(vm, width, label);
    readNodes(RichNode(result).as<Arity>().getElementsArray(), width);
    return result;
  }

  UnstableNode readRecordValue() {
    auto arity = readNode();
    size_t width = readSize();
    UnstableNode result = Record::build(vm, width, arity);
    readNodes(RichNode(result).as<Record>().getElementsArray(), width);
    return result;
  }

  UnstableNode readBuiltinValue() {
    auto moduleName = readAtom();
    auto builtinName = readAtom();
    return vm->findBuiltin(moduleName, builtinName);
  }

  UnstableNode readCodeAreaValue() {
    return readGlobalEntity(
      [this] (const UUID& uuid, GlobalNode* gnode) -> UnstableNode {
        size_t size = readSize();
        std::vector<unsigned char> buffer;
        buffer.resize(size*2);
        read(reinterpret_cast<char*>(buffer.data()), size*2);

        std::vector<ByteCode> codeBlock;
        codeBlock.resize(size);
        for (size_t i = 0; i < size; ++i) {
          codeBlock[i] =
            ((ByteCode) buffer[i*2] << 8) | (ByteCode) buffer[i*2+1];
        }

        size_t arity = readSize();
        size_t Xcount = readSize();
        atom_t printName = readAtom();
        auto debugData = readNode();
        size_t Kcount = readSize();

        UnstableNode result = CodeArea::build(
          vm, Kcount, codeBlock.data(), size*2,
          arity, Xcount, printName, debugData);

        readNodes(RichNode(result).as<CodeArea>().getElementsArray(), Kcount);
        RichNode(result).as<CodeArea>().setUUID(vm, uuid);

        return result;
      },
      [this] () {
        size_t size = readSize();
        input.ignore(size*2 + (4 + 4));
        readString();
        readSize();
        size_t Kcount = readSize();
        input.ignore(Kcount*4);
      }
    );
  }

  UnstableNode readPatMatWildcardValue() {
    return PatMatCapture::build(vm, -1);
  }

  UnstableNode readPatMatCaptureValue() {
    return PatMatCapture::build(vm, readSize());
  }

  UnstableNode readPatMatConjunctionValue() {
    size_t width = readSize();
    UnstableNode result = PatMatConjunction::build(vm, width);
    readNodes(RichNode(result).as<PatMatConjunction>().getElementsArray(), width);
    return result;
  }

  UnstableNode readPatMatOpenRecordValue() {
    auto arity = readNode();
    size_t width = readSize();
    UnstableNode result = PatMatOpenRecord::build(vm, width, arity);
    readNodes(RichNode(result).as<PatMatOpenRecord>().getElementsArray(), width);
    return result;
  }

  UnstableNode readAbstractionValue() {
    return readGlobalEntity(
      [this] (const UUID& uuid, GlobalNode* gnode) -> UnstableNode {
        auto codeArea = readNode();
        size_t Gcount = readSize();
        UnstableNode result = Abstraction::build(vm, Gcount, codeArea);
        readNodes(RichNode(result).as<Abstraction>().getElementsArray(), Gcount);
        RichNode(result).as<Abstraction>().setUUID(vm, uuid);
        return result;
      },
      [this] () {
        input.ignore(4);
        size_t Gcount = readSize();
        input.ignore(Gcount*4);
      }
    );
  }

  UnstableNode readChunkValue() {
    UnstableNode underlying = readNode();
    return Chunk::build(vm, underlying);
  }

  UnstableNode readUniqueNameValue() {
    atom_t atom = readAtom();
    return build(vm, unique_name_t(atom));
  }

  UnstableNode readNameValue() {
    return readGlobalEntity(
      [this] (const UUID& uuid, GlobalNode* gnode) -> UnstableNode {
        auto result = GlobalName::build(vm, uuid);
        gnode->self.init(vm, result);
        gnode->protocol.init(vm, MOZART_STR("immval"));
        return result;
      },
      [this] () {
      }
    );
  }

  UnstableNode readNamedNameValue() {
    return readGlobalEntity(
      [this] (const UUID& uuid, GlobalNode* gnode) -> UnstableNode {
        UnstableNode printName(vm, readAtom());
        auto result = NamedName::build(vm, printName, uuid);
        gnode->self.init(vm, result);
        gnode->protocol.init(vm, MOZART_STR("immval"));
        return result;
      },
      [this] () {
      }
    );
  }

  template <typename F, typename G>
  UnstableNode readGlobalEntity(const F& createFun, const G& skipProc) {
    UUID uuid = readUUID();
    GlobalNode* gnode;

    if (!GlobalNode::get(vm, uuid, gnode)) {
      return createFun(uuid, gnode);
    } else {
      skipProc();
      return { vm, gnode->self };
    }
  }

private:
  /** Read a size integer */
  size_t readSize() {
    unsigned char bytes[4];
    read(reinterpret_cast<char*>(bytes), 4);
    return ((size_t) bytes[0] << 24) | ((size_t) bytes[1] << 16) |
      ((size_t) bytes[2] << 8) | (size_t) bytes[3];
  }

  /** Read a byte */
  unsigned char readByte() {
    char bytes[1];
    read(bytes, 1);
    return (unsigned char) bytes[0];
  }

  /** Read a string */
  std::string readString() {
    size_t length = readSize();
    std::string result(length, '\0');
    read(&result[0], length);
    return result;
  }

  /** Read an atom */
  atom_t readAtom() {
    std::string str = readString();
    return vm->getAtom(str.size(), str.data());
  }

  /** Read a node reference */
  template <typename T>
  void readNode(T& dest) {
    size_t index = readSize();
    dest.init(vm, nodes[index]);
  }

  /** Read a node reference */
  UnstableNode readNode() {
    UnstableNode result;
    readNode(result);
    return result;
  }

  /** Read an array of node references */
  template <typename T>
  void readNodes(StaticArray<T> elements, size_t count) {
    for (size_t i = 0; i < count; ++i)
      readNode(elements[i]);
  }

  /** Read a UUID */
  UUID readUUID() {
    char buffer[UUID::byte_count];
    read(buffer, UUID::byte_count);
    return UUID(reinterpret_cast<unsigned char*>(buffer));
  }

  /** Read a byte array */
  void read(char* buffer, size_t length) {
    input.read(buffer, length);
    assert(!input.bad() && "failure while reading");
    assert(!input.eof() && "reached eof too early");
  }

private:
  VM vm;
  std::istream& input;
  std::vector<UnstableNode> nodes;
};

} // namespace <anonymous>

/////////////////
// Entry point //
/////////////////

UnstableNode bootUnpickle(VM vm, std::istream& input) {
  BootUnpickler unpickler(vm, input);
  return unpickler.unpickle();
}

} // namespace mozart
