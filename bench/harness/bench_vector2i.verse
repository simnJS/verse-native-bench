using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckEquals2i<public>()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Equals (vector2i)"}
    Values := array{-3, 0, 7}
    Vectors := for (A : Values, B : Values) do vector2i{X := A, Y := B}
    for (A : Vectors, B : Vectors):
        Native := option{Equals[A, B]}
        Fast := option{FastEquals[A, B]}
        Report.AddTripleResult("A={A} B={B}", option{IntTriple(Native?)}, option{IntTriple(Fast?)})
    Report

BenchEquals2i<public>(Pairs:[]tuple(vector2i, vector2i))<transacts>:float =
    var Acc:float = 0.0
    profile("Native Equals (vector2i)"):
        for (Pair : Pairs, E := Equals[Pair(0), Pair(1)]):
            set Acc += E.X * 1.0
    profile("Fast Equals (vector2i)"):
        for (Pair : Pairs, E := FastEquals[Pair(0), Pair(1)]):
            set Acc += E.X * 1.0
    Acc

IntTriple(V:vector2i)<computes>:triple = (V.X * 1.0, V.Y * 1.0, 0.0)
