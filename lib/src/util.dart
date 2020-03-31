part of 'sheet.dart';

void postFrame(VoidCallback callback) {
  assert(callback != null);
  WidgetsBinding.instance.addPostFrameCallback((_) => callback());
}

T swapSign<T extends num>(T value) {
  if (value.isNegative)
    return value.abs();
  else
    return value * -1;
}
