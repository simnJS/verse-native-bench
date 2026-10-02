using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

LerpParameters:[]float = array{0.0, 0.3, 1.0, 2.0}

CheckLerpVector<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Lerp (vector3)"}
    for (Pair : TestVectorPairs(), T : LerpParameters):
        From := Pair(0)
        To := Pair(1)
        Report.AddVector("From={From} To={To} T={T}", Lerp(From, To, T), FastLerp(From, To, T))
    Report

BenchLerpVector<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native Lerp"):
        for (Pair : Pairs):
            set Acc += Lerp(Pair(0), Pair(1), 0.3).X
    profile("Fast Lerp"):
        for (Pair : Pairs):
            set Acc += FastLerp(Pair(0), Pair(1), 0.3).X
    Acc
