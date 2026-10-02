using { /UnrealEngine.com/Temporary/SpatialMath }

# Vectors as tuples: on the BPVM a tuple costs almost nothing to build, unlike a Temporary vector3.
TupleMath<public> := module:

    vec3<public> := tuple(float, float, float)

    ToTuple<public>(V:vector3)<computes>:vec3 = (V.X, V.Y, V.Z)

    ToVector3<public>(T:vec3)<computes>:vector3 = vector3{X := T(0), Y := T(1), Z := T(2)}

    Add<public>(A:vec3, B:vec3)<computes>:vec3 = (A(0) + B(0), A(1) + B(1), A(2) + B(2))

    Sub<public>(A:vec3, B:vec3)<computes>:vec3 = (A(0) - B(0), A(1) - B(1), A(2) - B(2))

    Scale<public>(A:vec3, S:float)<computes>:vec3 = (A(0) * S, A(1) * S, A(2) * S)

    Dot<public>(A:vec3, B:vec3)<computes>:float = A(0) * B(0) + A(1) * B(1) + A(2) * B(2)

    Cross<public>(A:vec3, B:vec3)<computes>:vec3 =
        (A(1) * B(2) - A(2) * B(1), A(2) * B(0) - A(0) * B(2), A(0) * B(1) - A(1) * B(0))

    NormSquared<public>(A:vec3)<computes>:float = A(0) * A(0) + A(1) * A(1) + A(2) * A(2)

    Norm<public>(A:vec3)<reads>:float = Sqrt(A(0) * A(0) + A(1) * A(1) + A(2) * A(2))

    Distance<public>(A:vec3, B:vec3)<reads>:float = Norm(Sub(B, A))

    Lerp<public>(From:vec3, To:vec3, Parameter:float)<computes>:vec3 =
        Rest := 1.0 - Parameter
        (From(0) * Rest + To(0) * Parameter, From(1) * Rest + To(1) * Parameter, From(2) * Rest + To(2) * Parameter)
