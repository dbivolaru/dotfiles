# Programs for the HP-17bii+ Financial Calculator

This is meant as an archive for the programs I use and is not meant as a comprehensive list of programs.

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
- `Q(x) = CDF(x)-0.5 = Prob.(   0 < X <= x)`
- `R(x) = 1-CDF(x)   = Prob.(   x < X <= +inf)`

```
NORM:SIGMA(I:1:5:1:ITEM(NORM:I)*SPPV(23.1641888*ABS(X):I))/EXP(X^2/2))+IF(S(P):P-1:0)+IF(S(Q):Q-0.5:0)+IF(S(R):-R:0)
```

## Options on Futures calculator

This is an options on futures calculator - do not use for stocks.

- `K` strike price
- `F` futures price
- `DTE` days to expiration on a 365 basis
- `R%` risk-free interest rate
- `IV%` implied volatility
- `V` value of the option price
- `DELTA` delta of the option price (output only - use `RCL`)
- `MODE` for a call option (`0`) or for a put option (`1` or any other non-zero value)

Validated against the CME Futures Options Calculator, CME SPAN and Bloomberg OVME L. Note Bloomberg conventions for delta and gamma using %.

```
FUT.OPT:0*L(A:-LN(K/F))*L(DF:EXP(-DTE*R%/36500))*L(B:IV%*SQRT(DTE/365)/100)
*L(D1:G(A)/G(B)+G(B)/2)*L(D2:G(A)/G(B)-G(B)/2)
*L(ND1:ABS(IF(G(D1)<0:0:-1)+SIGMA(I:1:5:1:ITEM(NORM:I)*SPPV(23.1641888*ABS(G(D1)):I))/EXP(G(D1)^2/2)))
*L(ND2:ABS(IF(G(D2)<0:0:-1)+SIGMA(I:1:5:1:ITEM(NORM:I)*SPPV(23.1641888*ABS(G(D2)):I))/EXP(G(D2)^2/2)))
*L(PD1:INV(SQRT(2*PI*EXP(G(D1)^2))))
*L(C:G(DF)*(F*G(ND1)-K*G(ND2)))
*L(DELTA:G(DF)*(G(ND1)+IF(G(MODE)=0:0:-1)))
*L(GAMA:G(DF)*G(PD1)/(G(B)*F))
*L(VEGA:F*G(DF)*SQRT(DTE/365)*G(PD1)/100)
*L(THETA:-(G(F)*G(PD1)*IV%/200/SQRT(DTE/365)+G(K)*G(R%)/100*(G(ND2)+IF(G(MODE)=0:0:-1)))*G(DF)/365)
+V-G(C)+IF(G(MODE)=0:0:G(DF)*(F-K))
+0*DELTA*GAMA*VEGA*THETA*MODE
```

The equation requires a named SUM-list called `NORM` to be added to the calculator:
```
1      0.127414796
2     -0.142248368
3      0.710706871
4     -0.726576013
5      0.530702714
       -----------
Total  0.500000000
```

The algorithm used for the normal distribution cdf is from Handbook of Mathematical Functions, Abramowitz-Stegun et al 26.2.17 and has an approximation error of O(-7). Also, credits go to Tony Hutchins / MoHC for the original implementation of the stocks version.

## Options on Futures calculator (Bachelier)

We also give the Bachelier version for use with spreads or when the underlying is negative/close to zero in super-contango.
The inputs & outputs are identical to the previous calculator.

For this, mainly I want to highlight the following two differences compared to the normal Bachelier model:
- `IV%` is the usual percentage returns vola; it's used to calculate the Bachelier implied volatility internally by `xF`; not super exact but it works well in practice as drop-in replacement when your broker forgot to read the clearing advisories about negative prices
- `VEGA` has similar units as the previous calculator (ie Bachelier `xF`) with the intent of being also a drop-in replacement

Validated against the CME Futures Options Calculator.

```
FUT.OPT.B:0*L(A:-K+F)*L(DF:EXP(-DTE*R%/36500))*L(B:IV%*F*SQRT(DTE/365)/100)
*L(D1:G(A)/G(B))
*L(ND1:ABS(IF(G(D1)<0:0:-1)+SIGMA(I:1:5:1:ITEM(NORM:I)*SPPV(23.1641888*ABS(G(D1)):I))/EXP(G(D1)^2/2)))
*L(PD1:INV(SQRT(2*PI*EXP(G(D1)^2))))
*L(C:G(DF)*(G(A)*G(ND1)+G(B)*G(PD1)))
*L(DELTA:G(DF)*(G(ND1)+IF(G(MODE)=0:0:-1)+IV%*SQRT(DTE/365)/100*G(PD1)))
*L(GAMA:G(DF)*G(PD1)/G(B))
*L(VEGA:G(DF)*F*SQRT(DTE/365)*G(PD1)/100)
*L(THETA:-G(DF)*G(B)*G(PD1)/2/DTE-G(R%)/100*G(V)/365)
+V-G(C)+IF(G(MODE)=0:0:G(DF)*G(A))
+0*DELTA*GAMA*VEGA*THETA*MODE
```

## Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
