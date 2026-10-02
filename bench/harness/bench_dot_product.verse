using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckDotProduct<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "DotProduct"}
    for (Pair : TestVectorPairs()):
        A := Pair(0)
        B := Pair(1)
        Report.AddFloat("A={A} B={B}", DotProduct(A, B), FastDotProduct(A, B))
    Report

BenchDotProduct<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native DotProduct"):
        for (Pair : Pairs):
            set Acc += DotProduct(Pair(0), Pair(1))
    profile("Fast DotProduct"):
        for (Pair : Pairs):
            set Acc += FastDotProduct(Pair(0), Pair(1))
    profile("Inline DotProduct"):
        for (Pair : Pairs):
            A := Pair(0)
            B := Pair(1)
            set Acc += A.X * B.X + A.Y * B.Y + A.Z * B.Z
    Acc
