using { /UnrealEngine.com/Temporary/SpatialMath }

FastSpatial<public> := module:

    # Same value as InternalTolerance, used by MakeUnitVector.
    UnitVectorTolerance:float = 0.00000001

    FastDotProduct<public>(V1:vector3, V2:vector3)<computes>:float =
        V1.X * V2.X + V1.Y * V2.Y + V1.Z * V2.Z

    FastCrossProduct<public>(V1:vector3, V2:vector3)<computes>:vector3 =
        vector3:
            X := V1.Y * V2.Z - V1.Z * V2.Y
            Y := V1.Z * V2.X - V1.X * V2.Z
            Z := V1.X * V2.Y - V1.Y * V2.X

    FastDistance<public>(V1:vector3, V2:vector3)<reads>:float =
        Sqrt(FastDistanceSquared(V1, V2))

    FastDistanceSquared<public>(V1:vector3, V2:vector3)<computes>:float =
        DX := V2.X - V1.X
        DY := V2.Y - V1.Y
        DZ := V2.Z - V1.Z
        DX * DX + DY * DY + DZ * DZ

    FastDistanceXY<public>(V1:vector3, V2:vector3)<reads>:float =
        Sqrt(FastDistanceSquaredXY(V1, V2))

    FastDistanceSquaredXY<public>(V1:vector3, V2:vector3)<computes>:float =
        DX := V2.X - V1.X
        DY := V2.Y - V1.Y
        DX * DX + DY * DY

    (V:vector3).FastLength<public>()<reads>:float =
        Sqrt(V.X * V.X + V.Y * V.Y + V.Z * V.Z)

    (V:vector3).FastLengthXY<public>()<reads>:float =
        Sqrt(V.X * V.X + V.Y * V.Y)

    (V:vector3).FastIsFinite<public>()<computes><decides>:vector3 =
        Abs(V.X) < Inf and Abs(V.Y) < Inf and Abs(V.Z) < Inf
        V

    (V:vector3).FastMakeUnitVector<public>()<reads><decides>:vector3 =
        CanNormalize[V]
        Norm := V.FastLength()
        vector3{X := V.X / Norm, Y := V.Y / Norm, Z := V.Z / Norm}

    FastLerp<public>(From:vector3, To:vector3, Parameter:float)<computes>:vector3 =
        Rest := 1.0 - Parameter
        vector3:
            X := From.X * Rest + To.X * Parameter
            Y := From.Y * Rest + To.Y * Parameter
            Z := From.Z * Rest + To.Z * Parameter

    # Same computation as ReflectVector, without its three intermediate vector3.
    FastReflectVector<public>(Direction:vector3, Normal:vector3)<reads><decides>:vector3 =
        Direction.X <> 0.0 or Direction.Y <> 0.0 or Direction.Z <> 0.0
        CanNormalize[Normal]
        Norm := Normal.FastLength()
        UX := Normal.X / Norm
        UY := Normal.Y / Norm
        UZ := Normal.Z / Norm
        Scale := 2.0 * (Direction.X * UX + Direction.Y * UY + Direction.Z * UZ)
        vector3{X := Direction.X - Scale * UX, Y := Direction.Y - Scale * UY, Z := Direction.Z - Scale * UZ}

    # The natives rebuild the axis on every call.
    UnitX:vector3 = vector3{X := 1.0, Y := 0.0, Z := 0.0}
    UnitY:vector3 = vector3{X := 0.0, Y := 1.0, Z := 0.0}
    UnitZ:vector3 = vector3{X := 0.0, Y := 0.0, Z := 1.0}

    (Rotation:rotation).FastGetLocalForward<public>()<reads>:vector3 = Rotation.RotateVector(UnitX)

    (Rotation:rotation).FastGetLocalRight<public>()<reads>:vector3 = Rotation.RotateVector(UnitY)

    (Rotation:rotation).FastGetLocalUp<public>()<reads>:vector3 = Rotation.RotateVector(UnitZ)

    (InitialRotation:rotation).FastApplyLocalRotationY<public>(AngleRadians:float)<transacts>:rotation =
        InitialRotation.RotateBy(MakeRotation(InitialRotation.FastGetLocalRight(), AngleRadians))

    (InitialRotation:rotation).FastApplyLocalRotationZ<public>(AngleRadians:float)<transacts>:rotation =
        InitialRotation.RotateBy(MakeRotation(InitialRotation.FastGetLocalUp(), AngleRadians))

    # With a unit scale, Scale * InVector equals InVector, so it is not built.
    FastTransformVector<public>(InTransform:transform, InVector:vector3)<reads>:vector3 =
        S := InTransform.Scale
        Scaled := if (S.X = 1.0, S.Y = 1.0, S.Z = 1.0) then InVector else vector3{X := S.X * InVector.X, Y := S.Y * InVector.Y, Z := S.Z * InVector.Z}
        Rotated := InTransform.Rotation.RotateVector(Scaled)
        T := InTransform.Translation
        vector3{X := Rotated.X + T.X, Y := Rotated.Y + T.Y, Z := Rotated.Z + T.Z}

    FastTransformVectorNoScale<public>(InTransform:transform, InVector:vector3)<reads>:vector3 =
        Rotated := InTransform.Rotation.RotateVector(InVector)
        T := InTransform.Translation
        vector3{X := Rotated.X + T.X, Y := Rotated.Y + T.Y, Z := Rotated.Z + T.Z}

    # One rounding fewer than Degrees * PiFloat / 180.0: may differ by 1 ulp.
    RadiansPerDegree:float = PiFloat / 180.0
    DegreesPerRadian:float = 180.0 / PiFloat

    FastDegreesToRadians<public>(Degrees:float)<computes>:float = Degrees * RadiansPerDegree

    FastRadiansToDegrees<public>(Radians:float)<computes>:float = Radians * DegreesPerRadian

    FastDistance<public>(V1:vector2, V2:vector2)<reads>:float =
        Sqrt(FastDistanceSquared(V1, V2))

    FastDistanceSquared<public>(V1:vector2, V2:vector2)<computes>:float =
        DX := V2.X - V1.X
        DY := V2.Y - V1.Y
        DX * DX + DY * DY

    (V:vector2).FastLength<public>()<reads>:float =
        Sqrt(V.X * V.X + V.Y * V.Y)

    (V:vector2).FastLengthSquared<public>()<computes>:float =
        V.X * V.X + V.Y * V.Y

    (V:vector2).FastIsFinite<public>()<computes><decides>:vector2 =
        Abs(V.X) < Inf and Abs(V.Y) < Inf
        V

    (V:vector2).FastMakeUnitVector<public>()<reads><decides>:vector2 =
        CanNormalize[V]
        Norm := V.FastLength()
        vector2{X := V.X / Norm, Y := V.Y / Norm}

    FastLerp<public>(From:vector2, To:vector2, Parameter:float)<computes>:vector2 =
        Rest := 1.0 - Parameter
        vector2{X := From.X * Rest + To.X * Parameter, Y := From.Y * Rest + To.Y * Parameter}

    FastReflectVector<public>(Direction:vector2, Normal:vector2)<reads><decides>:vector2 =
        Direction.X <> 0.0 or Direction.Y <> 0.0
        CanNormalize[Normal]
        Norm := Normal.FastLength()
        UX := Normal.X / Norm
        UY := Normal.Y / Norm
        Scale := 2.0 * (Direction.X * UX + Direction.Y * UY)
        vector2{X := Direction.X - Scale * UX, Y := Direction.Y - Scale * UY}

    # The native rebuilds a vector2i identical to V1.
    FastEquals<public>(V1:vector2i, V2:vector2i)<computes><decides>:vector2i =
        V1.X = V2.X and V1.Y = V2.Y
        V1

    # MakeUnitVector's conditions: finite components, not all within [-1e-8, 1e-8].
    CanNormalize(V:vector3)<computes><decides>:void =
        Abs(V.X) < Inf and Abs(V.Y) < Inf and Abs(V.Z) < Inf
        Abs(V.X) > UnitVectorTolerance or Abs(V.Y) > UnitVectorTolerance or Abs(V.Z) > UnitVectorTolerance

    CanNormalize(V:vector2)<computes><decides>:void =
        Abs(V.X) < Inf and Abs(V.Y) < Inf
        Abs(V.X) > UnitVectorTolerance or Abs(V.Y) > UnitVectorTolerance
