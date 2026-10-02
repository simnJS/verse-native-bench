using { /UnrealEngine.com/Temporary/SpatialMath }

Epsilon:float = 2.220446049250313e-16
SmallestNormal:float = 2.2250738585072014e-308
SmallestSubnormal:float = 4.9406564584124654e-324
BigStep:float = 18446744073709551616.0
InvBigStep:float = 5.421010862427522e-20

triple<public> := tuple(float, float, float)

Triple<public>(V:vector3)<computes>:triple = (V.X, V.Y, V.Z)

Triple<public>(V:vector2)<computes>:triple = (V.X, V.Y, 0.0)

IsFiniteTriple(T:triple)<computes><decides>:void =
    T(0).IsFinite[]
    T(1).IsFinite[]
    T(2).IsFinite[]

# Gap between the native and the rewrite, in ulps of the native.
accuracy_report<public> := class:
    Name<public>:string
    var Samples<public>:int = 0
    var MaxUlps<public>:float = 0.0
    var WorstInput<public>:string = ""
    var Mismatches<public>:int = 0
    var FirstMismatch<public>:string = ""

    AddFloat<public>(Input:string, Native:float, Fast:float)<transacts>:void =
        set Samples += 1
        if (ZeroSign(Native) <> ZeroSign(Fast)):
            Mismatch(Input)
        else if (Native.IsFinite[], Fast.IsFinite[]):
            Track(Input, Abs(Native - Fast) / UlpOf(Native))
        else if (not (Native = Fast)):
            Mismatch(Input)

    # For a vector, the gap is measured in ulps of its largest component.
    AddTriple<public>(Input:string, Native:triple, Fast:triple)<transacts>:void =
        set Samples += 1
        if (ZeroSign(Native(0)) <> ZeroSign(Fast(0)) or ZeroSign(Native(1)) <> ZeroSign(Fast(1)) or ZeroSign(Native(2)) <> ZeroSign(Fast(2))):
            Mismatch(Input)
        else if (IsFiniteTriple[Native], IsFiniteTriple[Fast]):
            Diff := Max(Abs(Native(0) - Fast(0)), Max(Abs(Native(1) - Fast(1)), Abs(Native(2) - Fast(2))))
            Size := Max(Abs(Native(0)), Max(Abs(Native(1)), Abs(Native(2))))
            Track(Input, Diff / UlpOf(Size))
        else if (not (Native(0) = Fast(0) and Native(1) = Fast(1) and Native(2) = Fast(2))):
            Mismatch(Input)

    # For <decides> functions: both must succeed or fail together.
    AddTripleResult<public>(Input:string, Native:?triple, Fast:?triple)<transacts>:void =
        if (N := Native?, F := Fast?):
            AddTriple(Input, N, F)
        else:
            set Samples += 1
            if (Native? or Fast?):
                Mismatch(Input)

    # For results without a numeric gap (arrays, strings): identical or divergent.
    AddMatch<public>(Input:string, Matches:logic)<transacts>:void =
        set Samples += 1
        if (not Matches?):
            Mismatch(Input)

    AddVector<public>(Input:string, Native:vector3, Fast:vector3)<transacts>:void =
        AddTriple(Input, Triple(Native), Triple(Fast))

    AddVectorResult<public>(Input:string, Native:?vector3, Fast:?vector3)<transacts>:void =
        AddTripleResult(Input, option{Triple(Native?)}, option{Triple(Fast?)})

    AddVector<public>(Input:string, Native:vector2, Fast:vector2)<transacts>:void =
        AddTriple(Input, Triple(Native), Triple(Fast))

    AddVector2Result<public>(Input:string, Native:?vector2, Fast:?vector2)<transacts>:void =
        AddTripleResult(Input, option{Triple(Native?)}, option{Triple(Fast?)})

    Summary<public>()<reads>:string =
        Worst := if (MaxUlps > 0.0) then ", worst input {WorstInput}" else ""
        Divergences := if (Mismatches > 0) then ", {Mismatches} divergence(s), e.g. {FirstMismatch}" else ", no divergence"
        "{Name}: {Samples} inputs, max gap {FormatSci(MaxUlps)} ulp{Worst}{Divergences}"

    Track<private>(Input:string, Ulps:float)<transacts>:void =
        if (Ulps > MaxUlps):
            set MaxUlps = Ulps
            set WorstInput = Input

    Mismatch<private>(Input:string)<transacts>:void =
        if (Mismatches = 0):
            set FirstMismatch = Input
        set Mismatches += 1

# -1 for -0.0, 1 otherwise. The BPVM keeps -0.0 but = does not tell it from 0.0: only a native reveals it.
ZeroSign<public>(X:float)<reads>:int =
    if (X = 0.0, ArcTan(X, -1.0) < 0.0) then -1 else 1

UlpOf<public>(X:float)<computes>:float =
    A := Abs(X)
    if (not (A < Inf)) then A
    else if (A < SmallestNormal) then SmallestSubnormal
    else PowerOfTwoFloor(A, 1.0) * Epsilon

PowerOfTwoFloor(A:float, P:float)<computes>:float =
    if (P * BigStep <= A) then PowerOfTwoFloor(A, P * BigStep)
    else if (P * 2.0 <= A) then PowerOfTwoFloor(A, P * 2.0)
    else if (P * InvBigStep > A) then PowerOfTwoFloor(A, P * InvBigStep)
    else if (P > A) then PowerOfTwoFloor(A, P * 0.5)
    else P

# Print only shows 6 fixed decimals: 1.0e-12 would come out as "0.000000".
FormatSci<public>(X:float)<reads>:string =
    if (X = NaN) then "NaN"
    else if (X = Inf) then "+Inf"
    else if (X = -Inf) then "-Inf"
    else if (X = 0.0) then "0"
    else if (X < 0.0) then "-{FormatSci(-X)}"
    else FormatMantissa(X, 0)

FormatMantissa(M:float, Exponent:int)<reads>:string =
    if (M >= 1.0e10) then FormatMantissa(M * 1.0e-10, Exponent + 10)
    else if (M >= 10.0) then FormatMantissa(M * 0.1, Exponent + 1)
    else if (M < 1.0e-10) then FormatMantissa(M * 1.0e10, Exponent - 10)
    else if (M < 1.0) then FormatMantissa(M * 10.0, Exponent - 1)
    else "{M}e{Exponent}"
