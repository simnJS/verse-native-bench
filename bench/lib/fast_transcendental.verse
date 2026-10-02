# Ports of the fdlibm kernels behind glibc, which the Verse natives call.
FastTranscendental<public> := module:

    Pi:float = 3.14159265358979311600
    HalfPi:float = 1.57079632679489655800
    QuarterPi:float = 7.85398163397448278999e-01
    ThreeQuarterPi:float = 2.35619449019234483700
    Ln2:float = 6.93147180559945286227e-01

    # Cody-Waite splits: N * Hi is exact, Lo carries the remaining bits.
    TwoOverPi:float = 6.36619772367581382433e-01
    HalfPiHi:float = 1.57079632673412561417
    HalfPiLo:float = 6.07710050650619224932e-11
    PiLo:float = 1.22464679914735317720e-16
    InvLn2:float = 1.44269504088896338700
    Ln2Hi:float = 6.93147180369123816490e-01
    Ln2Lo:float = 1.90821492927058770002e-10

    # Adding then subtracting 1.5 * 2^52 rounds to the nearest integer (ties to even) for |X| < 2^51.
    RoundingShift:float = 6755399441055744.0
    Sqrt2:float = 1.41421356237309504880
    HalfSqrt2:float = 0.70710678118654752440
    Two28:float = 268435456.0
    InvTwo28:float = 3.7252902984619140625e-09
    Two64:float = 18446744073709551616.0
    InvTwo64:float = 5.421010862427522e-20

    # Beyond this, two-term reduction by Pi/2 drifts; the native handles huge angles.
    MaxReducibleAngle:float = 1.0e5
    ExpOverflow:float = 7.09782712893383973096e+02
    ExpUnderflow:float = -7.45133219101941108420e+02

    RoundToNearest(X:float)<computes>:float = (X + RoundingShift) - RoundingShift

    # K mod M for an integral K, as a float in [0, M).
    Remainder(K:float, M:float)<computes>:float = K - M * RoundToNearest(K / M - (0.5 - 0.5 / M))

    FastSin<public>(X:float)<reads>:float =
        if (X = 0.0):
            X
        else if (Abs(X) <= MaxReducibleAngle):
            N := RoundToNearest(X * TwoOverPi)
            R := ReduceByHalfPi(X, N)
            Quadrant := Remainder(N, 4.0)
            if (Quadrant = 0.0) then SinKernel(R)
            else if (Quadrant = 1.0) then CosKernel(R)
            else if (Quadrant = 2.0) then -SinKernel(R)
            else -CosKernel(R)
        else:
            Sin(X)

    FastCos<public>(X:float)<reads>:float =
        if (Abs(X) <= MaxReducibleAngle):
            N := RoundToNearest(X * TwoOverPi)
            R := ReduceByHalfPi(X, N)
            Quadrant := Remainder(N, 4.0)
            if (Quadrant = 0.0) then CosKernel(R)
            else if (Quadrant = 1.0) then -SinKernel(R)
            else if (Quadrant = 2.0) then -CosKernel(R)
            else SinKernel(R)
        else:
            Cos(X)

    # The native extensionalizes its argument first, so -0.0 gives +0.0 (unlike Sin).
    FastTan<public>(X:float)<reads>:float =
        if (X = 0.0):
            0.0
        else if (Abs(X) <= MaxReducibleAngle):
            N := RoundToNearest(X * TwoOverPi)
            R := ReduceByHalfPi(X, N)
            if (Remainder(N, 2.0) = 0.0) then SinKernel(R) / CosKernel(R) else -CosKernel(R) / SinKernel(R)
        else:
            Tan(X)

    ReduceByHalfPi(X:float, N:float)<computes>:float =
        (X - N * HalfPiHi) - N * HalfPiLo

    # Sin and Cos on [-Pi/4, Pi/4].
    SinKernel(X:float)<computes>:float =
        Z := X * X
        R := 8.33333333332248946124e-03 + Z * (-1.98412698298579493134e-04 + Z * (2.75573137070700676789e-06 + Z * (-2.50507602534068634195e-08 + Z * 1.58969099521155010221e-10)))
        X + Z * X * (-1.66666666666666324348e-01 + Z * R)

    CosKernel(X:float)<computes>:float =
        Z := X * X
        R := Z * (4.16666666666666019037e-02 + Z * (-1.38888888888741095749e-03 + Z * (2.48015872894767294178e-05 + Z * (-2.75573143513906633035e-07 + Z * (2.08757232129817482790e-09 + Z * -1.13596475577881948265e-11)))))
        HalfZ := 0.5 * Z
        W := 1.0 - HalfZ
        W + (((1.0 - W) - HalfZ) + Z * R)

    FastExp<public>(X:float)<computes>:float =
        if (X > ExpOverflow):
            Inf
        else if (X >= ExpUnderflow):
            K := RoundToNearest(X * InvLn2)
            Hi := X - K * Ln2Hi
            Lo := K * Ln2Lo
            R := Hi - Lo
            Z := R * R
            C := R - Z * (1.66666666666666019037e-01 + Z * (-2.77777777770155933842e-03 + Z * (6.61375632143793436117e-05 + Z * (-1.65339022054652515390e-06 + Z * 4.13813679705723846039e-08))))
            Y := 1.0 - ((Lo - (R * C) / (2.0 - C)) - Hi)
            if (K > 1023.0) then 2.0 * Y * PowerOfTwo(K - 1.0) else Y * PowerOfTwo(K)
        else if (X < ExpUnderflow):
            0.0
        else:
            X

    # 2^K for an integral K, exact over the whole double range including subnormals.
    PowerOfTwo(K:float)<computes>:float =
        if (K >= 64.0) then Two64 * PowerOfTwo(K - 64.0)
        else if (K <= -64.0) then InvTwo64 * PowerOfTwo(K + 64.0)
        else if (K >= 8.0) then 256.0 * PowerOfTwo(K - 8.0)
        else if (K <= -8.0) then 0.00390625 * PowerOfTwo(K + 8.0)
        else if (K > 0.0) then 2.0 * PowerOfTwo(K - 1.0)
        else if (K < 0.0) then 0.5 * PowerOfTwo(K + 1.0)
        else 1.0

    FastLn<public>(X:float)<computes>:float =
        if (X > 0.0, X < Inf):
            Normalized := Normalize(X, 0.0)
            LnOfNormalized(Normalized(0), Normalized(1))
        else if (X = 0.0):
            -Inf
        else if (X < 0.0):
            NaN
        else:
            X

    # X = M * 2^K with Sqrt(0.5) <= M < Sqrt(2); the factors are exact powers of two.
    Normalize(M:float, K:float)<computes>:tuple(float, float) =
        if (M >= Two64) then Normalize(M * InvTwo64, K + 64.0)
        else if (M >= 256.0) then Normalize(M * 0.00390625, K + 8.0)
        else if (M >= Sqrt2) then Normalize(M * 0.5, K + 1.0)
        else if (M < InvTwo64) then Normalize(M * Two64, K - 64.0)
        else if (M < 0.00390625) then Normalize(M * 256.0, K - 8.0)
        else if (M < HalfSqrt2) then Normalize(M * 2.0, K - 1.0)
        else (M, K)

    LnOfNormalized(M:float, K:float)<computes>:float =
        F := M - 1.0
        S := F / (2.0 + F)
        Z := S * S
        W := Z * Z
        Odd := W * (3.999999999940941908e-01 + W * (2.222219843214978396e-01 + W * 1.531383769920937332e-01))
        Even := Z * (6.666666666666735130e-01 + W * (2.857142874366239149e-01 + W * (1.818357216161805012e-01 + W * 1.479819860511658591e-01)))
        HalfFSquared := 0.5 * F * F
        K * Ln2Hi - ((HalfFSquared - (S * (HalfFSquared + Even + Odd) + K * Ln2Lo)) - F)

    # Ln(1 + X) and Exp(X) - 1 without cancellation near 0 (Goldberg's and Kahan's corrections).
    LnOnePlus(X:float)<computes>:float =
        U := 1.0 + X
        if (U = 1.0) then X else FastLn(U) * X / (U - 1.0)

    ExpMinusOne(X:float)<computes>:float =
        U := FastExp(X)
        if (U = 1.0) then X
        else if (U = Inf) then U
        else if (U - 1.0 = -1.0) then -1.0
        else (U - 1.0) * X / FastLn(U)

    FastArcTan<public>(X:float)<reads>:float =
        A := Abs(X)
        Magnitude :=
            if (A < 0.4375) then A - A * ArcTanSeries(A)
            else if (A < 0.6875) then ArcTanAround(4.63647609000806093515e-01, 2.26987774529616870924e-17, (2.0 * A - 1.0) / (2.0 + A))
            else if (A < 1.1875) then ArcTanAround(QuarterPi, 3.06161699786838301793e-17, (A - 1.0) / (A + 1.0))
            else if (A < 2.4375) then ArcTanAround(9.82793723247329054082e-01, 1.39033110312309984516e-17, (A - 1.5) / (1.0 + 1.5 * A))
            else if (A < Inf) then ArcTanAround(HalfPi, 6.12323399573676603587e-17, -1.0 / A)
            else if (A = Inf) then HalfPi
            else A
        WithSignOf(Magnitude, X)

    ArcTanAround(Hi:float, Lo:float, T:float)<computes>:float =
        Hi - ((T * ArcTanSeries(T) - Lo) - T)

    ArcTanSeries(T:float)<computes>:float =
        Z := T * T
        W := Z * Z
        Odd := Z * (3.33333333333329318027e-01 + W * (1.42857142725034663711e-01 + W * (9.09088713343650656196e-02 + W * (6.66107313738753120669e-02 + W * (4.97687799461593236017e-02 + W * 1.62858201153657823623e-02)))))
        Even := W * (-1.99999999998764832476e-01 + W * (-1.11111104054623557880e-01 + W * (-7.69187620504482999495e-02 + W * (-5.83357013379057348645e-02 + W * -3.65315727442169155270e-02))))
        Odd + Even

    # Same contract as the native: ArcTan(0.0, 0.0) = 0.0.
    FastArcTan2<public>(Y:float, X:float)<reads>:float =
        if (Y = NaN or X = NaN):
            NaN
        else if (Y = 0.0, X = 0.0):
            0.0
        else if (Abs(Y) = Inf):
            Angle := if (X = Inf) then QuarterPi else if (X = -Inf) then ThreeQuarterPi else HalfPi
            WithSignOf(Angle, Y)
        else if (X = Inf):
            WithSignOf(0.0, Y)
        else if (X = -Inf):
            WithSignOf(Pi, Y)
        else if (X = 0.0):
            WithSignOf(HalfPi, Y)
        else:
            Z := FastArcTan(Abs(Y / X))
            WithSignOf((if (X > 0.0) then Z else Pi - (Z - PiLo)), Y)

    WithSignOf(Magnitude:float, S:float)<reads>:float =
        if (HasNegativeSign[S]) then -Magnitude else Magnitude

    # Verse arithmetic and comparisons do not see the sign of zero, but natives receive it intact
    # (the BPVM keeps -0.0), so the native is asked only in that rare case.
    HasNegativeSign(S:float)<reads><decides>:void =
        S < 0.0 or (S = 0.0 and ArcTan(S, -1.0) < 0.0)

    # The natives clamp to [-1, 1] first (NaN becomes 1.0), as FMath::Asin and FMath::Acos do.
    FastArcSin<public>(X:float)<reads>:float =
        C := ClampUnit(X)
        FastArcTan2(C, Sqrt((1.0 - C) * (1.0 + C)))

    FastArcCos<public>(X:float)<reads>:float =
        C := ClampUnit(X)
        FastArcTan2(Sqrt((1.0 - C) * (1.0 + C)), C)

    ClampUnit(X:float)<computes>:float =
        if (X < -1.0) then -1.0 else if (X < 1.0) then X else 1.0

    FastSinh<public>(X:float)<reads>:float =
        A := Abs(X)
        Magnitude :=
            if (A < 22.0) then SinhOfSmall(A)
            else if (A < ExpOverflow) then 0.5 * FastExp(A)
            else HalfSquaredExp(A)
        WithSignOf(Magnitude, X)

    SinhOfSmall(A:float)<computes>:float =
        E := ExpMinusOne(A)
        0.5 * (E + E / (E + 1.0))

    FastCosh<public>(X:float)<computes>:float =
        A := Abs(X)
        if (A < 0.34657359027997264):
            E := ExpMinusOne(A)
            1.0 + (E * E) / (2.0 * (1.0 + E))
        else if (A < ExpOverflow):
            E := FastExp(A)
            0.5 * E + 0.5 / E
        else:
            HalfSquaredExp(A)

    # 0.5 * Exp(A) for A near the overflow threshold, without overflowing early.
    HalfSquaredExp(A:float)<computes>:float =
        W := FastExp(0.5 * A)
        (0.5 * W) * W

    FastTanh<public>(X:float)<reads>:float =
        A := Abs(X)
        Magnitude :=
            if (A >= 22.0) then 1.0
            else if (A >= 1.0) then 1.0 - 2.0 / (ExpMinusOne(2.0 * A) + 2.0)
            else if (A > 0.0) then TanhOfSmall(ExpMinusOne(-2.0 * A))
            else A
        WithSignOf(Magnitude, X)

    TanhOfSmall(E:float)<computes>:float =
        -E / (E + 2.0)

    FastArSinh<public>(X:float)<reads>:float =
        A := Abs(X)
        Magnitude :=
            if (A < InvTwo28) then A
            else if (A <= 2.0) then LnOnePlus(A + A * A / (1.0 + Sqrt(1.0 + A * A)))
            else if (A <= Two28) then FastLn(2.0 * A + 1.0 / (Sqrt(A * A + 1.0) + A))
            else FastLn(A) + Ln2
        WithSignOf(Magnitude, X)

    FastArCosh<public>(X:float)<reads>:float =
        if (X > Two28):
            FastLn(X) + Ln2
        else if (X > 2.0):
            FastLn(2.0 * X - 1.0 / (X + Sqrt(X * X - 1.0)))
        else if (X >= 1.0):
            T := X - 1.0
            LnOnePlus(T + Sqrt(2.0 * T + T * T))
        else:
            NaN

    FastArTanh<public>(X:float)<reads>:float =
        A := Abs(X)
        Magnitude :=
            if (A < 0.5) then 0.5 * LnOnePlus(2.0 * A + 2.0 * A * A / (1.0 - A))
            else if (A < 1.0) then 0.5 * LnOnePlus(2.0 * A / (1.0 - A))
            else if (A = 1.0) then Inf
            else NaN
        WithSignOf(Magnitude, X)

    # Integer exponents (squares, cubes...) by repeated squaring, sign applied last since Verse
    # arithmetic does not keep -0.0 (an underflowed odd power or a -0.0 base would lose it).
    FastPowInt<public>(Base:float, Exponent:int)<reads>:float =
        Magnitude := PowerBySquaring(Abs(Base), Abs(Exponent), 1.0)
        Result := if (Exponent < 0) then 1.0 / Magnitude else Magnitude
        if (HasNegativeSign[Base], Mod[Exponent, 2] = 1) then -Result else Result

    PowerBySquaring(Base:float, Exponent:int, Result:float)<computes>:float =
        if (Exponent = 0) then Result
        else if (Mod[Exponent, 2] = 1) then PowerBySquaring(Base * Base, Quotient[Exponent, 2] or 0, Result * Base)
        else PowerBySquaring(Base * Base, Quotient[Exponent, 2] or 0, Result)
