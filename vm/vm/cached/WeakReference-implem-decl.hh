class WeakReference;

template <>
class Storage<WeakReference> {
public:
  typedef class mozart::StableNode * Type;
};
