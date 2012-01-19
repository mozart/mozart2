#include "vm.hh"

#include "variables.hh"

StableNode* VirtualMachine::newVariable() {
  StableNode* result = new (this) StableNode;
  UnstableNode temp;
  temp.make<Unbound>(this);
  result->init(this, temp);
  return result;
}
