/*----------------------------------------------------------------------------------------------------*/
/*---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p----*/
/*----------------------------------------------------------------------------------------------------*/
PROC IMPORT
	datafile= "C:\Users\damia\Desktop\PROJEKT Z SASA\creditcard.csv"
	out=creditcard  							
	dbms=csv replace;
	getnames=yes;
	GUESSINGROWS=MAX;
RUN;
							     							/* Import danych z pliku CSV             */
PROC CONTENTS data=creditcard;				     			/* Badanie zbioru za pomoc� PROC CONTENTS*/
RUN;							     						/* Wy�wietlanie kilku obserwacji         */

PROC PRINT DATA=creditcard (OBS=10);			
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p---Wst�p----*/
/*----------------------------------------------------------------------------------------------------*/







/*----------------------------------------------------------------------------------------------------*/
/*---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�*/
/*----------------------------------------------------------------------------------------------------*/

PROC GCHART data=creditcard;						
	PIE class /VALUE= ARROW							
	LEGEND DISCRETE;
RUN;

PROC SGPLOT data=creditcard;
	density amount / type=normal group=class;
RUN;
						    					  /* Wykres ciastkowy i rozk�ad normalny             */
						    					  /* Zauwa� jak ma�� cz�� ca�o�ci stanowi� oszustwa */
DATA NoFrauds;					    			  /* Rozdzielam zbiory na Frauds i NoFrouds          */
	SET creditcard;				    			  /* Wst�pne por�wnanie zbior�w                      */
	WHERE class='0';			    			  /* Patrz na odchylenie standardowe 		         */
RUN;

DATA Frauds;
	SET creditcard;
	WHERE class='1';
RUN;

title'Zbi�r ��czony';
PROC MEANS data=creditcard;
RUN;

title'Zbi�r Frauds';
PROC MEANS data=Frauds;
RUN;

title'Zbi�r NoFrauds';
PROC MEANS data=NoFrauds;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�---Podzia�*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne-*/
/*----------------------------------------------------------------------------------------------------*/

DATA RandInt;						
DO i = 1 TO 800;					
   LP = rand("Integer", 1, 284315);           /* Wybieramy losowo 492 obserwacji z NoFrauds           */
   OUTPUT;				      				  /* aby uzyska� zbi�r 50-50 (Frauds - NoFrauds)          */
END;					      				  /* 800 <--- wybieramy 800 poniewa� x mog� si� powtarza� */
RUN;					      				  /* 284315 <--- tyle jest uczciwych transakcji           */


PROC SORT data=RandInt Nodupkey OUT=RandInt_better;
	BY LP;				            				/* Usuwamy powtarzaj�ce si� LP       		      */
RUN;						    					/* wybieramy dok�adnie 492 interesuj�cych nasz LP */

DATA RandInt_better;
	SET RandInt_better (OBS=492);		
RUN;

DATA NoFrauds;
SET NoFrauds;
	LP = _N_;
RUN;

DATA NoFrauds_492 (DROP= LP i);
MERGE NoFrauds (in=pierwszy) RandInt_better (in=drugi);
BY LP;
IF pierwszy=drugi;
PUT _ALL_;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne---G��wne-*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w--------*/
/*----------------------------------------------------------------------------------------------------*/

DATA GoodSet;
	SET NoFrauds_492 Frauds;				 					  /* Pr�bka 50 - 50 zosta�a utworzona */
RUN;								  							  /* Tworzenie "Esencji" zbioru       */

DATA GoodSet_Essence;
	SET GoodSet;
	KEEP Time Amount Class;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w--------*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy*/
/*----------------------------------------------------------------------------------------------------*/

title "Por�wnanie dw�ch zbior�w"; 
proc sgplot data=GoodSet_Essence;
  scatter x=time y=amount / markerattrs=(symbol=CircleFilled) group=Class;
run;


PROC SGPANEL DATA=GoodSet_Essence;
 PANELBY Class;
 SCATTER X = time Y = amount / markerattrs=(symbol=CircleFilled);
 TITLE 'Por�wnanie dw�ch zbior�w';						/* wykres g�sto�ci dwa przypadki:             */
RUN; 													/* - GoodSet                                  */
														/* - creditcard                               */
