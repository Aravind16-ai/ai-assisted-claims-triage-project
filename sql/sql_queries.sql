Create database AI_Assisted_Claims_Triage_Project;
USE AI_Assisted_Claims_Triage_Project;

select * from cleaned_merged_claims limit 10;
select count(*) from cleaned_merged_claims;
select * from cleaned_merged_claims 
where procedure_code is null or amount is null;

describe cleaned_merged_claims;
select claim_date, timestamp from cleaned_merged_claims limit 1;

CREATE INDEX idx_fraud ON cleaned_merged_claims(fraud_flag);
CREATE INDEX idx_procedure ON cleaned_merged_claims(procedure_code);
CREATE INDEX idx_date ON cleaned_merged_claims(claim_date);
show INDEX from  cleaned_merged_claims;

alter table cleaned_merged_claims
partition by range (year(claim_date)) (
partition p2023 values less than (2024),
partition p2024 values less than (2025));

Create database claims_project;
Use claims_project;

Create table claimants(claimant_id int auto_increment primary key,
                       age int not null,
                       bmi decimal (5,2),
                       smoker enum ('yes', 'no'),
                       region varchar(50),
                       smoker_flag boolean);
select count(*) as total_claimants
from claimants;

Create table providers(provider_id varchar (50) primary key);
select count(*) as total_providers
from providers;

Create table claims(claim_id varchar(50) primary key,
    claimant_id int, 
    provider_id varchar(50),
    procedure_code varchar(20), 
    amount decimal(10,2),
    amount_capped decimal(10,2), 
    status varchar(20),
    claim_type varchar(20), 
    claim_date date,
    claim_month varchar(7), 
    needs_review boolean,
    fraud_flag boolean, 
    timestamp datetime,
    risk_score decimal(5,2),
    foreign key (claimant_id) references claimants(claimant_id),
    foreign key (provider_id) references providers(provider_id));
select count(*) as total_claims
from claims;

describe claims;

drop table if exists real_time_alerts;
create table real_time_alerts (
    alert_id int auto_increment primary key,
    claim_id varchar(50), original_claim VARCHAR(50), 
    duplicate_claim VARCHAR(50), rule_name VARCHAR(100),     
    rule_triggered VARCHAR(100), alert_status VARCHAR(50),    
    alert_level VARCHAR(20), risk_score FLOAT,            
    alert_score FLOAT, provider_id VARCHAR(50),     
    claimant_id VARCHAR(50), detection_time DATETIME,     
    detection_timestamp DATETIME,
    triggered_on DATETIME DEFAULT NOW(), 
    provider_fraud_history INT,  
    procedure_code VARCHAR(20), amount FLOAT,                
    days_apart INT, needs_review BOOLEAN);
    
create index idx_alert_claim on real_time_alerts(claim_id);
create index idx_alert_rule on real_time_alerts(rule_triggered);
create index idx_alert_time on real_time_alerts(alert_level);
show index from real_time_alerts;

select count(*) as real_alerts
from real_time_alerts;

alter table real_time_alerts 
add constraint fk_alert_claim
foreign key(claim_id) references claims(claim_id);

insert into claimants (age, bmi, smoker, region, smoker_flag)
values (35, 29.5, 'no', 'southeasth', 0);
select last_insert_id();

select distinct age, bmi, smoker, region, smoker_flag
from AI_Assited_Claims_Triage_Project.cleaned_merged_claims
where bmi not regexp '^[0-9.]+';


insert into real_time_alerts (claim_id, original_claim, duplicate_claim, rule_name, rule_triggered,
  alert_status, alert_level, risk_score, alert_score, provider_id,
  claimant_id, detection_time, detection_timestamp, provider_fraud_history,
  procedure_code, amount, days_apart, needs_review)
values ('generated-uuid', 'generated-uuid', 'duplicate-claim-id',
  'Duplicate_Claim', 'Same procedure in 90 days',
  'Flagged', 'High', 85.0, 85.0, 'test-provider-1234',
  738, NOW(), NOW(), 2, 'PROC123', 500.0, 10, TRUE);
  
select 
  claim_id,
  'High Risk Score',
  case 
    when fraud_flag = 1 then 'Confirmed Fraud'
    when risk_score > 90 then 'Critical Risk'
    when risk_score > 75 then 'High Risk'
  end
from claims
where fraud_flag = 1 or risk_score > 75;

insert ignore into providers(provider_id)
values ('test-provider-1234');

select distinct provider_id
from AI_Assisted_Claims_Triage_Project.cleaned_merged_claims;
select count(*) from providers;
select * from providers where provider_id = 'test-provider-1234';

insert ignore into claims (`claim_id`, `claimant_id`, `provider_id`, `procedure_code`, 
                           `amount`, `amount_capped`, `status`, `claim_type`, `claim_date`,
                           `claim_month`, `needs_review`,`fraud_flag`, `timestamp`, `risk_score`)
select
    cmc.claim_id, c.claimant_id, cmc.provider_id,
    cmc.procedure_code, cmc.amount, cmc.amount_capped,
    cmc.status, cmc.claim_type, cmc.claim_date,
    cmc.claim_month, cmc.needs_review,
    cmc.fraud_flag, cmc.timestamp, cmc.risk_score
    
from AI_Assisted_Claims_Triage_Project.cleaned_merged_claims as cmc
join claimants c on cmc.age = c.age and round(cmc.bmi, 1) = round(c.bmi, 1) 
	   and trim(lower(cmc.smoker)) = trim(lower(c.smoker)) 
       and trim(lower(cmc.region)) = trim(lower(c.region))
       and cmc.smoker_flag = c.smoker_flag;
