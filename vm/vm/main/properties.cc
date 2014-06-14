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

#include "mozart.hh"

namespace mozart {

//////////////////////
// PropertyRegistry //
//////////////////////

PropertyRegistry::PropertyRegistry(VirtualMachineOptions options) {
  // Print

  config.printDepth = 10;
  config.printWidth = 20;

  // Errors

  config.errorsDebug = true;
  config.errorsDepth = 10;
  config.errorsWidth = 20;
  config.errorsThread = 40;

  // Garbage collection, aka memory management

  config.minimalHeapSize = options.minimalHeapSize;
  config.maximalHeapSize = options.maximalHeapSize;
  config.heapSize = config.minimalHeapSize;
  config.desiredFreeMemPercentageAfterGC = 75; // percent
  config.gcThresholdTolerance = 10; // percent
  computeInitialGCThreshold();
  computeMaxGCThreshold();
  config.autoGC = true;

  // Memory usage statistics

  stats.activeMemory = 0;
  stats.totalUsedMemory = 0;
}

void PropertyRegistry::registerPredefined(VM vm) {
  // Initialize value properties only now since they need the heap
  config.defaultExceptionHandler = new (vm) StableNode(vm, buildNil(vm));
  config.errorPrefix = new (vm) StableNode(vm, buildNil(vm));

  // Threads

  registerReadOnlyProp<nativeint>(vm, "threads.runnable",
    [] (VM vm) -> nativeint {
      return vm->getThreadPool().getRunnableCount();
    });
  registerConstantProp(vm, "threads.created", 0);
  registerConstantProp(vm, "threads.min", 1);

  // Print

  registerReadWriteProp(vm, "print.depth", config.printDepth);
  registerReadWriteProp(vm, "print.width", config.printWidth);

  // Errors

  registerProp(vm, "errors.handler",
    [this] (VM vm) -> UnstableNode {
      return { vm, *config.defaultExceptionHandler };
    },
    [this] (VM vm, RichNode value) {
      config.defaultExceptionHandler = value.getStableRef(vm);
    }
  );

  registerProp(vm, "errors.prefix",
    [this] (VM vm) -> UnstableNode {
      return { vm, *config.errorPrefix };
    },
    [this] (VM vm, RichNode value) {
      config.errorPrefix = value.getStableRef(vm);
    }
  );

  registerReadWriteProp(vm, "errors.debug", config.errorsDebug);
  registerReadWriteProp(vm, "errors.depth", config.errorsDepth);
  registerReadWriteProp(vm, "errors.width", config.errorsWidth);
  registerReadWriteProp(vm, "errors.thread", config.errorsThread);

  // Garbage collection, aka memory management

  registerConstantProp(vm, "gc.watcher", ReadOnlyVariable::build(vm));

  registerReadOnlyProp<nativeint>(vm, "gc.size",
    [] (VM vm) -> nativeint {
      return vm->getMemoryManager().getAllocated();
    });

  registerReadOnlyProp(vm, "gc.active", stats.activeMemory);
  registerReadOnlyProp(vm, "gc.threshold", config.gcThreshold);
  registerReadOnlyProp(vm, "gc.heapsize", config.heapSize);

  registerReadWriteProp<nativeint>(vm, "gc.min",
    [this] (VM vm) {
      return config.minimalHeapSize;
    },
    [this] (VM vm, nativeint value) {
      if (value > 0 && (size_t) value < config.maximalHeapSize)
        config.minimalHeapSize = value;
    }
  );
  registerReadWriteProp<nativeint>(vm, "gc.max",
    [this] (VM vm) {
      return config.maximalHeapSize;
    },
    [this] (VM vm, nativeint value) {
      if (value > 0 && (size_t) value > config.minimalHeapSize) {
        config.maximalHeapSize = value;
        computeMaxGCThreshold();
      }
    }
  );
  registerReadWriteProp(vm, "gc.free", config.desiredFreeMemPercentageAfterGC);
  registerReadWriteProp(vm, "gc.tolerance", config.gcThresholdTolerance);
  registerReadWriteProp(vm, "gc.on", config.autoGC);

  registerValueProp(vm, "gc.codeCycles", 1); // compatibility, ignored

  // Memory usage statistics - most are irrelevant in Mozart 2

  registerReadOnlyProp<nativeint>(vm, "memory.freelist",
    [] (VM vm) -> nativeint {
      return vm->getMemoryManager().getAllocatedInFreeList();
    });

  registerReadOnlyProp<nativeint>(vm, "memory.heap",
    [] (VM vm) -> nativeint {
      return vm->getMemoryManager().getAllocatedOutsideFreeList() +
        vm->getPropertyRegistry().stats.totalUsedMemory;
    });

  registerConstantProp(vm, "memory.atoms", 0);
  registerConstantProp(vm, "memory.names", 0);
  registerConstantProp(vm, "memory.code", 0);

  // Priorities

  // TODO: these should be mutable, but does the code handle it?
  registerConstantProp(vm, "priorities.high", HiToMiddlePriorityRatio);
  registerConstantProp(vm, "priorities.medium", MiddleToLowPriorityRatio);

  // Messages

  registerValueProp(vm, "messages.gc", false);
  registerValueProp(vm, "messages.idle", false);

  // Limits

  registerConstantProp(vm, "limits.int.min", SmallInt::min());
  registerConstantProp(vm, "limits.int.max", SmallInt::max());
  registerConstantProp(vm, "limits.bytecode.xregisters",
                       std::numeric_limits<ByteCode>::max());

  // Time

  registerConstantProp(vm, "time.user", 0);
  registerConstantProp(vm, "time.system", 0);
  registerConstantProp(vm, "time.total", 0);
  registerConstantProp(vm, "time.run", 0);
  registerConstantProp(vm, "time.idle", 0);
  registerConstantProp(vm, "time.copy", 0);
  registerConstantProp(vm, "time.propagate", 0);
  registerConstantProp(vm, "time.gc", 0);
  registerValueProp(vm, "time.detailed", false);

  // FD

  registerConstantProp(vm, "fd.variables", 0);
  registerConstantProp(vm, "fd.propagators", 0);
  registerConstantProp(vm, "fd.invoked", 0);
  registerValueProp(vm, "fd.threshold", 0);

  // Spaces

  registerConstantProp(vm, "spaces.created", 0);
  registerConstantProp(vm, "spaces.cloned", 0);
  registerConstantProp(vm, "spaces.committed", 0);
  registerConstantProp(vm, "spaces.failed", 0);
  registerConstantProp(vm, "spaces.succeeded", 0);

  // Config - generated by CMake

#include "properties-config.cc"
}

}
