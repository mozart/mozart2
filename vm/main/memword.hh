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

// A MemWord (memory word) is a type which is defined as having the size of a
// char* and behaving as the union of a number of other types. If they are
// small enough, they are actually stored in the MemWord. If not, they are
// stored as a pointer to external memory.

// The MWUnion type implements the MemWord by having a template pack of types
// to be made into a union.

// The MWUAccessor provides the getters/setters for the MWUnion.

// The MWTest is an helper class to deal with types which are bigger than a
// char*


#ifndef __MEMWORD_H
#define __MEMWORD_H

#include "core-forward-decl.hh"

namespace mozart {

// MWTest is a metafunction that returns T if i!=0 and a type guaranteed to be
// smaller or equal to char* if i==0
template<class T, int i>
struct MWTest{
public:
  typedef T Type;
};
template<class T>
class MWTest<T,0>{
public:
  typedef char Type;
};

template<class ...args>
union MWUnion;

// In an MWUAccessor, U is a specialization of MWUnion, T is the requested type
// and R is the type of the first member of the union.
// In the default case, the requested type is different from the first one and
// we recurse in the rest.
template<class U, class T, class R>
class MWUAccessor{
public:
  static T& get(U *u){return (u->next).template get<T>();}
  static void alloc(VM vm, U *u){u->next.template alloc<T>(vm);}
};

// The bottom case of the MWUnion contains just a char* as it can be cast to
// any other pointer without fear of aliasing problems.
template<>
union MWUnion<>{
  char* it;
  template<class T>
  T& get(){return MWUAccessor<MWUnion,T,T>::get(this);}
  template<class T>
  void alloc(VM vm){MWUAccessor<MWUnion,T,T>::alloc(vm,this);}
};

// The easy case of accessing what we have in the first member of the union.
template<class U, class T>
class MWUAccessor<U,T,T>{
public:
  static T& get(U *u){return u->it;}
  static void alloc(VM vm, U *u){}
};

// Accessing something that wasn't there, if a pointer type, we just get away
// with a cast.
template<class T>
class MWUAccessor<MWUnion<>,T*,T*>{
public:
  static T*& get(MWUnion<>* u){return reinterpret_cast<T*&>(u->it);}
  static void alloc(VM vm, MWUnion<> *u){}
};
// It isn't there and isn't a pointer so we store a pointer to it.
// This requires external memory
template<class T>
class MWUAccessor<MWUnion<>,T,T>{
public:
  static T& get(MWUnion<>* u){return *reinterpret_cast<T*>(u->it);}
  static void alloc(VM vm, MWUnion<> *u){
    u->it=reinterpret_cast<char*>(new(vm)T);
  }
};
// The union itself, recursive on the parameter pack. If the first type is too
// big, we reduce it.
template<class T, class ...args>
union MWUnion<T,args...>{
  typedef typename MWTest<T,sizeof(T)<=sizeof(char*)>::Type Tred;
  Tred it;
  MWUnion<args...> next;
  template<class Q>
  Q& get(){return MWUAccessor<MWUnion,Q,Tred>::get(this);}
  template<class Q>
  void init(VM vm,Q v){ alloc<Q>(vm); get<Q>() = v; }
  template<class Q>
  void alloc(VM vm){MWUAccessor<MWUnion,Q,Tred>::alloc(vm,this);}
};

// Finally, here comes the list of potentially small types that we want to
// optimize in a memory word.
typedef MWUnion<nativeint, bool, double, unit_t, SpaceRef> MemWord;

static_assert(sizeof(MemWord) == sizeof(char *),
  "MemWord has not the size of a word");

}

#endif // __MEMWORD_H
