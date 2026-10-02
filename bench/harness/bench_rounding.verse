using { FastMath }

# No value beyond 2^63: the native Floor, Ceil, Round and Int raise a runtime error there.
RoundingTestFloats:[]float = (for (I := -4000..4000) do I * 0.25) + array{
    0.49999999999999994, -0.49999999999999994, 1.0e-300, -1.0e-300, -0.0,
    2251799813685247.5, -2251799813685247.5, 4503599627370497.0, -4503599627370497.0,
    9.2e18, -9.2e18, Inf, -Inf, NaN}

CheckRounding<public>()<transacts>:[]accuracy_report =
    FloorReport := accuracy_report{Name := "Floor"}
    CeilReport := accuracy_report{Name := "Ceil"}
    RoundReport := accuracy_report{Name := "Round"}
    IntReport := accuracy_report{Name := "Int"}
    for (X : RoundingTestFloats):
        Input := "{X}"
        FloorReport.AddTripleResult(Input, IntResult(option{Floor[X]}), IntResult(option{FastFloor[X]}))
        CeilReport.AddTripleResult(Input, IntResult(option{Ceil[X]}), IntResult(option{FastCeil[X]}))
        RoundReport.AddTripleResult(Input, IntResult(option{Round[X]}), IntResult(option{FastRound[X]}))
        IntReport.AddTripleResult(Input, IntResult(option{Int[X]}), IntResult(option{FastInt[X]}))
    array{FloorReport, CeilReport, RoundReport, IntReport}

BenchRounding<public>(Floats:[]float)<transacts>:float =
    var Acc:int = 0
    profile("Native Floor"):
        for (X : Floats, V := Floor[X]):
            set Acc += V
    profile("Fast Floor"):
        for (X : Floats, V := FastFloor[X]):
            set Acc += V
    profile("Native Round"):
        for (X : Floats, V := Round[X]):
            set Acc += V
    profile("Fast Round"):
        for (X : Floats, V := FastRound[X]):
            set Acc += V
    Acc * 1.0

# Exact integer up to 2^53, compared as a triple of floats.
IntResult(X:?int)<computes>:?triple = option{(X? * 1.0, 0.0, 0.0)}
