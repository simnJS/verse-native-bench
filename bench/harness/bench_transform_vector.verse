using { /UnrealEngine.com/Temporary/SpatialMath }
using { FastSpatial }

CheckTransformVector<public>()<transacts>:[]accuracy_report =
    WithScale := accuracy_report{Name := "TransformVector"}
    NoScale := accuracy_report{Name := "TransformVectorNoScale"}
    for (T : TestTransforms(), V : TestVectors()):
        Input := "T={T.Scale}/{T.Rotation}/{T.Translation} V={V}"
        WithScale.AddVector(Input, TransformVector(T, V), FastTransformVector(T, V))
        NoScale.AddVector(Input, TransformVectorNoScale(T, V), FastTransformVectorNoScale(T, V))
    array{WithScale, NoScale}

BenchTransformVector<public>(UnitScale:[]tuple(transform, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native TransformVector"):
        for (Case : UnitScale):
            set Acc += TransformVector(Case(0), Case(1)).X
    profile("Fast TransformVector"):
        for (Case : UnitScale):
            set Acc += FastTransformVector(Case(0), Case(1)).X
    profile("Native TransformVectorNoScale"):
        for (Case : UnitScale):
            set Acc += TransformVectorNoScale(Case(0), Case(1)).X
    profile("Fast TransformVectorNoScale"):
        for (Case : UnitScale):
            set Acc += FastTransformVectorNoScale(Case(0), Case(1)).X
    Acc

BenchTransformVectorScaled<public>(Scaled:[]tuple(transform, vector3))<transacts>:float =
    var Acc:float = 0.0
    profile("Native TransformVector scaled"):
        for (Case : Scaled):
            set Acc += TransformVector(Case(0), Case(1)).X
    profile("Fast TransformVector scaled"):
        for (Case : Scaled):
            set Acc += FastTransformVector(Case(0), Case(1)).X
    Acc
