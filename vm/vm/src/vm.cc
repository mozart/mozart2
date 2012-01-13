#include "vm.hh"

#include "variables.hh"

StableNode* VirtualMachine::newVariable() {
  StableNode* result = new (*this) StableNode;
  UnstableNode temp;
  temp.make<Unbound>(*this);
  result->init(*this, temp);
  return result;
}

void* operator new (size_t size, VM vm) {
  return vm.malloc(size);
}
