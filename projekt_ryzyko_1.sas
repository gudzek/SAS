Damian Guzek i Mateusz Cielesz 
Kod sasowy - ryzyko inwestycji. Optymalny portfel ze względu na VaR i ES.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Import notowań giełdowych spółek DHL i UPS*/
DATA DHL;
INPUT open close;
DATALINES;
21.366 22.322
22.322 22.725
...
31.26 30.71
30.66 28.22
;
RUN;

DATA UPS;
INPUT open close;
DATALINES;
84.979 89.066
88.854 91.407
...
118.99 122.88
118.55 115.64
;
RUN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* Wyliczanie stóp strat obu spółek*/
DATA UPS1;
	SET UPS;
	L_UPS = round(((open - close)/open)*100,0.0001);
RUN;

DATA DHL1;
	SET DHL;
	L_DHL = round(((open - close)/open)*100,0.0001);
RUN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* Testy dopasowania danych do rozkładu normalnego (wraz z testem Shapiro-Wilka)*/
PROC UNIVARIATE data=UPS1 NORMALTEST ;
	VAR L_UPS;
	HISTOGRAM L_UPS /normal(mu=est sigma=est);
RUN; 

PROC UNIVARIATE data=DHL1 NORMALTEST;
	VAR L_DHL;
	HISTOGRAM L_DHL /normal;
RUN;

/*Testy dopasowania dla rozkładu lognormalnego*/
PROC UNIVARIATE data=DHL1;
	VAR L_DHL;
	HISTOGRAM L_DHL /lognormal(theta=est zeta=est sigma=est);
RUN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Kod służący do wyliczenia wartości Expected Shortfall dla stop strat UPS i DHL. */                                                                                                                                  
proc sort data=UPS1 out=UPS_sort;                                                                                        
by descending L_UPS;   
                                                                                                                
proc means data=UPS_sort (obs=3) mean ;                                                                                          
var L_UPS;                                                                                                                                                                                                                               
run;

proc sort data=DHL1 out=DHL_sort;                                                                                                 
by descending L_DHL;   
                                                                                                                 
proc means data=DHL_sort (obs=3) mean ;                                                                                           
var L_DHL;                                                                                                                              
run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Wielowymiarowy rozkład normalny*/
/*Łączymy dwa zbiory zawierające stopy strat poleceniem MERGE*/
DATA cork;
	MERGE DHL1 UPS1;
RUN;

/*Estymacja gęstości za pomocą procedury proc kde (kernel density estimation) */
title "Estymacja gestosci" ;
ods graphics on ;
proc kde data =cork;
title 'Wykresy kde' ;
bivar L_DHL L_UPS / plots =all ;
run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* Procedura IML (Interactive Matrix Language); procedura korzysta z  tzw. języka macierzowego i pozwala pracować na tychże macierzach w efektywny sposób */
/*Kod użyty do przeprowadzenia testu Mardii dla wektora y=(L_dhl, L_ups)*/
proc iml;
  * wczytanie danych do IML ;
  use cork;
  read all ;
  * połączenie danych do jednej macierzy y ;
  y = L_dhl || L_ups;

  print y;
  n = nrow(y) ;                     * przypisanie do n liczby wierszy macierzy y;
  p = ncol(y) ;            	         * przypisanie do p liczby kolumn macierzy y;
  dfchi = p*(p+1)*(p+2)/6 ;   *stopień swobody dla rozkładu chi-squared;
  q = i(n) - (1/n)*j(n,n,1);      *stworzenie macierzy potrzebnej do dalszych obliczeń, funkcja i(rozmiar) tworzy macierz jednostkową o podanym rozmiarze, funkcja j(n,n,1)- tworzy macierz nxn wypełnioną samymi jedynkami;
