class WeakReference;

template <>
class Storage<WeakReference> {
public:
  typedef mozart::StableNode * Type;
};
