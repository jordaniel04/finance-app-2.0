import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<bool> {
  // state = isDark
  ThemeCubit() : super(true);

  void toggleTheme() => emit(!state);
  void setDark() => emit(true);
  void setLight() => emit(false);
}
