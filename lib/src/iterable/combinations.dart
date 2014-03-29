part of iterable;

/**
 * Returns an iterable over the combinations of [elements].
 *
 * The resulting iterable is equivalent to nested for-loops. The rightmost elements
 * advance on every iteration. This pattern creates a lexicographic ordering so that
 * if the input’s iterables are sorted, the product is sorted as well.
 *
 * For example, the product of `['x', 'y']` and `[1, 2, 3]` is created with
 *
 *    product([['x', 'y'], [1, 2, 3]]);
 *
 * and results in an iterable with the following elements:
 *
 *    ['x', 1]
 *    ['x', 2]
 *    ['x', 3]
 *    ['y', 1]
 *    ['y', 2]
 *    ['y', 3]
 *
 */
Iterable/*<E>*/ combinations(Iterable/*<E>*/ elements, int count, {bool repetitions: false}) {
  return new _CombinationsIterable(elements.toList(growable: false), count, repetitions);
}

class _CombinationsIterable<E> extends IterableBase<List<E>> {

  final List<E> _elements;
  final int _count;
  final bool _repetitions;

  _CombinationsIterable(this._elements, this._count, this._repetitions);

  @override
  Iterator<List> get iterator {
    var state = _repetitions
        ? new List.filled(_count, 0)
        : new List.generate(_count, (i) => i, growable: false);
    return new _CombinationsIterator(_elements, state, _repetitions);
  }

}

class _CombinationsIterator<E> extends Iterator<List<E>> {

  final List<E> _elements;
  final List<int> _state;
  final bool _repetitions;

  List<E> _current = null;
  bool _completed = false;

  _CombinationsIterator(this._elements, this._state, this._repetitions);

  @override
  List<E> get current => _current;

  @override
  bool moveNext() {
    if (_completed) {
      return false;
    }
    if (_current == null) {
      _current = new List.generate(_state.length, (i) {
        return _elements[_state[i]];
      }, growable: false);
      return true;
    } else {
      for (var i = _state.length - 1; i >= 0; i--) {
        if (_state[i] < _state.length - 1) {
          _state[i]++;
          _current[i] = _elements[_state[i]];
          return true;
        } else {
          for (int j = _state.length - 1; j >= i; j--) {
            _state[j] = 0;
            _current[j] = _elements[_state[j]];
          }
        }
      }
    }
    _completed = true;
    _current = null;
    return false;
  }

}

/**
 * Combinations
 *
 * Return r length subsequences of elements from the input iterable.

Combinations are emitted in lexicographic sort order. So, if the input iterable is sorted, the combination tuples will be produced in sorted order.

Elements are treated as unique based on their position, not on their value. So if the input elements are unique, there will be no repeat values in each combination.

Equivalent to:

def combinations(iterable, r):
    # combinations('ABCD', 2) --> AB AC AD BC BD CD
    # combinations(range(4), 3) --> 012 013 023 123
    pool = tuple(iterable)
    n = len(pool)
    if r > n:
        return
    indices = range(r)
    yield tuple(pool[i] for i in indices)
    while True:
        for i in reversed(range(r)):
            if indices[i] != i + n - r:
                break
        else:
            return
        indices[i] += 1
        for j in range(i+1, r):
            indices[j] = indices[j-1] + 1
        yield tuple(pool[i] for i in indices)
The code for combinations() can be also expressed as a subsequence of permutations() after filtering entries where the elements are not in sorted order (according to their position in the input pool):

def combinations(iterable, r):
    pool = tuple(iterable)
    n = len(pool)
    for indices in permutations(range(n), r):
        if sorted(indices) == list(indices):
            yield tuple(pool[i] for i in indices)
The number of items returned is n! / r! / (n-r)! when 0 <= r <= n or zero when r > n.

combinations_with_replacement(iterable, r)
Return r length subsequences of elements from the input iterable allowing individual elements to be repeated more than once.

Combinations are emitted in lexicographic sort order. So, if the input iterable is sorted, the combination tuples will be produced in sorted order.

Elements are treated as unique based on their position, not on their value. So if the input elements are unique, the generated combinations will also be unique.

Equivalent to:

def combinations_with_replacement(iterable, r):
    # combinations_with_replacement('ABC', 2) --> AA AB AC BB BC CC
    pool = tuple(iterable)
    n = len(pool)
    if not n and r:
        return
    indices = [0] * r
    yield tuple(pool[i] for i in indices)
    while True:
        for i in reversed(range(r)):
            if indices[i] != n - 1:
                break
        else:
            return
        indices[i:] = [indices[i] + 1] * (r - i)
        yield tuple(pool[i] for i in indices)
The code for combinations_with_replacement() can be also expressed as a subsequence of product() after filtering entries where the elements are not in sorted order (according to their position in the input pool):

def combinations_with_replacement(iterable, r):
    pool = tuple(iterable)
    n = len(pool)
    for indices in product(range(n), repeat=r):
        if sorted(indices) == list(indices):
            yield tuple(pool[i] for i in indices)
The number of items returned is (n+r-1)! / r! / (n-1)! when n > 0.

New in version 2.7.
 */
