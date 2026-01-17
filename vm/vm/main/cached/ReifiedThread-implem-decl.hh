class ReifiedThread;

template <>
class Storage<ReifiedThread> {
public:
  typedef mozart::Runnable * Type;
};
