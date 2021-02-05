--SprawdŸ jak wygl¹daj¹ zapasy magazynowe poszczególnych kategorii produktów (tabele products, categories) - suma unitinstock
select 	c."CategoryName"
,		sum(p."UnitsInStock") as stan_magazynowy
from categories c 
join products p on p."CategoryID" = c."CategoryID"
group by c."CategoryName" 
;

select sum("UnitsInStock") from products p 
where "CategoryID" = 1
;


--Do wyników tabeli orders dodaj numer zamówienia w miesi¹cu (partycjonowanie po miesi¹cach) kolejnoœæ wed³ug daty.
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate") 
from orders o 
;

--Dodaj analogiczne pole, ale w kolejnoœci malej¹cej.
select 	o."OrderDate" 
,		row_number() over (partition by to_char(o."OrderDate",'YYYY-MM') order by o."OrderDate" desc) 
from orders o 
;

--Wypisz datê pierwszego i ostatniego zamówienia w poszczególnych miesi¹cach.
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

--• Dodaj do wyników kwotê zamówienia.
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

--• Podziel zbiór za pomoc¹ funkcji ntile na 5 podzbiorów wed³ug kwoty zamówienia.
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

-- Wyznacz minimaln¹ i maksymaln¹ wartoœæ z wyników poprzedniego punktu dla ka¿dego klienta. (wyniki funkcji ntile)
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

-- SprawdŸ, czy istniej¹ klienci premium (którzy zawsze wystêpuj¹ w kwnatylu 4 lub 5).
select  vzn."CustomerID" from v_zam_ntile vzn 
where vzn.ntile_5 = 4
intersect 
select  vzn."CustomerID" from v_zam_ntile vzn 
where vzn.ntile_5 = 5
