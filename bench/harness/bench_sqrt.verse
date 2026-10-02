using { FastMath }

CheckSqrt<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Sqrt"}
    for (X : SqrtInputs()):
        Report.AddFloat(FormatSci(X), Sqrt(X), FastSqrt(X))
    Report

BenchSqrt<public>(N:int)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Sqrt"):
        for (I := 1..N):
            set Acc += Sqrt(I * 1.0)
    profile("Fast Sqrt"):
        for (I := 1..N):
            set Acc += FastSqrt(I * 1.0)
    Acc

SqrtInputs()<reads>:[]float =
    Linear := for (I := 0..2000) do I * 0.05
    HalfDecades := for (I := -600..600) do Pow(10.0, I * 0.5)
    Linear + HalfDecades + SqrtEdgeCases

SqrtEdgeCases:[]float = array{-0.0, 2.0, -1.0, 1.0e-310, 4.9406564584124654e-324, 1.7976931348623157e308, Inf, -Inf, NaN}
