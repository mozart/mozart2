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

#ifndef __OZCALLS_H
#define __OZCALLS_H

#include "mozartcore.hh"
#include "emulate.hh"

#include <type_traits>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace ozcalls {

//////////////////////////////
// Calling Oz code from C++ //
//////////////////////////////

namespace internal {

/**
 * Specializable routine to initialize the input arguments of an ozcall.
 */
template <typename T, bool synchronous>
struct InitOneArg {
  static void call(VM vm, UnstableNode& dest, T&& value) {
    dest.init(vm, std::forward<T>(value));
  }
};

// Specializations for asynchronous calls

template <>
struct InitOneArg<OutputParam<UnstableNode>, false> {
  static void call(VM vm, UnstableNode& dest, OutputParam<UnstableNode> param) {
    StableNode* variable = new (vm) StableNode(vm, OptVar::build(vm));
    param.value = Reference::build(vm, variable);
    dest = Reference::build(vm, variable);
  }
};

template <>
struct InitOneArg<OutputParam<RichNode>, false> {
  static void call(VM vm, UnstableNode& dest, OutputParam<RichNode> param) {
    StableNode* variable = new (vm) StableNode(vm, OptVar::build(vm));
    param.value = *variable;
    dest = Reference::build(vm, variable);
  }
};

template <typename T>
struct InitOneArg<OutputParam<T>, false> {
  static_assert(!std::is_same<T, T>::value,
    "out(V) with a C++ value is only permitted in synchronous calls");
};

// Specializations for synchronous calls

template <typename T>
struct InitOneArg<OutputParam<T>, true> {
  static void call(VM vm, UnstableNode& dest, OutputParam<T> param) {
    dest = OptVar::build(vm);
  }
};

template <typename T>
struct InitOneArg<nullable<T&>, true> {
  static void call(VM vm, UnstableNode& dest, nullable<T&> param) {
    if (param.isNull())
      dest = buildTuple(vm, "none");
    else
      dest = buildTuple(vm, "some", OptVar::build(vm));
  }
};

template <typename T>
struct InitOneArg<nullable<T&>&, true>: public InitOneArg<nullable<T&>, true> {
};

template <size_t i, bool synchronous>
inline
void initNodesFromVariadicArgs(VM vm, UnstableNode nodes[]) {
}

template <size_t i, bool synchronous, typename Head, typename... Tail>
inline
void initNodesFromVariadicArgs(VM vm, UnstableNode nodes[],
                               Head&& head, Tail&&... tail) {
  InitOneArg<Head, synchronous>::call(vm, nodes[i],
                                      std::forward<Head>(head));
  initNodesFromVariadicArgs<i+1, synchronous>(vm, nodes,
                                              std::forward<Tail>(tail)...);
}

template <bool synchronous, typename... Args>
inline
void initInputArguments(VM vm, UnstableNode unstables[], RichNode riches[],
                        Args&&... args) {
  constexpr size_t argc = sizeof...(args);

  internal::initNodesFromVariadicArgs<0, synchronous>(
    vm, unstables, std::forward<Args>(args)...);

  for (size_t i = 0; i < argc; i++)
    riches[i] = unstables[i];
}

/** Metastruct that defines how to process the output arguments */
template <size_t inputIdx, size_t outputIdx, typename... Args>
struct OutputProcessing {
};

/** Base case specialization */
template <size_t inputIdx, size_t outputIdx>
struct OutputProcessing<inputIdx, outputIdx> {
  static constexpr size_t outArgc() {
    return outputIdx;
  }

  static void initOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                  UnstableNode inputs[]) {
  }

  static void processOutputArguments(VM vm, StaticArray<StableNode> outputs) {
  }
};

/** Input parameter specialization */
template <size_t inputIdx, size_t outputIdx, typename Head, typename... Tail>
struct OutputProcessing<inputIdx, outputIdx, Head, Tail...> {
  typedef OutputProcessing<inputIdx+1, outputIdx, Tail...> Next;

  static constexpr size_t outArgc() {
    return Next::outArgc();
  }

