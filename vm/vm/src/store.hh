class UnstableNode;
class Node;
typedef long size_t;
#include "memword.hh"
#include "tagged.hh"
#include "type.hh"
#ifndef TAGGED_POINTERS
class Node {
private:
  friend class UnstableNode;
  template<class T, class ...Args>
  void make(VM vm, Args... args){ 
    Accessor<T,typename Storage<T>::Type>::set(data, vt, vm, args...); 
  }
  union {
    struct {
      Node* gcNext;
      Node* gcFrom;
    };
    struct {
      TypeId* vt;
      MemWord data;
    };
  };
};
#else
class Node {
private:
  friend class UnstableNode;
  template<class T, class ...Args>
  void make(VM vm, Args... args){ 
    Accessor<T,typename Storage<T>::Type>::set(tagged, vm, args...); 
  }
  Tagged tagged;
};
#endif
class StableNode {
public:
  void init(UnstableNode& from);
private:
  Node node;
};
class UnstableNode {
public:
  void copy(StableNode& from);
  void copy(UnstableNode& from);
  void swap(UnstableNode& from);
  void reset();
  template<class T, class ...Args>
  void make(VM vm, Args... args){
    node.make(vm,args...);
  }
private:
  Node node;
};

template<class H, class E>
class ArrayWithHeader{
  char* p;
public:
  H* operator->(){return static_cast<H*>(p);}
  E& operator[](size_t i){return static_cast<E*>(p+sizeof(H))[i];}
};
