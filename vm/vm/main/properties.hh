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

#ifndef __PROPERTIES_H
#define __PROPERTIES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

#include <iostream>

namespace mozart {

//////////////////////
// PropertyRegistry //
//////////////////////

UnstableNode* PropertyRegistry::registerInternal(VM vm, const nchar* property) {
  UnstableNode key = build(vm, property);
  UnstableNode* descriptor;
  if (_registry->lookupOrCreate(vm, key, descriptor)) {
    raiseKernelError(vm, MOZART_STR("registerProperty"), key);
  } else {
    return descriptor;
  }
}

template <class T>
void PropertyRegistry::registerValueProp(VM vm, const nchar* property,
                                         T&& value) {
  auto descriptor = registerInternal(vm, property);
  *descriptor = buildTuple(vm, vm->coreatoms.sharp,
                           false, std::forward<T>(value));
}

template <class T>
void PropertyRegistry::registerConstantProp(VM vm, const nchar* property,
                                            T&& value) {
  auto descriptor = registerInternal(vm, property);
  *descriptor = buildTuple(vm, vm->coreatoms.sharp,
                           true, std::forward<T>(value));
}

void PropertyRegistry::registerProp(VM vm, const nchar* property,
                                    const PropertyRecord::Getter& getter,
                                    const PropertyRecord::Setter& setter) {
  auto descriptor = registerInternal(vm, property);
  *descriptor = build(vm, _records.size());
  _records.emplace_back(getter, setter);
}

template <class T>
void PropertyRegistry::registerReadWriteProp(
  VM vm, const nchar* property, const std::function<T(VM)>& getter,
  const std::function<void(VM, T)>& setter) {

  registerProp(
    vm, property,
    [getter] (VM vm) -> UnstableNode {
      return build(vm, getter(vm));
    },
    [setter] (VM vm, RichNode value) {
      setter(vm, getArgument<T>(vm, value));
    });
}

template <class T>
void PropertyRegistry::registerReadOnlyProp(
  VM vm, const nchar* property, const std::function<T(VM)>& getter) {

  registerProp(
    vm, property,
    [getter] (VM vm) -> UnstableNode {
      return build(vm, getter(vm));
    },
    nullptr);
}

template <class T>
void PropertyRegistry::registerWriteOnlyProp(
  VM vm, const nchar* property, const std::function<void(VM, T)>& setter) {

  registerProp(
    vm, property,
    nullptr,
    [setter] (VM vm, RichNode value) {
      setter(vm, getArgument<T>(vm, value));
    });
}

template <class T>
void PropertyRegistry::registerReadWriteProp(VM vm, const nchar* property,
                                             T& variable) {
  registerProp(
    vm, property,
    [&variable] (VM vm) -> UnstableNode {
      return build(vm, variable);
    },
    [&variable] (VM vm, RichNode value) {
      variable = getArgument<T>(vm, value);
    });
}

template <class T>
void PropertyRegistry::registerReadOnlyProp(VM vm, const nchar* property,
                                            T& variable) {
  registerProp(
    vm, property,
    [&variable] (VM vm) -> UnstableNode {
      return build(vm, variable);
    },
    nullptr);
}

bool PropertyRegistry::get(VM vm, RichNode property, UnstableNode& result) {
  using namespace patternmatching;

  UnstableNode* descriptor0;
  if (!_registry->lookup(vm, property, descriptor0))
    return false;

  RichNode descriptor = *descriptor0;
  nativeint systemProp = 0;

  if (matches(vm, descriptor, capture(systemProp))) {
    result = getSystemProp(vm, property, systemProp);
    return true;
  } else if (matchesSharp(vm, descriptor, wildcard(), capture(result))) {
    return true;
  } else {
    std::cerr << repr(vm, descriptor) << "\n";
    assert(false);
    return false;
  }
}

template <typename Prop>
bool PropertyRegistry::get(VM vm, Prop&& property, UnstableNode& result) {
  auto prop = build(vm, std::forward<Prop>(property));
  return get(vm, RichNode(prop), result);
}

bool PropertyRegistry::put(VM vm, RichNode property, RichNode value) {
  using namespace patternmatching;

  UnstableNode* descriptor0;
  if (!_registry->lookup(vm, property, descriptor0))
    return false;

  RichNode descriptor = *descriptor0;
  nativeint systemProp = 0;

  if (matches(vm, descriptor, capture(systemProp))) {
    putSystemProp(vm, property, systemProp, value);
    return true;
  } else if (matchesSharp(vm, descriptor, false, wildcard())) {
    *descriptor0 = buildTuple(vm, vm->coreatoms.sharp, false, value);
    return true;
  } else if (matchesSharp(vm, descriptor, true, wildcard())) {
    raiseError(vm, vm->coreatoms.system,
               MOZART_STR("putProperty"), property);
  } else {
    std::cerr << repr(vm, descriptor) << "\n";
    assert(false);
    return false;
  }
}

template <typename Prop, typename Value>
bool PropertyRegistry::put(VM vm, Prop&& property, Value&& value) {
  auto prop = build(vm, std::forward<Prop>(property));
  auto val = build(vm, std::forward<Value>(value));
  return put(vm, RichNode(prop), RichNode(val));
}

UnstableNode PropertyRegistry::getSystemProp(VM vm, RichNode property,
                                             nativeint systemProp) {
  assert((systemProp >= 0) && ((size_t) systemProp < _records.size()));
  PropertyRecord& record = _records[systemProp];

  if (record.getter) {
    return record.getter(vm);
  } else {
    raiseError(vm, vm->coreatoms.system,
               MOZART_STR("getProperty"), property);
  }
}

void PropertyRegistry::putSystemProp(VM vm, RichNode property,
                                     nativeint systemProp, RichNode value) {
  assert((systemProp >= 0) && ((size_t) systemProp < _records.size()));
  PropertyRecord& record = _records[systemProp];

  if (record.setter) {
    record.setter(vm, value);
  } else {
    raiseError(vm, vm->coreatoms.system,
               MOZART_STR("putProperty"), property);
  }
}

void PropertyRegistry::create(VM vm) {
  _registry = new (vm) NodeDictionary;
}

void PropertyRegistry::gCollect(GC gc) {
  _registry = new (gc->vm) NodeDictionary(gc, *_registry);

  gc->copyStableRef(config.defaultExceptionHandler,
                    config.defaultExceptionHandler);
}

}

#endif // MOZART_GENERATOR

#endif // __PROPERTIES_H
