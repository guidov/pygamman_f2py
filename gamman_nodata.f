      function atg(s,t,p) 
c     **************************** 
c     adiabatic temperature gradient deg c per decibar
c     ref: bryden,h.,1973,deep-sea res.,20,401-408
c     units:      
c     pressure        p        decibars
c     temperature     t        deg celsius (ipts-68)
c     salinity        s        (ipss-78)
c     adiabatic       atg      deg. c/decibar
c     checkvalue: atg=3.255976e-4 c/dbar for s=40 (ipss-78),
c     t=40 deg c,p0=10000 decibars
      
      ds = s - 35.0 
      
      atg = (((-2.1687d-16*t+1.8676d-14)*t-4.6206d-13)*p
     x     +((2.7759d-12*t-1.1351d-10)*ds+((-5.4481d-14*t
     x     +8.733d-12)*t-6.7795d-10)*t+1.8741d-8))*p 
     x     +(-4.2393d-8*t+1.8932d-6)*ds
     x     +((6.6228d-10*t-6.836d-8)*t+8.5258d-6)*t+3.5803d-5
      
      
      return
      end


      subroutine depth_ns(s,t,p,n,s0,t0,p0,sns,tns,pns)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Find the position which the neutral surface through a
ccc   specified bottle intersects a neighbouring cast
ccc   
ccc   PRECISION :		Real
ccc   
ccc   INPUT :			s(n)		array of cast salinities
ccc   t(n)		array of cast in situ temperatures
ccc   p(n)		array of cast pressures
ccc   n		length of cast
ccc   s0		the bottle salinity
ccc   t0		the bottle in situ temperature
ccc   p0		the bottle pressure
ccc   
ccc   OUTPUT :		sns		salinity of the neutral surface
ccc   intersection with the cast
ccc   tns		in situ temperature of the intersection
ccc   pns		pressure of the intersection
ccc   
ccc   UNITS :			salinities	psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures	db
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		June 1993
ccc   
ccc   REVISION :		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real (a-h,o-z)

      parameter(nmax=100)

      dimension s(n),t(n),p(n),e(nmax)

      data n2/2/



      if(n.gt.nmax) then
         print *, '\nparameter nmax in depth-ns.f < ',n,'\n'
         stop
      end if

ccc   
ccc   find the bottle pairs containing a crossing
ccc   

      ncr = 0

      do k = 1,n

         call sig_vals(s0,t0,p0,s(k),t(k),p(k),sigl,sigu)
         e(k) = sigu-sigl

         if(k.gt.1) then

ccc   
ccc   an exact crossing at the k-1 bottle
ccc   

	    if(e(k-1).eq.0.) then

               ncr = ncr+1
               sns = s(k-1)
               tns = t(k-1)
               pns = p(k-1)

ccc   
ccc   a crossing between k-1 and k bottles
ccc   

	    elseif(e(k)*e(k-1).lt.0.0) then

               ncr = ncr+1

ccc   
ccc   some Newton-Raphson iterations to find the crossing
ccc   

               pc0 = p(k-1)-e(k-1)*(p(k)-p(k-1))/(e(k)-e(k-1))

               iter = 0
               isuccess = 0

               do while(isuccess.eq.0)

                  iter = iter+1

                  call stp_interp(s(k-1),t(k-1),p(k-1),n2,sc0,tc0,pc0)

                  call sig_vals(s0,t0,p0,sc0,tc0,pc0,sigl,sigu)
                  ec0 = sigu-sigl

                  p1 = (p(k-1)+pc0)/2
                  ez1 = (e(k-1)-ec0)/(pc0-p(k-1))
                  p2 = (pc0+p(k))/2
                  ez2 = (ec0-e(k))/(p(k)-pc0)
                  r = (pc0-p1)/(p2-p1)
                  ecz_0 = ez1+r*(ez2-ez1)

                  if(iter.eq.1) then
                     ecz0 = ecz_0
                  else
                     ecz0 = -(ec0-ec_0)/(pc0-pc_0)
                     if(ecz0.eq.0) ecz0 = ecz_0
                  end if

                  pc1 = pc0+ec0/ecz0

ccc   
ccc   strategy when the iteration jumps out of the inteval
ccc   

                  if(pc1.le.p(k-1).or.pc1.ge.p(k)) then
                     call e_solve(s,t,p,e,n,k,s0,t0,p0,sns,tns,pns,niter)
                     if(pns.lt.p(k-1).or.pns.gt.p(k)) then
                        stop 'ERROR 1 in depth-ns.f'
                     else
                        isuccess = 1
                     endif
                  else

ccc   
ccc   otherwise, test the accuracy of the iterate
ccc   

                     eps = abs(pc1-pc0)

                     if(abs(ec0).le.5.e-5.and.eps.le.5.e-3) then
                        sns = sc0
                        tns = tc0
                        pns = pc0
                        isuccess = 1
                        niter = iter
                     elseif(iter.gt.10) then
                        call e_solve(s,t,p,e,n,k,s0,t0,p0,sns,tns,pns,niter)
                        isuccess = 1
                     else
                        pc_0 = pc0
                        ec_0 = ec0
                        pc0 = pc1
                        isuccess = 0
                     end if

                  end if

               end do

	    end if

         end if

ccc   
ccc   the last bottle
ccc   

         if(k.eq.n.and.e(k).eq.0.0) then
	    ncr = ncr+1
	    sns = s(k)
	    tns = t(k)
	    pns = p(k)
         end if

      end do

ccc   
ccc   multiple crossings
ccc   

      if(ncr.eq.0) then
         sns = -99.0
         tns = -99.0
         pns = -99.0
      elseif(ncr.ge.2) then
c     print *, 'WARNING in depth-ns.f: multiple crossings'
         sns = -99.2
         tns = -99.2
         pns = -99.2
      end if



      return
      end


      SUBROUTINE DERTHE(S,T,P0,DTHEDT,DTHEDS,DTHEDP)
C     *********************************************************************
C     ******* THIS SUBROUTINE USES THE BRYDEN (1973) POLYNOMIAL
C     ******* FOR POTENTIAL TEMPERATURE AS A FUNCTION OF S,T,P
C     ******* TO OBTAIN THE PARTIAL DERIVATIVES OF THETA WITH
C     ******* RESPECT TO T,S,P. PRESSURE IS IN DBARS.
      IMPLICIT REAL (A-Z)
      PARAMETER (A0=-0.36504D-4,A1=-0.83198D-5,A2=+0.54065D-7)
      PARAMETER (A3=-0.40274D-9,B0=-0.17439D-5,B1=+0.29778D-7)
      PARAMETER (D0=+0.41057D-10,C0=-0.89309D-8,C1=+0.31628D-9)
      PARAMETER (C2=-0.21987D-11,E0=+0.16056D-12,E1=-0.50484D-14)
      DS=S-35.0
      P=P0
      PP=P*P
      PPP=PP*P
      TT=T*T
      TTT=TT*T
      PART=1.0+P*(A1+2.*A2*T+3.*A3*TT+DS*B1)
      DTHEDT=PART+PP*(C1+2.*C2*T)+PPP*E1
      DTHEDS=P*(B0+B1*T)+PP*D0
      PART=A0+A1*T+A2*TT+A3*TTT+DS*(B0+B1*T)
      DTHEDP=PART+2.*P*(DS*D0+C0+C1*T+C2*TT)+3.*PP*(E0+E1*T)
C     CHECK=T+PART*P+PP*(DS*D0+C0+C1*T+C2*TT)+PPP*(E0+E1*T)
C     TYPE 100,CHECK
C     100 FORMAT(1H ,' THE CHECK VALUE OF THETA FROM DERTHE IS = ',F9.5)
      RETURN
      END


      subroutine depth_scv(s,t,p,n,s0,t0,p0,sscv,tscv,pscv,nscv)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Find the position which the scv surface through a
ccc   specified bottle intersects a neighbouring cast
ccc   
ccc   PRECISION :		Real
ccc   
ccc   INPUT :			s(n)		array of cast salinities
ccc   t(n)		array of cast in situ temperatures
ccc   p(n)		array of cast pressures
ccc   n			length of cast
ccc   s0			the bottle salinity
ccc   t0			the bottle in situ temperature
ccc   p0			the bottle pressure
ccc   
ccc   OUTPUT :		sscv		salinities of the scv surface
ccc   intersections with the cast
ccc   tscv		temperatures of the intersections
ccc   pscv		pressures of the intersections
ccc   nscv		number of intersections
ccc   
ccc   UNITS :			salinities	psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures	db
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		February 1995
ccc   
ccc   REVISION :		1.1		9/2/95
ccc   
ccc   
ccc   
      implicit real (a-h,o-z)

      parameter(n_max=2000,nscv_max=50)

      dimension s(n),t(n),p(n),e(n_max)
      dimension sscv(nscv_max),tscv(nscv_max),pscv(nscv_max)

      data n2/2/



      if(n.gt.n_max) then
         print *, '\nparameter n_max in depth-scv.f < ',n,'\n'
         stop
      end if

ccc   
ccc   find the bottle pairs containing a crossing
ccc   

      ncr = 0
      nscv = 0

      do k = 1,n

         sdum = svan(s0,theta(s0,t0,p0,p(k)),p(k),sigl)
         sdum = svan(s(k),t(k),p(k),sigu)
         e(k) = sigu-sigl

         if(k.gt.1) then

ccc   
ccc   an exact crossing at the k-1 bottle
ccc   

	    if(e(k-1).eq.0.) then

               ncr = ncr+1
               sscv_tmp = s(k-1)
               tscv_tmp = t(k-1)
               pscv_tmp = p(k-1)


ccc   
ccc   a crossing between k-1 and k bottles
ccc   

	    elseif(e(k)*e(k-1).lt.0.0) then

               ncr = ncr+1

ccc   
ccc   some Newton-Raphson iterations to find the crossing
ccc   

               pc0 = p(k-1)-e(k-1)*(p(k)-p(k-1))/(e(k)-e(k-1))

               iter = 0
               isuccess = 0

               do while(isuccess.eq.0)

                  iter = iter+1

                  call stp_interp(s(k-1),t(k-1),p(k-1),n2,sc0,tc0,pc0)

                  sdum = svan(s0,theta(s0,t0,p0,pc0),pc0,sigl)
                  sdum = svan(sc0,tc0,pc0,sigu)
                  ec0 = sigu-sigl

                  p1 = (p(k-1)+pc0)/2
                  ez1 = (e(k-1)-ec0)/(pc0-p(k-1))
                  p2 = (pc0+p(k))/2
                  ez2 = (ec0-e(k))/(p(k)-pc0)
                  r = (pc0-p1)/(p2-p1)
                  ecz_0 = ez1+r*(ez2-ez1)

                  if(iter.eq.1) then
                     ecz0 = ecz_0
                  else
                     ecz0 = -(ec0-ec_0)/(pc0-pc_0)
                     if(ecz0.eq.0) ecz0 = ecz_0
                  end if

                  pc1 = pc0+ec0/ecz0

