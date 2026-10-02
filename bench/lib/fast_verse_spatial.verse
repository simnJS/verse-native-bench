FastVerseSpatial<public> := module:
    using { /Verse.org/SpatialMath }

    # Unambiguous names when /UnrealEngine.com/Temporary/SpatialMath is imported too.
    verse_vector3<public> := (/Verse.org/SpatialMath:)vector3
    verse_rotation<public> := (/Verse.org/SpatialMath:)rotation
    verse_transform<public> := (/Verse.org/SpatialMath:)transform

    # The natives rebuild the axis on every call.
    ForwardUnit:verse_vector3 = verse_vector3{Forward := 1.0, Left := 0.0, Up := 0.0}
    LeftUnit:verse_vector3 = verse_vector3{Forward := 0.0, Left := 1.0, Up := 0.0}
    UpUnit:verse_vector3 = verse_vector3{Forward := 0.0, Left := 0.0, Up := 1.0}

    FastDistance<public>(V1:verse_vector3, V2:verse_vector3)<reads>:float =
        Sqrt(FastDistanceSquared(V1, V2))

    FastDistanceSquared<public>(V1:verse_vector3, V2:verse_vector3)<computes>:float =
        DF := V2.Forward - V1.Forward
        DL := V2.Left - V1.Left
        DU := V2.Up - V1.Up
        DF * DF + DL * DL + DU * DU

    FastDistanceForwardLeft<public>(V1:verse_vector3, V2:verse_vector3)<reads>:float =
        Sqrt(FastDistanceSquaredForwardLeft(V1, V2))

    FastDistanceSquaredForwardLeft<public>(V1:verse_vector3, V2:verse_vector3)<computes>:float =
        DF := V2.Forward - V1.Forward
        DL := V2.Left - V1.Left
        DF * DF + DL * DL

    (V:verse_vector3).FastLength<public>()<reads>:float =
        Sqrt(V.Forward * V.Forward + V.Left * V.Left + V.Up * V.Up)

    (V:verse_vector3).FastLengthForwardLeft<public>()<reads>:float =
        Sqrt(V.Forward * V.Forward + V.Left * V.Left)

    FastLerp<public>(From:verse_vector3, To:verse_vector3, Parameter:float)<computes>:verse_vector3 =
        Rest := 1.0 - Parameter
        verse_vector3:
            Forward := From.Forward * Rest + To.Forward * Parameter
            Left := From.Left * Rest + To.Left * Parameter
            Up := From.Up * Rest + To.Up * Parameter

    (V:verse_vector3).FastIsFinite<public>()<computes><decides>:verse_vector3 =
        Abs(V.Forward) < Inf and Abs(V.Left) < Inf and Abs(V.Up) < Inf
        V

    (V:verse_vector3).FastMakeUnitVector<public>()<reads>:verse_vector3 =
        Norm := V.FastLength()
        verse_vector3{Forward := V.Forward / Norm, Left := V.Left / Norm, Up := V.Up / Norm}

    # Same computation as ReflectVector, without its three intermediate vector3.
    FastReflectVector<public>(Direction:verse_vector3, Normal:verse_vector3)<reads>:verse_vector3 =
        Norm := Normal.FastLength()
        UF := Normal.Forward / Norm
        UL := Normal.Left / Norm
        UU := Normal.Up / Norm
        Scale := 2.0 * (Direction.Forward * UF + Direction.Left * UL + Direction.Up * UU)
        verse_vector3{Forward := Direction.Forward - Scale * UF, Left := Direction.Left - Scale * UL, Up := Direction.Up - Scale * UU}

    (Rotation:verse_rotation).FastGetForwardAxis<public>()<reads>:verse_vector3 = ForwardUnit * Rotation

    (Rotation:verse_rotation).FastGetLeftAxis<public>()<reads>:verse_vector3 = LeftUnit * Rotation

    (Rotation:verse_rotation).FastGetUpAxis<public>()<reads>:verse_vector3 = UpUnit * Rotation

    # The natives go through DegreesToRadians/RadiansToDegrees; one rounding fewer, so it may differ by 1 ulp.
    RadiansPerDegree:float = PiFloat / 180.0
    DegreesPerRadian:float = 180.0 / PiFloat

    FastMakeRotationDegrees<public>(Axis:verse_vector3, Angle:float)<reads>:verse_rotation =
        MakeRotationRadians(Axis, Angle * RadiansPerDegree)

    FastMakeRotationFromYawPitchRollRadians<public>(YawAngle:float, PitchAngle:float, RollAngle:float)<reads>:verse_rotation =
        (/Verse.org/SpatialMath:)MakeRotationFromYawPitchRollDegrees(YawAngle * DegreesPerRadian, PitchAngle * DegreesPerRadian, RollAngle * DegreesPerRadian)

    FastMakeRotationFromEulerDegrees<public>(LeftAxisAngle:float, UpAxisAngle:float, ForwardAxisAngle:float)<reads>:verse_rotation =
        MakeRotationFromEulerRadians(LeftAxisAngle * RadiansPerDegree, UpAxisAngle * RadiansPerDegree, ForwardAxisAngle * RadiansPerDegree)

    FastAngularDistanceDegrees<public>(Rotation1:verse_rotation, Rotation2:verse_rotation)<reads>:float =
        AngularDistanceRadians(Rotation1, Rotation2) * DegreesPerRadian

    (Rotation:verse_rotation).FastGetYawPitchRollRadians<public>()<reads>:tuple(float, float, float) =
        Degrees := Rotation.GetYawPitchRollDegrees()
        (Degrees(0) * RadiansPerDegree, Degrees(1) * RadiansPerDegree, Degrees(2) * RadiansPerDegree)

    (Rotation:verse_rotation).FastGetEulerDegrees<public>()<reads>:tuple(float, float, float) =
        Radians := Rotation.GetEulerRadians()
        (Radians(0) * DegreesPerRadian, Radians(1) * DegreesPerRadian, Radians(2) * DegreesPerRadian)

    (Rotation:verse_rotation).FastGetAngleDegrees<public>()<reads>:float =
        Rotation.GetAngleRadians() * DegreesPerRadian

    # Equivalent to InVector * InTransform; with a unit scale, Scale * InVector equals InVector.
    FastTransformVector<public>(InVector:verse_vector3, InTransform:verse_transform)<reads>:verse_vector3 =
        S := InTransform.Scale
        Scaled := if (S.Forward = 1.0, S.Left = 1.0, S.Up = 1.0) then InVector else verse_vector3{Forward := S.Forward * InVector.Forward, Left := S.Left * InVector.Left, Up := S.Up * InVector.Up}
        Rotated := Scaled * InTransform.Rotation
        T := InTransform.Translation
        verse_vector3{Forward := Rotated.Forward + T.Forward, Left := Rotated.Left + T.Left, Up := Rotated.Up + T.Up}
