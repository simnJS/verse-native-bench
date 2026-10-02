using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckIsFiniteVector<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "IsFinite (vector3)"}
    for (V : TestVectors()):
        Report.AddVectorResult("V={V}", option{V.IsFinite[]}, option{V.FastIsFinite[]})
    Report

BenchIsFiniteVector<public>(Vectors:[]vector3)<transacts>:float =
    var Acc:float = 0.0
    profile("Native IsFinite"):
        for (V : Vectors, F := V.IsFinite[]):
            set Acc += F.X
    profile("Fast IsFinite"):
        for (V : Vectors, F := V.FastIsFinite[]):
            set Acc += F.X
    Acc