ccc   
ccc   strategy when the iteration jumps out of the inteval
ccc   

                  if(pc1.le.p(k-1).or.pc1.ge.p(k)) then
                     call scv_solve(s,t,p,e,n,k,s0,t0,p0,
     &                    sscv_tmp,tscv_tmp,pscv_tmp,niter)
                     if(pscv_tmp.lt.p(k-1).or.pscv_tmp.gt.p(k)) then
                        stop 'ERROR 1 in depth-scv.f'
                     else
                        isuccess = 1
                     endif
                  else

ccc   
ccc   otherwise, test the accuracy of the iterate
ccc   

                     eps = abs(pc1-pc0)

                     if(abs(ec0).le.5.e-5.and.eps.le.5.e-3) then
                        sscv_tmp = sc0
                        tscv_tmp = tc0
                        pscv_tmp = pc0
                        isuccess = 1
                        niter = iter
                     elseif(iter.gt.10) then
                        call scv_solve(s,t,p,e,n,k,s0,t0,p0,
     &                       sscv_tmp,tscv_tmp,pscv_tmp,niter)
                        isuccess = 1
                     else
                        pc_0 = pc0
                        ec_0 = ec0
                        pc0 = pc1
                        isuccess = 0
                     end if

                  end if

               end do

	    end if

         end if

ccc   
ccc   the last bottle
ccc   

         if(k.eq.n.and.e(k).eq.0.0) then
	    ncr = ncr+1
	    sscv_tmp = s(k)
	    tscv_tmp = t(k)
	    pscv_tmp = p(k)
         end if


ccc   
ccc   store multiples
ccc   

         if(ncr.gt.nscv) then
	    nscv = nscv+1
	    if(nscv.gt.nscv_max) stop 'ERROR 2 in depth-scv.f'
	    sscv(nscv) = sscv_tmp
	    tscv(nscv) = tscv_tmp
	    pscv(nscv) = pscv_tmp
         end if
         
      end do


ccc   
ccc   no crossings
ccc   

      if(nscv.eq.0) then
         sscv(1) = -99.0
         tscv(1) = -99.0
         pscv(1) = -99.0
      end if



      return
      end


C     APRIL 12 1984
C     EOS80 DERIVATIVES TEMP. & SALT
      FUNCTION EOS8D(S,T,P0,DRV)
C     MODIFIED RCM
C     ******************************************************
C     SPECIFIC VOLUME ANOMALY (STERIC ANOMALY) BASED ON 1980 EQUATION
C     OF STATE FOR SEAWATER AND 1978 PRACTICAL SALINITY SCALE.
C     REFERENCES
C     MILLERO, ET AL (1980) DEEP-SEA RES.,27A,255-264
C     MILLERO AND POISSON 1981,DEEP-SEA RES.,28A PP 625-629.
C     BOTH ABOVE REFERENCES ARE ALSO FOUND IN UNESCO REPORT 38 (1981)
C     UNITS:      
C     PRESSURE        P0       DECIBARS
C     TEMPERATURE     T        DEG CELSIUS (IPTS-68)
C     SALINITY        S        (IPSS-78)
C     SPEC. VOL. ANA. EOS8D    M**3/KG *1.0E-8
C     DENSITY ANA.    SIGMA    KG/M**3
C     DRV MATRIX FORMAT
C     1    2     3
C     1   V  ,VT  ,VTT    TEMP DERIV. S,T,P
C     2   V0 ,VOT ,V0TT   FOR S,T,0
C     3   RO ,ROT ,ROTT   FOR S,T,P  DENSITY DERIV
C     4   K0 ,K0T ,K0TT   FOR S,T,0 SEC BULK MOD
C     5   A  ,AT  ,ATT
C     6   B  ,BT  ,BTT    BULK MOD PRESS COEFFS
C     7 DRDP ,K   ,DVDP   PRESSURE DERIVATIVE
C     8   R0S,    ,VS      SALINITY DERIVATIVES
C     
C     HECK VALUE: FOR S = 40 (IPSS-78) , T = 40 DEG C, P0= 10000 DECIBARS.
C     DR/DP                  DR/DT                 DR/DS
C     DRV(1,7)              DRV(2,3)             DRV(1,8)
C     
C     FINITE DIFFERENCE WITH 3RD ORDER CORRECTION DONE IN DOUBLE PRECSION
C     
C     3.46969238E-3       -.43311722           .705110777
C     
C     EXPLICIT DIFFERENTIATION SINGLE PRECISION FORMULATION EOS80 
C     
C     3.4696929E-3        -.4331173            .7051107
C     
C     *******************************************************
C     
      IMPLICIT real (A-Z)
c     real K,K0,KW,K35
      REAL P,T,S,SIG,SR,R1,R2,R3,R4
      REAL A,B,C,D,E,A1,B1,AW,BW,K,K0,KW,K35
      real DRV(3,8)
C     ********************
C     DATA
      DATA R3500,R4/1028.1063,4.8314D-4/
      DATA DR350/28.106331/
C     R4 IS REFERED TO AS  C  IN MILLERO AND POISSON 1981
C     CONVERT PRESSURE TO BARS AND TAKE SQUARE ROOT SALINITY.
      P=P0/10.
      R3500=1028.1063
      SAL=S
      SR = SQRT(ABS(S)) 
C     *********************************************************
C     PURE WATER DENSITY AT ATMOSPHERIC PRESSURE
C     BIGG P.H.,(1967) BR. J. APPLIED PHYSICS 8 PP 521-537.
C     
      R1 = ((((6.536332d-9*T-1.120083d-6)*T+1.001685d-4)*T 
     X     -9.095290d-3)*T+6.793952d-2)*T-28.263737
C     SEAWATER DENSITY ATM PRESS. 
C     COEFFICIENTS INVOLVING SALINITY
C     R2 = A   IN NOTATION OF MILLERO AND POISSON 1981
      R2 = (((5.3875d-9*T-8.2467d-7)*T+7.6438d-5)*T-4.0899d-3)*T
     X     +8.24493d-1 
C     R3 = B  IN NOTATION OF MILLERO AND POISSON 1981
      R3 = (-1.6546d-6*T+1.0227d-4)*T-5.72466d-3
C     INTERNATIONAL ONE-ATMOSPHERE EQUATION OF STATE OF SEAWATER
      SIG = (R4*S + R3*SR + R2)*S + R1 
C     SPECIFIC VOLUME AT ATMOSPHERIC PRESSURE
      V350P = 1.0/R3500
      SVA = -SIG*V350P/(R3500+SIG)
      SIGMA=SIG+DR350
      DRV(1,3) = SIGMA
      V0 = 1.0/(1000.0 + SIGMA)
      DRV(1,2) = V0
C     COMPUTE DERIV WRT SALT OF RHO
      R4S=9.6628d-4
      RHOS=R4S*SAL+1.5*R3*SR+R2
C*************************************
C     COMPUTE DERIV WRT TEMP OF RHO
      R1 =(((3.268166d-8*T-4.480332d-6)*T+3.005055d-4)*T
     X     -1.819058d-2)*T+6.793952d-2
      R2 = ((2.155d-8*T-2.47401d-6)*T+1.52876d-4)*T-4.0899d-3
      R3 = -3.3092d-6*T+1.0227d-4
C     
      RHOT = (R3*SR + R2)*SAL + R1
      DRDT=RHOT
      DRV(2,3) = RHOT
      RHO1 = 1000.0 + SIGMA
      RHO2 = RHO1*RHO1
      V0T = -RHOT/(RHO2)
C***********SPECIFIC VOL. DERIV WRT S ***********
      V0S=-RHOS/RHO2
C****************************
      DRV(1,8)=RHOS
      DRV(2,2) = V0T
C     COMPUTE SECOND DERIVATIVE OF RHO
      R1 = ((1.3072664d-7*T-1.3440996d-5)*T+6.01011d-4)*T-1.819058d-2
      R2 = (6.465d-8*T-4.94802d-6)*T+1.52876d-4
      R3 = -3.3092d-6
C     
      RHOTT = (R3*SR + R2)*SAL + R1
      DRV(3,3) = RHOTT
      V0TT = (2.0*RHOT*RHOT/RHO1 - RHOTT)/(RHO2)
      DRV(3,2) = V0TT
C     SCALE SPECIFIC VOL. ANAMOLY TO NORMALLY REPORTED UNITS
      SVAN=SVA*1.0E+8
      EOS8D=SVAN
C     ******************************************************************
C     ******  NEW HIGH PRESSURE EQUATION OF STATE FOR SEAWATER ********
C     ******************************************************************
C     MILLERO, ET AL , 1980 DSR 27A, PP 255-264
C     CONSTANT NOTATION FOLLOWS ARTICLE
C********************************************************
C     COMPUTE COMPRESSION TERMS
      E = (9.1697d-10*T+2.0816d-8)*T-9.9348d-7
      BW = (5.2787d-8*T-6.12293d-6)*T+3.47718d-5
      B = BW + E*S
C     
C*******DERIV B WRT SALT
      DBDS=E
C************************
C     CORRECT B FOR ANAMOLY BIAS CHANGE
      DRV(1,6) = B + 5.03217d-5 
C     DERIV OF B
      BW = 1.05574d-7*T-6.12293d-6
      E = 1.83394d-9*T +2.0816d-8
      BT = BW + E*SAL
      DRV(2,6) = BT
C     COEFFICIENTS OF A
C     SECOND DERIV OF B
      E = 1.83394d-9
      BW = 1.05574d-7
      BTT = BW + E*SAL
      DRV(3,6) = BTT
      D = 1.91075d-4
      C = (-1.6078d-6*T-1.0981d-5)*T+2.2838d-3
      AW = ((-5.77905d-7*T+1.16092d-4)*T+1.43713d-3)*T 
     X     -0.1194975
      A = (D*SR + C)*S + AW 
C     
C     CORRECT A FOR ANAMOLY BIAS CHANGE
      DRV(1,5) = A + 3.3594055
C*****DERIV A WRT SALT ************
      DADS=2.866125d-4*SR+C
C************************************
C     DERIV OF A
      C = -3.2156d-6*T -1.0981d-5
      AW = (-1.733715d-6*T+2.32184d-4)*T+1.43713d-3
C     
      AT = C*SAL + AW
      DRV(2,5) = AT
C     SECOND DERIV OF A
      C = -3.2156d-6
      AW = -3.46743d-6*T + 2.32184d-4
C     
      ATT = C*SAL + AW
      DRV(3,5) = ATT