select count(*) 
from AI_Assisted_Claims_Triage_Project.cleaned_merged_claims cmc
join claimants c on cmc.age = c.age 
 and round(cmc.bmi, 1) = round(c.bmi, 1)
 and trim(lower(cmc.smoker)) = trim(lower(c.smoker))
 and trim(lower(cmc.region)) = trim(lower(c.region))
 and cmc.smoker_flag = c.smoker_flag;


-- Business Rules
-- Rule 1: Duplicate Claims Detection 

select 
    a.claim_id as original_claim,
    b.claim_id as duplicate_claim,
    a.claimant_id, a.procedure_code as original_procedure,
    a.claim_date as original_date,
    b.claim_date as duplicate_date,
    datediff(b.claim_date, a.claim_date) as days_apart
from claims a
join claims b on a.claimant_id = b.claimant_id
 and a.procedure_code  LIKE CONCAT(SUBSTRING(b.procedure_code, 1, 3), '%')
 and a.claim_id <> b.claim_id
 and abs(datediff(a.claim_date, b.claim_date)) <= 90;

-- Rule2: High-Risk Patient Profiling

select claimant_id, count(distinct provider_id) as unique_providers
from claims
group by claimant_id
having unique_providers >= 3;

-- Rule3: Cappeed Amount Variance Analysis

select provider_id, procedure_code, count(*) as claim_count,
    round(avg((amount - amount_capped)/amount_capped * 100), 2) as avg_overage_pct
from claims
where amount > amount_capped
group by provider_id, procedure_code
having avg_overage_pct > 0
order by avg_overage_pct desc;

-- Rule4: Duplicate Service Prevention

select a.claimant_id, a.claim_id as claim1, b.claim_id as claim2,
    a.procedure_code, a.claim_date as date1, b.claim_date as date2,
    datediff(b.claim_date, a.claim_date) as days_apart
from claims a
join claims b on a.claimant_id = b.claimant_id
 and a.procedure_code = b.procedure_code
 and a.claim_id <> b.claim_id
 and datediff(b.claim_date, a.claim_date) between 1 and 90;

-- Rule5: Sudden Surge in Risk Score (Daily Spike Detection)
USE claims_project;
with date_info as (
select max(date(claim_date)) as latest_date,
    date_format(max(date(claim_date)), '%Y-%m-%d') as latest_date_formatted,
    date_format(max(date(claim_date)) - interval 1 day, '%Y-%m-%d') as yesterday_formatted,
    date_format(max(date(claim_date)) - interval 7 day, '%Y-%m-%d') as seven_days_ago_formatted
  from claims
  )
select di.latest_date_formatted as analysis_date,
  (select avg(risk_score) from claims 
   where date(claim_date) = di.latest_date) as today_avg,
  (select avg(risk_score) from claims 
   where date(claim_date) between di.seven_days_ago_formatted and di.yesterday_formatted) as prev_7d_avg,
  case 
    when (select avg(risk_score) from claims where date(claim_date) = di.latest_date) > 
         1.2 * (select avg(risk_score) from claims 
                where date(claim_date) between di.seven_days_ago_formatted and di.yesterday_formatted)
    then 'ALERT: Risk score spike detected'
    else 'No significant spike detected'
  end as alert_status
from date_info di;

-- Rule6: High Fraud Score Alert System
select  c.claim_id, c.claimant_id, c.provider_id, c.risk_score,
case when c.fraud_flag = 1 then 'Confirmed Fraud'
     when c.risk_score > 90 then 'Critical Risk'
	 when c.risk_score > 75 then 'High Risk'
    end as alert_level,
    coalesce(p.fraud_history_count, 0) as provider_fraud_history, c.claim_date
from claims c
left join (select provider_id, COUNT(*) as fraud_history_count
    from claims
    where fraud_flag = 1
    group by provider_id) p on c.provider_id = p.provider_id
where (c.fraud_flag = 1 OR c.risk_score > 75)
    and c.claim_date between'2023-01-01' and '2024-07-08'  
order by c.fraud_flag desc, c.risk_score desc, provider_fraud_history desc  
limit 100;

-- Re-verifying Mock Data Test
select * from real_time_alerts 
where rule_name like 'Duplicate_Claim' 
   or rule_name like 'High_Fraud_Score_Alert'
   or rule_name like 'Sudden_Surge_Risk_Score'
   or rule_name like 'Repeat_Claims_Same_Procedure'
   or rule_name like 'Provider_Overcharging'
   or rule_name like 'Multiple_Providers';

select claim_id, claimant_id, procedure_code, claim_date, amount, provider_id
from claims;

create or replace view duplicate_claims_view as
select a.claim_id as original_claim, b.claim_id as duplicate_claim,
    a.claimant_id, a.procedure_code, a.claim_date as original_date,
    b.claim_date as duplicate_date,
    ABS(DATEDIFF(a.claim_date, b.claim_date)) as days_apart
from claims a
join claims b on a.claimant_id = b.claimant_id
 and a.procedure_code = b.procedure_code
 and a.claim_id <> b.claim_id
where ABS(DATEDIFF(a.claim_date, b.claim_date)) <= 90;

select claimant_id, procedure_code, count(*) as count
from claims
group by claimant_id, procedure_code
having count(*) > 1;

SELECT 
    claim_id, rule_name, alert_status, risk_score, alert_level, original_claim, duplicate_claim
FROM real_time_alerts
ORDER BY triggered_on DESC
LIMIT 10;
