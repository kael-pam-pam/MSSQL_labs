
use Lab7

-- 1. Добавить внешние ключи.

ALTER TABLE [dbo].[lesson]  WITH CHECK ADD  CONSTRAINT [FK_lesson_group] FOREIGN KEY([id_group])
REFERENCES [dbo].[group] ([id_group])
GO

ALTER TABLE [dbo].[lesson] CHECK CONSTRAINT [FK_lesson_group]
GO

ALTER TABLE [dbo].[lesson]  WITH CHECK ADD  CONSTRAINT [FK_lesson_subject] FOREIGN KEY([id_subject])
REFERENCES [dbo].[subject] ([id_subject])
GO

ALTER TABLE [dbo].[lesson] CHECK CONSTRAINT [FK_lesson_subject]
GO

ALTER TABLE [dbo].[lesson]  WITH CHECK ADD  CONSTRAINT [FK_lesson_teacher] FOREIGN KEY([id_teacher])
REFERENCES [dbo].[teacher] ([id_teacher])
GO

ALTER TABLE [dbo].[lesson] CHECK CONSTRAINT [FK_lesson_teacher]
GO

ALTER TABLE [dbo].[mark]  WITH CHECK ADD  CONSTRAINT [FK_mark_lesson] FOREIGN KEY([id_lesson])
REFERENCES [dbo].[lesson] ([id_lesson])
GO

ALTER TABLE [dbo].[mark] CHECK CONSTRAINT [FK_mark_lesson]
GO

ALTER TABLE [dbo].[mark]  WITH CHECK ADD  CONSTRAINT [FK_mark_student] FOREIGN KEY([id_student])
REFERENCES [dbo].[student] ([id_student])
GO

ALTER TABLE [dbo].[mark] CHECK CONSTRAINT [FK_mark_student]
GO

ALTER TABLE [dbo].[student]  WITH CHECK ADD  CONSTRAINT [FK_student_group] FOREIGN KEY([id_group])
REFERENCES [dbo].[group] ([id_group])
GO

ALTER TABLE [dbo].[student] CHECK CONSTRAINT [FK_student_group]
GO

-- 2. Выдать оценки студентов по информатике если они обучаются данному
--	предмету. Оформить выдачу данных с использованием view.
create view informaticsMark
as
	select b.id_lesson, d.name studentName, e.id_group, e.name groupName, c.mark, b.[date] 
	from [dbo].[subject] a
	join [dbo].[lesson] b on a.id_subject = b.id_subject
	join [dbo].[mark] c on c.id_lesson = b.id_lesson
	join [dbo].[student] d on d.id_student = c.id_student
	join [dbo].[group] e on e.id_group = d.id_group
	where a.name = 'Информатика'
go

CREATE NONCLUSTERED INDEX [IX_lesson_id_subject] ON [dbo].[lesson]
(
	[id_subject] ASC
)
go

CREATE NONCLUSTERED INDEX [IX_mark_id_lesson_id_student] ON [dbo].[mark]
(
	[id_lesson] ASC,
	[id_student] ASC
)
INCLUDE
(
	[mark]
)
go

CREATE NONCLUSTERED INDEX [IX_subject_name] ON [dbo].[subject]
(
	[name] ASC
)
go

-- 3. Дать информацию о должниках с указанием фамилии студента и названия
--	предмета. Должниками считаются студенты, не имеющие оценки по предмету,
--	который ведется в группе. Оформить в виде процедуры, на входе
--	идентификатор группы.

create procedure debtorStudentsInGroup
	@id_group int
as
begin
	select a.id_subject, d.name subjectName, a.id_group, e.name groupName, b.id_student, b.name studentName
	from (
		select distinct id_subject, id_group
		from lesson
	) a
	join student b on a.id_group = b.id_group
	left join (
		select distinct a.id_student, b.id_subject
		from mark a
		join lesson b on a.id_lesson = b.id_lesson
	) c on c.id_student = b.id_student and c.id_subject = a.id_subject
	join subject d on d.id_subject = a.id_subject
	join [group] e on e.id_group = a.id_group
	where a.id_group = @id_group and c.id_student is null
	order by subjectName, studentName
end

exec debtorStudentsInGroup 4

CREATE NONCLUSTERED INDEX [IX_lesson_id_subject_id_group] ON [dbo].[lesson]
(
	[id_subject] ASC, 
	[id_group] ASC
)
go

-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по
--	которым занимается не менее 35 студентов.

select b.id_subject, avg(a.mark) markAvg
from mark a
join lesson b on a.id_lesson = b.id_lesson
where b.id_subject in (
	select a.id_subject
	from (
		select distinct id_group, id_subject
		from lesson
	) a
	join student b on a.id_group = b.id_group
	group by a.id_subject
	having count(*) >= 35)
group by b.id_subject
order by b.id_subject

CREATE NONCLUSTERED INDEX [IX_student_id_group] ON [dbo].[student]
(
	[id_group] ASC
)
go

-- 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с
--	указанием группы, фамилии, предмета, даты. При отсутствии оценки заполнить
--	значениями NULL поля оценки.

select a.id_group, a.name groupName, b.id_subject, d.name subjectName, c.id_student, c.name studentName, e.mark, e.date
from [group] a
join (
	select distinct id_group, id_subject
	from lesson
) b on b.id_group = a.id_group
join student c on c.id_group = a.id_group
join subject d on d.id_subject = b.id_subject
left join (
	select b.id_subject, a.id_student, a.mark, b.date
	from mark a
	join lesson b on a.id_lesson = b.id_lesson
) e on c.id_student = e.id_student and b.id_subject = e.id_subject
where a.name = 'ВМ'
order by d.name, c.name, e.date

CREATE NONCLUSTERED INDEX [IX_group_name] ON [dbo].[group]
(
	[name] ASC
)
go

-- 6. Всем студентам специальности ПС, получившим оценки меньшие 5 по предмету
--	БД до 12.05, повысить эти оценки на 1 балл.

begin tran
	
	update mark
	set mark = mark + 1
	where id_mark in (
		select a.id_mark
		from mark a
		join student b on a.id_student = b.id_student
		join [group] c on c.id_group = b.id_group
		join lesson d on d.id_lesson = a.id_lesson
		join subject e on e.id_subject = d.id_subject
		where c.name = 'ПС' and e.name = 'БД' and d.date < '2019-05-12' and a.mark < 5)

commit
rollback
