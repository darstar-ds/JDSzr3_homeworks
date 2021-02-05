--Sprawd� jak wygl�daj� zapasy magazynowe poszczeg�lnych kategorii produkt�w (tabele products, categories) - suma unitinstock
select 	c."CategoryName"
,		sum(p."UnitsInStock") as stan_magazynowy
from categories c 
join products p on p."CategoryID" = c."CategoryID"
group by c."CategoryName" 
;

select sum("UnitsInStock") from products p 
where "CategoryID" = 1
;


--Do wynik�w tabeli orders dodaj numer zam�wienia w miesi�cu (partycjonowanie po miesi�cach) kolejno�� wed�ug daty.
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate") 
from orders o 
;

--Dodaj analogiczne pole, ale w kolejno�ci malej�cej.
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate" desc) 
from orders o 
;

--Wypisz dat� pierwszego i ostatniego zam�wienia w poszczeg�lnych miesi�cach.
create view v_zamowienia as
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate" desc) as nr_zamowienia
from orders o
group by o."OrderDate" 
;

select 	o."OrderDate" 
,		to_char(o."OrderDate",'YYYY-MM') as miesiac
,		min(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as pierwsza_data
,		max(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as ostatnia_data
from orders o
group by o."OrderDate"
order by o."OrderDate" 
;

--� Dodaj do wynik�w kwot� zam�wienia.
select 	o."OrderDate" 
,		to_char(o."OrderDate",'YYYY-MM') as miesiac
,		min(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as pierwsza_data
,		max(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as ostatnia_data
,		round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric , 2) as wartosc_zamowien
from orders o
join order_details od on o."OrderID" = od."OrderID" 
group by o."OrderDate" 
order by o."OrderDate"
;

--� Podziel zbi�r za pomoc� funkcji ntile na 5 podzbior�w wed�ug kwoty zam�wienia.
drop view v_zam_ntile;

create view v_zam_ntile as
select 	o."OrderDate" 
,		o."CustomerID" 
,		to_char(o."OrderDate",'YYYY-MM') as miesiac
,		min(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as pierwsza_data
,		max(o."OrderDate") over (partition by to_char(o."OrderDate",'YYYY-MM')) as ostatnia_data
,		round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric , 2) as wartosc_zamowien
,		ntile(5) over (order by round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric, 2)) as ntile_5
from orders o
join order_details od on o."OrderID" = od."OrderID" 
group by 	o."OrderDate" 
,			o."CustomerID" 
order by ntile_5
;

-- Wyznacz minimaln� i maksymaln� warto�� z wynik�w poprzedniego punktu dla ka�dego klienta. (wyniki funkcji ntile)
select 	o2."CustomerID"
,		o2."OrderID" 
,		o2."OrderDate" 
,		round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric, 2) as suma_zamowienia
,		min(round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric , 2)) over (partition by o2."CustomerID") as min_zam_per_CID
,		max(round(sum(od."UnitPrice"*od."Quantity"*(1-od."Discount"))::numeric , 2)) over (partition by o2."CustomerID") as max_zam_per_CID
from orders o2 
join order_details od on o2."OrderID" = od."OrderID" 
group by 	o2."CustomerID"
,			o2."OrderID" 
;

-- Sprawd�, czy istniej� klienci premium (kt�rzy zawsze wyst�puj� w kwnatylu 4 lub 5).
select  vzn."CustomerID" from v_zam_ntile vzn 
where vzn.ntile_5 = 4
intersect 
select  vzn."CustomerID" from v_zam_ntile vzn 
where vzn.ntile_5 = 5
