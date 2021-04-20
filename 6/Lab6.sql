
use Lab6

--1. Добавить внешние ключи.

ALTER TABLE [dbo].[order]  WITH CHECK ADD  CONSTRAINT [FK_order_dealer] FOREIGN KEY([id_dealer])
REFERENCES [dbo].[dealer] ([id_dealer])
GO

ALTER TABLE [dbo].[order] CHECK CONSTRAINT [FK_order_dealer]
GO

ALTER TABLE [dbo].[order]  WITH CHECK ADD  CONSTRAINT [FK_order_pharmacy] FOREIGN KEY([id_pharmacy])
REFERENCES [dbo].[pharmacy] ([id_pharmacy])
GO

ALTER TABLE [dbo].[order] CHECK CONSTRAINT [FK_order_pharmacy]
GO

ALTER TABLE [dbo].[order]  WITH CHECK ADD  CONSTRAINT [FK_order_production] FOREIGN KEY([id_production])
REFERENCES [dbo].[production] ([id_production])
GO

ALTER TABLE [dbo].[order] CHECK CONSTRAINT [FK_order_production]
GO

ALTER TABLE [dbo].[production]  WITH CHECK ADD  CONSTRAINT [FK_production_company] FOREIGN KEY([id_company])
REFERENCES [dbo].[company] ([id_company])
GO

ALTER TABLE [dbo].[production] CHECK CONSTRAINT [FK_production_company]
GO

ALTER TABLE [dbo].[production]  WITH CHECK ADD  CONSTRAINT [FK_production_medicine] FOREIGN KEY([id_medicine])
REFERENCES [dbo].[medicine] ([id_medicine])
GO

ALTER TABLE [dbo].[production] CHECK CONSTRAINT [FK_production_medicine]
GO

--2. Выдать информацию по всем заказам лекарства “Кордерон” компании “Аргус”
--	с указанием названий аптек, дат, объема заказов.

select e.name, d.date, d.quantity
from dbo.medicine a
join dbo.production b on b.id_medicine = a.id_medicine
join dbo.company c on c.id_company = b.id_company
join dbo.[order] d on d.id_production = b.id_production
join dbo.pharmacy e on e.id_pharmacy = d.id_pharmacy
where (a.name = 'Кордерон') and (c.name = 'Аргус')
order by e.name

--3. Дать список лекарств компании “Фарма”, на которые 
--	не были сделаны заказы до 25 января.

select e.name
from dbo.company a
join dbo.production b on b.id_company = a.id_company
join (
	select id_production, min(date) min_date
	from dbo.[order]
	group by id_production
) c on c.id_production = b.id_production and c.min_date > '2019-01-25'
join dbo.medicine e on e.id_medicine = b.id_medicine
where a.name = 'Фарма'

--4. Дать минимальный и максимальный баллы лекарств каждой фирмы, 
--	которая оформила не менее 120 заказов.

select a.id_company, min(a.rating) min_rating, max(a.rating) max_rating 
from dbo.production a
where a.id_company in (
	select id_company
	from dbo.[order] a
	join dbo.production b on b.id_production = a.id_production
	group by id_company
	having count(*) >= 120
)
group by a.id_company

--5. Дать списки сделавших заказы аптек по всем дилерам компании “AstraZeneca”.
--	Если у дилера нет заказов, в названии аптеки проставить NULL.

select distinct b.*, d.*
from dbo.company a
join dbo.dealer b on b.id_company = a.id_company
left join dbo.[order] c on c.id_dealer = b.id_dealer
left join dbo.pharmacy d on d.id_pharmacy = c.id_pharmacy
where a.name = 'AstraZeneca'
order by b.id_dealer

--6. Уменьшить на 20% стоимость всех лекарств, если она превышает 3000, 
--	а длительность лечения не более 7 дней.

update [dbo].[production]
set price = price * 0.8
where id_production in (
	select a.id_production
	from [dbo].[production] a
	join [dbo].[medicine] b on b.id_medicine = a.id_medicine
	where (a.price > 3000) and (b.cure_duration < 7)
)

--7. Добавить необходимые индексы.
CREATE NONCLUSTERED INDEX [IX_company_name] ON [dbo].[company]
(
	[name] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_medicine_name] ON [dbo].[medicine]
(
	[name] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_order_id_production] ON [dbo].[order]
(
	[id_production] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_dealer_id_company] ON [dbo].[dealer]
(
	[id_company] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_order_id_dealer] ON [dbo].[order]
(
	[id_dealer] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_order_id_pharmacy] ON [dbo].[order]
(
	[id_pharmacy] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_production_id_medicine] ON [dbo].[production]
(
	[id_medicine] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_production_price] ON [dbo].[production]
(
	[price] ASC
)
go