  static void initOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                  UnstableNode inputs[]) {
    Next::initOutputArguments(vm, outputs, inputs);
  }

  static void processOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                     Head&& head, Tail&&... tail) {
    Next::processOutputArguments(vm, outputs, std::forward<Tail>(tail)...);
  }
};

/** Output parameter specialization */
template <size_t inputIdx, size_t outputIdx, typename T, typename... Tail>
struct OutputProcessing<inputIdx, outputIdx, OutputParam<T>, Tail...> {
  typedef OutputProcessing<inputIdx+1, outputIdx+1, Tail...> Next;

  static constexpr size_t outArgc() {
    return Next::outArgc();
  }

  static void initOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                  UnstableNode inputs[]) {
    outputs[outputIdx].init(vm, inputs[inputIdx]);
    Next::initOutputArguments(vm, outputs, inputs);
  }

  static void processOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                     OutputParam<T> head, Tail&&... tail) {
    head.value = getArgument<T>(vm, outputs[outputIdx]);
    Next::processOutputArguments(vm, outputs, std::forward<Tail>(tail)...);
  }
};

/** Optional output parameter specialization */
template <size_t inputIdx, size_t outputIdx, typename T, typename... Tail>
struct OutputProcessing<inputIdx, outputIdx, nullable<T&>, Tail...> {
  typedef OutputProcessing<inputIdx+1, outputIdx+1, Tail...> Next;

  static constexpr size_t outArgc() {
    return Next::outArgc();
  }

  static void initOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                  UnstableNode inputs[]) {
    outputs[outputIdx].init(vm, inputs[inputIdx]);
    Next::initOutputArguments(vm, outputs, inputs);
  }

  static void processOutputArguments(VM vm, StaticArray<StableNode> outputs,
                                     nullable<T&> head, Tail&&... tail) {
    using namespace patternmatching;

    if (!head.isNull()) {
      RichNode value;
      matchesTuple(vm, outputs[outputIdx], "some", capture(value));
      head.get() = getArgument<T>(vm, value);
    }

    Next::processOutputArguments(vm, outputs, std::forward<Tail>(tail)...);
  }
};

template <size_t inputIdx, size_t outputIdx, typename T, typename... Tail>
struct OutputProcessing<inputIdx, outputIdx, nullable<T&>&, Tail...>
  : public OutputProcessing<inputIdx, outputIdx, nullable<T&>, Tail...> {
};

} // namespace internal

void asyncOzCall(VM vm, Space* space, RichNode callable) {
  new (vm) Thread(vm, space, callable, 0, nullptr);
}

template <typename... Args>
void asyncOzCall(VM vm, Space* space, RichNode callable, Args&&... args) {
  constexpr size_t argc = sizeof...(args);

  UnstableNode unstableArgs[argc];
  RichNode arguments[argc];
  internal::initInputArguments<false>(
    vm, unstableArgs, arguments, std::forward<Args>(args)...);

  new (vm) Thread(vm, space, callable, argc, arguments);
}

template <typename... Args>
void asyncOzCall(VM vm, RichNode callable, Args&&... args) {
  asyncOzCall(vm, vm->getCurrentSpace(), callable,
              std::forward<Args>(args)...);
}

