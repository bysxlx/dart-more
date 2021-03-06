/// A first-class model of character classes, their composition and operations
/// on strings.
///
/// The implementation is inspired by [Guava](http://goo.gl/xXROX), the Google
/// collection of libraries for Java-based projects.
library more.char_matcher;

import 'package:meta/meta.dart' show immutable;

import 'src/char_matcher/any.dart';
import 'src/char_matcher/ascii.dart';
import 'src/char_matcher/char_set.dart';
import 'src/char_matcher/digit.dart';
import 'src/char_matcher/disjunctive.dart';
import 'src/char_matcher/letter.dart';
import 'src/char_matcher/letter_or_digit.dart';
import 'src/char_matcher/lower_case.dart';
import 'src/char_matcher/negate.dart';
import 'src/char_matcher/none.dart';
import 'src/char_matcher/pattern.dart';
import 'src/char_matcher/range.dart';
import 'src/char_matcher/single.dart';
import 'src/char_matcher/upper_case.dart';
import 'src/char_matcher/whitespace.dart';

/// Abstract character matcher function.
///
/// The [CharMatcher] is a boolean predicate on characters. The inclusion of a
/// character can be determined by calling [match] with the code-unit of a
/// character as the function argument, for example:
///
///     CharMatcher.whitespace().match(' '.codeUnitAt(0)); // true
///     CharMatcher.digit().match('a'.codeUnitAt(0)); // false
///
/// A large collection of helper methods let you perform string operations on
/// the occurrences of the specified class of characters: trimming, collapsing,
/// replacing, removing, retaining, etc. For example:
///
///     String withoutWhitespace = CharMatcher.whitespace().removeFrom(string);
///     String onlyDigits = CharMatcher.digit().retainFrom(string);
///
@immutable
abstract class CharMatcher {
  /// A matcher that accepts any character.
  factory CharMatcher.any() => const AnyCharMatcher();

  /// A matcher that accepts no character.
  factory CharMatcher.none() => const NoneCharMatcher();

  /// A matcher that accepts a single [character].
  factory CharMatcher.isChar(Object character) =>
      SingleCharMatcher(_toCharCode(character));

  /// A matcher that accepts a character range from [start] to [stop].
  factory CharMatcher.inRange(Object start, Object stop) =>
      RangeCharMatcher(_toCharCode(start), _toCharCode(stop));

  /// A matcher that accepts a set of characters.
  factory CharMatcher.charSet(String chars) => fromCharSet(chars);

  /// A matcher that accepts a regular expression character class.
  factory CharMatcher.pattern(String pattern) => fromPattern(pattern);

  /// A matcher that accepts ASCII characters.
  factory CharMatcher.ascii() => const AsciiCharMatcher();

  /// A matcher that accepts letters.
  factory CharMatcher.letter() => const LetterCharMatcher();

  /// A matcher that accepts upper-case letters.
  factory CharMatcher.upperCaseLetter() => const UpperCaseLetterCharMatcher();

  /// A matcher that accepts lower-case letters.
  factory CharMatcher.lowerCaseLetter() => const LowerCaseLetterCharMatcher();

  /// A matcher that accepts letters or digits.
  factory CharMatcher.letterOrDigit() => const LetterOrDigitCharMatcher();

  /// A matcher that accepts digits.
  factory CharMatcher.digit() => const DigitCharMatcher();

  /// A matcher that accepts whitespaces.
  factory CharMatcher.whitespace() => const WhitespaceCharMatcher();

  /// Internal constructor.
  const CharMatcher();

  /// Returns a matcher that matches any character not matched by this matcher.
  CharMatcher operator ~() => NegateCharMatcher(this);

  /// Returns a matcher that matches any character matched by either this
  /// matcher or [other].
  CharMatcher operator |(CharMatcher other) {
    if (other is AnyCharMatcher) {
      return other;
    } else if (other is NoneCharMatcher) {
      return this;
    } else if (other is DisjunctiveCharMatcher) {
      return DisjunctiveCharMatcher([this, ...other.matchers]);
    } else {
      return DisjunctiveCharMatcher([this, other]);
    }
  }

