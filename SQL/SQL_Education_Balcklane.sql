- where "Email" like '%science-first%'

- ,lcase(LEFT(SUBSTRING(pd."email",LOCATE('@', pd."email")),Locate('.',SUBSTRING(pd."email",LOCATE('@', pd."email")+1)))) AS "domain_company"
,substring(pd."email",LOCATE('@', pd."email")) as "domain_company_country"
- where ride_date >{d'2015-01-01'}
and cast(customer_special_request as string) <> ''

Dateparse -> fixes Datum hinterlegen
,CASE WHEN "td.corp_created_at" is null then parseDate('2009-12-31 22:00:00','yyyy-MM-dd hh:mm:ss')
ELSE "td.corp_created_at"
END as corp_created_at

empty or null
SELECT * FROM

### added Hartmut feature


(SELECT FORMATTIMESTAMP(starts_at, 'yyyy-MM-dd') as day_date

  , count(tour_id) as ride_count

 FROM frontend_helper.fe_tour_data t

 WHERE business_district_id = 133

   AND created_at >= '2016-06-01'

 GROUP BY FORMATTIMESTAMP(starts_at, 'yyyy-MM-dd')

) r

FULL OUTER JOIN

(SELECT FORMATTIMESTAMP(created_at, 'yyyy-MM-dd') as day_date

  , count(tour_id) as booking_count

 FROM frontend_helper.fe_tour_data t

 WHERE business_district_id = 133

   AND created_at >= '2016-06-01'

 GROUP BY FORMATTIMESTAMP(created_at, 'yyyy-MM-dd')

) b

ON r.day_date = b.day_date order by 3,1 ASC


SELECT * FROM

CREATE VIEW frontend.fe_affiliate_management_performance_bonus_data AS

/*###############################################################
## author Kurt Baarman <kurt.baarman@blacklane.com>
## status near final
## last touched 2016-03-11 KB Change KPIs to be calculated on quarterly basis and removed events
##
## Affiliate management performance bonus data - near final version
##
## To do:
## Create real values for satifaction rate - and change it to quality score
## Correct handling of tours with incidents
##
## Changelog
## 2016-03-11 KB Change KPIs to be calculated on quarterly basis and removed events
## 2016-03-02 KB Start calculation from Q2 2015
## 2016-03-01 KB Table created
##
###############################################################*/

WITH

base_tour_data AS
(SELECT
op.region,
op.area,
YEAR(op.ride_time_hq) AS "year",
/*MONTHNAME(op.ride_time_hq) AS period,*/
'Q'||QUARTER(op.ride_time_hq) AS period,
op.agreed_driver_price_index AS agreed_driver_price_index,
CASE
WHEN op.tour_state IN ('finished', 'no_show') THEN 1
WHEN op.tour_state IN ('rejected') THEN 0
ELSE NULL END AS fulfillment_rate,
CASE
WHEN op.tour_state NOT IN ('finished', 'no_show') THEN NULL
ELSE 1 END AS satisfaction_rate
FROM frontend.fe_operational_analysis_development AS op
WHERE op.passenger_category IN ('Private', 'Corporate')
AND op.ride_time_passed
AND op.ride_time_hq >= '2015-04-01'
AND op.tour_state IN ('finished', 'no_show', 'rejected')),

kpi_period_area AS (SELECT
base_tour_data.area,
base_tour_data.year,
base_tour_data.period,
AVG(base_tour_data.agreed_driver_price_index) AS agreed_driver_price_index,
AVG(base_tour_data.fulfillment_rate) AS fulfillment_rate,
AVG(base_tour_data.satisfaction_rate) AS satisfaction_rate
FROM base_tour_data
GROUP BY 1, 2, 3),

