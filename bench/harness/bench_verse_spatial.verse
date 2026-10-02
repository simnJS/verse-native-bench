# Separate module: its using of /Verse.org/SpatialMath must not make vector3 ambiguous elsewhere.
VerseSpatialBench<public> := module:
    using { /Verse.org/SpatialMath }
    using { FastVerseSpatial }

    verse_inputs<public> := class:
        Vectors<public>:[]verse_vector3
        Pairs<public>:[]tuple(verse_vector3, verse_vector3)
        Rotations<public>:[]verse_rotation
        UnitScaleTransforms<public>:[]tuple(verse_vector3, verse_transform)
        Angles<public>:[]float
        RotationPairs<public>:[]tuple(verse_rotation, verse_rotation)

    MakeVerseInputs<public>(N:int)<transacts>:verse_inputs =
        Vectors := for (I := 1..N) do BenchVerseVector(I)
        Rotations := for (I := 1..N) do (/Verse.org/SpatialMath:)MakeRotationFromYawPitchRollDegrees(I * 7.0, I * 3.0, I * 1.0)
        verse_inputs:
            Vectors := Vectors
            Pairs := for (I := 1..N) { (BenchVerseVector(I), BenchVerseVector(N + I)) }
            Rotations := Rotations
            UnitScaleTransforms := for (I -> R : Rotations, V := Vectors[I]) { (V, verse_transform{Rotation := R, Translation := V}) }
            Angles := for (I := 1..N) do 180.0 * Sin(I * 1.0)
            RotationPairs := for (I -> R : Rotations, Next := Rotations[Mod[I + 1, N]]) { (R, Next) }

    RunVerseChecks<public>()<transacts>:[]accuracy_report =
        Vectors := VerseTestVectors()
        Pairs := for (A : Vectors, B : Vectors) { (A, B) }
        Rotations := VerseTestRotations()
        DistanceReport := accuracy_report{Name := "Distance [Verse.org]"}
        DistanceSquaredReport := accuracy_report{Name := "DistanceSquared [Verse.org]"}
        ForwardLeftReport := accuracy_report{Name := "DistanceForwardLeft [Verse.org]"}
        SquaredForwardLeftReport := accuracy_report{Name := "DistanceSquaredForwardLeft [Verse.org]"}
        LerpReport := accuracy_report{Name := "Lerp [Verse.org]"}
        ReflectReport := accuracy_report{Name := "ReflectVector [Verse.org]"}
        for (Pair : Pairs):
            A := Pair(0)
            B := Pair(1)
            Input := "A={A} B={B}"
            DistanceReport.AddFloat(Input, Distance(A, B), FastDistance(A, B))
            DistanceSquaredReport.AddFloat(Input, DistanceSquared(A, B), FastDistanceSquared(A, B))
            ForwardLeftReport.AddFloat(Input, DistanceForwardLeft(A, B), FastDistanceForwardLeft(A, B))
            SquaredForwardLeftReport.AddFloat(Input, DistanceSquaredForwardLeft(A, B), FastDistanceSquaredForwardLeft(A, B))
            LerpReport.AddTriple(Input, VerseTriple(Lerp(A, B, 0.3)), VerseTriple(FastLerp(A, B, 0.3)))
            ReflectReport.AddTriple(Input, VerseTriple(ReflectVector(A, B)), VerseTriple(FastReflectVector(A, B)))
        LengthReport := accuracy_report{Name := "Length [Verse.org]"}
        LengthForwardLeftReport := accuracy_report{Name := "LengthForwardLeft [Verse.org]"}
        IsFiniteReport := accuracy_report{Name := "IsFinite [Verse.org]"}
        UnitReport := accuracy_report{Name := "MakeUnitVector [Verse.org]"}
        for (V : Vectors):
            LengthReport.AddFloat("V={V}", V.Length(), V.FastLength())
            LengthForwardLeftReport.AddFloat("V={V}", V.LengthForwardLeft(), V.FastLengthForwardLeft())
            IsFiniteReport.AddTripleResult("V={V}", option{VerseTriple(V.IsFinite[])}, option{VerseTriple(V.FastIsFinite[])})
            UnitReport.AddTriple("V={V}", VerseTriple(V.MakeUnitVector()), VerseTriple(V.FastMakeUnitVector()))
        AxesReport := accuracy_report{Name := "GetForward/Left/UpAxis [Verse.org]"}
        for (R : Rotations):
            AxesReport.AddTriple("Forward R={R}", VerseTriple(R.GetForwardAxis()), VerseTriple(R.FastGetForwardAxis()))
            AxesReport.AddTriple("Left R={R}", VerseTriple(R.GetLeftAxis()), VerseTriple(R.FastGetLeftAxis()))
            AxesReport.AddTriple("Up R={R}", VerseTriple(R.GetUpAxis()), VerseTriple(R.FastGetUpAxis()))
        TransformReport := accuracy_report{Name := "vector3 * transform [Verse.org]"}
        for (T : VerseTestTransforms(), V : Vectors):
            TransformReport.AddTriple("T={T} V={V}", VerseTriple(V * T), VerseTriple(FastTransformVector(V, T)))
        array{DistanceReport, DistanceSquaredReport, ForwardLeftReport, SquaredForwardLeftReport, LengthReport, LengthForwardLeftReport, IsFiniteReport, UnitReport, LerpReport, ReflectReport, AxesReport, TransformReport}

    RunVerseBenches<public>(Inputs:verse_inputs)<transacts>:float =
        var Acc:float = 0.0
        profile("Native Distance [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += Distance(Pair(0), Pair(1))
        profile("Fast Distance [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastDistance(Pair(0), Pair(1))
        profile("Native DistanceSquared [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += DistanceSquared(Pair(0), Pair(1))
        profile("Fast DistanceSquared [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastDistanceSquared(Pair(0), Pair(1))
        profile("Native DistanceForwardLeft [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += DistanceForwardLeft(Pair(0), Pair(1))
        profile("Fast DistanceForwardLeft [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastDistanceForwardLeft(Pair(0), Pair(1))
        profile("Native DistanceSquaredForwardLeft [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += DistanceSquaredForwardLeft(Pair(0), Pair(1))
        profile("Fast DistanceSquaredForwardLeft [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastDistanceSquaredForwardLeft(Pair(0), Pair(1))
        profile("Native LengthForwardLeft [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.LengthForwardLeft()
        profile("Fast LengthForwardLeft [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.FastLengthForwardLeft()
        profile("Native Lerp [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += Lerp(Pair(0), Pair(1), 0.3).Up
        profile("Fast Lerp [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastLerp(Pair(0), Pair(1), 0.3).Up
        profile("Native Length [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.Length()
        profile("Fast Length [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.FastLength()
        profile("Native IsFinite [Verse.org]"):
            for (V : Inputs.Vectors, F := V.IsFinite[]):
                set Acc += F.Up
        profile("Fast IsFinite [Verse.org]"):
            for (V : Inputs.Vectors, F := V.FastIsFinite[]):
                set Acc += F.Up
        profile("Native MakeUnitVector [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.MakeUnitVector().Up
        profile("Fast MakeUnitVector [Verse.org]"):
            for (V : Inputs.Vectors):
                set Acc += V.FastMakeUnitVector().Up
        profile("Native ReflectVector [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += ReflectVector(Pair(0), Pair(1)).Up
        profile("Fast ReflectVector [Verse.org]"):
            for (Pair : Inputs.Pairs):
                set Acc += FastReflectVector(Pair(0), Pair(1)).Up
        profile("Native GetForwardAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetForwardAxis().Up
        profile("Fast GetForwardAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetForwardAxis().Up
        profile("Native GetLeftAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetLeftAxis().Up
        profile("Fast GetLeftAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetLeftAxis().Up
        profile("Native GetUpAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.GetUpAxis().Up
        profile("Fast GetUpAxis [Verse.org]"):
            for (R : Inputs.Rotations):
                set Acc += R.FastGetUpAxis().Up
        profile("Native vector3 * transform [Verse.org]"):
            for (Case : Inputs.UnitScaleTransforms):
                set Acc += (Case(0) * Case(1)).Up
        profile("Fast vector3 * transform [Verse.org]"):
            for (Case : Inputs.UnitScaleTransforms):
                set Acc += FastTransformVector(Case(0), Case(1)).Up
        Acc

    VerseTriple(V:verse_vector3)<computes>:triple = (V.Forward, V.Left, V.Up)

    BenchVerseVector(I:int)<reads>:verse_vector3 =
        verse_vector3{Forward := 100.0 * Sin(I * 1.0), Left := 100.0 * Cos(I * 0.7), Up := 50.0 * Sin(I * 0.3)}

    VerseTestVectors()<computes>:[]verse_vector3 =
        Values := array{-2.5, 0.0, 0.75, 3.0e5}
        Grid := for (A : Values, B : Values, C : Values) do verse_vector3{Forward := A, Left := B, Up := C}
        Grid + array{
            verse_vector3{Forward := 1.0e-200, Left := 1.0e-200, Up := 1.0e-200},
            verse_vector3{Forward := 1.0e200, Left := -1.0e200, Up := 0.0},
            verse_vector3{Forward := NaN, Left := 1.0, Up := 0.0},
            verse_vector3{Forward := Inf, Left := 0.0, Up := 0.0},
            verse_vector3{Forward := -0.0, Left := 0.0, Up := -0.0}}

    VerseTestRotations()<reads>:[]verse_rotation =
        Angles := array{0.0, 30.0, -90.0, 180.0, 123.4}
        for (Yaw : Angles, Pitch : Angles, Roll : Angles) do (/Verse.org/SpatialMath:)MakeRotationFromYawPitchRollDegrees(Yaw, Pitch, Roll)

    VerseTestTransforms()<reads>:[]verse_transform =
        Scales := array{verse_vector3{Forward := 1.0, Left := 1.0, Up := 1.0}, verse_vector3{Forward := 2.0, Left := 0.5, Up := -1.0}}
        Rotation := (/Verse.org/SpatialMath:)MakeRotationFromYawPitchRollDegrees(30.0, 45.0, 60.0)
        for (S : Scales) do verse_transform{Scale := S, Rotation := Rotation, Translation := verse_vector3{Forward := 100.0, Left := -50.0, Up := 3.0}}