C     COEFFICIENT K0             
      B1 = (-5.3009d-4*T+1.6483d-2)*T+7.944d-2
      A1 = ((-6.1670d-5*T+1.09987d-2)*T-0.603459)*T+54.6746 
      KW = (((-5.155288d-5*T+1.360477d-2)*T-2.327105)*T 
     X     +148.4206)*T-1930.06
      K0 = (B1*SR + A1)*S + KW
C     ADD BIAS TO OUTPUT K0 VALUE
      DRV(1,4) = K0+21582.27
C******DERIV K0 WRT SALT ************
      K0S=1.5*B1*SR+A1
C*************************************
C     DERIV K WRT SALT   *************
      KS=(DBDS*P+DADS)*P+K0S
C***********************************
C     DERIV OF K0
      B1 = -1.06018d-3*T+1.6483d-2
C     APRIL 9 1984 CORRECT A1 BIAS FROM -.603457 !!!
      A1 = (-1.8501d-4*T+2.19974d-2)*T-0.603459
      KW = ((-2.0621152d-4*T+4.081431d-2)*T-4.65421)*T+148.4206
      K0T = (B1*SR+A1)*SAL + KW
      DRV(2,4) = K0T
C     SECOND DERIV OF K0
      B1 = -1.06018d-3
      A1 = -3.7002d-4*T + 2.19974d-2
      KW = (-6.1863456d-4*T+8.162862d-2)*T-4.65421
      K0TT = (B1*SR + A1)*SAL + KW
      DRV(3,4) = K0TT
C     
C     
C     EVALUATE PRESSURE POLYNOMIAL 
C     ***********************************************
C     K EQUALS THE SECANT BULK MODULUS OF SEAWATER
C     DK=K(S,T,P)-K(35,0,P)
C     K35=K(35,0,P)
C     ***********************************************
      DK = (B*P + A)*P + K0
      K35  = (5.03217d-5*P+3.359406)*P+21582.27
      GAM=P/K35
      PK = 1.0 - GAM
      SVA = SVA*PK + (V350P+SVA)*P*DK/(K35*(K35+DK))
C     SCALE SPECIFIC VOL. ANAMOLY TO NORMALLY REPORTED UNITS
      SVAN=SVA*1.0E+8
      EOS8D=SVAN
      V350P = V350P*PK
C     ****************************************************
C     COMPUTE DENSITY ANAMOLY WITH RESPECT TO 1000.0 KG/M**3
C     1) DR350: DENSITY ANAMOLY AT 35 (IPSS-78), 0 DEG. C AND 0 DECIBARS
C     2) DR35P: DENSITY ANAMOLY 35 (IPSS-78), 0 DEG. C ,  PRES. VARIATION
C     3) DVAN : DENSITY ANAMOLY VARIATIONS INVOLVING SPECFIC VOL. ANAMOLY
C     ********************************************************************
C     CHECK VALUE: SIGMA = 59.82037  KG/M**3 FOR S = 40 (IPSS-78),
C     T = 40 DEG C, P0= 10000 DECIBARS.
C     *******************************************************
      DR35P=GAM/V350P
      DVAN=SVA/(V350P*(V350P+SVA))
      SIGMA=DR350+DR35P-DVAN
      DRV(1,3)=SIGMA
      K=K35+DK
      VP=1.0-P/K
      KT = (BT*P + AT)*P + K0T
      KTT = (BTT*P + ATT)*P + K0TT
C     
      V = 1.0/(SIGMA+1000.0D0)
      DRV(1,1) = V
      V2=V*V
C     DERIV SPECIFIC VOL. WRT SALT **********
      VS=V0S*VP+V0*P*KS/(K*K)
      RHOS=-VS/V2
C***************************************
      DRV(3,8)=VS
      DRV(1,8)=RHOS
C     
      VT = V0T*VP + V0*P*KT/(K*K)
      VTT = V0TT*VP+P*(2.0*V0T*KT+KTT*V0-2.0*KT*KT*V0/K)/(K*K)
      R0TT=(2.0*VT*VT/V-VTT)/V2
      DRV(3,3)=R0TT
      DRV(2,1) = VT
      DRV(3,1) = VTT
      RHOT=-VT/V2
      DRDT=RHOT
      DRV(2,3)=RHOT
C     PRESSURE DERIVATIVE DVDP
C     SET A & B TO UNBIASED VALUES
      A=DRV(1,5)
      B=DRV(1,6)
      DKDP = 2.0*B*P + A
C     CORRECT DVDP TO PER DECIBAR BY MULTIPLE *.1
      DVDP = -.1*V0*(1.0 - P*DKDP/K)/K
      DRV(1,7) = -DVDP/V2
      DRV(2,7) = K
      DRV(3,7) = DVDP
      RETURN  
      END     

      
      SUBROUTINE EOSALL(S,T,P0,THET,SIGTHE,ALFNEW,BETNEW,
     &     GAMNEW,SOUNDV)
C     *********************************************************************
C     THIS PROGRAMME WRITTEN 8 JULY 1985 BY TREVOR J. McDOUGALL
C     EOSALL STANDS FOR "EQUATION OF STATE ALL"
C     THIS SUBROUTINE USES THE FOLLOWING FUNCTIONS WRITEN BY BOB MILLARD,
C     - THETA(S,T,P0,PR) ; SVAN(S,T,P0,SIGTHE) ; EOSED(S,T,P0,DRV)
C     THE NEW EXPANSION COEFFICIENT , ALFNEW , DUE TO HEAT , AND THE 
C     CORRESPONDING SALINE CONTRACTION COEFFICIENT ARE DEFINED IN 
C     TERMS OF THE TWO CONSERVATIVE PROPERTIES OF SEA WATER, 
C     NAMELY POTENTIAL TEMPERATURE (REFERED TO ANY REFERENCE LEVEL)
C     AND SALINITY. THESE COEFFICIENTS ARE DEFINED IN GILL(1982)
C     AND HE LABELS THEM WITH DASHES, SEE HIS SECTION 3.7.4
C     ********************************************************************
C     
      IMPLICIT REAL (A-Z)
      REAL DRV(3,8)
C     ******* THE REFERENCE PRESSURE PR IS KEPT GENERAL BUT WILL BE
C     ******* EQUAL TO ZERO FOR ALL PERCIEVED APPLICATIONS OF NEUTRAL
C     ******* SURFACES.
      PR=0.0
      THET=THETA(S,T,P0,PR)
      EDUM = EOS8D(S,T,P0,DRV)
C     ******* CALCULATE THE ORDINARY EXPANSION COEFFICIENTS, ALFOLD
C     ******* BETOLD AND THE OLD COMPRESSIBILITY, GAMOLD.
      ALFOLD=-DRV(2,3)/(DRV(1,3)+1000.0)
      BETOLD=DRV(1,8)/(DRV(1,3)+1000.0)
      GAMOLD=DRV(1,7)/(DRV(1,3)+1000.0)
C     ******* CALCULATE THE SPECIFIC VOLUME ANOMALY, SVAN, AND THE
C     ******* SIGMA THETA, SIGTHE, BY THE FUNCTION SVAN.
      SDUM=SVAN(S,THET,PR,SIGTHE)
      CALL DERTHE(S,T,P0,DTHEDT,DTHEDS,DTHEDP)
      ALFNEW=ALFOLD/DTHEDT
      BETNEW=BETOLD+ALFNEW*DTHEDS
      GAMNEW=GAMOLD+ALFNEW*DTHEDP
C     ******* CHECK VALUES OF THESE NEW 'EXPANSION COEFFICIENTS'
C     ******* AT S=40.0,T=40.0,THET=36.8907,P0=10000.0 DBARS,
C     ******* ALFNEW=4395.6E-7 ; (ALFOLD=4181.1E-7)
C     ******* BETNEW=6646.9E-7 ; (BETOLD=6653.1E-7)
C     ******* GAMNEW=31.4E-7   ; (GAMOLD=32.7E-7)
C     *******
C     ******* NOW FOR FUN WE CALCULATE THE SPEED OF SOUND. 
C     ******* THE IN SITU DENSITY IS (DRV(1,3)+1000.0)
      SOUNDV=SQRT(ABS(1.0E+4/(GAMNEW*(DRV(1,3)+1000.0))))
C     ******* CHECK VALUE OF THE SPEED OF SOUND IS 
C     ******* AT S=40.0,T=40.0,THET=36.8907,P0=10000.0 DBARS,
C     ******* IS SOUNDV=1734.8 M/S.
      RETURN
      END


      subroutine e_solve(s,t,p,e,n,k,s0,t0,p0,sns,tns,pns,iter)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Find the zero of the e function using a 
ccc   bisection method
ccc   
ccc   PRECISION :		Real
ccc   
ccc   INPUT :			s(n)		array of cast salinities
ccc   t(n)		array of cast in situ temperatures
ccc   p(n)		array of cast pressures
ccc   e(n)		array of cast e values
ccc   n			length of cast
ccc   k			interval (k-1,k) contains the zero
ccc   s0			the bottle salinity
ccc   t0			the bottle in situ temperature
ccc   p0			the bottle pressure
ccc   
ccc   OUTPUT :		sns			salinity of the neutral surface
ccc   intersection with the cast
ccc   tns			in situ temperature of the intersection
ccc   pns			pressure of the intersection
ccc   
ccc   
ccc   UNITS :			salinities		psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures		db
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		June 1993
ccc   
ccc   REVISION :		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real (a-h,o-z)

      dimension s(n),t(n),p(n),e(n)

      data n2/2/


      
      pl = p(k-1)
      el = e(k-1)
      pu = p(k)
      eu = e(k)

      iter = 0
      isuccess = 0

      do while(isuccess.eq.0)

         iter = iter+1

         pm = (pl+pu)/2

         call stp_interp(s(k-1),t(k-1),p(k-1),n2,sm,tm,pm)

         call sig_vals(s0,t0,p0,sm,tm,pm,sigl,sigu)
         em = sigu-sigl

         if(el*em.lt.0.) then
	    pu = pm
	    eu = em
         elseif(em*eu.lt.0.) then
	    pl = pm
	    el = em
         elseif(em.eq.0.) then
	    sns = sm
	    tns = tm
	    pns = pm
	    isuccess = 1
         end if

         if(isuccess.eq.0) then
	    if(abs(em).le.5.d-5.and.abs(pu-pl).le.5.d-3) then
               sns = sm
               tns = tm
               pns = pm
               isuccess = 1
	    elseif(iter.le.20) then
               isuccess = 0
	    else
               print *, 'WARNING 1 in e-solve.f'
               print *, iter,'  em',abs(em),'  dp',pl,pu,abs(pu-pl)
               sns = -99.0
               tns = -99.0
               pns = -99.0
               isuccess = 1
	    end if
         end if

      end do



      return
      
      end


      subroutine gamma_n(s,t,p,n,along,alat,gamma,dg_lo,dg_hi)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:
