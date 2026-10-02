using { FastMath }

CheckAbsLerp<public>()<transacts>:[]accuracy_report =
    AbsReport := accuracy_report{Name := "Abs (float)"}
    LerpReport := accuracy_report{Name := "Lerp (float)"}
    Parameters := array{0.0, 0.3, 0.5, 1.0, -0.5, 2.0}
    for (X : TestFloats):
        AbsReport.AddFloat("{X}", Abs(X), FastAbs(X))
        for (Y : TestFloats, T : Parameters):
            LerpReport.AddFloat("From={X} To={Y} T={T}", Lerp(X, Y, T), FastLerp(X, Y, T))
    array{AbsReport, LerpReport}

BenchAbsLerp<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Abs"):
        for (X : Floats):
            set Acc += Abs(X)
    profile("Fast Abs"):
        for (X : Floats):
            set Acc += FastAbs(X)
    profile("Native Lerp (float)"):
        for (X : Floats):
            set Acc += Lerp(X, 25.0, 0.3)
    profile("Fast Lerp (float)"):
        for (X : Floats):
            set Acc += FastLerp(X, 25.0, 0.3)
    Acc
