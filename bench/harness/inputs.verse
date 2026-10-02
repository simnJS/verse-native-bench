using { /UnrealEngine.com/Temporary/SpatialMath }

# Built once, outside the profile blocks: on the BPVM, building a vector3 is expensive.
bench_inputs<public> := class:
    Count<public>:int
    Floats<public>:[]float
    Vectors<public>:[]vector3
    Pairs<public>:[]tuple(vector3, vector3)
    Vectors2<public>:[]vector2
    Pairs2<public>:[]tuple(vector2, vector2)
    IntPairs2<public>:[]tuple(vector2i, vector2i)
    IntPairs<public>:[]tuple(int, int)
    Rotations<public>:[]rotation
    UnitScaleTransforms<public>:[]tuple(transform, vector3)
    ScaledTransforms<public>:[]tuple(transform, vector3)
    VerseOrg<public>:VerseSpatialBench.verse_inputs
    Tuples<public>:TupleMathBench.tuple_inputs
    Arrays<public>:array_inputs

MakeBenchInputs<public>(N:int)<transacts>:bench_inputs =
    Vectors := for (I := 1..N) do BenchVector(I)
    Pairs := for (I := 1..N) { (BenchVector(I), BenchVector(N + I)) }
    Rotations := for (I := 1..N) do MakeRotationFromYawPitchRollDegrees(I * 7.0, I * 3.0, I * 1.0)
    bench_inputs:
        Count := N
        Floats := for (I := 1..N) do 100.0 * Sin(I * 1.0)
        Vectors := Vectors
        Pairs := Pairs
        Vectors2 := for (I := 1..N) do BenchVector2(I)
        Pairs2 := for (I := 1..N) { (BenchVector2(I), BenchVector2(N + I)) }
        IntPairs2 := for (I := 1..N, Parity := Mod[I, 2]) { (vector2i{X := I, Y := 7}, vector2i{X := I + Parity, Y := 7}) }
        IntPairs := for (I := 1..N, Parity := Mod[I, 2]) { (I * 37 - 185000, 7 - 14 * Parity) }
        Rotations := Rotations
        UnitScaleTransforms := for (I -> R : Rotations, V := Vectors[I]) { (transform{Rotation := R, Translation := V}, V) }
        ScaledTransforms := for (I -> R : Rotations, V := Vectors[I]) { (transform{Scale := vector3{X := 2.0, Y := 0.5, Z := 1.5}, Rotation := R, Translation := V}, V) }
        VerseOrg := VerseSpatialBench.MakeVerseInputs(N)
        Tuples := TupleMathBench.MakeTupleInputs(Pairs, Vectors)
        Arrays := MakeArrayInputs()

BenchVector(I:int)<reads>:vector3 =
    vector3{X := 100.0 * Sin(I * 1.0), Y := 100.0 * Cos(I * 0.7), Z := 50.0 * Sin(I * 0.3)}

BenchVector2(I:int)<reads>:vector2 =
    vector2{X := 100.0 * Sin(I * 1.0), Y := 100.0 * Cos(I * 0.7)}

TestFloats<public>:[]float = array{-Inf, -1.0e300, -2.5, -1.0, -0.0, 0.0, 1.0e-300, 0.5, 1.0, 3.0, 1.0e300, Inf, NaN}

TestVectors<public>()<computes>:[]vector3 =
    Values := array{-2.5, 0.0, 0.75, 3.0e5}
    Grid := for (A : Values, B : Values, C : Values) do vector3{X := A, Y := B, Z := C}
    Grid + EdgeVectors

TestVectorPairs<public>()<computes>:[]tuple(vector3, vector3) =
    Vectors := TestVectors()
    for (A : Vectors, B : Vectors) { (A, B) }

EdgeVectors:[]vector3 = array{
    vector3{X := 1.0e-9, Y := 1.0e-9, Z := 1.0e-9},
    vector3{X := 1.0e-8, Y := -1.0e-8, Z := 0.0},
    vector3{X := 2.0e-8, Y := 0.0, Z := 0.0},
    vector3{X := 1.0e200, Y := -1.0e200, Z := 0.0},
    vector3{X := NaN, Y := 1.0, Z := 0.0},
    vector3{X := Inf, Y := 0.0, Z := 0.0},
    vector3{X := 0.0, Y := -Inf, Z := 1.0},
    vector3{X := -0.0, Y := 0.0, Z := -0.0},
    vector3{X := -0.0, Y := 1.0, Z := -2.0}}

TestVectors2<public>()<computes>:[]vector2 =
    Values := array{-2.5, 0.0, 0.75, 3.0e5}
    Grid := for (A : Values, B : Values) do vector2{X := A, Y := B}
    Grid + array{
        vector2{X := 1.0e-9, Y := 1.0e-9},
        vector2{X := 1.0e-8, Y := -1.0e-8},
        vector2{X := 2.0e-8, Y := 0.0},
        vector2{X := 1.0e200, Y := -1.0e200},
        vector2{X := NaN, Y := 1.0},
        vector2{X := Inf, Y := 0.0},
        vector2{X := -0.0, Y := 1.0}}

TestRotations<public>()<reads>:[]rotation =
    Angles := array{0.0, 30.0, -90.0, 180.0, 123.4}
    Grid := for (Yaw : Angles, Pitch : Angles, Roll : Angles) do MakeRotationFromYawPitchRollDegrees(Yaw, Pitch, Roll)
    Grid + array{IdentityRotation(), MakeRotationFromYawPitchRollDegrees(NaN, 0.0, 0.0)}

TestTransforms<public>()<reads>:[]transform =
    Scales := array{vector3{X := 1.0, Y := 1.0, Z := 1.0}, vector3{X := 2.0, Y := 0.5, Z := -1.0}, vector3{X := 0.0, Y := 1.0, Z := 1.0}}
    Translations := array{vector3{}, vector3{X := 100.0, Y := -50.0, Z := 3.0}}
    Rotations := array{IdentityRotation(), MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0), MakeRotationFromYawPitchRollDegrees(30.0, 45.0, 60.0)}
    for (S : Scales, R : Rotations, T : Translations) do transform{Scale := S, Rotation := R, Translation := T}
