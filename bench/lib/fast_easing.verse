# The Easing natives (experimental) solve a cubic Bezier in C++ (VerseEasing.cpp). Same steps here,
# in the same order, so the results match bit for bit.
FastEasing<public> := module:

    # Power-basis coefficients of X(t) without the constant term, then the two Y control points.
    curve<public> := tuple(float, float, float, float, float)

    MakeCurve<public>(X0:float, Y0:float, X1:float, Y1:float)<computes>:curve =
        A := X0 - 0.0
        B := X1 - X0
        C := 1.0 - X1
        D := B - A
        (3.0 * A, 3.0 * D, C - B - D, Y0, Y1)

    # UE_KINDA_SMALL_NUMBER is the float 1.e-4f, widened to double.
    NewtonTolerance:float = 9.99999974737875163555145263671875e-05
    MaxNewtonSteps:int = 10

    # The curve is rebuilt on each call, as the native does.
    FastEase<public>(Value:float)<computes>:float = Evaluate(Value, MakeCurve(0.25, 0.1, 0.25, 1.0))
    FastEaseIn<public>(Value:float)<computes>:float = Evaluate(Value, MakeCurve(0.42, 0.0, 1.0, 1.0))
    FastEaseOut<public>(Value:float)<computes>:float = Evaluate(Value, MakeCurve(0.0, 0.0, 0.58, 1.0))
    FastEaseInOut<public>(Value:float)<computes>:float = Evaluate(Value, MakeCurve(0.42, 0.0, 0.58, 1.0))

    # Same contract as Easing.CubicBezier: control X values outside [0, 1] or a straight curve return
    # Value, normalized like the native's VFloat (-0.0 becomes +0.0).
    FastCubicBezier<public>(Value:float, X0:float, Y0:float, X1:float, Y1:float)<computes>:float =
        if (X0 >= 0.0, X1 >= 0.0, X0 <= 1.0, X1 <= 1.0, not (X0 = Y0 and X1 = Y1)):
            Evaluate(Value, MakeCurve(X0, Y0, X1, Y1))
        else:
            Value + 0.0

    Evaluate(T:float, Curve:curve)<computes>:float =
        Root := Solve(Curve, 0.0 - T, T, 0)
        Interpolate(Curve(3), Curve(4), Root)

    # Newton-Raphson on X(t) - T, clamped to [0, 1] like FMath::Clamp (NaN becomes 1.0).
    Solve(Curve:curve, C0:float, Root:float, Step:int)<computes>:float =
        if (Step >= MaxNewtonSteps):
            Root
        else:
            Numerator := ((Curve(2) * Root + Curve(1)) * Root + Curve(0)) * Root + C0
            Denominator := (3.0 * Curve(2) * Root + 2.0 * Curve(1)) * Root + Curve(0)
            NewRoot := ClampUnit(Root - Numerator / Denominator)
            if (Abs(NewRoot - Root) > NewtonTolerance) then Solve(Curve, C0, NewRoot, Step + 1) else NewRoot

    ClampUnit(X:float)<computes>:float =
        Low := if (X <= 1.0) then X else 1.0
        if (Low >= 0.0) then Low else 0.0

    # De Casteljau with FMath::Lerp (A + Alpha * (B - A)), from (0, Y0, Y1, 1).
    Interpolate(Y0:float, Y1:float, Alpha:float)<computes>:float =
        P01 := Mix(0.0, Y0, Alpha)
        P12 := Mix(Y0, Y1, Alpha)
        P23 := Mix(Y1, 1.0, Alpha)
        P012 := Mix(P01, P12, Alpha)
        P123 := Mix(P12, P23, Alpha)
        Mix(P012, P123, Alpha)

    Mix(A:float, B:float, Alpha:float)<computes>:float = A + Alpha * (B - A)
