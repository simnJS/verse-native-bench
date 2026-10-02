using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckDistance<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Distance"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddFloat("A={A} B={B}", Distance(A, B), FastDistance(A, B))
    Report

BenchDistance<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native Distance"):
        for (Pair : Pairs):
            set Acc += Distance(Pair(0), Pair(1))
    profile("Fast Distance"):
        for (Pair : Pairs):
            set Acc += FastDistance(Pair(0), Pair(1))
    Acc
