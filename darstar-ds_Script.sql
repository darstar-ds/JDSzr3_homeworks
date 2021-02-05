--2. Stwórz w dbeaver tabelę odpowiadającą danym.

create table countries_dentists_10k
(	location 			varchar,
	period 				smallint,
	dentists_per_10K	numeric
);

--4. Wykonaj zapytania:
--a. Wypisz wszystkie dane z tabeli

select * from countries_dentists_10k;

--b. Wypisz rok oraz wskaźnik first tooltip 
--(first tooltip to wskaźnik dentystów na 10000 mieszkańców).

select period, dentists_per_10k from countries_dentists_10k;

--c. W wyniku powyższego zapytania zamień nazwy kolumn na polskie nazwy.

select period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k;

--d. Wypisz dane Krajów zaczynających się na literę B lub tych z 2006 roku.

select location as kraj, period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k
where upper(location) like 'B%' or period=2006;

--e. Wypisz dane krajów kończących się na „land”.

select location as kraj, period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k
where lower(location) like '%land';

--f. Wyznacz średnią, wartość minimalną, maksymalną wskaźnika w całej bazie.

select 	avg(dentists_per_10k) as srednia_cala,
		max(dentists_per_10k) as max_cala,
		min(dentists_per_10k) as min_cala
from countries_dentists_10k;

--g. Porównaj powyższe wyniki z wynikami dla polski.

select 	avg(dentists_per_10k) as srednia_polska,
		max(dentists_per_10k) as max_polska,
		min(dentists_per_10k) as min_polska
from countries_dentists_10k
where location='Poland';

--h. Wypisz wszystkie dane z tabeli dla Polski w kolejności według lat.

select location as kraj, period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k
where location='Poland'
order by period;

--i. Wyznacz minimalny oraz maksymalny rok z tabeli.

select 	max(period) as max_rok,
		min(period) as min_rok
from countries_dentists_10k;

--j. Który kraj ma maksymalną wartość wskaźnika w ostatnim, badanym roku?

select location as kraj, period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k
where period=2019
order by dentists_per_10k desc
limit 1;

--k. Który kraj ma maksymalną wartość wskaźnika w pierwszym, badanym roku?

select location as kraj, period as rok, dentists_per_10k as dent_na_10k from countries_dentists_10k
where period=1990
order by dentists_per_10k desc
limit 1;

/*
▪Stwórz raport sprzedaży za każdy miesiąc dla poszczególnych
pracowników. Wyznacz liczbę zamówień i ich wartość. Wypróbuj użycie
rollup oraz cube . (użycie tabel orders , order_details , employees
▪Dodatkowe: Sprawdź jak wyglądają zapasy magazynowe poszczególnych
kategorii produktów (tabele products, categories
*/

select 	o."EmployeeID",
		count(distinct o."OrderID") as liczba_zamowien,
		round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric , 2) as wartosc_zamowien, 
		to_char(o."OrderDate",'YYYY-MM') as miesiac
from orders o 
join order_details od on o."OrderID" = od."OrderID" 
join employees e on e."EmployeeID" = o."EmployeeID"
group by cube (o."EmployeeID", to_char(o."OrderDate",'YYYY-MM'))
order by 1, 4
;

select * from orders od 
where "EmployeeID" = 1
order by "OrderDate" 
;

select 	c."CategoryName"
,		sum(p."UnitsInStock") as stan_magazynowy
from categories c 
join products p on p."CategoryID" =c."CategoryID"
group by c."CategoryName" 
;

select sum("UnitsInStock") from products p 
where "CategoryID" = 1
;

/*▪Do wyników tabeli orders dodaj numer zamówienia w miesiącu (partycjonowanie po
miesiącach) kolejność według daty.
▪Dodaj analogiczne pole, ale w kolejności malejącej.
▪Wypisz datę pierwszego i ostatniego zamówienia.
▪Dodaj do wyników kwotę zamówienia.
▪Podziel zbiór za pomocą funkcji ntile na 5 podzbiorów według kwoty zamówienia.
▪Wyznacz minimalną i maksymalną wartość z wyników poprzedniego punktu dla
każdego klienta.
▪Sprawdź, czy istnieją klienci premium (którzy zawsze występują w kwnatylu 4 lub 5).*/

select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY_MM') order by o."OrderDate") 
from orders o 
;

--▪Dodaj analogiczne pole, ale w kolejności malejącej.
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate" desc) 
from orders o 
;

--▪Wypisz datę pierwszego i ostatniego zamówienia.
create view v_zamowienia as
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate" desc) as nr_zamowienia
from orders o
group by o."OrderDate" 
;

select 	o."OrderDate" 
,		to_char(o."OrderDate",'YYYY-MM')
,		min(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as pierwsza_data
,		max(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as ostatnia_data
from orders o
group by o."OrderDate" 
;


