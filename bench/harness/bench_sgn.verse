using { FastMath }

CheckSgn<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Sgn (float)"}
    for (X : TestFloats):
        Report.AddFloat("X={X}", Sgn(X), FastSgn(X))
    Report

BenchSgn<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Sgn"):
        for (X : Floats):
            set Acc += Sgn(X)
    profile("Fast Sgn"):
        for (X : Floats):
            set Acc += FastSgn(X)
    Acc
