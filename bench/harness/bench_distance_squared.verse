using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckDistanceSquared<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "DistanceSquared"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddFloat("A={A} B={B}", DistanceSquared(A, B), FastDistanceSquared(A, B))
    Report

BenchDistanceSquared<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native DistanceSquared"):
        for (Pair : Pairs):
            set Acc += DistanceSquared(Pair(0), Pair(1))
    profile("Fast DistanceSquared"):
        for (Pair : Pairs):
            set Acc += FastDistanceSquared(Pair(0), Pair(1))
    Acc
