// misc
export 'routes.dart';
export 'bindings.dart';
export 'constants.dart';

// packages
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'dart:math';
export 'dart:async';
export 'package:get/get.dart';
export 'package:uuid/uuid.dart';
export 'package:google_maps_flutter/google_maps_flutter.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_database/firebase_database.dart';
export 'package:cloud_firestore/cloud_firestore.dart'
    hide Query, Transaction, TransactionHandler;

// models
export 'models/user.dart';
export 'models/chest.dart';
export 'models/bonus.dart';

// views
export 'views/auth/auth.dart';
export 'views/auth/login.dart';
export 'views/auth/register.dart';
export 'views/home.dart';
export 'views/profile.dart';
export 'views/leaderboard.dart';
export 'views/mini_games/quiz.dart';
export 'views/mini_games/memory_match.dart';
export 'views/mini_games/slide_puzzle.dart';
export 'views/mini_games/whack_a_mole.dart';
export 'views/mini_games/ar_treasure_hunt.dart';

// controllers
export 'controllers/auth_controller.dart';
export 'controllers/home_controller.dart';
export 'controllers/theme_controller.dart';

// components
export 'components/text_field.dart';
export 'components/fading_line.dart';
