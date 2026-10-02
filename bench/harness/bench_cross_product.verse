using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckCrossProduct<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "CrossProduct"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddVector("A={A} B={B}", CrossProduct(A, B), FastCrossProduct(A, B))
    Report

BenchCrossProduct<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native CrossProduct"):
        for (Pair : Pairs):
            set Acc += CrossProduct(Pair(0), Pair(1)).X
    profile("Fast CrossProduct"):
        for (Pair : Pairs):
            set Acc += FastCrossProduct(Pair(0), Pair(1)).X
    Acc
