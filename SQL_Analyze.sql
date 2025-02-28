select * from customers_senior
select * from rooms_senior
select * from bookings_senior
select * from payments_senior
select * from services_senior
select * from service_usage_senior

--------
select cs.customer_id, cs.created_at, room_id, check_in, check_out
from customers_senior cs join bookings_senior bs on cs.customer_id = bs.customer_id
where cs.customer_id = 1
---
select min(check_out), max(check_out)
from bookings_senior
---
select *
from payments_senior
where booking_id = 3
---
select customer_id, rs.room_id, ps.booking_id, check_in, check_out,
	case 
		when check_in = check_out then 1
		else DATEDIFF(day, check_in, check_out)
	end as stay_duration,
	price_per_night, amount, payment_date
from rooms_senior rs join bookings_senior bs on rs.room_id = bs.room_id join payments_senior ps on ps.booking_id = bs.booking_id

-- Tỉ lệ lấp đầy của từng loại phòng
with cte_room_data as (
	select room_type, count(distinct rs.room_id) as cnt_room, DATEDIFF(DAY, min(check_in), max(check_out)) as available_day,
	sum(
		case 
			when check_in = check_out then 1
			else DATEDIFF(DAY, check_in, check_out)
		end) as cnt_stay_duration
	from rooms_senior rs join bookings_senior bs on rs.room_id = bs.room_id
	where bs.status = 'Confirmed'
	group by room_type
)
select room_type, round(cnt_stay_duration*100.0/(cnt_room*available_day), 2) as occupancy_rate
from cte_room_data

-- Khách hàng thường đặt phòng theo mùa hay có xu hướng cụ thể?
select month(check_in) as month_check_in, count(booking_id) as cnt_booking
from bookings_senior
group by month(check_in)
order by cnt_booking desc

select datepart(quarter, check_in) as quarter_check_in, count(booking_id) as cnt_booking
from bookings_senior
group by datepart(quarter, check_in)
order by cnt_booking desc

-- Những dịch vụ nào được sử dụng nhiều nhất?
select service_name, count(usage_id) as cnt_usage
from services_senior ss join service_usage_senior as sus on ss.service_id = sus.service_id
group by service_name
order by cnt_usage desc

-- Giá phòng hiện tại có ảnh hưởng đến lượng đặt phòng không?
select room_type, price_per_night, count(booking_id) as cnt_booking
from rooms_senior rs join bookings_senior bs on rs.room_id = bs.room_id
group by room_type, price_per_night
order by cnt_booking desc

-- Bao nhiêu % đặt phòng bị hủy?
with cte_booking_data as (
	select rs.room_type, count(booking_id) as cnt_booking,
		   sum (case when bs.status = 'Cancelled' then 1 else 0 end) as cnt_cancelled_booking
	from rooms_senior rs join bookings_senior bs on rs.room_id = bs.room_id
	group by rs.room_type
)
select room_type, round(cnt_cancelled_booking*100.0/cnt_booking,2) as booking_cancelled_rate
from cte_booking_data
