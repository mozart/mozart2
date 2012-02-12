#include "vm.hh"

#include "variables.hh"
#include "emulate.hh"

StableNode* VirtualMachine::newVariable() {
  StableNode* result = new (this) StableNode;
  UnstableNode temp;
  temp.make<Unbound>(this);
  result->init(this, temp);
  return result;
}

void VirtualMachine::run() {
  while (true) {
    Thread* currentThread;

    // Select a thread
    do {
      currentThread = dynamic_cast<Thread*>(threadPool.popNext());

      if (currentThread == nullptr) {
        // All remaining threads are suspended
        // TODO Is there something special to do in that case?
        return;
      }
    } while (currentThread->isTerminated());

    // Run the thread
    currentThread->run();

    // Schedule the thread anew if it is still runnable
    if (currentThread->isRunnable())
      threadPool.schedule(currentThread);
  }
}

void VirtualMachine::scheduleThread(Thread* thread) {
  threadPool.schedule(thread);
}