namespace internal {

template <bool reflective, typename Effect, typename... Args>
bool syncCallGeneric(VM vm, const char* identity, const Effect& effect,
                     Args&&... args) {
  constexpr size_t argc = sizeof...(args);

  typedef internal::OutputProcessing<0, 0, Args...> OutputProcessing;

  constexpr size_t outArgc = OutputProcessing::outArgc();

  /* Most unfortunately, gcc does not yet support capturing a parameter pack
   * in a lambda. See http://gcc.gnu.org/bugzilla/show_bug.cgi?id=41934
   * It makes it awkward to reuse performNonIdempotentStep. This is why we have
   * some code duplication with this routine.
   */

  assert(vm->isIntermediateStateAvailable());

  IntermediateState& intermediateState = vm->getIntermediateState();
  auto checkPoint = intermediateState.makeCheckPoint(vm);
  RichNode state;

  if (!intermediateState.fetch(vm, identity,
                               patternmatching::capture(state))) {
    // Initialize the input arguments

    UnstableNode unstableArgs[argc];
    internal::initNodesFromVariadicArgs<0, /* synchronous = */ true>(
      vm, unstableArgs, std::forward<Args>(args)...);

    // Perform the effect

    UnstableNode terminationVar;
    effect(vm, unstableArgs, terminationVar);

    // Build the output of the first step

    UnstableNode outputTuple = Tuple::build(vm, outArgc+1,
                                            vm->coreatoms.sharp);
    StaticArray<StableNode> outputs =
      RichNode(outputTuple).as<Tuple>().getElementsArray();

    OutputProcessing::initOutputArguments(vm, outputs, unstableArgs);
    outputs[outArgc].init(vm, std::move(terminationVar));

    // Store the result of the first step in the intermediate state

    intermediateState.resetAndStore(vm, checkPoint, identity, outputTuple);
    state = outputTuple;
    state.ensureStable(vm);
  }

  {
    StaticArray<StableNode> outputs =
      state.as<Tuple>().getElementsArray();

    RichNode terminationVar = outputs[outArgc];
    if (terminationVar.isTransient())
      waitFor(vm, terminationVar);

    if (reflective && !terminationVar.is<Unit>())
      return false;

    // Now the thread is terminated, we can fetch the arguments

    OutputProcessing::processOutputArguments(vm, outputs,
                                             std::forward<Args>(args)...);

    return true;
  }
}

template <size_t count, size_t i = 0, typename F>
inline
auto static_for(const F& f) -> typename std::enable_if<i == count, void>::type {
}

template <size_t count, size_t i = 0, typename F>
inline
auto static_for(const F& f) -> typename std::enable_if<i != count, void>::type {
  f(i);
  static_for<count, i+1, F>(f);
}

}

template <typename... Args>
void ozCall(VM vm, const char* identity, RichNode callable, Args&&... args) {
  internal::syncCallGeneric</* reflective = */ false>(
    vm, identity,
    [callable] (VM vm, UnstableNode unstableArgs[],
                UnstableNode& terminationVar) {
      constexpr size_t argc = sizeof...(Args);

      RichNode arguments[argc];
      internal::static_for<argc>(
        [&] (size_t i) {
          arguments[i] = unstableArgs[i];
        }
      );

      Thread* thr = new (vm) Thread(vm, vm->getCurrentSpace(),
                                    callable, argc, arguments);

      terminationVar.copy(vm, thr->getTerminationVar());
    },
    std::forward<Args>(args)...
  );
}

template <typename... Args>
void ozCall(VM vm, RichNode callable, Args&&... args) {
  ozCall(vm, "::mozart::ozcalls::ozCall", callable,
         std::forward<Args>(args)...);
}

namespace internal {

template <typename Label, typename... Args>
inline
bool doReflectiveCall(VM vm, const char* identity, UnstableNode& stream,
                      Label&& label, Args&&... args) {
  return internal::syncCallGeneric</* reflective = */ true>(
    vm, identity,
    [&stream, &label] (VM vm, UnstableNode unstableArgs[],
                       UnstableNode& terminationVar) {
      constexpr size_t argc = sizeof...(Args);

      // Create the message

      auto message = Tuple::build(vm, argc, std::forward<Label>(label));
      auto messageElements = RichNode(message).as<Tuple>().getElementsArray();
      internal::static_for<argc>(
        [&] (size_t i) {
          messageElements[i].init(vm, unstableArgs[i]);
        }
      );

      // Create the termination variable

      terminationVar = Variable::build(vm);

      // Send the message#terminationVar to the stream

      sendToReadOnlyStream(vm, stream, buildSharp(vm, message, terminationVar));
    },
    std::forward<Args>(args)...
  );
}

} // namespace internal

} // namespace ozcalls

} // namespace mozart

#endif

#endif // __OZCALLS_H
