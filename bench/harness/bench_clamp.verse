using { FastMath }

CheckClamp<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Clamp (float)"}
    for (Val : TestFloats, A : TestFloats, B : TestFloats):
        Report.AddFloat("Val={Val} A={A} B={B}", Clamp(Val, A, B), FastClamp(Val, A, B))
    Report

BenchClamp<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Clamp"):
        for (X : Floats):
            set Acc += Clamp(X, -50.0, 50.0)
    profile("Fast Clamp"):
        for (X : Floats):
            set Acc += FastClamp(X, -50.0, 50.0)
    Acc
