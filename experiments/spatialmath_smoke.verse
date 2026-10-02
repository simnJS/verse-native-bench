using { /UnrealEngine.com/Temporary/SpatialMath }

Main(Args:[]string, Env:[string]string)<suspends>:void =
    D := vector3{X := 1.0, Y := -1.0, Z := 0.0}
    N := vector3{X := 0.0, Y := 1.0, Z := 0.0}
    if (R := ReflectVector[D, N]):
        Print("ReflectVector={R}")
    var Acc:float = 0.0
    profile("ReflectVector x10000"):
        for (I := 1..10000):
            if (R := ReflectVector[D, N]):
                set Acc += R.Y
    Print("Acc={Acc}")
