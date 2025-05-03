# Programs for the HP-17bii+ Financial Calculator

## TVM Loan Calculator with ACT/360 ACT/365 support

This is a typical TVM loan calculator with typical parameters, but has two additional ones related to the ACT/360 and ACT/365 modes (`SD` and `D/YR`).

- `N` The total number of payments (months)
- `I%` The nominal annual interest rate as a percentage (ie 4% enter 4)
- `SD` The start date of the loan in MM.DDYYYY format
- `D/YR` The number of days per year for ACT/360 use 360 and for ACT/365 use 365
- `PV` The present value. To a lender or borrower, PV is the amount of the loan; to an investor, PV is the initial investment. If PV paid out, it is negative. PV always occurs at the beginning of the first period.
- `PMT` The dollar amount of each periodic payment. All payments are equal, and no payments are skipped. However due to the ACT handling, the interest payment in each month is bigger or smaller depending on the number of days in the month (28/29/30/31). The base TVM loan calculator uses a fixed amount of 30 days.

```
LOAN:
L(BAL:(N+I%+SD+D/YR)x0+PV)x0+
Σ(
    PER:1:N:1:
    L(
        IPER:
        TRN(
            G(BAL)xI%÷100x
            DDAYS(
                L(X:SD+PER-1)x0+MOD(G(X)-1:12)+1+0.000001xIDIV(G(X)-1:12):
                L(Y:SD+PER)x0+MOD(G(Y)-1:12)+1+0.000001*IDIV(G(Y)-1:12):
                1
            )
            ÷D/YR:
            2
        )
    )+
L(BAL:G(BAL)+G(IPER)+PMT)x0)+
TRN(NxPMT:2)+
TRN(PV:2)=0
```

Due to the way ACT loans work, the `P/YR` is fixed at 12 (ie 12 monthly payments per year) and is thus not available as a variable. As the HP-17bii+ lacks a function to increase the month, we do this through `MOD 12` and `IDIV 12` and exploit the fact that the format of a date is `MM.DDYYYY`.

To get the next month, we just need to increment by 1.
To wrap around the 12th month again to the 1st month of the year, we leverage `MOD`.
If the wrap-around happens, then we need to increase the year by adding a 0.000001 to the date value. For this we leverage `IDIV`.

In theory one could replace `D/YR` with another `L(D/YR:DDAYS(...:1)` definition outside the main loop to implement also ACT/ACT type of loans, if needed. Or change that `1` parameter to `2` for ACT/360A and to `3` for ACT/365A.

<ins>Example</ins>

To calculate the payments on an ACT/360 $517,000 loan at 4% nominal interest rate over 8 years (96 months) you would type:

96 `N`
4 `I%`
01.132020 `SD`
360 `D/YR`
517000 `+/-` `PV`
`PMT`

<ins>Correct Output</ins>

The correct output (after several minutes), will be $6,315.67.

Note, the problem is intractable and not trivial. Even in MS Excel you will need to setup the payments schedule and solve for the payment manually or use the built-in Solver.

<ins>Additional Considerations</ins>

The payment amount for a normal loan (ie 30/360) using the built-in TVM functionality would have given $6,301.86.

A good approximation for an ACT/360 loan using the built-in TVM can be obtained with an 365/360 approximation of the nominal interest rate:

4 `INPUT` 365 `x` 360 `÷` `I%YR`

The resulting 365/360 payment is $6,315.23 which is quite close to the correct solution.

Considering the 365.25/360 approximation yields $6,315.89, we observe the ACT/360 solution is somewhere in-between, which is exactly what is to be expected.

This can provide initial values for the solver to reduce the calculation time significantly.


## Normal Distribution functions

The three normal distribution functions usually found on calculators:

- `P(x) = CDF(x)     = Prob.(-inf < X <=    x)`
- `Q(x) = 1-CDF(x)   = Prob.(   x < X <= +inf)`
- `R(x) = CDF(x)-1/2 = Prob.(   0 < X <=    x)`

```
NORM:
P=0.5+INV(SQRT(2xPIxEXP(SQ(X))+L(M:1)x0))x
Σ(
    K:1:69:2:
    X^KxINV(L(M:G(M)xK))
)
```

```
NORM:
Q=0.5-INV(SQRT(2xPIxEXP(SQ(X))+L(M:1)x0))x
Σ(
    K:1:69:2:
    X^KxINV(L(M:G(M)xK))
)
```

```
NORM:
R=INV(SQRT(2xPIxEXP(SQ(X))+L(M:1)x0))x
Σ(
    K:1:69:2:
    X^KxINV(L(M:G(M)xK))
)
```