kpi_period_global AS (SELECT
'Global' AS area,
base_tour_data.year,
base_tour_data.period,
AVG(base_tour_data.agreed_driver_price_index) AS agreed_driver_price_index,
AVG(base_tour_data.fulfillment_rate) AS fulfillment_rate,
AVG(base_tour_data.satisfaction_rate) AS satisfaction_rate
FROM base_tour_data
GROUP BY 1, 2, 3),

kpi_year_area AS (SELECT
base_tour_data.area,
base_tour_data.year,
'Year' AS period,
AVG(base_tour_data.agreed_driver_price_index) AS agreed_driver_price_index,
AVG(base_tour_data.fulfillment_rate) AS fulfillment_rate,
AVG(base_tour_data.satisfaction_rate) AS satisfaction_rate
FROM base_tour_data
GROUP BY 1, 2, 3),

kpi_year_global AS (SELECT
'Global' AS area,
base_tour_data.year,
'Year' AS period,
AVG(base_tour_data.agreed_driver_price_index) AS agreed_driver_price_index,
AVG(base_tour_data.fulfillment_rate) AS fulfillment_rate,
AVG(base_tour_data.satisfaction_rate) AS satisfaction_rate
FROM base_tour_data
GROUP BY 1, 2, 3),

kpi_total AS (SELECT
*
FROM kpi_period_area
UNION ALL
SELECT
*
FROM kpi_period_global
UNION ALL
SELECT
*
FROM kpi_year_area
UNION ALL
SELECT
*
FROM kpi_year_global)

SELECT
"area"||"year"||"period" AS "key",
"area",
"year",
"period",
"agreed_driver_price_index",
"fulfillment_rate",
"satisfaction_rate"
FROM kpi_total

CREATE VIEW frontend.fe_cohort_data AS

/*###############################################################
## author Hartmut Leps <hartmut.leps@blacklane.com>
## status wip
## last touched 2016-04-29-FK-fixed missing fx_rate for fct_cr_net_trade_incl_boni
## 2016-04-07-HL-fixed GrProfit, added gross_revenue
## 2016-03-03-HL-added replaced-tag to fe_tour_data and pulled it up
## 2016-01-09-HL-added bd_id,lsp_id,pricing_id,diputed_flag,confirm_flag
## 2016-02-09-HL-credits replaced wit credit allocation
## 2016-02-01-HL-added event flag
## 2016-01-18-HL-changed some fields, added fx, added affilate
## 2015-11-02-HL-view created
###############################################################*/

SELECT
pd.passenger_number
, pd.passenger_id
, pd.passenger_id_m as unique_passenger_id
, pd.registered_at
, pd.title
, CASE WHEN LEFT(CASE
WHEN td.passenger_title IS NOT NULL AND td.passenger_title <> '.'
THEN td.passenger_title
ELSE pd.title
END, 3) IN ('mrs','ms','mis', 'unk')
THEN 'f'
ELSE 'm'
END as "passenger_gender"
, pad.first_booking_date
, pad.first_rev_booking_date
, pad.last_booking_date
, pad.acquisition_bd
, pad.acquisition_country

, md.tour_id
, md.booking_date
, formattimestamp(md.booking_date, 'yyyy-MM-01') as booking_month
, td.starts_at as ride_date
, formattimestamp(td.starts_at, 'yyyy-MM-01') as ride_month
, "bd.business_district_name" as ride_bd
, "bd.country_name" as ride_county
, "bd.region_name" as ride_region
, md.business_district_id
, td.state as tour_state
, ad.tour_type
, td.car_class
, id.revenue_relevant
, td.route_distance
, td.hourly_duration
, td.company_id as lsp_id
, td.pricing_id
, td.disputed_flag
, td.confirm_instantly

, td.car_class as service_class
, pd.fraud_state
, pd.corporation_id
, "cd.name" as corporation_name
, pad.voucher_type

, CASE WHEN pd.corporation_id IS NULL THEN 0 ELSE 1 END AS is_corp
, CASE WHEN td.booked_via IN ('api', 'cassandra') THEN 1 ELSE 0 END as app_booking
, cd.created_at as corp_created_at
, cd.disabled_at as corp_disabled_at
, md.currency as invoice_currency
, id.fx_rate as fx_rate
, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 THEN 'nb' ELSE 'nn/bb' END AS vat_schema