ccc   Label a cast of hydrographic data at a specified 
ccc   location with neutral density
ccc   
ccc   PRECISION:     	Single
ccc   
ccc   INPUT:
ccc   s(n)        array of cast salinities
ccc   t(n)        array of cast in situ temperatures
ccc   p(n)        array of cast pressures
ccc   n           length of cast (n=1 for single bottle)
ccc   along       longitude of cast (0-360)
ccc   alat        latitude of cast (-80,64)
ccc   
ccc   OUTPUT:
ccc   gamma(n)    array of cast gamma values
ccc   dg_lo(n)    array of gamma lower error estimates
ccc   dg_hi(n)    array of gamma upper error estimates
ccc   
ccc   NOTE:
ccc   -99.0 denotes algorithm failed
ccc   -99.1 denotes input data is outside
ccc   the valid range of the present
ccc   equation of state
ccc   
ccc   UNITS:
ccc   salinity    psu (IPSS-78)
ccc   temperature degrees C (IPTS-68)
ccc   pressure    db
ccc   gamma       kg m-3
ccc   
ccc   
ccc   AUTHOR:        	David Jackett
ccc   
ccc   CREATED:       	July 1993
ccc   
ccc   REVISION:      	3.1     23/1/97
ccc   
ccc   
ccc   
      parameter(nx=90,ny=45,nz=33,ndx=4,ndy=4)

      implicit real (a-h,o-z)

      integer*4 ioce,iocean0(2,2),n0(2,2)

      dimension s(n),t(n),p(n),gamma(n),dg_lo(n),dg_hi(n)
      dimension along0(2),alat0(2)
      dimension s0(nz,2,2),t0(nz,2,2),p0(nz),gamma0(nz,2,2),a0(nz,2,2)

      dimension gwij(4),wtij(4)

      external indx

      save

      data pr0/0.0/, dgamma_0/0.0005/, dgw_max/0.3/

ccc   
ccc   detect error conditions
ccc   

      if(along.lt.0.0) then
         along = along+360.0
         ialtered = 1
      elseif(along.eq.360.0) then
         along = 0.0
         ialtered = 2
      else
         ialtered = 0
      end if

      if(along.lt.0.0.or.along.gt.360.0.or.
     &     alat.lt.-90.0.or.alat.gt.90.0) then
ccc     &     alat.lt.-80.0.or.alat.gt.64.0) then
         print *, 'ERROR 1 in gamma-n.f : out of oceanographic range'
         print *
         stop
      end if


      do k = 1,n
         if(s(k).lt.0.0.or.s(k).gt.42.0.or.
     &        t(k).lt.-2.5.or.t(k).gt.40.0.or.
     &        p(k).lt.0.0.or.p(k).gt.10000.0) then
            gamma(k) = -99.1
            dg_lo(k) = -99.1
            dg_hi(k) = -99.1
         else
            gamma(k) = 0.0
            dg_lo(k) = 0.0
            dg_hi(k) = 0.0
         end if
      end do


ccc   
ccc   read records from the netCDF data file
ccc   

      call read_nc(along,alat,s0,t0,p0,gamma0,a0,n0,
     &     along0,alat0,iocean0)


ccc   
ccc   find the closest cast
ccc   

      dist2_min = 1.e10

      do j0 = 1,2
         do i0 = 1,2

            if(n0(i0,j0).ne.0) then
               dist2 = (along0(i0)-along)*(along0(i0)-along) + 
     &              (alat0(j0)-alat)*(alat0(j0)-alat)
               if(dist2.lt.dist2_min) then
                  i_min = i0
                  j_min = j0
                  dist2_min = dist2
               end if
            end if

         end do
      end do

      ioce = iocean0(i_min,j_min)


ccc   
ccc   label the cast
ccc   

      dx = abs(mod(along,dble(ndx)))
      dy = abs(mod(alat+80.0,dble(ndy)))
      rx = dx/dble(ndx)
      ry = dy/dble(ndy)

      do k = 1,n
         if(gamma(k).ne.-99.1) then

            thk = theta(s(k),t(k),p(k),pr0)

            dgamma_1 = 0.0
            dgamma_2_l = 0.0
            dgamma_2_h = 0.0

            wsum = 0.0

            nij = 0


ccc   
ccc   average the gammas over the box
ccc   

            do j0 = 1,2
               do i0 = 1,2
                  if(n0(i0,j0).ne.0) then

                     if(j0.eq.1) then
                        if(i0.eq.1) then
                           wt = (1.-rx)*(1.-ry)
                        elseif(i0.eq.2) then
                           wt = rx*(1-ry)
                        end if
                     elseif(j0.eq.2) then
                        if(i0.eq.1) then
                           wt = (1.-rx)*ry
                        elseif(i0.eq.2) then
                           wt = rx*ry
                        end if
                     end if

                     wt = wt+1.e-6

                     call ocean_test(along,alat,ioce,along0(i0),alat0(j0),
     &                    iocean0(i0,j0),p(k),itest)

                     if(itest.eq.0) wt = 0.0

                     call depth_ns(s0(1,i0,j0),t0(1,i0,j0),p0,n0(i0,j0),
     &                    s(k),t(k),p(k),sns,tns,pns)

                     if(pns.gt.-99.) then

                        call indx(p0,n0(i0,j0),pns,kns)
                        call gamma_qdr(p0(kns),gamma0(kns,i0,j0),a0(kns,i0,j0),
     &                       p0(kns+1),gamma0(kns+1,i0,j0),pns,gw)


ccc   
ccc   error bars
ccc   
                        call gamma_errors(s0(1,i0,j0),t0(1,i0,j0),p0,
     &                       gamma0(1,i0,j0),
     &                       a0(1,i0,j0),n0(i0,j0),along0(i0),alat0(j0),
     &                       s(k),t(k),p(k),sns,tns,pns,kns,
     &                       gw,g1_err,g2_l_err,g2_h_err)

                     elseif(pns.eq.-99.) then

                        call goor(s0(1,i0,j0),t0(1,i0,j0),p0,
     &                       gamma0(1,i0,j0),n0(i0,j0),s(k),t(k),p(k),
     &                       gw,g1_err,g2_l_err,g2_h_err)

ccc   
ccc   adjust weight for gamma extrapolation
ccc   

                        if(gw.gt.gamma0(n0(i0,j0),i0,j0)) then
                           rw = min(dgw_max,gw-gamma0(n0(i0,j0),i0,j0))/dgw_max
                           wt = (1-rw)*wt
                        end if

                     else
                        gw = 0.0
                        g1_err = 0.0
                        g2_l_err = 0.0
                        g2_h_err = 0.0
                     end if

                     if(gw.gt.0.) then
                        gamma(k) = gamma(k)+wt*gw
                        dgamma_1 = dgamma_1+wt*g1_err
                        dgamma_2_l = max(dgamma_2_l,g2_l_err)
                        dgamma_2_h = max(dgamma_2_h,g2_h_err)
                        wsum = wsum+wt
                        nij = nij+1
                        wtij(nij) = wt
                        gwij(nij) = gw
                     end if

                  end if
               end do
            end do


ccc   
ccc   the average
ccc   

            if(wsum.ne.0.0) then

               gamma(k) = gamma(k)/wsum
               dgamma_1 = dgamma_1/wsum


ccc   
ccc   the gamma errors
ccc   

               dgamma_3 = 0.0
               do ij = 1,nij
                  dgamma_3 = dgamma_3+wtij(ij)*abs(gwij(ij)-gamma(k))
               end do
               dgamma_3 = dgamma_3/wsum

               dg_lo(k) = max(dgamma_0,dgamma_1,dgamma_2_l,dgamma_3)
               dg_hi(k) = max(dgamma_0,dgamma_1,dgamma_2_h,dgamma_3)

            else

               gamma(k) = -99.0
               dg_lo(k) = -99.0
               dg_hi(k) = -99.0

            end if

         end if
      end do


      if(ialtered.eq.1) then
         along = along-360.0
      elseif(ialtered.eq.2) then
         along = 360.0
      end if




      return
      end


      subroutine gamma_errors(s,t,p,gamma,a,n,along,alat,
     &     s0,t0,p0,sns,tns,pns,kns,
     &     gamma_ns,pth_error,scv_l_error,scv_h_error)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :		Find the p-theta and the scv errors associated 
ccc   with the basic neutral surface calculation
ccc   
ccc   PRECISION :			Real
ccc   
ccc   INPUT :				s(n)		array of Levitus cast salinities
ccc   t(n)		array of cast in situ temperatures
ccc   p(n)		array of cast pressures
ccc   gamma(n)	array of cast neutral densities
ccc   a(n)		array of cast quadratic coefficients
ccc   n		length of cast
ccc   along		longitude of Levitus cast
ccc   alat		latitude of Levitus cast
ccc   s0		bottle salinity
ccc   t0		bottle temperature
ccc   p0		bottle pressure
ccc   sns		salinity of neutral surface on cast
ccc   tns		temperature of neutral surface on cast
ccc   pns		pressure of neutral surface on cast
ccc   kns		index of neutral surface on cast
ccc   gamma_ns	gamma value of neutral surface on cast
ccc   
ccc   OUTPUT :			pth_error	p-theta gamma error bar
ccc   scv_l_error	lower scv gamma error bar
ccc   scv_h_error	upper scv gamma error bar
ccc   
ccc   UNITS :				salinity	psu (IPSS-78)
ccc   temperature	degrees C (IPTS-68)
ccc   pressure	db
ccc   gamma		kg m-3
ccc   
ccc   
ccc   AUTHOR :			David Jackett
ccc   
ccc   CREATED :			March 1995
ccc   
ccc   REVISION :			1.1		9/3/95
ccc   
ccc   
ccc   
      parameter(nscv_max=50)

      implicit real(a-h,o-z)

      dimension s(n),t(n),p(n),gamma(n),a(n)

      dimension sscv_m(nscv_max),tscv_m(nscv_max),pscv_m(nscv_max)


      data pr0/0.0/, Tb/2.7e-8/, gamma_limit/26.845/, test_limit/0.1/



ccc   
ccc   p-theta error
ccc   

      th0 = theta(s0,t0,p0,pr0)
      thns = theta(sns,tns,pns,pr0)

      sdum = svan(sns,tns,pns,sig_ns)
      rho_ns = 1000+sig_ns

      call sig_vals(s(kns),t(kns),p(kns),s(kns+1),t(kns+1),p(kns+1),
     &     sig_l,sig_h)

      b = (gamma(kns+1)-gamma(kns))/(sig_h-sig_l)

      dp = pns-p0
      dth = thns-th0

      pth_error = rho_ns*b*Tb*abs(dp*dth)/6


