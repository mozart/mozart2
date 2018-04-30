class ReifiedThread;

template <>
class Storage<ReifiedThread> {
public:
  typedef class mozart::Runnable * Type;
};