, md.voucher_amount
, md.fct_voucher_amount
, CASE WHEN td.created_at = pad.first_booking_date THEN md.voucher_amount ELSE 0 END as fst_voucher_amount
, CASE WHEN td.created_at = pad.first_booking_date THEN md.fct_voucher_amount ELSE 0 END as fct_fst_voucher_amount
, id.cancelation_count * id.cancelation_amount as in_cancelation_amt
, id.cancelation_count * id.cancelation_amount / id.fx_rate as fct_in_cancelation_amt
, id.corp_discount_count * id.corp_discount_amount as in_corp_rebate_amt
, id.corp_discount_count * id.corp_discount_amount / id.fx_rate as fct_in_corp_rebate_amt
, id.detour_count * id.detour_amount as in_detour_amt
, id.detour_count * id.detour_amount / id.fx_rate as fct_in_detour_amt
, id.wait_time_count * id.wait_time_amount as in_wait_time_amt
, id.wait_time_count * id.wait_time_amount / id.fx_rate as fct_in_wait_time_amt
, id.tax_count * id.tax_amount as in_tax_amt
, id.tax_count * id.tax_amount / id.fx_rate as fct_in_tax_amt
, id.tour_count * id.tour_amount as in_tour_amt
, id.tour_count * id.tour_amount / id.fx_rate as fct_in_tour_amt
, id.other_count * id.other_amount as in_other_amt
, id.other_count * id.other_amount / id.fx_rate as fct_in_other_amt

, id.net_amount as net_invoice
, id.net_amount / id.fx_rate as fct_net_invoice

, id.net_amount - (id.voucher_count * id.voucher_amount) as gross_revenue
, (id.net_amount - (id.voucher_count * id.voucher_amount)) / id.fx_rate as fct_gross_revenue

, crd.net_base_price as cr_net_base_price
, cwb.net_base_price as cr_net_base_price_alloc
, crd.fct_net_base_price as fct_cr_net_base_price

, crd.differing_distance_price as cr_differing_distance_price
, crd.waiting_time_price as cr_waiting_time_price
, crd.net_trade_price as cr_net_trade_price
, crd.fct_net_trade_price as fct_cr_net_trade_price

, cwb.net_bonus_allocation_amount as cr_net_bonus_allocation_amt
, cwb.net_other_allocation_amount as cr_net_other_allocation_amt

, crd.gross_trade_price
, crd.fct_gross_trade_price

, cwb.net_trade_incl_boni as cr_net_trade_incl_boni
, cwb.net_trade_incl_boni / id.fx_rate as fct_cr_net_trade_incl_boni
, cwb.gross_trade_incl_boni as cr_gross_trade_incl_boni
, cwb.gross_trade_incl_boni/ id.fx_rate as fct_cr_gross_trade_incl_boni

, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price
ELSE crd.net_trade_price
END as cr_net_trade_price_relevant
, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price / id.fx_rate
ELSE crd.net_trade_price / id.fx_rate
END as fct_cr_net_trade_price_relevant

, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END as cr_net_trade_incl_boni_relevant
, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni / id.fx_rate
ELSE cwb.net_trade_incl_boni / id.fx_rate
END as fct_cr_net_trade_incl_boni_relevant

, crd.vat as cr_vat
, crd.fct_vat as fct_cr_vat

/* GROSS PROFIT OLD, INCORRECT
, id.net_amount - CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price / id.fx_rate
ELSE crd.net_trade_price / id.fx_rate
END
as gross_profit */
, id.net_amount - CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END
as gross_profit
, (id.net_amount - CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END) / id.fx_rate
as fct_gross_profit

, id.net_amount - (id.voucher_count * id.voucher_amount)
- CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END
as gross_profit_bef_voucher