PROC SGPLOT data=GoodSet;			       			    /*					 					      */
  density amount/ type=normal group=class;  	        /* UWAGA: dla klasy 1 g�sto�� si� nie zmieni�a*/
RUN;

PROC SGPLOT data=creditcard;
  density amount / type=normal group=class;  
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w--------*/
/*----------------------------------------------------------------------------------------------------*/

DATA NCorrelation;				   				   /* Tworzymy zbiory Positive i Negative Correlation */	
	SET GoodSet;				   				   /* Prosz� zauwa�y�, �e im ni�sze s� te warto�ci,   */
	KEEP v10 v12 v14 v17 Class;		  			   /* tym bardziej prawdopodobne, �e ostateczny wynik */
RUN;						   					   /* b�dzie FRAUD								      */

DATA NCorrelation;								   
	SET NCorrelation;							   
	LP =_N_;									   	
RUN;											   

DATA PCorrelation;								   
	SET GoodSet;								   
	KEEP v2 v4 v11 v19 Class;				       
RUN;

DATA PCorrelation;				   				  /* Prosz� zauwa�y�, �e im wy�sze s� te warto�ci,   */
	SET PCorrelation;			   				  /* tym bardziej prawdopodobne, �e ostateczny wynik */
	LP =_N_;				   					  /* b�dzie FRAUD		    		   	  	         */
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w---Tworzenie_podzbior�w--------*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy*/
/*----------------------------------------------------------------------------------------------------*/

proc sgplot data=NCorrelation;
  scatter x=LP y=v10 / markerattrs=(symbol=CircleFilled) group=Class;
run;								      							  /*Wykresy Positive Correlations */

proc sgplot data=NCorrelation;
  scatter x=LP y=v12 / markerattrs=(symbol=CircleFilled) group=Class;
run;

proc sgplot data=NCorrelation;
  scatter x=LP y=v14 / markerattrs=(symbol=CircleFilled) group=Class;
run;

proc sgplot data=NCorrelation;
  scatter x=LP y=v17 / markerattrs=(symbol=CircleFilled) group=Class;
run;

PROC SGPLOT data=PCorrelation;
  SCATTER x=LP y=v2 / markerattrs=(symbol=CircleFilled) group=Class;
RUN;								      							   /*Wykresy Negative Correlations */

PROC SGPLOT data=PCorrelation;
  SCATTER x=LP y=v4 / markerattrs=(symbol=CircleFilled) group=Class;
RUN;

PROC SGPLOT data=PCorrelation;
  SCATTER x=LP y=v11 / markerattrs=(symbol=CircleFilled) group=Class;
RUN;

PROC SGPLOT data=PCorrelation;
  SCATTER x=LP y=v19 / markerattrs=(symbol=CircleFilled) group=Class;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy---Wykresy*/
/*----------------------------------------------------------------------------------------------------*/





/*----------------------------------------------------------------------------------------------------*/
/*---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra----*/
/*----------------------------------------------------------------------------------------------------*/

%MACRO PCorrelationPlot (variable=);

	PROC SGPLOT data=PCorrelation;
    SCATTER x=LP y=&variable / markerattrs=(symbol=CircleFilled) group=Class;
	RUN;

%MEND PCorrelationPlot;											/* Napisa�em makra do powtarzaj�cych  */
																/* si� linijek kodu tworz�cych wykresy*/
%MACRO NCorrelationPlot (variable=);

	PROC SGPLOT data=NCorrelation;
    SCATTER x=LP y=&variable / markerattrs=(symbol=CircleFilled) group=Class;
	RUN;

%MEND NCorrelationPlot;

/*------------------------------------------------------------------------------Histogram & G�sto��---*/
PROC SGPLOT data=GoodSet;
  histogram v14 /group=class ;
RUN;

PROC SGPLOT data=GoodSet;
	density v14 / type=normal group=class;
RUN;
/*------------------------------------------------------------------------------Histogram & G�sto��---*/

%MACRO Histogram (variable=);

	PROC SGPLOT data=GoodSet;
  	histogram &variable /group=class ;
	RUN;

%MEND Histogram;

%MACRO Density (variable=);

