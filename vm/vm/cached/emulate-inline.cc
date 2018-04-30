
case 131: {
  ::mozart::builtins::ModInt::Plus1::call(
    vm, XPC(1), XPC(2));
  advancePC(2);
  break;
}

case 132: {
  ::mozart::builtins::ModInt::Minus1::call(
    vm, XPC(1), XPC(2));
  advancePC(2);
  break;
}

case 129: {
  ::mozart::builtins::ModNumber::Add::call(
    vm, XPC(1), XPC(2), XPC(3));
  advancePC(3);
  break;
}

case 130: {
  ::mozart::builtins::ModNumber::Subtract::call(
    vm, XPC(1), XPC(2), XPC(3));
  advancePC(3);
  break;
}

case 144: {
  ::mozart::builtins::ModObject::GetClass::call(
    vm, XPC(1), XPC(2));
  advancePC(2);
  break;
}