ccc   
ccc   scv error
ccc   

      scv_l_error = 0.0
      scv_h_error = 0.0

      if(alat.le.-60.0.or.gamma(1).ge.gamma_limit) then

         drldp = (sig_h-sig_l)/(rho_ns*(p(kns+1)-p(kns)))

         test = Tb*dth/drldp


c     c
c     c		approximation
c     c

         if(abs(test).le.test_limit) then
            
	    if(dp*dth.ge.0.0) then
               scv_h_error = (3*pth_error)/(1.0-test)
	    else
               scv_l_error = (3*pth_error)/(1.0-test)
	    end if

         else


c     c
c     c		explicit scv solution, when necessary
c     c

	    call depth_scv(s,t,p,n,s0,t0,p0,sscv_m,tscv_m,pscv_m,nscv)

	    if(nscv.eq.0) then

               continue

	    else

               if(nscv.eq.1) then

                  pscv = pscv_m(1)

               else

                  pscv_mid = pscv_m((1+nscv)/2)

                  if(p0.le.pscv_mid) then
                     pscv = pscv_m(1)
                  else
                     pscv = pscv_m(nscv)
                  end if

               end if

               call indx(p,n,pscv,kscv)
               call gamma_qdr(p(kscv),gamma(kscv),a(kscv),
     &              p(kscv+1),gamma(kscv+1),pscv,gamma_scv)

               if(pscv.le.pns) then
                  scv_l_error = gamma_ns-gamma_scv
               else
                  scv_h_error = gamma_scv-gamma_ns
               end if

	    end if

         end if

      else

         continue

      end if


ccc   
ccc   check for positive gamma errors
ccc   

      if(pth_error.lt.0.0.or.
     &     scv_l_error.lt.0.0.or.
     &     scv_h_error.lt.0.0) then

         stop 'ERROR 1 in gamma-errors: negative scv error'

      end if



      return
      end


      subroutine get_lunit(lun)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Find the first FORTRAN logical unit (>=20) 
ccc   which is available for writing
ccc   
ccc   PRECISION :		Real
ccc   
ccc   OUTPUT :		lun		- available logical unit
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		October 1994
ccc   
ccc   REVISION :		1.2		2/12/94
ccc   
ccc   
ccc   

      implicit real(a-h,o-z)

      integer lun

      logical lv

      data lun0/20/, lun1/70/



      ifound = 0
      lun = lun0

      do while (lun.le.lun1.and.ifound.eq.0)

         inquire(unit=lun,opened=lv)

         if(lv) then
	    lun = lun+1
         else
	    ifound = 1
         end if

      end do

      if(ifound.eq.0) stop 'ERROR 1 in get-lun.f'



      return
      end


      subroutine goor(s,t,p,gamma,n,sb,tb,pb,
     &     gammab,g1_err,g2_l_err,g2_h_err)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:    Extend a cast of hydrographic data so that 
ccc   a bottle outside the gamma range of the cast 
ccc   can be labelled with the neutral density variable
ccc   
ccc   PRECISION:      Real
ccc   
ccc   INPUT:          s(n)        array of cast salinities
ccc   t(n)        array of cast in situ temperatures
ccc   p(n)        array of cast pressures
ccc   gamma(n)    array of cast gammas
ccc   n       length of cast
ccc   sb      bottle salinity
ccc   tb      bottle temperature
ccc   pb      bottle pressure
ccc   
ccc   OUTPUT:         gammab      bottle gamma value
ccc   g1_err      bottle Type i error estimate
ccc   g2_l_err    bottle Type ii lower error estimate
ccc   g2_h_err    bottle Type ii upper error estimate
ccc   
ccc   UNITS:          salinity    psu (IPSS-78)
ccc   temperature degrees C (IPTS-68)
ccc   pressure    db
ccc   gamma       kg m-3
ccc   
ccc   
ccc   AUTHOR:         David Jackett
ccc   
ccc   CREATED:        June 1993
ccc   
ccc   REVISION:       1.2     2/11/94
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)

      dimension s(n),t(n),p(n),gamma(n)

      data delt_b/-0.1/, delt_t/0.1/, slope/-0.14/
      data    pr0/0.0/, Tbp/2.7e-8/



ccc   
ccc   determine if its bottom data
ccc   

      pmid = (p(n)+pb)/2.0
      
      sd = svan(s(n),theta(s(n),t(n),p(n),pmid),pmid,sigma)

      sd = svan(sb,theta(sb,tb,pb,pmid),pmid,sigb)

ccc   
ccc   a bottom extension
ccc   

      if(sigb.gt.sigma) then

c     c
c     c          extend the cast data till it is denser
c     c

         n_sth = 0
         s_new = s(n)
         t_new = t(n)
         e_new = sigma-sigb

         do while (sigma.lt.sigb)
            s_old = s_new
            t_old = t_new
            e_old = e_new
            n_sth = n_sth+1
            s_new = s(n)+n_sth*delt_b*slope
            t_new = t(n)+n_sth*delt_b
            sd = svan(s_new,theta(s_new,t_new,p(n),pmid),pmid,sigma)
            e_new = sigma-sigb
         end do

c     c
c     c          find the salinity and temperature with 
c     c          the same neutral density
c     c

         if(sigma.eq.sigb) then
            sns = s_new
            tns = t_new
         else
            call goor_solve(s_old,t_old,e_old,s_new,
     &           t_new,e_new,p(n),
     &           sb,tb,pb,sigb,sns,tns)
         end if

c     c
c     c          now compute the new gamma value
c     c

         call sig_vals(s(n-1),t(n-1),p(n-1),s(n),t(n),p(n),sigl,sigu)
         bmid = (gamma(n)-gamma(n-1))/(sigu-sigl)

         sd = svan(s(n),t(n),p(n),sigl)
         sd = svan(sns,tns,p(n),sigu)

         gammab = gamma(n)+bmid*(sigu-sigl)

         pns = p(n)

      else

ccc   
ccc   determine if its top data
ccc   

         pmid = (p(1)+pb)/2.0

         sd = svan(s(1),theta(s(1),t(1),p(1),pmid),pmid,sigma)

         sd = svan(sb,theta(sb,tb,pb,pmid),pmid,sigb)

ccc   
ccc   a top extension
ccc   

         if(sigb.lt.sigma) then

c     c
c     c          extend the cast data till it is lighter
c     c

            n_sth = 0
            s_new = s(1)
            t_new = t(1)
            e_new = sigma-sigb
            do while (sigma.gt.sigb)
               s_old = s_new
               t_old = t_new
               e_old = e_new
               n_sth = n_sth+1
               s_new = s(1)
               t_new = t(1)+n_sth*delt_t
               sd = svan(s_new,
     &              theta(s_new,t_new,p(1),pmid),pmid,sigma)
               e_new = sigma-sigb
            end do

c     c
c     c          find the salinity and temperature with 
c     c          the same neutral density
c     c

            if(sigma.eq.sigb) then
               sns = s_new
               tns = t_new
            else
               call goor_solve(s_new,t_new,e_new,
     &              s_old,t_old,e_old,p(1),
     &              sb,tb,pb,sigb,sns,tns)
            end if

c     c
c     c          now compute the new gamma value
c     c

            call sig_vals(s(1),t(1),p(1),s(2),t(2),p(2),sigl,sigu)
            bmid = (gamma(2)-gamma(1))/(sigu-sigl)

            sd = svan(sns,tns,p(1),sigl)
            sd = svan(s(1),t(1),p(1),sigu)

            gammab = gamma(1)-bmid*(sigu-sigl)

            pns = p(1)

ccc   
ccc   neither top nor bottom extension
ccc   

         else

            stop 'ERROR 1 in gamma-out-of-range.f'

         end if

      end if


ccc   
ccc   error estimate
ccc   


      thb = theta(sb,tb,pb,pr0)
      thns = theta(sns,tns,pns,pr0)

      sdum = svan(sns,tns,pns,sig_ns)
      rho_ns = 1000+sig_ns

      b = bmid

      dp = pns-pb
      dth = thns-thb

      g1_err = rho_ns*b*Tbp*abs(dp*dth)/6

      g2_err = rho_ns*b*Tbp*dp*dth/2

      if(g2_err.le.0.0) then
         g2_l_err = -g2_err
         g2_h_err = 0.0
      else
         g2_l_err = 0.0
         g2_h_err = g2_err
      end if



      return
      end


      subroutine goor_solve(sl,tl,el,su,tu,eu,p,s0,t0,p0,sigb,sns,tns)
ccc   
ccc   
ccc   
ccc   DESCRIPTION: 	Find the intersection of a potential density surface 
ccc   between two bottles using a bisection method
ccc   
ccc   PRECISION: 		Real
ccc   
ccc   INPUT:			sl, su		bottle salinities
ccc   tl, tu		bottle in situ temperatures
ccc   el, eu		bottle e values
ccc   p			bottle pressures (the same)
ccc   s0			emanating bottle salinity
ccc   t0			emanating bottle in situ temperature
ccc   p0			emanating bottle pressure
ccc   
ccc   OUTPUT:			sns			salinity of the neutral surface
ccc   intersection with the bottle pair
ccc   tns			in situ temperature of the intersection
ccc   
ccc   
ccc   UNITS:			salinities		psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures		db
ccc   
ccc   
ccc   AUTHOR:			David Jackett
ccc   
ccc   CREATED:		June 1993
ccc   
ccc   REVISION:		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)



      rl = 0.
      ru = 1.

      pmid = (p+p0)/2.0

      thl = theta(sl,tl,p,pmid)
      thu = theta(su,tu,p,pmid)

      iter = 0
      isuccess = 0

      do while(isuccess.eq.0)

         iter = iter+1

         rm = (rl+ru)/2

         sm = sl+rm*(su-sl)
         thm = thl+rm*(thu-thl)

         tm = theta(sm,thm,pmid,p)

         sd = svan(sm,thm,pmid,sigma)

         em = sigma-sigb

         if(el*em.lt.0.) then
	    ru = rm
	    eu = em
         elseif(em*eu.lt.0.) then
	    rl = rm
	    el = em
         elseif(em.eq.0.) then
	    sns = sm
	    tns = tm
	    isuccess = 1
         end if

         if(isuccess.eq.0) then
	    if(abs(em).le.5.e-5.and.abs(ru-rl).le.5.e-3) then
               sns = sm
               tns = tm
               isuccess = 1
	    elseif(iter.le.20) then
               isuccess = 0
	    else
               print *, 'WARNING 1 in goor-solve.f'
               sns = sm
               tns = tm
               isuccess = 1
	    end if
         end if

      end do



      return
      
      end


      subroutine gamma_qdr(pl,gl,a,pu,gu,p,gamma)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Evaluate the quadratic gamma profile at a pressure