PROC SGPLOT data=GoodSet;
	density &variable / type=normal group=class;
RUN;

%MEND Density;



%PCorrelationPlot (variable=v11);   							/* wybierz sposr�d V17, V14, V12, V10 */
%NCorrelationPlot (variable=v17);								/* wybierz sposr�d V2,  V4,  V11, V19 */
%Histogram (variable=v1);			 							/* wybierz sposr�d V1-V19             */
%Density (variable=v1);				 							/* wybierz sposr�d V1-V19             */

/*----------------------------------------------------------------------------------------------------*/
/*---Makra---Makra---Makr---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra---Makra-----*/
/*----------------------------------------------------------------------------------------------------*/




/*----------------------------------------------------------------------------------------------------*/
/*---Format---Format---Format---Format---Format---Format---Format---Format---Format---Format---Format-*/
/*----------------------------------------------------------------------------------------------------*/

PROC FORMAT FMTLIB;
	VALUE kwota
		low - 10 = 'ma�a'
		10 - 100 = 'du�a'
		100 - high = 'bardzo du�a'
	;
RUN;

DATA FRAUDS;
	SET Frauds;
	FORMAT amount kwota.;
RUN;

PROC SGPLOT DATA=FRAUDS;
	VBAR amount;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Format---Format---Format---Format---Format---Format---Format---Format---Format---Format---Format-*/
/*----------------------------------------------------------------------------------------------------*/







ods graphics on;											/* Tabela przekrowa	        */
proc freq data=GoodSet_Essence order=data;					/* lepiej nie wczytywa�     */
tables TIME*amount /PLOTS(ONLY)=FREQPLOT(twoway=cluster);	/* wczytywanie trwa 20 minut*/
weight Amount;
run;
ods graphics off;





/*----------------------------------------------------------------------------------------------------*/
/*---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford*/
/*----------------------------------------------------------------------------------------------------*/
DATA Logarytm;
	DO i=1 TO 9;
		y=100*log10((i+1)/i);
		OUTPUT;
	END;
RUN;


DATA Benford_NoFrauds;
	SET NoFrauds;										/* Wyliczam kolejne warto�ci rozk�adu benforda */
		WHERE (amount>0);								/* Korzystam z p�tli UNTIL aby wyznaczy�       */
			a=amount/100000;							/* pierwsze cyfry liczb podanych w kolumnie    */
														/* amount                                      */
		DO UNTIL (INT(a)>0);
			a=a*10;
		END;

	digit=int(a);
RUN;

DATA Benford_Frauds;
	SET Frauds;
		WHERE (amount>0);

			a=amount/100000;
		DO UNTIL (INT(a)>0);
			a=a*10;

		END;
	digit=int(a);
RUN;

PROC SORT data=Benford_NoFrauds OUT=Benford_NoFrauds;
BY digit;
RUN;

PROC SORT data=Benford_Frauds OUT=Benford_Frauds;
BY digit;
RUN;

/*------------------------------------------------------------------------------Wykresy---------------*/
PROC GCHART DATA=Benford_NoFrauds;						       	  /* Wy�wietlam wykresy ciasteczkowe  */
	PIE digit / VALUE=ARROW type=mean SUMVAR=digit				  /* dla Frauds i NoFrauds            */
	LEGEND DISCRETE;											  /* Por�wnuje rozk�ady pierwszych    */
RUN;															  /* cyfr liczb z rozk�adem benforda  */

PROC GCHART DATA=Benford_Frauds;
	PIE digit / VALUE=ARROW type=mean SUMVAR=digit
	LEGEND DISCRETE;
RUN;

title 'Frauds';
PROC SGPLOT data=Benford_Frauds;
	VBAR digit /categoryorder=respdesc; 
RUN;

title 'NoFrauds';
PROC SGPLOT data=Benford_NoFrauds;
	VBAR digit /categoryorder=respdesc;
RUN;

title 'Rozk�ad Benforda';
PROC SGPLOT data=Logarytm;
  yaxis label="Sales" ;
  vbar i/ response=y;
RUN;

/*----------------------------------------------------------------------------------------------------*/
/*---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford---Benford*/
/*----------------------------------------------------------------------------------------------------*/