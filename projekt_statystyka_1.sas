/*========================================================*/
/*Zestaw 1*/
/*Univariate Density Estimates and Posterior Probabilities*/
/*========================================================*/



/*KOD 1-------------------------------------------------------------*/
/*wczytanie danych oraz narysowanie skumulowanego wykresu słupkowego*/
/*oś X - szerokość płatka, oś Y - liczba występień------------------*/
title 'Analiza dyskryminacji Fishera (1936) Iris';
DATA iris;
	set sashelp.iris;
RUN; 
PROC FREQ data=iris noprint;
   tables petalwidth * species / out=freqout;
RUN;
PROC SGPLOT data=freqout;
   vbar petalwidth / response=count group=species;
   keylegend / location=inside position=ne noborder across=1;
RUN;



/*KOD 2--------------------------------------------------------------------------------*/
/*tworzymy wektor plotdata [-5.0, -4.5, -4.0, ..., 30]---------------------------------*/
/*oraz makra rysujące gęstości i prawdopodobieństwo a posteriori dla każdego z gatunków*/
DATA plotdata;
   do PetalWidth=-5 to 30 by 0.5;
      output;
   end;
RUN;
%MACRO plotden;
   title3 'Plot of Estimated Densities';

   data plotd2;
      set plotd;
      if setosa     < .002 then setosa     = .;
      if versicolor < .002 then versicolor = .;
      if virginica  < .002 then virginica  = .;
      g = 'Setosa    '; Density = setosa;     output;
      g = 'Versicolor'; Density = versicolor; output;
      g = 'Virginica '; Density = virginica;  output;
      label PetalWidth='szerokość płatka w mm';
   run;

   proc sgplot data=plotd2;
      series y=Density x=PetalWidth / group=g;
      discretelegend;
   run;
%MEND;
%MACRO plotprob;
   title3 'Plot of Posterior Probabilities';

   data plotp2;
      set plotp;
      if setosa     < .01 then setosa     = .;
      if versicolor < .01 then versicolor = .;
      if virginica  < .01 then virginica  = .;
      g = 'Setosa    '; Probability = setosa;     output;
      g = 'Versicolor'; Probability = versicolor; output;
      g = 'Virginica '; Probability = virginica;  output;
      label PetalWidth='szerokość płatka w mm';
   run;

   proc sgplot data=plotp2;
      series y=Probability x=PetalWidth / group=g;
      discretelegend;
   run;
%MEND;



/*KOD 3-----------------------------------------------------------------*/
/*estymujemy gęstości i prawdopodobieństwo a posteriori każdego gatunku-*/
/*zakładając stałość wariancji i ich normalność-------------------------*/
title2 'Korzystając z rozkładu normalnego ze stałą wariancją';
PROC DISCRIM data=iris method=normal pool=yes
             testdata=plotdata testout=plotp testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var PetalWidth;
RUN;
%plotden;
%plotprob;



/*KOD 4----------------------------------------------------------------------*/
/*estymujemy gęstości i Prawdopodobieństwo a posteriori każdego gatunku------*/
/*zakładając ich normalność, ale nie zakładając stałej wariancji-------------*/
title2 'Korzystając z rozkładu normalnego bez zał. o stałości wariancji';
PROC DISCRIM data=iris method=normal pool=no
             testdata=plotdata testout=plotp testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var PetalWidth;
RUN;
%plotden;
%plotprob;



/*KOD 5---------------------------------------------------------------------------------*/
/*estymujemy gęstości i prawdopodobieństwo a posteriori każdego gatunku-----------------*/
/*wykorzystując jądrowy estymator gęstości oraz zakładając stałość parametru wygładzenia*/
title2 'Korzystając z KDE ze stałym parametrem wygładzenia';
PROC DISCRIM data=iris method=npar kernel=normal
                r=.4 pool=yes
             testdata=plotdata testout=plotp
                testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var PetalWidth;
RUN;
%plotden;
%plotprob;



/*KOD 6---------------------------------------------------------------------------------*/
/*estymujemy gęstości i prawdopodobieństwo a posteriori każdego gatunku-----------------*/
/*wykorzystując jądrowy estymator gęstości oraz zakładając stałość parametru wygładzenia*/
title2 'Korzystając z KDE bez stałego parametru wygładzenia';
PROC DISCRIM data=iris method=npar kernel=normal
                r=.4 pool=no
             testdata=plotdata testout=plotp
                testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var PetalWidth;
RUN;
%plotden;
%plotprob;

/*========================================================*/
/*Zestaw 2*/
/*Bivariate Density Estimates and Posterior Probabilities */
/*========================================================*/



/*KOD 7----------------------------------------------------------------*/
/*rysowanie wykresu punktowego dla dwóch zmiennych---------------------*/
/*oś X - długość płatka, oś Y - szerokość płatka dla każdego z gatunków*/
PROC TEMPLATE;
   define statgraph scatter;
      begingraph;
         entrytitle 'Fisher (1936) Iris Data';
         layout overlayequated / equatetype=fit;
            scatterplot x=petallength y=petalwidth /
                        group=species name='iris';
            layout gridded / autoalign=(topleft);
               discretelegend 'iris' / border=false opaque=false;
            endlayout;
         endlayout;
      endgraph;
   end;
RUN;
PROC SGRENDER data=iris template=scatter;
RUN;



