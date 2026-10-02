FastMath<public> := module:

    Two32:float = 4294967296.0
    Two64:float = 18446744073709551616.0
    InvTwo32:float = 2.3283064365386963e-10
    InvTwo64:float = 5.421010862427522e-20
    Inv256:float = 0.00390625

    FastSqrt<public>(X:float)<computes>:float =
        if (X > 0.0, X < Inf) then ScaledSqrt(X, 1.0)
        else if (X < 0.0) then NaN
        else if (X = 0.0) then 0.0 # the native returns +0.0 even for -0.0
        else X

    # Sqrt(M) * Scale, with M brought into [0.25, 1) by exact powers of 4.
    ScaledSqrt(M:float, Scale:float)<computes>:float =
        if (M >= Two64) then ScaledSqrt(M * InvTwo64, Scale * Two32)
        else if (M >= 256.0) then ScaledSqrt(M * Inv256, Scale * 16.0)
        else if (M >= 1.0) then ScaledSqrt(M * 0.25, Scale * 2.0)
        else if (M >= 0.25) then Scale * UnitSqrt(M)
        else if (M >= Inv256) then ScaledSqrt(M * 4.0, Scale * 0.5)
        else if (M >= InvTwo64) then ScaledSqrt(M * 256.0, Scale * 0.0625)
        else ScaledSqrt(M * Two64, Scale * InvTwo32)

    # The native's Min(Max(Val, Lo), Hi) without its four calls: same NaN handling, same sign of zero.
    FastClamp<public>(Val:float, A:float, B:float)<computes>:float =
        Lo := if (A <= B or A = NaN) then A else B
        Hi := if (A > B or A = NaN) then A else B
        Low := if (Val > Lo or Val = NaN) then Val else Lo
        if (Low <= Hi or Low = NaN) then Low else Hi

    # Same logic as (X <= Y) or (X = NaN) or Y, written with if.
    FastMin<public>(X:float, Y:float)<computes>:float =
        if (X <= Y or X = NaN) then X else Y

    FastMax<public>(X:float, Y:float)<computes>:float =
        if (X > Y or X = NaN) then X else Y

    FastSgn<public>(Val:float)<computes>:float =
        if (Val > 0.0) then 1.0
        else if (Val < 0.0) then -1.0
        else if (Val = 0.0) then 0.0
        else NaN

    FastAbs<public>(X:float)<computes>:float =
        if (X < 0.0) then -X
        else if (X = 0.0) then 0.0 # the native returns +0.0 even for -0.0
        else X

    FastAbs<public>(X:int)<computes>:int = if (X < 0) then -X else X

    FastMin<public>(X:int, Y:int)<computes>:int = if (X < Y) then X else Y

    FastMax<public>(X:int, Y:int)<computes>:int = if (X > Y) then X else Y

    FastClamp<public>(Val:int, A:int, B:int)<computes>:int =
        Lo := if (A < B) then A else B
        Hi := if (A > B) then A else B
        if (Val < Lo) then Lo else if (Val > Hi) then Hi else Val

    # Same formula as the native: From * (1 - Parameter) + To * Parameter.
    FastLerp<public>(From:float, To:float, Parameter:float)<computes>:float =
        From * (1.0 - Parameter) + To * Parameter

    # Euclidean division through the exact rational quotient X / Y, which fails when Y = 0.
    FastQuotient<public>(X:int, Y:int)<computes><decides>:int =
        Q := X / Y
        if (Y > 0) then Floor(Q) else Ceil(Q)

    FastMod<public>(X:int, Y:int)<computes><decides>:int =
        X - FastQuotient[X, Y] * Y

    # Floor, Ceil, Round and Int without the native conversion: round as a float, then rebuild the int bit by bit.
    FastFloor<public>(X:float)<computes><decides>:int =
        Abs(X) < Inf
        R := RoundHalfEven(X)
        IntOf(if (R > X) then R - 1.0 else R)

    FastCeil<public>(X:float)<computes><decides>:int =
        Abs(X) < Inf
        R := RoundHalfEven(X)
        IntOf(if (R < X) then R + 1.0 else R)

    FastRound<public>(X:float)<computes><decides>:int =
        Abs(X) < Inf
        IntOf(RoundHalfEven(X))

    FastInt<public>(X:float)<computes><decides>:int =
        if (X >= 0.0) then FastFloor[X] else FastCeil[X]

    DigitStrings:[]string = array{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}

    FastToString<public>(X:int)<computes>:string =
        if (X < 0) then "-" + Digits(-X) else Digits(X)

    Digits(X:int)<computes>:string =
        if (Tens := X / 10, Rest := Floor(Tens), Last := DigitStrings[X - Rest * 10]):
            if (Rest > 0) then Digits(Rest) + Last else Last
        else ""

    TwoPow52:float = 4503599627370496.0

    # Adding then subtracting 2^52 rounds to the nearest integer (ties to even): exact for |X| < 2^52.
    RoundHalfEven(X:float)<computes>:float =
        if (X >= TwoPow52 or X <= -TwoPow52) then X
        else if (X >= 0.0) then (X + TwoPow52) - TwoPow52
        else (X - TwoPow52) + TwoPow52

    # X must already be integral.
    IntOf(X:float)<computes>:int =
        if (X < 0.0) then -NaturalOf(-X) else NaturalOf(X)

    NaturalOf(X:float)<computes>:int =
        if (X < 1.0):
            0
        else:
            H := X * 0.5
            R := RoundHalfEven(H)
            Half := if (R > H) then R - 1.0 else R
            2 * NaturalOf(Half) + (if (X > 2.0 * Half) then 1 else 0)

    UnitSqrt(M:float)<computes>:float =
        Y0 := 0.2592823740821695 + M * (1.0519971182683654 - 0.31630152119720517 * M)
        Y1 := 0.5 * (Y0 + M / Y0)
        Y2 := 0.5 * (Y1 + M / Y1)
        0.5 * (Y2 + M / Y2)
