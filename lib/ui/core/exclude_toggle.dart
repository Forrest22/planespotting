import 'package:flutter/material.dart';

/// The icon and label for the control that takes a card out of (or puts it back in) the game.
IconData excludeIcon(bool excluded) => excluded ? Icons.undo : Icons.block;

String excludeLabel(bool excluded) => excluded ? 'Include in game' : 'Exclude from game';
