using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckDegrees<public>()<transacts>:[]accuracy_report =
    ToRadians := accuracy_report{Name := "DegreesToRadians"}
    ToDegrees := accuracy_report{Name := "RadiansToDegrees"}
    for (I := -3600..3600):
        X := I * 0.1
        ToRadians.AddFloat("{X}", DegreesToRadians(X), FastDegreesToRadians(X))
        ToDegrees.AddFloat("{X}", RadiansToDegrees(X), FastRadiansToDegrees(X))
    for (X : TestFloats):
        ToRadians.AddFloat("{X}", DegreesToRadians(X), FastDegreesToRadians(X))
        ToDegrees.AddFloat("{X}", RadiansToDegrees(X), FastRadiansToDegrees(X))
    array{ToRadians, ToDegrees}

BenchDegrees<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native DegreesToRadians"):
        for (X : Floats):
            set Acc += DegreesToRadians(X)
    profile("Fast DegreesToRadians"):
        for (X : Floats):
            set Acc += FastDegreesToRadians(X)
    profile("Native RadiansToDegrees"):
        for (X : Floats):
            set Acc += RadiansToDegrees(X)
    profile("Fast RadiansToDegrees"):
        for (X : Floats):
            set Acc += FastRadiansToDegrees(X)
    Acc
