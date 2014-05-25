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

#ifndef MOZART_PROPERTIES_DECL_H
#define MOZART_PROPERTIES_DECL_H

#include "core-forward-decl.hh"

#include "store-decl.hh"

#include <vector>
#include <functional>

namespace mozart {

////////////////////
// PropertyRecord //
////////////////////

struct PropertyRecord {
  typedef std::function<UnstableNode(VM vm)> Getter;
  typedef std::function<void(VM vm, RichNode value)> Setter;

  PropertyRecord(const Getter& getter, const Setter& setter) {
    this->getter = getter;
    this->setter = setter;
  }

  Getter getter;
  Setter setter;
};

//////////////////////
// PropertyRegistry //
//////////////////////

class PropertyRegistry {
public:
  PropertyRegistry(VirtualMachineOptions options);

private:
  inline
  UnstableNode* registerInternal(VM vm, const char* property);

public:
  template <class T>
  inline
  void registerValueProp(VM vm, const char* property, T&& value);

  template <class T>
  inline
  void registerConstantProp(VM vm, const char* property, T&& value);

  inline
  void registerProp(VM vm, const char* property,
                    const PropertyRecord::Getter& getter,
                    const PropertyRecord::Setter& setter);

  template <class T>
  inline
  void registerReadWriteProp(VM vm, const char* property,
                             const std::function<T(VM)>& getter,
                             const std::function<void(VM, T)>& setter);

  template <class T>
  inline
  void registerReadOnlyProp(VM vm, const char* property,
                            const std::function<T(VM)>& getter);

  template <class T>
  inline
  void registerWriteOnlyProp(VM vm, const char* property,
                             const std::function<void(VM, T)>& setter);

  template <class T>
  inline
  void registerReadWriteProp(VM vm, const char* property, T& variable);

  template <class T>
  inline
  void registerReadOnlyProp(VM vm, const char* property, T& variable);

public:
  inline
  bool get(VM vm, RichNode property, UnstableNode& result);

  template <typename Prop>
  inline
  bool get(VM vm, Prop&& property, UnstableNode& result);

  inline
  bool put(VM vm, RichNode property, RichNode value,
           bool forceWriteConstantProp = false);

  template <typename Prop, typename Value>
  inline
  bool put(VM vm, Prop&& property, Value&& value,
           bool forceWriteConstantProp = false);

private:
  inline
  UnstableNode getSystemProp(VM vm, RichNode property, nativeint systemProp);

  inline
  void putSystemProp(VM vm, RichNode property, nativeint systemProp,
                     RichNode value);

private:
  friend class VirtualMachine;

  inline
  void create(VM vm);

  inline
  void gCollect(GC gc);

  void registerPredefined(VM vm);

public:
  StableNode* getDefaultExceptionHandler() {
    return config.defaultExceptionHandler;
  }

public:
  void computeGCThreshold(size_t activeMemory) {
    config.gcThreshold = std::min(config.maxGCThreshold,
      activeMemory / (100 - config.desiredFreeMemPercentageAfterGC) * 100);
  }

private:
  void computeInitialGCThreshold() {
    // We want the heap to be gcThresholdTolerance % above the threshold
    size_t tolerance = config.gcThresholdTolerance;
    config.gcThreshold = config.heapSize / (100 + tolerance) * 100;
  }

  void computeMaxGCThreshold() {
    size_t tolerance = config.gcThresholdTolerance;
    config.maxGCThreshold = config.maximalHeapSize / (100 + tolerance) * 100;
    config.gcThreshold = std::min(config.maxGCThreshold, config.gcThreshold);
  }

private:
  NodeDictionary* _registry;

  std::vector<PropertyRecord> _records;

public:
  struct {
    // Print
    nativeint printDepth;
    nativeint printWidth;

    // Errors
    StableNode* defaultExceptionHandler;
    StableNode* errorPrefix;
    bool errorsDebug;
    nativeint errorsDepth;
    nativeint errorsWidth;
    nativeint errorsThread;

    // Garbage collection, aka memory management - most are ignored, actually
    size_t heapSize;
    size_t minimalHeapSize;
    size_t maximalHeapSize;
    size_t desiredFreeMemPercentageAfterGC;
    size_t gcThreshold;
    size_t maxGCThreshold;
    size_t gcThresholdTolerance;
    bool autoGC;
  } config;

  struct {
    // Memory usage statistics
    size_t activeMemory;
    size_t totalUsedMemory;
  } stats;
};

}

#endif // MOZART_PROPERTIES_DECL_H
