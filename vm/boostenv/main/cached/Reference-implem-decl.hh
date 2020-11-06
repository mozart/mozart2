class Reference;

template <>
class Storage<Reference> {
public:
  typedef mozart::StableNode * Type;
};
