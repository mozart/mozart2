class SmallInt;

template <>
class Storage<SmallInt> {
public:
  typedef mozart::nativeint Type;
};
