using { /UnrealEngine.com/Temporary/SpatialMath }

# The same computation on three representations: Temporary vector3 (tag Native), Verse.org vector3 (VerseOrg), tuple (Tuple).
TupleMathBench<public> := module:
    using { /Verse.org/SpatialMath }
    using { FastVerseSpatial }
    using { TupleMath }

    temp_vector3 := (/UnrealEngine.com/Temporary/SpatialMath:)vector3

    MaxSpeed:float = 600.0
    Steering:float = 0.1
    DeltaTime:float = 0.033

    # One homing step towards a target, written like ordinary game code: 7 intermediate vectors.
    HomingStep(Pos:temp_vector3, Vel:temp_vector3, Target:temp_vector3)<reads>:temp_vector3 =
        ToTarget := Target - Pos
        Desired := ToTarget * (MaxSpeed / (ToTarget.Length() + 1.0))
        NewVel := Vel + (Desired - Vel) * Steering
        Pos + NewVel * DeltaTime

    HomingStep(Pos:verse_vector3, Vel:verse_vector3, Target:verse_vector3)<reads>:verse_vector3 =
        ToTarget := Target - Pos
        Desired := ToTarget * (MaxSpeed / (ToTarget.Length() + 1.0))
        NewVel := Vel + (Desired - Vel) * Steering
        Pos + NewVel * DeltaTime

    HomingStep(Pos:vec3, Vel:vec3, Target:vec3)<reads>:vec3 =
        ToTarget := Sub(Target, Pos)
        Desired := Scale(ToTarget, MaxSpeed / (Norm(ToTarget) + 1.0))
        NewVel := Add(Vel, Scale(Sub(Desired, Vel), Steering))
        Add(Pos, Scale(NewVel, DeltaTime))

    # The same computation on floats: a single Temporary vector3, built at the end.
    ScalarHomingStep(Pos:temp_vector3, Vel:temp_vector3, Target:temp_vector3)<reads>:temp_vector3 =
        TX := Target.X - Pos.X
        TY := Target.Y - Pos.Y
        TZ := Target.Z - Pos.Z
        S := MaxSpeed / (Sqrt(TX * TX + TY * TY + TZ * TZ) + 1.0)
        VX := Vel.X + (TX * S - Vel.X) * Steering
        VY := Vel.Y + (TY * S - Vel.Y) * Steering
        VZ := Vel.Z + (TZ * S - Vel.Z) * Steering
        temp_vector3{X := Pos.X + VX * DeltaTime, Y := Pos.Y + VY * DeltaTime, Z := Pos.Z + VZ * DeltaTime}

    tuple_inputs<public> := class:
        TempPairs<public>:[]tuple(temp_vector3, temp_vector3)
        VersePairs<public>:[]tuple(verse_vector3, verse_vector3)
        TuplePairs<public>:[]tuple(vec3, vec3)
        TempVelocities<public>:[]temp_vector3
        VerseVelocities<public>:[]verse_vector3
        TupleVelocities<public>:[]vec3

    MakeTupleInputs<public>(Pairs:[]tuple(temp_vector3, temp_vector3), Velocities:[]temp_vector3)<transacts>:tuple_inputs =
        tuple_inputs:
            TempPairs := Pairs
            VersePairs := for (Pair : Pairs) { (ToVerse(Pair(0)), ToVerse(Pair(1))) }
            TuplePairs := for (Pair : Pairs) { (ToTuple(Pair(0)), ToTuple(Pair(1))) }
            TempVelocities := Velocities
            VerseVelocities := for (V : Velocities) do ToVerse(V)
            TupleVelocities := for (V : Velocities) do ToTuple(V)

    # Every variant must give exactly the result of the Temporary vector3 version.
    RunTupleChecks<public>()<transacts>:[]accuracy_report =
        Ops := accuracy_report{Name := "Add/Scale/Cross/Lerp [Tuple, VerseOrg]"}
        Homing := accuracy_report{Name := "HomingStep [Tuple, VerseOrg, Scalar]"}
        Vel := temp_vector3{X := 1.0, Y := -2.0, Z := 0.5}
        for (Pair : TestVectorPairs()):
            A := Pair(0)
            B := Pair(1)
            Input := "A={A} B={B}"
            Ops.AddTriple(Input, Triple(A + B), Add(ToTuple(A), ToTuple(B)))
            Ops.AddTriple(Input, Triple(A + B), FromVerse(ToVerse(A) + ToVerse(B)))
            Ops.AddTriple(Input, Triple(A * 0.5), Scale(ToTuple(A), 0.5))
            Ops.AddTriple(Input, Triple(CrossProduct(A, B)), Cross(ToTuple(A), ToTuple(B)))
            Ops.AddTriple(Input, Triple(Lerp(A, B, 0.3)), Lerp(ToTuple(A), ToTuple(B), 0.3))
            Expected := Triple(HomingStep(A, Vel, B))
            Homing.AddTriple(Input, Expected, HomingStep(ToTuple(A), ToTuple(Vel), ToTuple(B)))
            Homing.AddTriple(Input, Expected, FromVerse(HomingStep(ToVerse(A), ToVerse(Vel), ToVerse(B))))
            Homing.AddTriple(Input, Expected, Triple(ScalarHomingStep(A, Vel, B)))
        array{Ops, Homing}

    RunTupleBenches<public>(Inputs:tuple_inputs)<transacts>:float =
        var Acc:float = 0.0
        profile("Native Add [repr]"):
            for (Pair : Inputs.TempPairs):
                set Acc += (Pair(0) + Pair(1)).X
        profile("VerseOrg Add [repr]"):
            for (Pair : Inputs.VersePairs):
                set Acc += (Pair(0) + Pair(1)).Forward
        profile("Tuple Add [repr]"):
            for (Pair : Inputs.TuplePairs):
                set Acc += Add(Pair(0), Pair(1))(0)
        profile("Native Scale [repr]"):
            for (Pair : Inputs.TempPairs):
                set Acc += (Pair(0) * 0.5).X
        profile("VerseOrg Scale [repr]"):
            for (Pair : Inputs.VersePairs):
                set Acc += (Pair(0) * 0.5).Forward
        profile("Tuple Scale [repr]"):
            for (Pair : Inputs.TuplePairs):
                set Acc += Scale(Pair(0), 0.5)(0)
        profile("Native Cross [repr]"):
            for (Pair : Inputs.TempPairs):
                set Acc += CrossProduct(Pair(0), Pair(1)).X
        profile("VerseOrg Cross [repr]"):
            for (Pair : Inputs.VersePairs):
                set Acc += CrossProduct(Pair(0), Pair(1)).Forward
        profile("Tuple Cross [repr]"):
            for (Pair : Inputs.TuplePairs):
                set Acc += Cross(Pair(0), Pair(1))(0)
        profile("Native Lerp [repr]"):
            for (Pair : Inputs.TempPairs):
                set Acc += Lerp(Pair(0), Pair(1), 0.3).X
        profile("VerseOrg Lerp [repr]"):
            for (Pair : Inputs.VersePairs):
                set Acc += Lerp(Pair(0), Pair(1), 0.3).Forward
        profile("Tuple Lerp [repr]"):
            for (Pair : Inputs.TuplePairs):
                set Acc += Lerp(Pair(0), Pair(1), 0.3)(0)
        Acc

    RunHomingBenches<public>(Inputs:tuple_inputs)<transacts>:float =
        var Acc:float = 0.0
        profile("Native HomingStep"):
            for (I -> Pair : Inputs.TempPairs, Vel := Inputs.TempVelocities[I]):
                set Acc += HomingStep(Pair(0), Vel, Pair(1)).X
        profile("VerseOrg HomingStep"):
            for (I -> Pair : Inputs.VersePairs, Vel := Inputs.VerseVelocities[I]):
                set Acc += HomingStep(Pair(0), Vel, Pair(1)).Forward
        profile("Tuple HomingStep"):
            for (I -> Pair : Inputs.TuplePairs, Vel := Inputs.TupleVelocities[I]):
                set Acc += HomingStep(Pair(0), Vel, Pair(1))(0)
        profile("Scalar HomingStep"):
            for (I -> Pair : Inputs.TempPairs, Vel := Inputs.TempVelocities[I]):
                set Acc += ScalarHomingStep(Pair(0), Vel, Pair(1)).X
        Acc

    # Same components, no change of axes: only the representation changes.
    ToVerse(V:temp_vector3)<computes>:verse_vector3 = verse_vector3{Forward := V.X, Left := V.Y, Up := V.Z}

    FromVerse(V:verse_vector3)<computes>:vec3 = (V.Forward, V.Left, V.Up)