, (id.net_amount - (id.voucher_count * id.voucher_amount)
- CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END) / id.fx_rate
as fct_gross_profit_bef_voucher

, seg_f.channel_group
, seg_f.customer_group
, seg_f.onboarding_date
, td.affiliate as affiliate_id
, sc.segment as segment_combined
, seg.segment as segment_var
, seg_f.segment as segment_fix
, CASE WHEN erl.account_id IS NOT NULL
THEN 1
ELSE 0
END AS "is_event_by_event_ref_list"
, CASE WHEN erl2.event_reference IS NOT NULL
THEN 1
ELSE 0
END AS "is_event_by_blacklane_booking"
/* identify all customer */
, CASE WHEN td.customer_reference IN (SELECT DISTINCT event_reference FROM "frontend_helper.fe_tour_event_reference_list" WHERE event_reference IS NOT NULL)
THEN 1
ELSE 0
END "is_event_booking"
, td.customer_reference
, "td.was_replaced"
, "td.was_replaced_by"
, td.starts_at <= NOW() as tour_has_passed
, NOW() as "ref_stamp_passed"
, md.agreed_driver_price_index
, cc.customer_country

FROM "frontend_two.fe_fin_tour_margin_data" md
JOIN "frontend_helper.fe_fin_tour_invoice_details" id ON id.tour_id = md.tour_id
JOIN "frontend_helper.fe_tour_data" td ON td.tour_id = md.tour_id
JOIN "frontend_helper.fe_passenger_activity_details_unique" pad ON pad.passenger_id = td.passenger_id
JOIN "frontend_helper.fe_pd_passenger_details" pd on pd.passenger_id = td.passenger_id
JOIN "frontend_helper.business_districts_macro_region" bd ON bd.business_district_id = md.business_district_id
LEFT JOIN "frontend_helper.fe_auction_details" ad ON ad.tour_id = md.tour_id
LEFT JOIN "frontend_helper.fe_fin_tour_credit_details" crd ON crd.tour_id = md.tour_id
LEFT JOIN "frontend_two.credit_w_allocated_bonus" cwb ON cwb.tour_id = md.tour_id
LEFT JOIN "frontend_helper.fe_pd_corporation_details" cd ON cd.corporation_id = pd.corporation_id
LEFT JOIN "frontend_two.segmentation_combined" sc ON sc.unique_passenger_id = pd.passenger_id_m
LEFT JOIN "frontend_helper.segmentation_corporation" seg ON seg.corporation_id = pd.corporation_id
AND seg.sg_year = year(td.starts_at)
AND seg.sg_month = month(td.starts_at)
LEFT JOIN "frontend_helper.segmentation_corporation" seg_f ON seg_f.corporation_id = pd.corporation_id
AND seg_f.latest = 1
LEFT JOIN "frontend_helper.fe_tour_event_reference_list" erl ON erl.event_reference = TRIM(td.customer_reference)
AND erl.account_id = td.passenger_id
/* UNPRETTY WORKAROUND TO INCLUDE EVENTS BOOKED VIA BLACKLANE GMBH ACCOUNTS (CORP ID 228) */
LEFT JOIN (SELECT DISTINCT event_reference, passenger_id
FROM "frontend_helper.fe_tour_event_reference_list" , "frontend_helper.fe_pd_passenger_details"
WHERE event_reference IS NOT NULL AND corporation_id = 228) erl2 ON erl2.event_reference = TRIM(td.customer_reference) AND erl2.passenger_id = td.passenger_id
LEFT JOIN "frontend_helper.fe_customer_country_per_tour_id" cc ON cc.tour_id = md.tour_id

/*PREVIOUS VERSION*/
/*CREATE VIEW frontend.fe_cohort_data AS */