s = (1/(n))*t(y)*q*y ; s_inv = inv(s) ;         *s-macierz kowariancji, s_inv-odwrócona macierz kowariancji;
g_matrix = q*y*s_inv*t(y)*q;                    *odległość Mahalanobisa;
beta1hat = ( sum(g_matrix#g_matrix#g_matrix) )/(n*n);  *skośność;
beta2hat =trace( g_matrix#g_matrix )/n ;                         *kurtoza;
kappa1 = n*beta1hat/6 ;                                                   *skośność statystyka testowa (skewness test statistic);
kappa2 = (beta2hat - p*(p+2) ) / sqrt(8*p*(p+2)/n) ;         *kurtoza statystyka testowa (kurtosis test statistic);
pvalskew = 1 - probchi(kappa1,dfchi) ;                             *wartość p dla skośności (skewness p-value);
pvalkurt = 2*( 1 - probnorm(abs(kappa2)) );                     *wartość p dla kurtozy (kurtosis p-value);
print s ;
print s_inv ;
print "TESTS:";                                                                 *wyświetlanie wyników testu;
print "Based on skewness:" beta1hat kappa1 pvalskew ;
print "Based on kurtosis" beta2hat kappa2 pvalkurt;
run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Generowanie macierzy losowej i tworzenie pliku danych z macierzy */
proc iml ;
n = 500;

/*deklarowanie macierzy*/
sigma = { 30.224914   13.549753, 
    13.549753    23.721028 };                                                  
mu = {-0.5494550, -0.6472333};
p = nrow(sigma);
m = repeat(t(mu),n) ;
g =root(sigma);
z =normal(repeat(0,n,p)) ;

/*alternatywnie z =normal(j(n,p,0)) ; */
ymatrix = z*g + m ;

/* przepisanie danych z macierzy do pliku*/
create newdata from ymatrix;
append from ymatrix;
close newdata;

/*Rysowanie wykresu dla wygenerowanych danych*/
proc gplot data=newdata;
plot col1*col2="star";
run;

/*alternatywny sposób*/
ods graphics on;
proc kde data=newdata;
bivar col1 col2 / plots=all;
run;
ods graphics off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Makro wyznaczające Metodą Monte Carlo portfel optymalny, korzystając z obliczonej macierzy korelacji*/
%macro MonteCarlo (a) ;
data div;
set newdata;
L=&a*col1+(1-&a)*col2 ;
run ;
title 'Zaangażowanie na UPS '&a;
ods select Quantiles;
proc univariate data= div ;
var L ;
run ;

proc sort data= div  out =div_sort;
by descending L ;
proc means data= div_sort ( obs =50) mean ;
var L ;
run ;

%mend ;
%MonteCarlo ( 0 );
%MonteCarlo ( 0.2 );
%MonteCarlo ( 0.3 );
%MonteCarlo ( 0.4 );
%MonteCarlo ( 0.5 );
%MonteCarlo ( 0.6 );
%MonteCarlo ( 0.7 );
%MonteCarlo ( 0.8 );
%MonteCarlo ( 0.9);
%MonteCarlo ( 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Wykres zależności VaR od wielkości zaangażowania danej firmy.*/
Data VaRt;
a=0; 				*a- część zaangażowania danej firmy;
delta = 0.01;
quan = quantile('normal',0.95);
OUTPUT;

DO i=0 TO 100;
VaR=(-0.5494550)*a+(-0.6472333)*(1-a)+sqrt(30.224914*a**2+2*13.549753*(1-a)*a+23.721028*(1-a)**2)*quan;

a= a+delta; 
OUTPUT;
end;
RUN;

Symbol value=none interpol=sms line=1  width=2;
title"Trajectory VaRt";
proc gplot data=VaRt;
	plot VaR*a  ;
run;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Połączenie zbiorów DHL1 i UPS1, oraz pozostawienie tylko zmiennych L_DHL i L_UPS*/    
data laczna;                                                                                                                                                                                                                              
set UPS1 (keep=L_UPS);
set DHL1 (keep=L_DHL); 
run;

/*Dopasowywanie kopuły do danych.*/
/*Programy dopasowujące kopuły do danych stóp*/
/* Szukamy kopuły dla której AIC jest najmniejsze*/
proc copula data=laczna;                                                                                                          
title "Kopuła Gumbela";                                                                                                                 
	var L_DHL L_UPS;                                                                                                                     
	fit gumbel/outcopula=gumbel_parametry;                                                                                            
run; 

proc copula data=laczna;                                                                                                          
title "Kopuła Franka";                                                                                                                  
	var L_DHL L_UPS;                                                                                                                     
	fit frank/outcopula=frank_parametry;                                                                                              
run;  

proc copula data=laczna;                                                                                                          
title "Kopuła Claytona";                                                                                                                
	var L_DHL L_UPS;                                                                                                                     
	fit clayton/outcopula=clayton_parametry;                                                                                          
run;

proc copula data=laczna;
title "Kopuła t-studenta";
	var L_DHL L_UPS;
	fit T/outcopula=t_student_parametry;
run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Programy użyte do symulacji danych z kopuł*/
proc copula;                                                                                                                            
title "Kopuła Gumbela";                                                                                                                 
var u v;                                                                                                                                
define g_cop gumbel (theta=1.558604);                                                                                                   
simulate g_cop/seed=1234                                                                                                                
ndraws=5000                                                                                                                             
outuniform=gumbel_jednorodne                                                                                                      
plots = (datatype=UNIFORM distribution=CDF);                                                                                             
run;

proc copula;                                                                                                                            
title "Kopuła Franka";                                                                                                                 
var u v;                                                                                                                                
define g_cop frank (theta=3.762083);                                                                                                   
simulate g_cop/seed=1234                                                                                                                
ndraws=5000                                                                                                                             
outuniform=frank_jednorodne                                                                                                      
plots = (datatype=UNIFORM distribution=CDF);                                                                                             
run;

proc copula;                                                                                                                            
title "Kopuła Claytona";                                                                                                                 
var u v;                                                                                                                                
define g_cop clayton (theta=0.911681);                                                                                                   
simulate g_cop/seed=1234                                                                                                                
ndraws=5000                                                                                                                             
outuniform=clayton_jednorodne                                                                                                      
plots = (datatype=UNIFORM distribution=CDF);                                                                                             
run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*Kod dokonujący transformacji danych wylosowanych z kopuły Gumbela za pomocą dystrybuanty odwrotnej.*/                                                                                                                      
data transformacja;                                                                                                               
set gumbel_jednorodne;                                                                                                            
L_UPS=quantile('Normal',u,-0.64723,4.911525);                                                                                          
L_DHL=quantile('Lognormal',v,2.844641,0.307707)-18.5541;                                                                                           
run;
 
/*Definiowanie makra*/
%macro Kopula (a) ;
data div;
set transformacja;
L=&a*L_UPS+(1-&a)*L_DHL ;
run ;

title 'Kopuła'&a;
ods select Quantiles;
proc univariate data= div ;
var L ;
run ;

proc sort data= div  out =div_sort;
by descending L ;
proc means data= div_sort ( obs =50) mean ;
var L ;
run ;

%mend ;
%Kopula ( 0 );
%Kopula ( 0.1 );
%Kopula ( 0.2 );
%Kopula ( 0.3 );
%Kopula ( 0.4 );
%Kopula ( 0.5 );
%Kopula ( 0.6 );
%Kopula ( 0.7 );
%Kopula ( 0.8);
%Kopula ( 0.9 );
%Kopula ( 1 );

