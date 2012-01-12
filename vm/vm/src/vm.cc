#include "vm.hh"

#include "variables.hh"

StableNode* VirtualMachine::newVariable() {
  StableNode* result = alloc<StableNode>();
  UnstableNode temp;
  temp.make<Unbound::Repr>(*this, Unbound::type, Unbound::value);
  result->init(temp);
  return result;
}

template <class T>
T* VirtualMachine::alloc(int count) {
  return static_cast<T*>(malloc(count * sizeof(T)));
}