/*###############################################################
## author Hartmut Leps <hartmut.leps@blacklane.com>
## status wip
## last touched 2016-03-03-HL-added replaced-tag to fe_tour_data and pulled it up
## 2016-01-09-HL-added bd_id,lsp_id,pricing_id,diputed_flag,confirm_flag
## 2016-02-09-HL-credits replaced wit credit allocation
## 2016-02-01-HL-added event flag
## 2016-01-18-HL-changed some fields, added fx, added affilate
## 2015-11-02-HL-view created
###############################################################*/
/*

SELECT
pd.passenger_number
, pd.passenger_id
, pd.passenger_id_m as unique_passenger_id
, pd.registered_at
, pd.title
, CASE WHEN LEFT(CASE
WHEN td.passenger_title IS NOT NULL AND td.passenger_title <> '.'
THEN td.passenger_title
ELSE pd.title
END, 3) IN ('mrs','ms','mis', 'unk')
THEN 'f'
ELSE 'm'
END as "passenger_gender"
, pad.first_booking_date
, pad.first_rev_booking_date
, pad.last_booking_date
, pad.acquisition_bd
, pad.acquisition_country

, md.tour_id
, md.booking_date
, formattimestamp(md.booking_date, 'yyyy-MM-01') as booking_month
, td.starts_at as ride_date
, formattimestamp(td.starts_at, 'yyyy-MM-01') as ride_month
, "bd.name" as ride_bd
, md.business_district_id
, td.state as tour_state
, ad.tour_type
, td.car_class
, id.revenue_relevant
, td.route_distance
, td.hourly_duration
, td.company_id as lsp_id
, td.pricing_id
, td.disputed_flag
, td.confirm_instantly

, td.car_class as service_class
, pd.fraud_state
, pd.corporation_id
, "cd.name" as corporation_name
, pad.voucher_type

, CASE WHEN pd.corporation_id IS NULL THEN 0 ELSE 1 END AS is_corp
, CASE WHEN td.booked_via IN ('api', 'cassandra') THEN 1 ELSE 0 END as app_booking
, cd.created_at as corp_created_at
, cd.disabled_at as corp_disabled_at
, md.currency as invoice_currency
, id.fx_rate as fx_rate
, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 THEN 'nb' ELSE 'nn/bb' END AS vat_schema
, md.voucher_amount
, md.fct_voucher_amount
, CASE WHEN td.created_at = pad.first_booking_date THEN md.voucher_amount ELSE 0 END as fst_voucher_amount
, CASE WHEN td.created_at = pad.first_booking_date THEN md.fct_voucher_amount ELSE 0 END as fct_fst_voucher_amount
, id.cancelation_count * id.cancelation_amount as in_cancelation_amt
, id.cancelation_count * id.cancelation_amount / id.fx_rate as fct_in_cancelation_amt
, id.corp_discount_count * id.corp_discount_amount as in_corp_rebate_amt
, id.corp_discount_count * id.corp_discount_amount / id.fx_rate as fct_in_corp_rebate_amt
, id.detour_count * id.detour_amount as in_detour_amt
, id.detour_count * id.detour_amount / id.fx_rate as fct_in_detour_amt
, id.wait_time_count * id.wait_time_amount as in_wait_time_amt
, id.wait_time_count * id.wait_time_amount / id.fx_rate as fct_in_wait_time_amt
, id.tax_count * id.tax_amount as in_tax_amt
, id.tax_count * id.tax_amount / id.fx_rate as fct_in_tax_amt
, id.tour_count * id.tour_amount as in_tour_amt
, id.tour_count * id.tour_amount / id.fx_rate as fct_in_tour_amt
, id.other_count * id.other_amount as in_other_amt
, id.other_count * id.other_amount / id.fx_rate as fct_in_other_amt
, id.net_amount as net_invoice
, id.net_amount / id.fx_rate as fct_net_invoice
, crd.net_base_price as cr_net_base_price
, cwb.net_base_price as cr_net_base_price_alloc
, crd.fct_net_base_price as fct_cr_net_base_price
, crd.differing_distance_price as cr_differing_distance_price
, cwb.differing_distance_price as cr_differing_distance_price_alloc
, crd.waiting_time_price as cr_waiting_time_price
, cwb.waiting_time_price as cr_waiting_time_price_alloc
, crd.net_trade_price as cr_net_trade_price
, cwb.net_trade_price as cr_net_trade_price_alloc
, crd.fct_net_trade_price as fct_cr_net_trade_price
, cwb.net_bonus_allocation_amount as cr_net_bonus_allocation_amt
, cwb.net_other_allocation_amount as cr_net_other_allocation_amt
, cwb.net_trade_incl_boni as cr_net_trade_incl_boni
, cwb.gross_trade_incl_boni as cr_gross_trade_incl_boni
, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price
ELSE crd.net_trade_price
END as cr_net_trade_price_relevant

, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price / id.fx_rate
ELSE crd.net_trade_price / id.fx_rate
END as fct_cr_net_trade_price_relevant

, CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN cwb.gross_trade_incl_boni
ELSE cwb.net_trade_incl_boni
END as cr_net_trade_incl_boni_relevant

, crd.vat as cr_vat
, crd.fct_vat as fct_cr_vat
, crd.gross_trade_price
, crd.fct_gross_trade_price
, id.net_amount - CASE WHEN md.customer_vat_rate = 0 AND md.lsp_vat_rate <> 0 AND "ad.vat_applicable"
THEN crd.gross_trade_price / id.fx_rate
ELSE crd.net_trade_price / id.fx_rate
END
as gross_profit
, seg_f.channel_group
, seg_f.customer_group
, seg_f.onboarding_date
, td.affiliate as affiliate_id
, sc.segment as segment_combined
, seg.segment as segment_var
, seg_f.segment as segment_fix
, CASE WHEN erl.account_id IS NOT NULL
THEN 1
ELSE 0
END as "is_event_booking"
, td.customer_reference
, "td.was_replaced"
, "td.was_replaced_by"
, td.starts_at <= NOW() as tour_has_passed
, NOW() as "ref_stamp_passed"
, md.agreed_driver_price_index

FROM "frontend_two.fe_fin_tour_margin_data" md
JOIN "frontend_helper.fe_fin_tour_invoice_details" id ON id.tour_id = md.tour_id
JOIN "frontend_helper.fe_tour_data" td ON td.tour_id = md.tour_id
JOIN "frontend_helper.fe_passenger_activity_details_unique" pad ON pad.passenger_id = td.passenger_id
JOIN "frontend_helper.fe_pd_passenger_details" pd on pd.passenger_id = td.passenger_id
JOIN "frontend_helper.fe_dim_business_districts" bd ON bd.business_district_id = md.business_district_id
LEFT JOIN "frontend_helper.fe_auction_details" ad ON ad.tour_id = md.tour_id
LEFT JOIN "frontend_helper.fe_fin_tour_credit_details" crd ON crd.tour_id = md.tour_id
LEFT JOIN "frontend_two.credit_w_allocated_bonus" cwb ON cwb.tour_id = md.tour_id
LEFT JOIN "frontend_helper.fe_pd_corporation_details" cd ON cd.corporation_id = pd.corporation_id
LEFT JOIN "frontend_two.segmentation_combined" sc ON sc.unique_passenger_id = pd.passenger_id_m
LEFT JOIN "frontend_helper.segmentation_corporation" seg ON seg.corporation_id = pd.corporation_id
AND seg.sg_year = year(td.starts_at)
AND seg.sg_month = month(td.starts_at)
LEFT JOIN "frontend_helper.segmentation_corporation" seg_f ON seg_f.corporation_id = pd.corporation_id
AND seg_f.latest = 1
LEFT JOIN "frontend_helper.fe_tour_event_reference_list" erl ON erl.event_reference = TRIM(td.customer_reference)
AND erl.account_id = td.passenger_id*/