class FailedValue;

template <>
class Storage<FailedValue> {
public:
  typedef class mozart::StableNode * Type;
};
