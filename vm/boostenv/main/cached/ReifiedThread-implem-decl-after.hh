template <>
class TypeInfoOf<ReifiedThread>: public TypeInfo {

  static constexpr UUID uuid() {
    return UUID();
  }
public:
  TypeInfoOf() : TypeInfo("ReifiedThread", uuid(), (! ::mozart::MemWord::requiresExternalMemory<mozart::Runnable *>()), false, false, sbValue, 0) {}

  static const TypeInfoOf<ReifiedThread>* const instance() {
    return &RawType<ReifiedThread>::rawType;
  }

  static Type type() {
    return Type(instance());
  }

  atom_t getTypeAtom(VM vm) const {
    return ReifiedThread::getTypeAtom(vm);
  }

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, StableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, UnstableNode& to) const;
};

template <>
class TypedRichNode<ReifiedThread>: public BaseTypedRichNode {
public:
  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}

  inline
  bool equals(mozart::VM vm, mozart::RichNode right);

  inline
  mozart::Runnable * value();

  inline
  void wakeUp(mozart::VM vm);

  inline
  bool shouldWakeUpUnderSpace(mozart::VM vm, mozart::Space * space);

  inline
  bool isThread(mozart::VM vm);

  inline
  mozart::ThreadPriority getThreadPriority(mozart::VM vm);

  inline
  void setThreadPriority(mozart::VM vm, mozart::ThreadPriority priority);

  inline
  void injectException(mozart::VM vm, mozart::RichNode exception);

  inline
  void suspend(mozart::VM vm);

  inline
  void resume(mozart::VM vm);

  inline
  void preempt(mozart::VM vm);

  inline
  bool isSuspended(mozart::VM vm);
};
