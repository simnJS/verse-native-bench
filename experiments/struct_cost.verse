using { /UnrealEngine.com/Temporary/SpatialMath }

Iterations:int = 10000

MakeVector(I:int)<computes>:vector3 = vector3{X := I * 1.0, Y := 2.0, Z := 3.0}

Main(Args:[]string, Env:[string]string)<suspends>:void =
    Input := vector3{X := 1.0, Y := 2.0, Z := 3.0}
    var Acc:float = 0.0
    for (Pass := 1..4):
        profile("Native Loop"):
            for (I := 1..Iterations):
                set Acc += I * 1.0
        profile("Native Vector3Construct"):
            for (I := 1..Iterations):
                set Acc += vector3{X := I * 1.0, Y := 2.0, Z := 3.0}.X
        profile("Native Vector3Copy"):
            for (I := 1..Iterations):
                Copy := Input
                set Acc += Copy.X
        profile("Native Vector3Call"):
            for (I := 1..Iterations):
                set Acc += MakeVector(I).X
        profile("Native Vector3Sub"):
            for (I := 1..Iterations):
                set Acc += (Input - Input).X
    Print("Acc={Acc}")