  /// Determines if the given character code belongs to the character class.
  bool match(int value);

  /// Returns `true` if the [sequence] contains only matching characters.
  bool everyOf(String sequence) => sequence.codeUnits.every(match);

  /// Returns `true` if the [sequence] contains at least one matching character.
  bool anyOf(String sequence) => sequence.codeUnits.any(match);

  /// Returns the last matching index in [sequence] starting at [start]
  /// (inclusive). Returns `-1` if it could not be found.
  int firstIndexIn(String sequence, [int start = 0]) {
    final codeUnits = sequence.codeUnits;
    for (var i = start; i < codeUnits.length; i++) {
      if (match(codeUnits[i])) {
        return i;
      }
    }
    return -1;
  }

  /// Returns the first matching index in [sequence], searching backward
  /// starting at [start] (inclusive). Returns `-1` if it could not be found.
  int lastIndexIn(String sequence, [int start]) {
    final codeUnits = sequence.codeUnits;
    start ??= codeUnits.length - 1;
    for (var i = start; i >= 0; i--) {
      if (match(codeUnits[i])) {
        return i;
      }
    }
    return -1;
  }

  /// Counts the number of matches in [sequence].
  int countIn(String sequence) => sequence.codeUnits.where(match).length;

  /// Replaces each group of consecutive matched characters in [sequence]
  /// with the specified [replacement].
  String collapseFrom(String sequence, String replacement) {
    var i = 0;
    final list = <int>[];
    final codeUnits = sequence.codeUnits;
    final replacementCodes = replacement.codeUnits;
    while (i < codeUnits.length) {
      final codeUnit = codeUnits[i];
      if (match(codeUnit)) {
        do {
          i++;
          // ignore: invariant_booleans
        } while (i < codeUnits.length && match(codeUnits[i]));
        list.addAll(replacementCodes);
      } else {
        list.add(codeUnit);
        i++;
      }
    }
    return String.fromCharCodes(list);
  }

  /// Replaces each matched character in [sequence] with the specified
  /// [replacement].
  String replaceFrom(String sequence, String replacement) {
    final replacementCodes = replacement.codeUnits;
    return String.fromCharCodes(sequence.codeUnits
        .expand((value) => match(value) ? replacementCodes : [value]));
  }

  /// Removes all matched characters in [sequence].
  String removeFrom(String sequence) => (~this).retainFrom(sequence);

  /// Retains all matched characters in [sequence].
  String retainFrom(String sequence) =>
      String.fromCharCodes(sequence.codeUnits.where(match));

  /// Removes leading and trailing matching characters in [sequence].
  String trimFrom(String sequence) {
    final codeUnits = sequence.codeUnits;
    var left = 0, right = codeUnits.length - 1;
    while (left <= right && match(codeUnits[left])) {
      left++;
    }
    while (left <= right && match(codeUnits[right])) {
      right--;
    }
    return sequence.substring(left, right + 1);
  }

  /// Removes leading matching characters in [sequence].
  String trimLeadingFrom(String sequence) {
    final codeUnits = sequence.codeUnits;
    var left = 0;
    final right = codeUnits.length - 1;
    while (left <= right && match(codeUnits[left])) {
      left++;
    }
    return sequence.substring(left, right + 1);
  }

  /// Removes tailing matching characters in [sequence].
  String trimTailingFrom(String sequence) {
    final codeUnits = sequence.codeUnits;
    var right = codeUnits.length - 1;
    while (0 <= right && match(codeUnits[right])) {
      right--;
    }
    return sequence.substring(0, right + 1);
  }
}

int _toCharCode(Object char) {
  if (char is num) {
    return char.round();
  }
  final value = '$char';
  if (value.length != 1) {
    throw ArgumentError('$value is not a character');
  }
  return value.codeUnitAt(0);
}
