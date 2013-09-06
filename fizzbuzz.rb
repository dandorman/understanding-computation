Z = -> f { -> x { f[-> y { x[x][y] }] }[-> x { f[-> y { x[x][y] }] }] }

ZERO  = -> p { -> x {       x    } }
ONE   = -> p { -> x {     p[x]   } }
TWO   = -> p { -> x {   p[p[x]]  } }
THREE = -> p { -> x { p[p[p[x]]] } }
FIVE  = -> p { -> x { p[p[p[p[p[x]]]]] } }
FIFTEEN = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]] } }
HUNDRED = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]] } }

IS_ZERO = -> n { n[-> x { FALSE }][TRUE] }

INCREMENT = -> n { -> p { -> x { p[n[p][x]] } } }
SLIDE = -> p { PAIR[RIGHT[p]][INCREMENT[RIGHT[p]]] }
DECREMENT = -> n { LEFT[n[SLIDE][PAIR[ZERO][ZERO]]] }

ADD      = -> m { -> n { n[INCREMENT][m] } }
SUBTRACT = -> m { -> n { n[DECREMENT][m] } }
MULTIPLY = -> m { -> n { n[ADD[m]][ZERO] } }
POWER    = -> m { -> n { n[MULTIPLY[m]][ONE] } }

TRUE  = -> x { -> y { x } }
FALSE = -> x { -> y { y } }
IF    = -> b { b }

PAIR  = -> x { -> y { -> f { f[x][y] } } }
LEFT  = -> p { p[-> x { -> y { x } }] }
RIGHT = -> p { p[-> x { -> y { y } }] }

EMPTY    = PAIR[TRUE][TRUE]
UNSHIFT  = -> l { -> x { PAIR[FALSE][PAIR[x][l]] } }
IS_EMPTY = LEFT
FIRST    = -> l { LEFT[RIGHT[l]] }
REST     = -> l { RIGHT[RIGHT[l]] }

RANGE = Z[-> f {
  -> m { -> n {
    IF[IS_LESS_OR_EQUAL[m][n]][
      -> x {
        UNSHIFT[f[INCREMENT[m]][n]][m][x]
      }
    ][
      EMPTY
    ]
  } }
}]

FOLD = Z[-> f {
  -> l {
    -> x {
      -> g {
        IF[IS_EMPTY[l]][
          x
        ][
          -> y {
            g[f[REST[l]][x][g]][FIRST[l]][y]
          }
        ]
      }
    }
  }
}]

MAP = -> k {
  -> f {
    FOLD[k][EMPTY][
      -> l { -> x { UNSHIFT[l][f[x]] } }
    ]
  }
}

IS_LESS_OR_EQUAL = -> m { -> n { IS_ZERO[SUBTRACT[m][n]] } }

MOD = Z[-> f {
  -> m { -> n {
    IF[IS_LESS_OR_EQUAL[n][m]][
      -> x {
        f[SUBTRACT[m][n]][n][x]
      }
    ][
      m
    ]
  } }
}]

TEN = MULTIPLY[TWO][FIVE]
B   = TEN
F   = INCREMENT[B]
I   = INCREMENT[F]
U   = INCREMENT[I]
ZED = INCREMENT[U]

FIZZ     = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][I]][F]
BUZZ     = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[EMPTY][ZED]][ZED]][U]][B]
FIZZBUZZ = UNSHIFT[UNSHIFT[UNSHIFT[UNSHIFT[BUZZ][ZED]][ZED]][I]][F]

DIV = Z[-> f {
  -> m {
    -> n {
      IF[IS_LESS_OR_EQUAL[n][m]][
        -> x {
          INCREMENT[f[SUBTRACT[m][n]][n]][x]
        }
      ][
        ZERO
      ]
    }
  }
}]

PUSH = -> l { -> x { FOLD[l][UNSHIFT[EMPTY][x]][UNSHIFT] } }

TO_DIGITS = Z[-> f {
  -> n {
    PUSH[
      IF[IS_LESS_OR_EQUAL[n][DECREMENT[TEN]]][
        EMPTY
      ][
        -> x {
          f[DIV[n][TEN]][x]
        }
      ]
    ][MOD[n][TEN]]
  }
}]

ZEROS = Z[-> f { UNSHIFT[f][ZERO] }]
UPWARDS_OF = Z[-> f {
  -> n {
    UNSHIFT[-> x { f[INCREMENT[n]][x] }][n]
  }
}]
MULTIPLES_OF = -> m {
  Z[-> f {
    -> n { UNSHIFT[-> x { f[ADD[m][n]][x] }][n] }
  }][m]
}

MULTIPLY_STREAMS = Z[-> f {
  -> k { -> l {
    UNSHIFT[-> x { f[REST[k]][REST[l]][x] }][MULTIPLY[FIRST[k]][FIRST[l]]]
  } }
}]

def to_integer(proc)
  proc[-> n { n + 1 }][0]
end

def to_boolean(proc)
  IF[proc][true][false]
end

def to_array(l, count = nil)
  array = []

  until to_boolean(IS_EMPTY[l]) || count == 0
    array.push(FIRST[l])
    l = REST[l]
    count = count - 1 unless count.nil?
  end

  array
end

def to_char(c)
  "0123456789BFiuz".slice(to_integer(c))
end

def to_string(s)
  to_array(s).map { |c| to_char(c) }.join
end

__END__
solution = MAP[RANGE[ONE][HUNDRED]][-> n {
  IF[IS_ZERO[MOD[n][FIFTEEN]]][
    FIZZBUZZ
  ][IF[IS_ZERO[MOD[n][THREE]]][
    FIZZ
  ][IF[IS_ZERO[MOD[n][FIVE]]][
    BUZZ
  ][
    TO_DIGITS[n]
  ]]]
}]

to_array(solution).each do |p|
  puts to_string(p)
end
