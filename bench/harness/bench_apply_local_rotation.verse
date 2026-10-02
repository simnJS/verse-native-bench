using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

LocalRotationAngles:[]float = array{0.0, 0.5, -2.0, 3.141592653589793}

ProbeVector:vector3 = vector3{X := 1.0, Y := 2.0, Z := 3.0}

# Two rotations are compared through their effect on the same vector.
CheckApplyLocalRotation<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "ApplyLocalRotationY/Z"}
    for (R : TestRotations(), Angle : LocalRotationAngles):
        NativeY := R.ApplyLocalRotationY(Angle)
        FastY := R.FastApplyLocalRotationY(Angle)
        Report.AddVector("Y R={R} Angle={Angle}", NativeY.RotateVector(ProbeVector), FastY.RotateVector(ProbeVector))
        NativeZ := R.ApplyLocalRotationZ(Angle)
        FastZ := R.FastApplyLocalRotationZ(Angle)
        Report.AddVector("Z R={R} Angle={Angle}", NativeZ.RotateVector(ProbeVector), FastZ.RotateVector(ProbeVector))
    Report

BenchApplyLocalRotation<public>(Rotations:[]rotation)<transacts>:float =
    var Acc:float = 0.0
    profile("Native ApplyLocalRotationY"):
        for (R : Rotations):
            set Acc += R.ApplyLocalRotationY(0.1).GetAngle()
    profile("Fast ApplyLocalRotationY"):
        for (R : Rotations):
            set Acc += R.FastApplyLocalRotationY(0.1).GetAngle()
    profile("Native ApplyLocalRotationZ"):
        for (R : Rotations):
            set Acc += R.ApplyLocalRotationZ(0.1).GetAngle()
    profile("Fast ApplyLocalRotationZ"):
        for (R : Rotations):
            set Acc += R.FastApplyLocalRotationZ(0.1).GetAngle()
    Acc