ccc   between two bottles
ccc   
ccc   PRECISION :		Real
ccc   
ccc   INPUT :			pl, pu		bottle pressures
ccc   gl, gu		bottle gamma values
ccc   a		quadratic coefficient
ccc   p		pressure for gamma value
ccc   
ccc   OUTPUT :		gamma		gamma value at p
ccc   
ccc   UNITS :			pressure	db
ccc   gamma		kg m-3
ccc   a		kg m-3
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		June 1993
ccc   
ccc   REVISION :		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)



      p1 = (p-pu)/(pu-pl)
      p2 = (p-pl)/(pu-pl)

      gamma = (a*p1+(gu-gl))*p2+gl



      return
      end


      subroutine indx(x,n,z,k)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:	Find the index of a real number in a
ccc   monotonically increasing real array
ccc   
ccc   PRECISION:		Real
ccc   
ccc   INPUT:			x		array of increasing values
ccc   n		length of array
ccc   z		real number
ccc   
ccc   OUTPUT:			k		index k - if x(k) <= z < x(k+1), or
ccc   n-1     		- if z = x(n)
ccc   
ccc   
ccc   AUTHOR:			David Jackett
ccc   
ccc   CREATED:		June 1993
ccc   
ccc   REVISION:		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)

      dimension x(n)



      if(x(1).lt.z.and.z.lt.x(n)) then

         kl=1
         ku=n

         do while (ku-kl.gt.1)
	    km=(ku+kl)/2
	    if(z.gt.x(km))then
               kl=km
	    else
               ku=km
	    endif
         end do

         k=kl

         if(z.eq.x(k+1)) k = k+1

      else

         if(z.eq.x(1)) then
	    k = 1
         elseif(z.eq.x(n)) then
	    k = n-1
         else
	    print *, 'ERROR 1 in indx.f : out of range'
	    print *, z,n,x
         end if

      end if



      return
      end


      subroutine neutral_surfaces(s,t,p,gamma,n,glevels,ng,
     &     sns,tns,pns,dsns,dtns,dpns)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:
ccc   For a cast of hydrographic data which has been 
ccc   labelled with the neutral density variable gamma,
ccc   find the salinities, temperatures and pressures
ccc   on ng specified neutral density surfaces.
ccc   
ccc   PRECISION:      Real
ccc   
ccc   INPUT:          
ccc   s(n)        array of cast salinities
ccc   t(n)        array of cast in situ temperatures
ccc   p(n)        array of cast pressures
ccc   gamma(n)    array of cast gamma values
ccc   n           length of cast
ccc   glevels(ng) array of neutral density values
ccc   ng          number of neutral density surfaces
ccc   
ccc   OUTPUT:
ccc   sns(ng)     salinity on the neutral density surfaces
ccc   tns(ng)     in situ temperature on the surfaces
ccc   pns(ng)     pressure on the surfaces
ccc   dsns(ng)    surface salinity errors
ccc   dtns(ng)    surface temperature errors
ccc   dpns(ng)    surface pressure errors
ccc   
ccc   NOTE:
ccc   sns, tns and pns values of -99.0
ccc   denotes under or outcropping
ccc   
ccc   non-zero dsns, dtns and dpns values
ccc   indicates multiply defined surfaces,
ccc   and file 'ns-multi.dat' contains
ccc   information on the multiple solutions
ccc   
ccc   UNITS:
ccc   salinity    psu (IPSS-78)
ccc   temperature degrees C (IPTS-68)
ccc   pressure    db
ccc   gamma       kg m-3
ccc   
ccc   
ccc   AUTHOR:         David Jackett
ccc   
ccc   CREATED:        July 1993
ccc   
ccc   REVISION:       2.1     17/5/95
ccc   
ccc   
ccc   
      parameter(nint_max=50)

      implicit real(a-h,o-z)

      integer int(nint_max)

      dimension s(n),t(n),p(n),gamma(n)
      dimension glevels(ng),sns(ng),tns(ng),pns(ng)
      dimension dsns(ng),dtns(ng),dpns(ng)

      double precision alfa_l,beta_l,alfa_u,beta_u,alfa_mid,beta_mid
      double precision rhomid,thl,thu,dels,delth,pl,pu,delp,delp2,bmid
      double precision a,b,c,q

      data n2/2/, pr0/0.0/, ptol/1.0e-3/




ccc   
ccc   detect error condition
ccc   

      in_error = 0
      do k = 1,n
         if(gamma(k).le.0.d0) in_error = 1
      end do
      
      if(in_error.eq.1)
     &     stop '\nERROR 1 in neutral-surfaces.f : missing gamma value'


ccc   
ccc   loop over the surfaces
ccc   

c     call system('rm -f ns-multi.dat')

      ierr = 0

      do ig = 1,ng


ccc   
ccc   find the intervals of intersection
ccc   

         nint = 0

         do k = 1,n-1

            gmin = min(gamma(k),gamma(k+1))
            gmax = max(gamma(k),gamma(k+1))

            if(gmin.le.glevels(ig).and.glevels(ig).le.gmax) then
               nint = nint+1
               if(nint.gt.nint_max) stop 'ERROR 2 in neutral-surfaces.f'
               int(nint) = k
            end if

         end do


ccc   
ccc   find point(s) of intersection
ccc   

         if(nint.eq.0) then

            sns(ig) = -99.0
            tns(ig) = -99.0
            pns(ig) = -99.0
            dsns(ig) = 0.0
            dtns(ig) = 0.0
            dpns(ig) = 0.0

         else


ccc   
ccc   choose the central interval
ccc   

            if(mod(nint,2).eq.0.and.int(1).gt.n/2) then
               int_middle = (nint+2)/2
            else
               int_middle = (nint+1)/2
            end if


ccc   
ccc   loop over all intersections
ccc   

            do i_int = 1,nint

               k = int(i_int)

ccc   
ccc   coefficients of a quadratic for gamma
ccc   

               pmid = (p(k)+p(k+1))/2.

               call eosall(s(k),t(k),p(k),thdum,sthdum,
     &              alfa,beta,gdum,sdum)
               alfa_l = alfa
               beta_l = beta
               call eosall(s(k+1),t(k+1),p(k+1),thdum,sthdum,
     &              alfa,beta,gdum,sdum)
               alfa_u = alfa
               beta_u = beta

               alfa_mid = (alfa_l+alfa_u)/2.0
               beta_mid = (beta_l+beta_u)/2.0

               call stp_interp(s(k),t(k),p(k),n2,smid,tmid,pmid)

               sd = svan(smid,tmid,pmid,sigmid)
               rhomid = 1000.+sigmid

               thl = theta(s(k),t(k),p(k),pr0)
               thu = theta(s(k+1),t(k+1),p(k+1),pr0)

               dels = s(k+1)-s(k)
               delth = thu-thl

               pl = p(k)
               pu = p(k+1)
               delp = pu-pl
               delp2 = delp*delp

               bden = rhomid*(beta_mid*dels-alfa_mid*delth)

               if(abs(bden).le.1.d-6) bden = 1.d-6

               bmid = (gamma(k+1)-gamma(k))/bden
     &              

c     c
c     c          coefficients
c     c

               a = dels*(beta_u-beta_l)-delth*(alfa_u-alfa_l)
               a = (a*bmid*rhomid)/(2*delp2)

               b = dels*(pu*beta_l-pl*beta_u) - delth*(pu*alfa_l-pl*alfa_u)
               b = (b*bmid*rhomid)/delp2

               c = dels*(beta_l*(pl-2.*pu)+beta_u*pl) -
     &              delth*(alfa_l*(pl-2.*pu)+alfa_u*pl) 
               c = gamma(k) + (bmid*rhomid*pl*c)/(2*delp2)
               c = c - glevels(ig)

ccc   
ccc   solve the quadratic
ccc   

               if(a.ne.0.d0.and.bden.ne.1.d-6) then

                  q = -(b+sign(1.d0,b)*sqrt(b*b-4*a*c))/2.0

                  pns1 = q/a
                  pns2 = c/q

                  if(pns1.ge.p(k)-ptol.and.pns1.le.p(k+1)+ptol) then
                     pns(ig) = min(p(k+1),max(pns1,p(k)))
                  elseif(pns2.ge.p(k)-ptol.and.pns2.le.p(k+1)+ptol) then
                     pns(ig) = min(p(k+1),max(pns2,p(k)))
                  else
                     stop 'ERROR 3 in neutral-surfaces.f'
                  end if

               else
                  
                  rg = (glevels(ig)-gamma(k))/(gamma(k+1)-gamma(k))
                  pns(ig) = p(k)+rg*(p(k+1)-p(k))

               end if

               call stp_interp(s,t,p,n,sns(ig),tns(ig),pns(ig))


ccc   
ccc   write multiple values to file
ccc   

               if(nint.gt.1) then

                  if(ierr.eq.0) then
                     ierr = 1
c     call system('rm -f ns-multi.dat')
                     call get_lunit(lun)
                     open(lun,file='ns-multi.dat',status='unknown')
                  end if

                  if(i_int.eq.1) write(lun,*) ig,nint

                  write(lun,*) sns(ig),tns(ig),pns(ig)


ccc   
ccc   find median values and errors
ccc   

                  if(i_int.eq.1) then
                     sns_top = sns(ig)
                     tns_top = tns(ig)
                     pns_top = pns(ig)
                  elseif(i_int.eq.int_middle) then
                     sns_middle = sns(ig)
                     tns_middle = tns(ig)
                     pns_middle = pns(ig)
                  elseif(i_int.eq.nint) then
                     if((pns_middle-pns_top).gt.(pns(ig)-pns_middle)) then
                        dsns(ig) = sns_middle-sns_top
                        dtns(ig) = tns_middle-tns_top
                        dpns(ig) = pns_middle-pns_top
                     else
                        dsns(ig) = sns(ig)-sns_middle
                        dtns(ig) = tns(ig)-tns_middle
                        dpns(ig) = pns(ig)-pns_middle
                     end if
                     sns(ig) = sns_middle
                     tns(ig) = tns_middle
                     pns(ig) = pns_middle
                  end if

               else

                  dsns(ig) = 0.0
                  dtns(ig) = 0.0
                  dpns(ig) = 0.0

               end if

            end do

         end if


      end do


      if(ierr.eq.1) close(lun)




      return
      end


      subroutine ocean_test(x1,y1,io1,x2,y2,io2,z,itest)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:	Test whether two locations are connected by ocean
