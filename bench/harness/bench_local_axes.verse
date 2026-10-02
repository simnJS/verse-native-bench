using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckLocalAxes<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "GetLocalForward/Right/Up"}
    for (R : TestRotations()):
        Report.AddVector("Forward R={R}", R.GetLocalForward(), R.FastGetLocalForward())
        Report.AddVector("Right R={R}", R.GetLocalRight(), R.FastGetLocalRight())
        Report.AddVector("Up R={R}", R.GetLocalUp(), R.FastGetLocalUp())
    Report

BenchLocalAxes<public>(Rotations:[]rotation)<transacts>:float =
    var Acc:float = 0.0
    profile("Native GetLocalForward"):
        for (R : Rotations):
            set Acc += R.GetLocalForward().X
    profile("Fast GetLocalForward"):
        for (R : Rotations):
            set Acc += R.FastGetLocalForward().X
    profile("Native GetLocalRight"):
        for (R : Rotations):
            set Acc += R.GetLocalRight().X
    profile("Fast GetLocalRight"):
        for (R : Rotations):
            set Acc += R.FastGetLocalRight().X
    profile("Native GetLocalUp"):
        for (R : Rotations):
            set Acc += R.GetLocalUp().X
    profile("Fast GetLocalUp"):
        for (R : Rotations):
            set Acc += R.FastGetLocalUp().X
    Acc