/*KOD 8----------------------------------------------------------------*/
/*tworzymy zbiór danych potrzebny później do narysowania wykresu-------*/
/*oraz makra rysujące wykresy konturowe 
	>contden   - estymowanej funkcji gęstości
	>contprob  - prawdopodobieństwa a posteriori
	>contclass - wyników klasyfikacji------------------------------*/
DATA plotdata;
   do PetalLength = -2 to 72 by 0.5;
      do PetalWidth= - 5 to 32 by 0.5;
         output;
      end;
   end;
RUN;
%let close = thresholdmin=0 thresholdmax=0 offsetmin=0 offsetmax=0;
%let close = xaxisopts=(&close) yaxisopts=(&close);
PROC TEMPLATE;
   define statgraph contour;
      begingraph;
         layout overlayequated / equatetype=equate &close;
            contourplotparm x=petallength y=petalwidth z=z /
                            contourtype=fill nhint=30;
            scatterplot x=pl y=pw / group=species name='iris'
                        includemissinggroup=false primary=true;
            layout gridded / autoalign=(topleft);
               discretelegend 'iris' / border=false opaque=false;
            endlayout;
         endlayout;
      endgraph;
   end;
RUN;

%macro contden;
   data contour(keep=PetalWidth PetalLength species z pl pw);
      merge plotd(in=d) iris(keep=PetalWidth PetalLength species
                             rename=(PetalWidth=pw PetalLength=pl));
      if d then z = max(setosa,versicolor,virginica);
   run;

   title3 'Plot of Estimated Densities';

   proc sgrender data=contour template=contour;
   run;
%mend;

%macro contprob;
   data posterior(keep=PetalWidth PetalLength species z pl pw _into_);
      merge plotp(in=d) iris(keep=PetalWidth PetalLength species
                             rename=(PetalWidth=pw PetalLength=pl));
      if d then z = max(setosa,versicolor,virginica);
   run;

   title3 'Plot of Posterior Probabilities ';

   proc sgrender data=posterior template=contour;
   run;
%mend;

%macro contclass;
   title3 'Plot of Classification Results';

   proc sgrender data=posterior(drop=z rename=(_into_=z)) template=contour;
   run;
%mend;



/*KOD 9------------------------------------------------------------------------------------*/
/*wyznaczamy liniowe granice klasyfikacji korzystając z------------------------------------*/
/*Normal thoery (method=normal) oraz zakładając stałość macierzy kowariancji (pool=yes)*/
title2 'korzystając z estymacji rozkładu normalnego i stałości wariancji';
PROC DISCRIM data=iris method=normal pool=yes
             testdata=plotdata testout=plotp testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var Petal:;
RUN;
%contden;
%contprob;
%contclass;



/*KOD 10-----------------------------------------------------------------------------------*/
/*wyznaczamy kwadratowe granice klasyfikacji korzystając z---------------------------------*/
/*Normal thoery (method=normal) oraz nie zakładając stałości macierzy kowariancji (pool=no)*/
title2 'korzystając z estymacji rozkładu normalnego bez stałości wariancji';
PROC DISCRIM data=iris method=normal pool=no
             testdata=plotdata testout=plotp testoutd=plotd
             short noclassify crosslisterr;
   class Species;
   var Petal:;
RUN;
%contden;
%contprob;
%contclass;



/*KOD 11-----------------------------------------------------------------------------------------------------*/
/*wyznaczamy granice klasyfikacji korzystając z metod nieparametycznych (method=npar)------------------------*/
/*przyjmując za jądro rozkład normalny(kernel=normal) oraz zakładając stałość parametru wygładzania(pool=yes)*/
title2 'Korzystając z KDE ze stałym parametrem wygładzenia';
PROC DISCRIM data=iris method=npar kernel=normal
             r=.5 pool=yes testoutd=plotd
             testdata=plotdata testout=plotp
             short noclassify crosslisterr;
   class Species;
   var Petal:;
RUN;
%contden;
%contprob;
%contclass;



/*KOD 12----------------------------------------------------------------------------------------------*/
/*wyznaczamy granice klasyfikacji korzystając z metod nieparametycznych (method=npar)-----------------*/
/*przyjmując za jądro rozkład normalny(kernel=normal) oraz bez stałości parametru wygładzania(pool=no)*/
title2 'Korzystając z KDE bez stałego parametru wygładzenia';
PROC DISCRIM data=iris method=npar kernel=normal
             r=.5 pool=no testoutd=plotd
             testdata=plotdata testout=plotp
             short noclassify crosslisterr;
   class Species;
   var Petal:;
RUN;
%contden;
%contprob;
%contclass;


/*========================================================*/
/*Zestaw 3*/
/*Normal-Theory Discriminant Analysis of Iris Data		  */
/*========================================================*/


/*KOD 13----------------------------------------------------------------------------------------------*/
title 'Analiza dyskryminacyjna irysów';
title2 'Korzystając z kwadratowej funkcji dyskryminacji';
PROC DISCRIM data=iris outstat=irisstat
             wcov pcov method=normal pool=test
             distance anova manova listerr crosslisterr;
   class Species;
   var SepalLength SepalWidth PetalLength PetalWidth;
RUN;

PROC PRINT data=irisstat;
   title2 'Wyniki analizy dyskryminacji';
RUN;