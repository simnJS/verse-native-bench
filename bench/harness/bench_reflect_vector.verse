using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckReflectVector<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "ReflectVector"}
    for (Pair : TestVectorPairs()):
        Direction := Pair(0)
        Normal := Pair(1)
        Native := option{ReflectVector[Direction, Normal]}
        Fast := option{FastReflectVector[Direction, Normal]}
        Report.AddVectorResult("D={Direction} N={Normal}", Native, Fast)
    Report

BenchReflectVector<public>(Pairs:[]tuple(vector3, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native ReflectVector"):
        for (Pair : Pairs, R := ReflectVector[Pair(0), Pair(1)]):
            set Acc += R.X
    profile("Fast ReflectVector"):
        for (Pair : Pairs, R := FastReflectVector[Pair(0), Pair(1)]):
            set Acc += R.X
    Acc
