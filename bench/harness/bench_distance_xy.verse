using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckDistanceXY<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "DistanceXY"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddFloat("A={A} B={B}", DistanceXY(A, B), FastDistanceXY(A, B))
    Report

CheckDistanceSquaredXY<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "DistanceSquaredXY"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddFloat("A={A} B={B}", DistanceSquaredXY(A, B), FastDistanceSquaredXY(A, B))
    Report

BenchDistanceXY<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native DistanceXY"):
        for (Pair : Pairs):
            set Acc += DistanceXY(Pair(0), Pair(1))
    profile("Fast DistanceXY"):
        for (Pair : Pairs):
            set Acc += FastDistanceXY(Pair(0), Pair(1))
    profile("Native DistanceSquaredXY"):
        for (Pair : Pairs):
            set Acc += DistanceSquaredXY(Pair(0), Pair(1))
    profile("Fast DistanceSquaredXY"):
        for (Pair : Pairs):
            set Acc += FastDistanceSquaredXY(Pair(0), Pair(1))
    Acc
