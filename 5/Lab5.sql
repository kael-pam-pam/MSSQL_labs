
use Lab5

-- 1. Добавить внешние ключи.

ALTER TABLE [dbo].[booking]  WITH CHECK ADD  CONSTRAINT [FK_booking_client] FOREIGN KEY([id_client])
REFERENCES [dbo].[client] ([id_client])
GO

ALTER TABLE [dbo].[booking] CHECK CONSTRAINT [FK_booking_client]
GO

ALTER TABLE [dbo].[room]  WITH CHECK ADD  CONSTRAINT [FK_room_hotel] FOREIGN KEY([id_hotel])
REFERENCES [dbo].[hotel] ([id_hotel])
GO

ALTER TABLE [dbo].[room] CHECK CONSTRAINT [FK_room_hotel]
GO

ALTER TABLE [dbo].[room]  WITH CHECK ADD  CONSTRAINT [FK_room_room_category] FOREIGN KEY([id_room_category])
REFERENCES [dbo].[room_category] ([id_room_category])
GO

ALTER TABLE [dbo].[room] CHECK CONSTRAINT [FK_room_room_category]
GO

ALTER TABLE [dbo].[room_in_booking]  WITH CHECK ADD  CONSTRAINT [FK_room_in_booking_booking] FOREIGN KEY([id_booking])
REFERENCES [dbo].[booking] ([id_booking])
GO

ALTER TABLE [dbo].[room_in_booking] CHECK CONSTRAINT [FK_room_in_booking_booking]
GO

ALTER TABLE [dbo].[room_in_booking]  WITH CHECK ADD  CONSTRAINT [FK_room_in_booking_room] FOREIGN KEY([id_room])
REFERENCES [dbo].[room] ([id_room])
GO

ALTER TABLE [dbo].[room_in_booking] CHECK CONSTRAINT [FK_room_in_booking_room]
GO

-- 2. Выдать информацию о клиентах гостиницы “Космос”, 
--	проживающих в номерах категории “Люкс” на 1 апреля 2019г.
-- ?!	"В дату выезда номер освобождается и доступен для заезда." Считаю, что в дату выезда
--		клиент не проживает в номере.

select f.*
from dbo.hotel a
join dbo.room b on b.id_hotel = a.id_hotel
join dbo.room_category c on c.id_room_category = b.id_room_category
join dbo.room_in_booking d on d.id_room = b.id_room
join dbo.booking e on e.id_booking = d.id_booking
join dbo.client f on f.id_client = e.id_client
where (a.name = 'Космос') and (c.name = 'Люкс') and
	('2019-04-01' between d.checkin_date and d.checkout_date
	and
	d.checkout_date != '2019-04-01')

-- 3. Дать список свободных номеров всех гостиниц на 22 апреля.

select id_hotel, id_room_category, id_room, number, price
from dbo.room
where id_room not in (
	select id_room
	from dbo.room_in_booking
	where (
		'2019-04-22' between checkin_date and checkout_date
		and
		checkout_date != '2019-04-22'
		)
)
order by id_hotel, id_room_category, id_room

-- 4. Дать количество проживающих в гостинице “Космос” на 23 марта по каждой категории номеров

select b.id_room_category, count(*) count_clients
from dbo.hotel a
join dbo.room b on b.id_hotel = a.id_hotel
join dbo.room_in_booking d on d.id_room = b.id_room
where (a.name = 'Космос') and
	('2019-03-23' between d.checkin_date and d.checkout_date
	and
	d.checkout_date != '2019-03-23')
group by b.id_room_category
order by b.id_room_category

-- 5. Дать список последних проживавших клиентов по всем комнатам гостиницы “Космос”, 
--	выехавшим в апреле с указанием даты выезда.

select a.id_room, b.*, a.checkout_date
from (
	select b.id_room, e.id_client, d.checkout_date, ROW_NUMBER() over(partition by b.id_room order by d.checkout_date desc) r_n
	from dbo.hotel a
	join dbo.room b on b.id_hotel = a.id_hotel
	join dbo.room_in_booking d on d.id_room = b.id_room and month(d.checkout_date) = 4
	join dbo.booking e on e.id_booking = d.id_booking
	where a.name = 'Космос'
) a
left join dbo.client b on b.id_client = a.id_client
where a.r_n = 1
order by a.id_room

-- 6. Продлить на 2 дня дату проживания в гостинице “Космос” всем клиентам комнат категории “Бизнес”, 
--	которые заселились 10 мая.

update x
set x.checkout_date = dateadd(dd, 2, x.checkout_date)
from dbo.room_in_booking x
where x.id_room_in_booking in (
	select d.id_room_in_booking
	from dbo.hotel a
	join dbo.room b on b.id_hotel = a.id_hotel
	join dbo.room_category c on c.id_room_category = b.id_room_category
	join dbo.room_in_booking d on d.id_room = b.id_room
	where (a.name = 'Космос') and (c.name = 'Бизнес') and (d.checkin_date = '2019-05-10')
)

-- 7. Найти все "пересекающиеся" варианты проживания. 
--	Правильное состояние: 
--		не может быть забронирован один номер на одну дату несколько раз, т.к. нельзя
--		заселиться нескольким клиентам в один номер. Записи в таблице
--		[room_in_booking] с id_room_in_booking = 5 и 2154 являются примером
--		неправильного состояния, которые необходимо найти. Результирующий кортеж
--		выборки должен содержать информацию о двух конфликтующих номерах.

select a.id_room, a.id_room_in_booking, b.id_room_in_booking
from dbo.room_in_booking a
left join dbo.room_in_booking b on b.id_room = a.id_room and b.id_room_in_booking != a.id_room_in_booking
where (a.checkin_date between b.checkin_date and dateadd(dd, -1, b.checkout_date)) 
order by a.id_room, a.id_room_in_booking, b.id_room_in_booking

-- 8. Создать бронирование в транзакции.

declare 
	@booking_date date = '2016-06-16', 
	@id_client int = 6, 
	@id_room int = 66, 
	@checkin_date date = '2016-07-03',
	@checkout_date date = '2016-07-12',
	@id int

begin tran
	insert into dbo.booking (id_client, booking_date)
	values (@id_client, @booking_date)
	
	set @id = scope_identity();

	insert into dbo.room_in_booking (id_booking, id_room, checkin_date, checkout_date)
	values (@id, @id_room, @checkin_date, @checkout_date)


	select *
	from dbo.booking
	order by id_booking desc

	select *
	from dbo.room_in_booking
	order by id_room_in_booking desc
--ИЛИ ... ИЛИ 
commit
rollback

-- 9. Добавить необходимые индексы для всех таблиц.

CREATE NONCLUSTERED INDEX [IX_booking_id_client] ON [dbo].[booking]
(
	[id_client] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_hotel_name] ON [dbo].[hotel]
(
	[name] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_room_id_hotel] ON [dbo].[room]
(
	[id_hotel] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_room_id_room_category] ON [dbo].[room]
(
	[id_room_category] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_room_category_name] ON [dbo].[room_category]
(
	[name] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_room_in_booking_id_booking] ON [dbo].[room_in_booking]
(
	[id_booking] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_room_in_booking_id_room] ON [dbo].[room_in_booking]
(
	[id_room] ASC
)
go