class FailedValue;

template <>
class Storage<FailedValue> {
public:
  typedef mozart::StableNode * Type;
};
