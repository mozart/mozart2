template<class T>
class VTable;

template<class... Ts>
class Type;

template<class Q, class T, class... Ts>
class TypeGetter{
  static VTable<Q> *get(Type<T,Ts...>* it){
    return it->next.template getVT<Q>();
  }
};

template<class T, class... Ts>
class TypeGetter<T,T,Ts...>{
  static VTable<T> *get(Type<T,Ts...>* it){
    return &(it->vt);
  }
};

template<class T, class Is>
class InterfGetter;

template<>
class Type<>{
  void* (*getInterf)(void*);
  template<class Q>
  VTable<Q> *getVT(){
    static_cast<VTable<Q>*>(getInterf(VTable<Q>::def));
  }
  template<class I>
  Type(I*):getInterf(&InterfGetter<I,typename I::interfaces>::getInterf){}
};

template<class N, class H, class T, class F>
class IsInInterfaces;

template<class T>
class DefaultImpl;

template<class T, class... Ts>
class Type<T,Ts...>{
  VTable<T> vt;
  Type<Ts...> next;
  template<class Q>
  VTable<Q> *getVT(){return TypeGetter<Q,T,Ts...>::get(this);}
  template<class I>
  Type(I* x):
    vt(static_cast<typename IsInInterfaces<T,typename I::interfaces,I,DefaultImpl<T> >::Result*>(0)),
       next(x){}
};

typedef Type<> TypeId;

template<class...Is>
class Implements;

template<class N,class...O,class T,class F>
class IsInInterfaces<N,Implements<N,O...>,T,F>{
  typedef T Result;
};

template<class N,class T,class F>
class IsInInterfaces<N,Implements<>,T,F>{
  typedef F Result;
};

template<class T>
class InterfGetter<T,Implements<> >{
  static void* getInterf(void* x){return x;}
};

template<class T, class U, class...Vs>
class InterfGetter<T,Implements<U,Vs...> >{
  static void* getInterf(void* x){
    if(x==VTable<U>::def){
      static const VTable<U> vt(static_cast<T*>(0));
      return vt;
    }else{
      return InterfGetter<T,Implements<Vs...> >::getInterf(x);
    }
  }
};

template<class T>
class DefaultStorage{};
template<class T>
class Storage{
  typedef DefaultStorage<T> Type;
};

class BaseDynObj{
public:
  BaseDynObj(TypeId* t):vt(t){}
private:
  TypeId* vt;
};
template<class T>
class DynObj:BaseDynObj{
  template<class...Args>
  DynObj(TypeId* t,Args...args):BaseDynObj(t),data(args...){}
  T data;
};
template<class T, class U>
class Accessor{
  template<class ...Args>
  void set(MemWord &w, TypeId* &vt, VM vm, Args... args){
    w.set(vm,T::build(args...));
    vt=T::VTable;
  }
  T get(MemWord w){
    return T(w.get<U>());
  }
  template<class ...Args>
  void set(Tagged &w, VM vm, Args... args){
    w.set(Tagged::TagOther,new(vm)DynObj<U>(T::VTable,T::build(args...)));
  }
  T get(Tagged w){
    return T(w.get<U*>());
  }
};
template<class T>
class Accessor<T,DefaultStorage<T>>{
  template<class ...Args>
  void set(MemWord &w, TypeId* &vt, VM vm, Args... args){
    w.set(vm,new(vm)T(vm,args...));
    vt=T::VTable;
  }
  T& get(MemWord w){
    return *(w.get<T*>());
  }
  template<class ...Args>
  void set(Tagged &w, VM vm, Args... args){
    w.set(Tagged::TagOther,new(vm)DynObj<T>(T::VTable,args...));
  }
  T& get(Tagged w){
    return w.get<DynObj<T>*>()->data;
  }
};


template<class T, class R, class M, M m>
class Impl{
  template<class...Args>
  static R f(Node*it, Args...as){
    return (Accessor<T,typename Storage<T>::Type>::get()->*m)(T::Self(it),as...);
  }
};