ccc   
ccc   PRECISION:		Real
ccc   
ccc   INPUT:			x1		longitude of first location
ccc   y1		latitude of first location
ccc   io1		ocean of first location
ccc   x2		longitude of second location
ccc   y2		latitude of second location
ccc   io2		ocean of second location
ccc   z		depth of connection
ccc   
ccc   OUTPUT:			itest		success of connection
ccc   
ccc   
ccc   AUTHOR:			David Jackett
ccc   
ccc   CREATED:		June 1994
ccc   
ccc   REVISION:		1.1		7/7/94
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)

      integer*4 io1,io2

      dimension x_js(3),y_js(3)

      data x_js/129.87, 140.37, 142.83/
      data y_js/ 32.75,  37.38,  53.58/



      y = (y1+y2)/2



ccc   
ccc   same ocean talks
ccc   

      if(io1.eq.io2) then

         itest = 1
         return
         
      elseif(y.le.-20.) then

ccc   
ccc   land of South America doesn't talk
ccc   

         if(y.ge.-48..and.(io1*io2).eq.12) then
	    itest = 0

ccc   
ccc   everything else south of -20 talks
ccc   

         else
	    itest = 1
         end if

ccc   
ccc   Pacific talks
ccc   

      elseif((io1.eq.1.or.io1.eq.2).and.
     &        (io2.eq.1.or.io2.eq.2)) then
         itest = 1

ccc   
ccc   Indian talks
ccc   

      elseif((io1.eq.3.or.io1.eq.4).and.
     &        (io2.eq.3.or.io2.eq.4)) then
         itest = 1

ccc   
ccc   Atlantic talks
ccc   

      elseif((io1.eq.5.or.io1.eq.6).and.
     &        (io2.eq.5.or.io2.eq.6)) then
         itest = 1

ccc   
ccc   Indonesian throughflow
ccc   

      elseif(io1*io2.eq.8.and.z.le.1200..and.
     &        x1.ge.124..and.x1.le.132..and.
     &        x2.ge.124..and.x2.le.132.) then
         itest = 1

ccc   
ccc   anything else doesn't
ccc   
      else
         itest = 0
      end if


ccc   
ccc   exclude Japan Sea from talking
ccc   

      if( (x_js(1).le.x1.and.x1.le.x_js(3).and.
     &     y_js(1).le.y1.and.y1.le.y_js(3)) .or. 

     &     (x_js(1).le.x2.and.x2.le.x_js(3).and.
     &     y_js(1).le.y2.and.y2.le.y_js(3)) ) then

      em1 = (y_js(2)-y_js(1))/(x_js(2)-x_js(1))
      c1 = y_js(1)-em1*x_js(1)

      em2 = (y_js(3)-y_js(2))/(x_js(3)-x_js(2))
      c2 = y_js(2)-em2*x_js(2)

      if((y1-em1*x1-c1).ge.0.0.and.(y1-em2*x1-c2).ge.0.0) then
         isj1 = 1
      else
         isj1 = 0
      end if

      if((y2-em1*x2-c1).ge.0.0.and.(y2-em2*x2-c2).ge.0.0) then
         isj2 = 1
      else
         isj2 = 0
      end if

      if(isj1.eq.isj2) then
         itest = 1
      else
         itest = 0
      end if

      end if

ccc   
ccc   exclude Antarctic tip
ccc   

      if(io1*io2.eq.12.and.y.lt.-60.) itest = 0



      return
      end


      subroutine read_nc(along,alat,s0,t0,p0,gamma0,a0,n0,
     &     along0,alat0,iocean0)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :   Read variables from the netcdf labelled data file 
ccc   
ccc   PRECISION:      Real
ccc   
ccc   INPUT :         along       longitude of record
ccc   alat        latitude of record
ccc   
ccc   OUTPUT :        s0(nz,2,2)  array of cast salinities
ccc   t0(nz,2,2)  array of cast in situ temperatures
ccc   p0(nz)      array of cast pressures
ccc   gamma0(nz,2,2)  array of cast gamma values
ccc   a0(nz,2,2)  array of cast a values
ccc   n0(2,2)     length of casts
ccc   along0(2)   array of cast longitudes
ccc   alat0(2)    array of cast latitudes
ccc   iocean0(2,2)    array of cast oceans
ccc   
ccc   UNITS :         salinity    psu (IPSS-78)
ccc   temperature degrees C (IPTS-68)
ccc   pressure    db
ccc   gamma       kg m-3
ccc   
ccc   
ccc   AUTHOR :        David Jackett
ccc   
ccc   CREATED :       July 1993
ccc   
ccc   REVISION :      1.3     15/11/94
ccc   
ccc   
ccc   


      parameter(nx=90,ny=45,nz=33,ndx=4,ndy=4)

      implicit real(a-h,o-z)

      integer*4 n(nx,ny),n0(2,2)
      integer*4 iocean(nx,ny),iocean0(2,2)

      real*4 along_s(nx),alat_s(ny)
      real*4 s0_s(nz,2,2),t0_s(nz,2,2),p0_s(nz)
      real*4 gamma0_s(nz,2,2),a0_s(nz,2,2)

      dimension along_d(nx),alat_d(ny),along0(2),alat0(2)
      dimension s0(nz,2,2),t0(nz,2,2),p0(nz),gamma0(nz,2,2),a0(nz,2,2)

      save along_d,alat_d,p0_s,n,iocean,i0,j0

      data i0/1/, j0/1/


      ilong(alng) = int(alng/ndx + 1)
      jlat(alt) = int((88+alt)/ndy + 1)


ccc   
ccc   only read when you have to
ccc   

      dx = along-along_d(i0)
      dy = alat-alat_d(j0)

      if(dx.lt.0.0.or.dx.ge.4.0.or.dy.lt.0.0.or.dy.ge.4.0.or.
     &     (i0.eq.1.and.j0.eq.1)) then

ccc   
ccc   read the 'llp.fdt' file
ccc   

         call get_lunit(lun)

         if(i0.eq.1.and.j0.eq.1) then

            open(lun,
     &file='OCNDATAPATH/llp.fdt',
     &status='old',form='unformatted')
            read(lun) along_s,alat_s,p0_s,n,iocean
            close(lun)
            
            do i = 1,nx
               along_d(i) = along_s(i)
            end do
            
            do j = 1,ny
               alat_d(j) = alat_s(j)
            end do

         end if

         do k = 1,nz
            p0(k) = p0_s(k)
         end do

         
ccc   
ccc   read the appropriate records from 'stga.fdt'
ccc   

         i0 = ilong(along)
         j0 = jlat(alat)

         if(i0.eq.nx+1) i0 = 1
         
         along0(1) = along_d(i0)
         alat0(1) = alat_d(j0)
         alat0(2) = alat0(1)+ndy
         
         open(lun,
     &file='OCNDATAPATH/stga.fdt',
     &status='old',access='direct',recl=528,form='unformatted')
         
         if(i0.lt.nx) then

            along0(2) = along0(1)+ndx

            irec = i0
            jrec = j0
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,1,1),k=1,nz),
     &           (t0_s(k,1,1),k=1,nz),
     &           (gamma0_s(k,1,1),k=1,nz),
     &           (a0_s(k,1,1),k=1,nz)

            irec = i0+1
            jrec = j0
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,2,1),k=1,nz),
     &           (t0_s(k,2,1),k=1,nz),
     &           (gamma0_s(k,2,1),k=1,nz),
     &           (a0_s(k,2,1),k=1,nz)
            
            irec = i0
            jrec = j0+1
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,1,2),k=1,nz),
     &           (t0_s(k,1,2),k=1,nz),
     &           (gamma0_s(k,1,2),k=1,nz),
     &           (a0_s(k,1,2),k=1,nz)
            
            irec = i0+1
            jrec = j0+1
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,2,2),k=1,nz),
     &           (t0_s(k,2,2),k=1,nz),
     &           (gamma0_s(k,2,2),k=1,nz),
     &           (a0_s(k,2,2),k=1,nz)
            
         elseif(i0.eq.nx) then

            along0(2) = 0.0
            
            irec = i0
            jrec = j0
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,1,1),k=1,nz),
     &           (t0_s(k,1,1),k=1,nz),
     &           (gamma0_s(k,1,1),k=1,nz),
     &           (a0_s(k,1,1),k=1,nz)

            irec = i0
            jrec = j0+1
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,1,2),k=1,nz),
     &           (t0_s(k,1,2),k=1,nz),
     &           (gamma0_s(k,1,2),k=1,nz),
     &           (a0_s(k,1,2),k=1,nz)

            irec = 1
            jrec = j0
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,2,1),k=1,nz),
     &           (t0_s(k,2,1),k=1,nz),
     &           (gamma0_s(k,2,1),k=1,nz),
     &           (a0_s(k,2,1),k=1,nz)

            irec = 1
            jrec = j0+1
            krec = irec+(jrec-1)*nx
            read(lun,rec=krec)  (s0_s(k,2,2),k=1,nz),
     &           (t0_s(k,2,2),k=1,nz),
     &           (gamma0_s(k,2,2),k=1,nz),
     &           (a0_s(k,2,2),k=1,nz)

         end if


ccc   
ccc   get the depth and ocean information
ccc   

         do j = 1,2
            do i = 1,2
               n0(i,j) = n(ilong(along0(i)),jlat(alat0(j)))
               iocean0(i,j) = iocean(ilong(along0(i)),jlat(alat0(j)))
            end do
         end do


ccc   
ccc   the data
ccc   

         do j = 1,2
            do i = 1,2
               do k = 1,nz
                  s0(k,i,j) = s0_s(k,i,j)
                  t0(k,i,j) = t0_s(k,i,j)
                  gamma0(k,i,j) = gamma0_s(k,i,j)
                  a0(k,i,j) = a0_s(k,i,j)
               end do
            end do
         end do

         close(lun)

      end if


      return
      end


      subroutine scv_solve(s,t,p,e,n,k,s0,t0,p0,sscv,tscv,pscv,iter)
