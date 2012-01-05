#include "vm.hh"

UnstableNode* VirtualMachine::newVariable() {
  return new UnstableNode;
}
