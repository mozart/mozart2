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

#ifndef __UTILS_H
#define __UTILS_H

#include "mozartcore.hh"
#include "utils-decl.hh"

namespace mozart {

// function_traits -------------------------------------------------------------
//
// Note: function_traits is taken from
// https://github.com/kennytm/utils/blob/master/traits.hpp.
//
//          Copyright kennytm (auraHT Ltd.) 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file doc/LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
.. type:: struct utils::function_traits<F>

    Obtain compile-time information about a function object *F*.

    This template currently supports the following types:

    * Normal function types (``R(T...)``), function pointers (``R(*)(T...)``)
      and function references (``R(&)(T...)`` and ``R(&&)(T...)``).
    * Member functions (``R(C::*)(T...)``)
    * ``std::function<F>``
    * Type of lambda functions, and any other types that has a unique
      ``operator()``.
    * Type of ``std::mem_fn`` (only for GCC's libstdc++ and LLVM's libc++).
      Following the C++ spec, the first argument will be a raw pointer.
*/
template <typename T>
struct function_traits
    : public function_traits<decltype(&T::operator())>
{};

namespace xx_impl
{
    template <typename C, typename R, typename... A>
    struct memfn_type
    {
        typedef typename std::conditional<
            std::is_const<C>::value,
            typename std::conditional<
                std::is_volatile<C>::value,
                R (C::*)(A...) const volatile,
                R (C::*)(A...) const
            >::type,
            typename std::conditional<
                std::is_volatile<C>::value,
                R (C::*)(A...) volatile,
                R (C::*)(A...)
            >::type
        >::type type;
    };
}

template <typename ReturnType, typename... Args>
struct function_traits<ReturnType(Args...)>
{
    /**
    .. type:: type result_type

        The type returned by calling an instance of the function object type *F*.
    */
    typedef ReturnType result_type;

    /**
    .. type:: type function_type

        The function type (``R(T...)``).
    */
    typedef ReturnType function_type(Args...);

#if defined(__has_feature) && __has_feature(cxx_alias_templates) || __GNUC__ > 4 || __GNUC__ == 4 && __GNUC_MINOR__ >= 7
    /**
    .. type:: type member_function_type<OwnerType>

        The member function type for an *OwnerType* (``R(OwnerType::*)(T...)``).
    */
    template <typename OwnerType>
    using member_function_type = typename xx_impl::memfn_type<
        typename std::remove_pointer<typename std::remove_reference<OwnerType>::type>::type,
        ReturnType, Args...
    >::type;
#endif

    /**
    .. data:: static const size_t arity

        Number of arguments the function object will take.
    */
    enum { arity = sizeof...(Args) };

    /**
    .. type:: type arg<n>::type

        The type of the *n*-th argument.
    */
    template <size_t i>
    struct arg
    {
        typedef typename std::tuple_element<i, std::tuple<Args...>>::type type;
    };
};

template <typename ReturnType, typename... Args>
struct function_traits<ReturnType(*)(Args...)>
    : public function_traits<ReturnType(Args...)>
{};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits<ReturnType(ClassType::*)(Args...)>
    : public function_traits<ReturnType(Args...)>
{
    typedef ClassType& owner_type;
};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits<ReturnType(ClassType::*)(Args...) const>
    : public function_traits<ReturnType(Args...)>
{
    typedef const ClassType& owner_type;
};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits<ReturnType(ClassType::*)(Args...) volatile>
    : public function_traits<ReturnType(Args...)>
{
    typedef volatile ClassType& owner_type;
};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits<ReturnType(ClassType::*)(Args...) const volatile>
    : public function_traits<ReturnType(Args...)>
{
    typedef const volatile ClassType& owner_type;
};

template <typename FunctionType>
struct function_traits<std::function<FunctionType>>
    : public function_traits<FunctionType>
{};

#if defined(_GLIBCXX_FUNCTIONAL)
#define MEM_FN_SYMBOL_XX0SL7G4Z0J std::_Mem_fn
#elif defined(_LIBCPP_FUNCTIONAL)
#define MEM_FN_SYMBOL_XX0SL7G4Z0J std::__mem_fn
#endif

#ifdef MEM_FN_SYMBOL_XX0SL7G4Z0J

template <typename R, typename C>
struct function_traits<MEM_FN_SYMBOL_XX0SL7G4Z0J<R C::*>>
    : public function_traits<R(C*)>
{};
template <typename R, typename C, typename... A>
struct function_traits<MEM_FN_SYMBOL_XX0SL7G4Z0J<R(C::*)(A...)>>
    : public function_traits<R(C*, A...)>
{};
template <typename R, typename C, typename... A>
struct function_traits<MEM_FN_SYMBOL_XX0SL7G4Z0J<R(C::*)(A...) const>>
    : public function_traits<R(const C*, A...)>
{};
template <typename R, typename C, typename... A>
struct function_traits<MEM_FN_SYMBOL_XX0SL7G4Z0J<R(C::*)(A...) volatile>>
    : public function_traits<R(volatile C*, A...)>
{};
template <typename R, typename C, typename... A>
struct function_traits<MEM_FN_SYMBOL_XX0SL7G4Z0J<R(C::*)(A...) const volatile>>
    : public function_traits<R(const volatile C*, A...)>
{};

#undef MEM_FN_SYMBOL_XX0SL7G4Z0J
#endif

template <typename T>
struct function_traits<T&> : public function_traits<T> {};
template <typename T>
struct function_traits<const T&> : public function_traits<T> {};
template <typename T>
struct function_traits<volatile T&> : public function_traits<T> {};
template <typename T>
struct function_traits<const volatile T&> : public function_traits<T> {};
template <typename T>
struct function_traits<T&&> : public function_traits<T> {};
template <typename T>
struct function_traits<const T&&> : public function_traits<T> {};
template <typename T>
struct function_traits<volatile T&&> : public function_traits<T> {};
template <typename T>
struct function_traits<const volatile T&&> : public function_traits<T> {};

// ozListForEach ---------------------------------------------------------------

template <class F, class G>
inline
OpResult ozListForEach(VM vm, RichNode cons, const F& onHead, const G& onTail) {
  while (true) {
    using namespace patternmatching;

    OpResult matchRes = OpResult::proceed();
    typename function_traits<F>::template arg<0>::type head;
    UnstableNode tail;

    if (matchesCons(vm, matchRes, cons, capture(head), capture(tail))) {
      MOZART_CHECK_OPRESULT(onHead(head));
      cons = tail;

    } else if (matches(vm, matchRes, cons, vm->coreatoms.nil)) {
      return OpResult::proceed();

    } else {
      if (matchRes.isProceed())
        return onTail(cons);
      else
        return matchRes;
    }
  }
}

template <class F>
inline
OpResult ozListForEach(VM vm, RichNode cons, const F& onHead,
                       const nchar* expectedType)
{
  return ozListForEach(vm, cons, onHead, [=](RichNode node) {
    return raiseTypeError(vm, expectedType, node);
  });
}

}

#endif

