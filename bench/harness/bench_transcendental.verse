using { FastTranscendental }

CheckTranscendental<public>()<transacts>:[]accuracy_report =
    array{
        CheckUnary("Sin", AngleInputs(), Sin, FastSin),
        CheckUnary("Cos", AngleInputs(), Cos, FastCos),
        CheckUnary("Tan", AngleInputs(), Tan, FastTan),
        CheckUnary("Exp", ExpInputs(), Exp, FastExp),
        CheckUnary("Ln", PositiveInputs(), Ln, FastLn),
        CheckUnary("ArcTan", AngleInputs() + PositiveInputs(), NativeArcTan, FastArcTan),
        CheckUnary("ArcSin", UnitInputs(), ArcSin, FastArcSin),
        CheckUnary("ArcCos", UnitInputs(), ArcCos, FastArcCos),
        CheckUnary("Sinh", HyperbolicInputs(), Sinh, FastSinh),
        CheckUnary("Cosh", HyperbolicInputs(), Cosh, FastCosh),
        CheckUnary("Tanh", HyperbolicInputs(), Tanh, FastTanh),
        CheckUnary("ArSinh", HyperbolicInputs() + PositiveInputs(), ArSinh, FastArSinh),
        CheckUnary("ArCosh", ArCoshInputs(), ArCosh, FastArCosh),
        CheckUnary("ArTanh", UnitInputs(), ArTanh, FastArTanh),
        CheckArcTan2(),
        CheckPowInt()}

CheckUnary(Name:string, Inputs:[]float, Native(X:float)<reads>:float, Fast(X:float)<reads>:float)<transacts>:accuracy_report =
    Report := accuracy_report{Name := Name}
    for (X : Inputs):
        Report.AddFloat(FormatSci(X), Native(X), Fast(X))
    Report

CheckArcTan2()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "ArcTan(Y, X)"}
    for (Y : SpecialInputs + CoordinateInputs, X : SpecialInputs + CoordinateInputs):
        Report.AddFloat("Y={FormatSci(Y)} X={FormatSci(X)}", ArcTan(Y, X), FastArcTan2(Y, X))
    for (I := 0..1256):
        Y := 3.0 * Sin(I * 0.005)
        X := 3.0 * Cos(I * 0.005)
        Report.AddFloat("Y={FormatSci(Y)} X={FormatSci(X)}", ArcTan(Y, X), FastArcTan2(Y, X))
    Report

CheckPowInt()<transacts>:accuracy_report =
    Report := accuracy_report{Name := "Pow (integer exponent)"}
    for (Base : SpecialInputs + CoordinateInputs, Exponent := -5..10):
        Report.AddFloat("{FormatSci(Base)}^{Exponent}", Pow(Base, Exponent * 1.0), FastPowInt(Base, Exponent))
    Report

NativeArcTan(X:float)<reads>:float = ArcTan(X)

