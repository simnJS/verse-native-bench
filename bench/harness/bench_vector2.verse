using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckVector2<public>()<transacts>:[]accuracy_report =
    Vectors := TestVectors2()
    DistanceReport := accuracy_report{Name := "Distance (vector2)"}
    DistanceSquaredReport := accuracy_report{Name := "DistanceSquared (vector2)"}
    ReflectReport := accuracy_report{Name := "ReflectVector (vector2)"}
    LerpReport := accuracy_report{Name := "Lerp (vector2)"}
    for (A : Vectors, B : Vectors):
        Input := "A={A} B={B}"
        DistanceReport.AddFloat(Input, Distance(A, B), FastDistance(A, B))
        DistanceSquaredReport.AddFloat(Input, DistanceSquared(A, B), FastDistanceSquared(A, B))
        ReflectReport.AddVector2Result(Input, option{ReflectVector[A, B]}, option{FastReflectVector[A, B]})
        LerpReport.AddVector(Input, Lerp(A, B, 0.3), FastLerp(A, B, 0.3))
    LengthReport := accuracy_report{Name := "Length (vector2)"}
    LengthSquaredReport := accuracy_report{Name := "LengthSquared (vector2)"}
    IsFiniteReport := accuracy_report{Name := "IsFinite (vector2)"}
    UnitReport := accuracy_report{Name := "MakeUnitVector (vector2)"}
    for (V : Vectors):
        LengthReport.AddFloat("V={V}", V.Length(), V.FastLength())
        LengthSquaredReport.AddFloat("V={V}", V.LengthSquared(), V.FastLengthSquared())
        IsFiniteReport.AddVector2Result("V={V}", option{V.IsFinite[]}, option{V.FastIsFinite[]})
        UnitReport.AddVector2Result("V={V}", option{V.MakeUnitVector[]}, option{V.FastMakeUnitVector[]})
    array{DistanceReport, DistanceSquaredReport, LengthReport, LengthSquaredReport, IsFiniteReport, UnitReport, LerpReport, ReflectReport}

BenchVector2<public>(Vectors:[]vector2, Pairs:[]tuple(vector2, vector2))<transacts>:float =
    var Acc:float = 0.0
    profile("Native Distance (vector2)"):
        for (Pair : Pairs):
            set Acc += Distance(Pair(0), Pair(1))
    profile("Fast Distance (vector2)"):
        for (Pair : Pairs):
            set Acc += FastDistance(Pair(0), Pair(1))
    profile("Native DistanceSquared (vector2)"):
        for (Pair : Pairs):
            set Acc += DistanceSquared(Pair(0), Pair(1))
    profile("Fast DistanceSquared (vector2)"):
        for (Pair : Pairs):
            set Acc += FastDistanceSquared(Pair(0), Pair(1))
    profile("Native Length (vector2)"):
        for (V : Vectors):
            set Acc += V.Length()
    profile("Fast Length (vector2)"):
        for (V : Vectors):
            set Acc += V.FastLength()
    profile("Native LengthSquared (vector2)"):
        for (V : Vectors):
            set Acc += V.LengthSquared()
    profile("Fast LengthSquared (vector2)"):
        for (V : Vectors):
            set Acc += V.FastLengthSquared()
    Acc

BenchVector2Shape<public>(Vectors:[]vector2, Pairs:[]tuple(vector2, vector2))<transacts>:float =
    var Acc:float = 0.0
    profile("Native IsFinite (vector2)"):
        for (V : Vectors, F := V.IsFinite[]):
            set Acc += F.X
    profile("Fast IsFinite (vector2)"):
        for (V : Vectors, F := V.FastIsFinite[]):
            set Acc += F.X
    profile("Native MakeUnitVector (vector2)"):
        for (V : Vectors, U := V.MakeUnitVector[]):
            set Acc += U.X
    profile("Fast MakeUnitVector (vector2)"):
        for (V : Vectors, U := V.FastMakeUnitVector[]):
            set Acc += U.X
    profile("Native Lerp (vector2)"):
        for (Pair : Pairs):
            set Acc += Lerp(Pair(0), Pair(1), 0.3).X
    profile("Fast Lerp (vector2)"):
        for (Pair : Pairs):
            set Acc += FastLerp(Pair(0), Pair(1), 0.3).X
    profile("Native ReflectVector (vector2)"):
        for (Pair : Pairs, R := ReflectVector[Pair(0), Pair(1)]):
            set Acc += R.X
    profile("Fast ReflectVector (vector2)"):
        for (Pair : Pairs, R := FastReflectVector[Pair(0), Pair(1)]):
            set Acc += R.X
    Acc
