using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckMakeUnitVector<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "MakeUnitVector"}
    for (V : TestVectors()):
        Report.AddVectorResult("V={V}", option{V.MakeUnitVector[]}, option{V.FastMakeUnitVector[]})
    Report

BenchMakeUnitVector<public>(Vectors:[]vector3)<transacts>:float =
    var Acc:float = 0.0
    profile("Native MakeUnitVector"):
        for (V : Vectors, U := V.MakeUnitVector[]):
            set Acc += U.X
    profile("Fast MakeUnitVector"):
        for (V : Vectors, U := V.FastMakeUnitVector[]):
            set Acc += U.X
    Acc