BenchTrig<public>(Angles:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native Sin"):
        for (X : Angles):
            set Acc += Sin(X)
    profile("Fast Sin"):
        for (X : Angles):
            set Acc += FastSin(X)
    profile("Native Cos"):
        for (X : Angles):
            set Acc += Cos(X)
    profile("Fast Cos"):
        for (X : Angles):
            set Acc += FastCos(X)
    profile("Native Tan"):
        for (X : Angles):
            set Acc += Tan(X)
    profile("Fast Tan"):
        for (X : Angles):
            set Acc += FastTan(X)
    Acc

BenchExpLn<public>(Floats:[]float)<transacts>:float =
    Exponents := for (F : Floats) do F * 0.05
    Positives := for (F : Floats) do Abs(F) + 0.5
    var Acc:float = 0.0
    profile("Native Exp"):
        for (X : Exponents):
            set Acc += Exp(X)
    profile("Fast Exp"):
        for (X : Exponents):
            set Acc += FastExp(X)
    profile("Native Ln"):
        for (X : Positives):
            set Acc += Ln(X)
    profile("Fast Ln"):
        for (X : Positives):
            set Acc += FastLn(X)
    Acc

BenchInverseTrig<public>(Floats:[]float)<transacts>:float =
    Units := for (F : Floats) do F * 0.01
    Points := for (I -> Y : Floats) { (Y, 50.0 * Cos(I * 0.7)) }
    var Acc:float = 0.0
    profile("Native ArcTan"):
        for (X : Floats):
            set Acc += ArcTan(X)
    profile("Fast ArcTan"):
        for (X : Floats):
            set Acc += FastArcTan(X)
    profile("Native ArcTan2"):
        for (P : Points):
            set Acc += ArcTan(P(0), P(1))
    profile("Fast ArcTan2"):
        for (P : Points):
            set Acc += FastArcTan2(P(0), P(1))
    profile("Native ArcSin"):
        for (X : Units):
            set Acc += ArcSin(X)
    profile("Fast ArcSin"):
        for (X : Units):
            set Acc += FastArcSin(X)
    profile("Native ArcCos"):
        for (X : Units):
            set Acc += ArcCos(X)
    profile("Fast ArcCos"):
        for (X : Units):
            set Acc += FastArcCos(X)
    Acc

BenchHyperbolic<public>(Floats:[]float)<transacts>:float =
    Moderate := for (F : Floats) do F * 0.05
    AboveOne := for (F : Floats) do Abs(F) + 1.0
    Units := for (F : Floats) do F * 0.0099
    var Acc:float = 0.0
    profile("Native Sinh"):
        for (X : Moderate):
            set Acc += Sinh(X)
    profile("Fast Sinh"):
        for (X : Moderate):
            set Acc += FastSinh(X)
    profile("Native Cosh"):
        for (X : Moderate):
            set Acc += Cosh(X)
    profile("Fast Cosh"):
        for (X : Moderate):
            set Acc += FastCosh(X)
    profile("Native Tanh"):
        for (X : Moderate):
            set Acc += Tanh(X)
    profile("Fast Tanh"):
        for (X : Moderate):
            set Acc += FastTanh(X)
    profile("Native ArSinh"):
        for (X : Moderate):
            set Acc += ArSinh(X)
    profile("Fast ArSinh"):
        for (X : Moderate):
            set Acc += FastArSinh(X)
    profile("Native ArCosh"):
        for (X : AboveOne):
            set Acc += ArCosh(X)
    profile("Fast ArCosh"):
        for (X : AboveOne):
            set Acc += FastArCosh(X)
    profile("Native ArTanh"):
        for (X : Units):
            set Acc += ArTanh(X)
    profile("Fast ArTanh"):
        for (X : Units):
            set Acc += FastArTanh(X)
    Acc

BenchPowInt<public>(Floats:[]float)<transacts>:float =
    var Acc:float = 0.0
    profile("Native PowCube"):
        for (X : Floats):
            set Acc += Pow(X, 3.0)
    profile("Fast PowCube"):
        for (X : Floats):
            set Acc += FastPowInt(X, 3)
    Acc

SpecialInputs:[]float = array{0.0, -0.0, 4.9406564584124654e-324, -1.0e-300, 1.0e-10, -1.0e-10, 1.0, -1.0, 1.0e300, -1.0e300, Inf, -Inf, NaN}

CoordinateInputs:[]float = array{-3.5, -0.75, 0.25, 0.5, 2.5, 7.0, -1234.5}

AngleInputs()<computes>:[]float =
    Dense := for (I := -2000..2000) do I * 0.005
    Wide := for (I := -400..400) do I * 123.456
    Dense + Wide + array{1.0e6, -3.0e7} + SpecialInputs

ExpInputs()<computes>:[]float =
    Range := for (I := -1500..1440) do I * 0.5
    NearZero := for (I := -100..100) do I * 1.0e-6
    Range + NearZero + array{709.78, 709.79, -708.4, -745.1, -745.2} + SpecialInputs

PositiveInputs()<reads>:[]float =
    Decades := for (I := -1300..1300) do Pow(10.0, I * 0.25)
    NearOne := for (I := -200..200) do 1.0 + I * 1.0e-6
    Decades + NearOne + SpecialInputs

UnitInputs()<computes>:[]float =
    Range := for (I := -1100..1100) do I * 0.001
    NearEdges := array{0.999999, -0.999999, 1.0 - 1.0e-12, -1.0 + 1.0e-12, 1.0e-20}
    Range + NearEdges + SpecialInputs

HyperbolicInputs()<computes>:[]float =
    Range := for (I := -3000..3000) do I * 0.01
    NearOverflow := for (I := 700..712) do I * 1.0
    Range + NearOverflow + array{-710.4, 1.0e-12, -1.0e-12, 0.3465, 0.3466} + SpecialInputs

ArCoshInputs()<computes>:[]float =
    Range := for (I := 0..3000) do 1.0 + I * 0.01
    Range + array{1.0 + 1.0e-12, 3.0e8, 1.0e200, 0.999, 0.0} + SpecialInputs
