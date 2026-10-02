using { FastMath }

CheckMinMax<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Min/Max (float)"}
    for (X : TestFloats, Y : TestFloats):
        Report.AddFloat("Min X={X} Y={Y}", Min(X, Y), FastMin(X, Y))
        Report.AddFloat("Max X={X} Y={Y}", Max(X, Y), FastMax(X, Y))
    Report

BenchMinMax<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Min"):
        for (X : Floats):
            set Acc += Min(X, 25.0)
    profile("Fast Min"):
        for (X : Floats):
            set Acc += FastMin(X, 25.0)
    profile("Native Max"):
        for (X : Floats):
            set Acc += Max(X, 25.0)
    profile("Fast Max"):
        for (X : Floats):
            set Acc += FastMax(X, 25.0)
    Acc
