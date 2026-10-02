using { FastEasing }

# The natives only accept Value in [0, 1] (outside, their Newton guess trips an ensure).
CheckEasing<public>()<transacts>:[]accuracy_report =
    Inputs := EasingInputs()
    array{
        CheckEasingCurve("Ease", Inputs, Easing.Ease, FastEase),
        CheckEasingCurve("EaseIn", Inputs, Easing.EaseIn, FastEaseIn),
        CheckEasingCurve("EaseOut", Inputs, Easing.EaseOut, FastEaseOut),
        CheckEasingCurve("EaseInOut", Inputs, Easing.EaseInOut, FastEaseInOut),
        CheckCubicBezier(Inputs)}

CheckEasingCurve(Name:string, Inputs:[]float, Native(Value:float)<reads>:float, Fast(Value:float)<reads>:float)<transacts>:accuracy_report =
    Report := accuracy_report{Name := Name}
    for (Value : Inputs):
        Report.AddFloat(FormatSci(Value), Native(Value), Fast(Value))
    Report

# Overshooting, symmetric, straight and invalid (X outside [0, 1]) control points.
CheckCubicBezier(Inputs:[]float)<transacts>:accuracy_report =
    Report := accuracy_report{Name := "CubicBezier"}
    Curves := array{(0.3, -0.5, 0.7, 1.5), (0.1, 0.9, 0.9, 0.1), (0.0, 0.0, 1.0, 1.0), (0.5, 0.5, 0.5, 0.5), (1.2, 0.0, 0.5, 1.0), (0.0, 1.0, 0.0, 1.0)}
    for (C : Curves):
        Native := Easing.CubicBezier(C(0), C(1), C(2), C(3))
        for (Value : Inputs):
            Report.AddFloat("{FormatSci(Value)} ({C(0)}, {C(1)}, {C(2)}, {C(3)})", Native(Value), FastCubicBezier(Value, C(0), C(1), C(2), C(3)))
    Report

BenchEasing<public>(Floats:[]float)<transacts>:float =
    Values := for (F : Floats) do F * 0.005 + 0.5
    Custom := Easing.CubicBezier(0.3, -0.5, 0.7, 1.5)
    var Acc:float = 0.0
    profile("Native EaseInOut"):
        for (Value : Values):
            set Acc += Easing.EaseInOut(Value)
    profile("Fast EaseInOut"):
        for (Value : Values):
            set Acc += FastEaseInOut(Value)
    profile("Native CubicBezier"):
        for (Value : Values):
            set Acc += Custom(Value)
    profile("Fast CubicBezier"):
        for (Value : Values):
            set Acc += FastCubicBezier(Value, 0.3, -0.5, 0.7, 1.5)
    Acc

EasingInputs()<computes>:[]float =
    Dense := for (I := 0..2000) do I * 0.0005
    Dense + array{1.0e-12, 0.5 - 1.0e-12, 1.0 - 1.0e-12, 4.9406564584124654e-324, -0.0}
