using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckLength<public>()<transacts>:[]accuracy_report =
    Length := accuracy_report{Name := "Length"}
    LengthXY := accuracy_report{Name := "LengthXY"}
    for (V : TestVectors()):
        Length.AddFloat("V={V}", V.Length(), V.FastLength())
        LengthXY.AddFloat("V={V}", V.LengthXY(), V.FastLengthXY())
    array{Length, LengthXY}

BenchLength<public>(Vectors:[]vector3)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Length"):
        for (V : Vectors):
            set Acc += V.Length()
    profile("Fast Length"):
        for (V : Vectors):
            set Acc += V.FastLength()
    profile("Native LengthXY"):
        for (V : Vectors):
            set Acc += V.LengthXY()
    profile("Fast LengthXY"):
        for (V : Vectors):
            set Acc += V.FastLengthXY()
    Acc
