import 'package:flutter/material.dart';

import '../../core/data/exercise_catalog.dart';
import '../session/exercise_session_screen.dart';

void startExercise(
  BuildContext context,
  Exercise exercise, {
  String title = 'Egzersiz',
}) => ExerciseSessionScreen.open(context, [exercise], title: title);

void startRoutine(BuildContext context, BodyArea area) =>
    ExerciseSessionScreen.open(
      context,
      ExerciseCatalog.byArea(area),
      title: '${area.name} Serisi',
    );
