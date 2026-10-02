# Separate module for the same reason as VerseSpatialBench.
VerseRotationBench<public> := module:
    using { /Verse.org/SpatialMath }
    using { FastVerseSpatial }
    using { VerseSpatialBench }

    Probe:verse_vector3 = verse_vector3{Forward := 1.0, Left := 2.0, Up := 3.0}

    TestAngles:[]float = array{0.0, 30.0, -90.0, 180.0, 123.4, 0.001, NaN}

    # Two rotations are compared through their effect on the same vector.
    RunVerseRotationChecks<public>()<transacts>:[]accuracy_report =
        Rotations := for (Yaw : TestAngles, Pitch : TestAngles) do (/Verse.org/SpatialMath:)MakeRotationFromYawPitchRollDegrees(Yaw, Pitch, 10.0)
        Axes := array{verse_vector3{Forward := 1.0, Left := 0.0, Up := 0.0}, verse_vector3{Forward := -2.5, Left := 0.75, Up := 3.0}, verse_vector3{}}
        MakeDegrees := accuracy_report{Name := "MakeRotationDegrees [Verse.org]"}
        for (Axis : Axes, Angle : TestAngles):
            MakeDegrees.AddTriple("Axis={Axis} Angle={Angle}", Rotated(MakeRotationDegrees(Axis, Angle)), Rotated(FastMakeRotationDegrees(Axis, Angle)))
        FromYprRadians := accuracy_report{Name := "MakeRotationFromYawPitchRollRadians [Verse.org]"}
        FromEulerDegrees := accuracy_report{Name := "MakeRotationFromEulerDegrees [Verse.org]"}
        for (A : TestAngles, B : TestAngles):
            Radians := A * 0.017
            FromYprRadians.AddTriple("{Radians} {B}", Rotated(MakeRotationFromYawPitchRollRadians(Radians, B * 0.017, -Radians)), Rotated(FastMakeRotationFromYawPitchRollRadians(Radians, B * 0.017, -Radians)))
            FromEulerDegrees.AddTriple("{A} {B}", Rotated(MakeRotationFromEulerDegrees(A, B, -A)), Rotated(FastMakeRotationFromEulerDegrees(A, B, -A)))
        Angular := accuracy_report{Name := "AngularDistanceDegrees [Verse.org]"}
        for (R1 : Rotations, R2 : Rotations):
            Angular.AddFloat("R1={R1} R2={R2}", AngularDistanceDegrees(R1, R2), FastAngularDistanceDegrees(R1, R2))
        YprRadians := accuracy_report{Name := "GetYawPitchRollRadians [Verse.org]"}
        EulerDegrees := accuracy_report{Name := "GetEulerDegrees [Verse.org]"}
        AngleDegrees := accuracy_report{Name := "GetAngleDegrees [Verse.org]"}
        for (R : Rotations):
            YprRadians.AddTriple("R={R}", R.GetYawPitchRollRadians(), R.FastGetYawPitchRollRadians())
            EulerDegrees.AddTriple("R={R}", R.GetEulerDegrees(), R.FastGetEulerDegrees())
            AngleDegrees.AddFloat("R={R}", R.GetAngleDegrees(), R.FastGetAngleDegrees())
        array{MakeDegrees, FromYprRadians, FromEulerDegrees, Angular, YprRadians, EulerDegrees, AngleDegrees}

    RunVerseRotationBenches<public>(Inputs:verse_inputs)<transacts>:float =
        var Acc:float = 0.0
        profile("Native MakeRotationDegrees [Verse.org]"):
            for (I -> Axis : Inputs.Vectors, Angle := Inputs.Angles[I]):
                set Acc += MakeRotationDegrees(Axis, Angle).GetAngleRadians()
        profile("Fast MakeRotationDegrees [Verse.org]"):
            for (I -> Axis : Inputs.Vectors, Angle := Inputs.Angles[I]):
                set Acc += FastMakeRotationDegrees(Axis, Angle).GetAngleRadians()
        profile("Native MakeRotationFromYawPitchRollRadians [Verse.org]"):
            for (Angle : Inputs.Angles):
                set Acc += MakeRotationFromYawPitchRollRadians(Angle * 0.017, Angle * 0.008, -Angle * 0.017).GetAngleRadians()
        profile("Fast MakeRotationFromYawPitchRollRadians [Verse.org]"):
            for (Angle : Inputs.Angles):
                set Acc += FastMakeRotationFromYawPitchRollRadians(Angle * 0.017, Angle * 0.008, -Angle * 0.017).GetAngleRadians()
        profile("Native MakeRotationFromEulerDegrees [Verse.org]"):
            for (Angle : Inputs.Angles):
                set Acc += MakeRotationFromEulerDegrees(Angle, Angle * 0.5, -Angle).GetAngleRadians()
        profile("Fast MakeRotationFromEulerDegrees [Verse.org]"):
            for (Angle : Inputs.Angles):
                set Acc += FastMakeRotationFromEulerDegrees(Angle, Angle * 0.5, -Angle).GetAngleRadians()
        profile("Native AngularDistanceDegrees [Verse.org]"):
            for (Pair : Inputs.RotationPairs):
                set Acc += AngularDistanceDegrees(Pair(0), Pair(1))
        profile("Fast AngularDistanceDegrees [Verse.org]"):
            for (Pair : Inputs.RotationPairs):
                set Acc += FastAngularDistanceDegrees(Pair(0), Pair(1))
        profile("Native GetYawPitchRollRadians [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetYawPitchRollRadians()(0)
        profile("Fast GetYawPitchRollRadians [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetYawPitchRollRadians()(0)
        profile("Native GetEulerDegrees [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetEulerDegrees()(0)
        profile("Fast GetEulerDegrees [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetEulerDegrees()(0)
        profile("Native GetAngleDegrees [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetAngleDegrees()
        profile("Fast GetAngleDegrees [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetAngleDegrees()
        Acc

    Rotated(R:verse_rotation)<reads>:triple =
        V := Probe * R
        (V.Forward, V.Left, V.Up)