ccc   
ccc   
ccc   
ccc   DESCRIPTION :	Find the zero of the v function using a 
ccc   bisection method
ccc   
ccc   PRECISION :		Real
ccc   
ccc   INPUT :			s(n)		array of cast salinities
ccc   t(n)		array of cast in situ temperatures
ccc   p(n)		array of cast pressures
ccc   e(n)		array of cast e values
ccc   n			length of cast
ccc   k			interval (k-1,k) contains the zero
ccc   s0			the bottle salinity
ccc   t0			the bottle in situ temperature
ccc   p0			the bottle pressure
ccc   
ccc   OUTPUT :		sscv		salinity of the scv surface
ccc   intersection with the cast
ccc   tscv		in situ temperature of the intersection
ccc   pscv		pressure of the intersection
ccc   
ccc   
ccc   UNITS :			salinities	psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures	db
ccc   
ccc   
ccc   AUTHOR :		David Jackett
ccc   
ccc   CREATED :		February 1995
ccc   
ccc   REVISION :		1.1		1/2/95
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)

      dimension s(n),t(n),p(n),e(n)

      data n2/2/


      
      pl = p(k-1)
      el = e(k-1)
      pu = p(k)
      eu = e(k)

      iter = 0
      isuccess = 0

      do while(isuccess.eq.0)

         iter = iter+1

         pm = (pl+pu)/2

         call stp_interp(s(k-1),t(k-1),p(k-1),n2,sm,tm,pm)

         sdum = svan(s0,theta(s0,t0,p0,pm),pm,sigl)
         sdum = svan(sm,tm,pm,sigu)
         em = sigu-sigl

         if(el*em.lt.0.) then
	    pu = pm
	    eu = em
         elseif(em*eu.lt.0.) then
	    pl = pm
	    el = em
         elseif(em.eq.0.) then
	    sscv = sm
	    tscv = tm
	    pscv = pm
	    isuccess = 1
         end if

         if(isuccess.eq.0) then
	    if(abs(em).le.5.d-5.and.abs(pu-pl).le.5.d-3) then
               sscv = sm
               tscv = tm
               pscv = pm
               isuccess = 1
	    elseif(iter.le.20) then
               isuccess = 0
	    else
               print *, 'WARNING 1 in scv-solve.f'
               print *, iter,'  em',abs(em),'  dp',pl,pu,abs(pu-pl)
               sscv = -99.0
               tscv = -99.0
               pscv = -99.0
               isuccess = 1
	    end if
         end if

      end do



      return
      
      end


      subroutine sig_vals(s1,t1,p1,s2,t2,p2,sig1,sig2)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:	Computes the sigma values of two neighbouring 
ccc   bottles w.r.t. the mid pressure
ccc   
ccc   PRECISION:		Real
ccc   
ccc   INPUT:			s1,s2		bottle salinities
ccc   t1,t2		bottle in situ temperatures
ccc   p1,p2		bottle pressures
ccc   
ccc   OUTPUT:			sig1,sig2	bottle potential density values
ccc   
ccc   UNITS:			salinity	psu (IPSS-78)
ccc   temperature	degrees C (IPTS-68)
ccc   pressure	db
ccc   density		kg m-3
ccc   
ccc   
ccc   AUTHOR:			David Jackett
ccc   
ccc   CREATED:		June 1993
ccc   
ccc   REVISION:		1.1		30/6/93
ccc   
ccc   
ccc   

      implicit real(a-h,o-z)



      pmid = (p1+p2)/2.0

      sd = svan(s1,theta(s1,t1,p1,pmid),pmid,sig1)

      sd = svan(s2,theta(s2,t2,p2,pmid),pmid,sig2)



      return
      end


      subroutine stp_interp(s,t,p,n,s0,t0,p0)
ccc   
ccc   
ccc   
ccc   DESCRIPTION:	Interpolate salinity and in situ temperature
ccc   on a cast by linearly interpolating salinity
ccc   and potential temperature
ccc   
ccc   PRECISION:		Real
ccc   
ccc   INPUT:			s(n)	array of cast salinities
ccc   t(n)	array of cast in situ temperatures
ccc   p(n)	array of cast pressures
ccc   n		length of cast
ccc   p0		pressure for which salinity and
ccc   in situ temperature are required
ccc   
ccc   OUTPUT:			s0			interpolated value of salinity
ccc   t0			interpolated value of situ temperature
ccc   
ccc   UNITS:			salinities		psu (IPSS-78)
ccc   temperatures	degrees C (IPTS-68)
ccc   pressures		db
ccc   
ccc   
ccc   AUTHOR:			David Jackett
ccc   
ccc   CREATED:		June 1993
ccc   
ccc   REVISION:		1.1		30/6/93
ccc   
ccc   
ccc   
      implicit real(a-h,o-z)
      
      dimension s(n),t(n),p(n)

      external indx

      data pr0/0.0/



      call indx(p,n,p0,k)

      r = (p0-p(k))/(p(k+1)-p(k))

      s0 = s(k) + r*(s(k+1)-s(k))

      thk = theta(s(k),t(k),p(k),pr0)

      th0 = thk + r*(theta(s(k+1),t(k+1),p(k+1),pr0)-thk)

      t0 = theta(s0,th0,pr0,p0)



      return
      end


      function svan(s,t,p0,sigma)
c     
c     modified rcm
c     ******************************************************
c     specific volume anomaly (steric anomaly) based on 1980 equation
c     of state for seawater and 1978 practical salinity scale.
c     references
c     millero, et al (1980) deep-sea res.,27a,255-264
c     millero and poisson 1981,deep-sea res.,28a pp 625-629.
c     both above references are also found in unesco report 38 (1981)
c     units:      
c     pressure        p0       decibars
c     temperature     t        deg celsius (ipts-68)
c     salinity        s        (ipss-78)
c     spec. vol. ana. svan     m**3/kg *1.0e-8
c     density ana.    sigma    kg/m**3
c     ******************************************************************
c     check value: svan=981.3021 e-8 m**3/kg.  for s = 40 (ipss-78) ,
c     t = 40 deg c, p0= 10000 decibars.
c     check value: sigma = 59.82037  kg/m**3 for s = 40 (ipss-78) ,
c     t = 40 deg c, p0= 10000 decibars.
c     *******************************************************
c     

      real p,t,s,sig,sr,r1,r2,r3,r4
      real a,b,c,d,e,a1,b1,aw,bw,k,k0,kw,k35
      real svan,p0,sigma,r3500,dr350,v350p,sva,dk,gam,pk,dr35p
      real dvan
c     equiv       
      equivalence (e,d,b1),(bw,b,r3),(c,a1,r2) 
      equivalence (aw,a,r1),(kw,k0,k)
c     ********************
c     data
      data r3500,r4/1028.1063,4.8314d-4/
      data dr350/28.106331/
c     r4 is refered to as  c  in millero and poisson 1981
c     convert pressure to bars and take square root salinity.
      p=p0/10.
      sr = sqrt(abs(s)) 
c     *********************************************************
c     pure water density at atmospheric pressure
c     bigg p.h.,(1967) br. j. applied physics 8 pp 521-537.
c     
      r1 = ((((6.536332d-9*t-1.120083d-6)*t+1.001685d-4)*t 
     x     -9.095290d-3)*t+6.793952d-2)*t-28.263737
c     seawater density atm press. 
c     coefficients involving salinity
c     r2 = a   in notation of millero and poisson 1981
      r2 = (((5.3875d-9*t-8.2467d-7)*t+7.6438d-5)*t-4.0899d-3)*t
     x     +8.24493d-1 
c     r3 = b  in notation of millero and poisson 1981
      r3 = (-1.6546d-6*t+1.0227d-4)*t-5.72466d-3
c     international one-atmosphere equation of state of seawater
      sig = (r4*s + r3*sr + r2)*s + r1 
c     specific volume at atmospheric pressure
      v350p = 1.0/r3500
      sva = -sig*v350p/(r3500+sig)
      sigma=sig+dr350
c     scale specific vol. anamoly to normally reported units
      svan=sva*1.0d+8
      if(p.eq.0.0) return
c     ******************************************************************
c     ******  new high pressure equation of state for seawater ********
c     ******************************************************************
c     millero, et al , 1980 dsr 27a, pp 255-264
c     constant notation follows article
c********************************************************
c     compute compression terms
      e = (9.1697d-10*t+2.0816d-8)*t-9.9348d-7
      bw = (5.2787d-8*t-6.12293d-6)*t+3.47718d-5
      b = bw + e*s
c     
      d = 1.91075d-4
      c = (-1.6078d-6*t-1.0981d-5)*t+2.2838d-3
      aw = ((-5.77905d-7*t+1.16092d-4)*t+1.43713d-3)*t 
     x     -0.1194975
      a = (d*sr + c)*s + aw 
c     
      b1 = (-5.3009d-4*t+1.6483d-2)*t+7.944d-2
      a1 = ((-6.1670d-5*t+1.09987d-2)*t-0.603459)*t+54.6746 
      kw = (((-5.155288d-5*t+1.360477d-2)*t-2.327105)*t 
     x     +148.4206)*t-1930.06
      k0 = (b1*sr + a1)*s + kw
c     evaluate pressure polynomial 
c     ***********************************************
c     k equals the secant bulk modulus of seawater
c     dk=k(s,t,p)-k(35,0,p)
c     k35=k(35,0,p)
c     ***********************************************
      dk = (b*p + a)*p + k0
      k35  = (5.03217d-5*p+3.359406)*p+21582.27
      gam=p/k35
      pk = 1.0 - gam
      sva = sva*pk + (v350p+sva)*p*dk/(k35*(k35+dk))
c     scale specific vol. anamoly to normally reported units
      svan=sva*1.0d+8
      v350p = v350p*pk
c     ****************************************************
c     compute density anamoly with respect to 1000.0 kg/m**3
c     1) dr350: density anamoly at 35 (ipss-78), 0 deg. c and 0 decibars
c     2) dr35p: density anamoly 35 (ipss-78), 0 deg. c ,  pres. variation
c     3) dvan : density anamoly variations involving specfic vol. anamoly
c     ********************************************************************
c     check value: sigma = 59.82037  kg/m**3 for s = 40 (ipss-78),
c     t = 40 deg c, p0= 10000 decibars.
c     *******************************************************
      dr35p=gam/v350p
      dvan=sva/(v350p*(v350p+sva))
      sigma=dr350+dr35p-dvan
      return  
      end     


      function theta(s,t0,p0,pr)
c     
c     ***********************************
c     to compute local potential temperature at pr
c     using bryden 1973 polynomial for adiabatic lapse rate
c     and runge-kutta 4-th order integration algorithm.
c     ref: bryden,h.,1973,deep-sea res.,20,401-408
c     fofonoff,n.,1977,deep-sea res.,24,489-491
c     units:      
c     pressure        p0       decibars
c     temperature     t0       deg celsius (ipts-68)
c     salinity        s        (ipss-78)
c     reference prs   pr       decibars
c     potential tmp.  theta    deg celsius 
c     checkvalue: theta= 36.89073 c,s=40 (ipss-78),t0=40 deg c,
c     p0=10000 decibars,pr=0 decibars
c     
c     set-up intermediate temperature and pressure variables
c     

      real p,p0,t,t0,h,pr,xk,s,q,theta,atg
      p=p0
      t=t0
c**************
      h = pr - p
      xk = h*atg(s,t,p) 
      t = t + 0.5*xk
      q = xk  
      p = p + 0.5*h 
      xk = h*atg(s,t,p) 
      t = t + 0.29289322*(xk-q) 
      q = 0.58578644*xk + 0.121320344*q 
      xk = h*atg(s,t,p) 
      t = t + 1.707106781*(xk-q)
      q = 3.414213562*xk - 4.121320344*q
      p = p + 0.5*h 
      xk = h*atg(s,t,p) 
      theta = t + (xk-2.0*q)/6.0
      return  
      end 

