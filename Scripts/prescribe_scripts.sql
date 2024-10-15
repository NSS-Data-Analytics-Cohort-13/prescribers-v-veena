select * from prescriber 
select * from prescription
--Q.1 a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
select  pc.nppes_provider_last_org_name as provider
	,	pc.npi
	,	sum(p1.total_claim_count) as total_claims
		
from prescription p1
join prescriber as pc
using(npi)
group by provider,pc.npi
order by total_claims desc
limit 1;

select npi,sum(total_claim_count) as tt from prescription 
group by npi
order by tt desc
limit 1;


--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
select  pc.nppes_provider_last_org_name as provider
	,	pc.nppes_provider_first_name as first_name
	,	pc.specialty_description as description
	,	sum(p1.total_claim_count) as total_claims
		
from prescriber  pc
join prescription p1
using(npi)
group by provider,first_name,description
order by total_claims desc
;

-- Q.2.a. Which specialty had the most total number of claims (totaled over all drugs)?
select  pc.specialty_description as description
	,	sum(p1.total_claim_count) as total_claims
from prescriber pc
join prescription p1
using(npi)
group by description
order by total_claims desc
;

--2.b. Which specialty had the most total number of claims for opioids?

select * from drug where opioid_drug_flag  ilike 'Y'

select  pc.specialty_description as description
	,	sum(p1.total_claim_count) as total_claims
from prescriber pc
join prescription p1
using(npi)
join drug d1
on p1.drug_name=d1.drug_name
where d1.opioid_drug_flag ilike 'Y'
group by description--,p1.drug_name
order by total_claims desc
;

--Q.2.c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
select * from prescription

select  p1.specialty_description as description
	,	pres.npi
from prescriber as p1
left join prescription as pres
using(npi)
where pres.npi is null
;

--Q.2.d.Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

select  p1.specialty_description as description
	,	round(avg(pres.total_claim_count),3) as avg_of_totalclaims
from prescriber as p1
left join prescription as pres
using(npi)
join drug as d1
on pres.drug_name=d1.drug_name
where d1.opioid_drug_flag ='Y'
group by  p1.specialty_description
order by avg_of_totalclaims desc
limit 1
;


--Q.3.a. Which drug (generic_name) had the highest total drug cost?
select  d1.generic_name
	,	sum(p1.total_drug_cost) as totalcost
from drug as d1
join prescription p1
on p1.drug_name=d1.drug_name
group by d1.generic_name
order by totalcost desc
limit 1;

--Q.3.b.Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

select  round(sum(p1.total_drug_cost)/sum(p1.total_day_supply),2):: money as day_cost
	,	d1.generic_name
--	,	d1.drug_name
from prescription as p1
join drug d1
on p1.drug_name=d1.drug_name
group by d1.generic_name
order by day_cost desc
limit 1 
;

--4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

select drug_name,
	case
		when  d1.opioid_drug_flag = 'Y'       then 'opioid'
		when  d1.antibiotic_drug_flag = 'Y'   then 'antibiotic'
		else  'neither' end as drug_type
from drug as d1
;

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

select  

		case when  d1.opioid_drug_flag = 'Y'       then 'opioid'
		     when  d1.antibiotic_drug_flag = 'Y'   then 'antibiotic'
		     else  'neither' end as drug_type
	,   to_char(sum(p1.total_drug_cost),'FM$999,999,999.00') as cost_spent
--  ,   round(sum(p1.total_drug_cost)):: money as cost_spent
from drug as d1
join prescription p1
on p1.drug_name=d1.drug_name
group by drug_type
;

--Q.5.a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

select * from cbsa where cbsaname ilike '% TN'

select count(c1.cbsa)
from cbsa as c1
join fips_county f1
on c1.fipscounty=f1.fipscounty 
where f1.state = 'TN'
;
--5.b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

select * from population 
select * from fips_county where state = 'TN'


select -- c1.cbsa
--	,	f1.state
		c1.cbsaname
	,	sum(p1.population) as combined_population
from cbsa as c1
join fips_county f1
on c1.fipscounty=f1.fipscounty 
join population p1
on c1.fipscounty=p1.fipscounty
--where f1.state = 'TN'
group by c1.cbsaname --,c1.cbsa,f1.state
order by combined_population desc
--limit 1 
--offset 9
;

--methos 2 using union
(select  cbsaname, sum(population) as total_population,'largest' as flag
from cbsa
join population
using(fipscounty)
group by cbsaname
order by total_population desc
limit 1 )

union
(
select  cbsaname, sum(population) as total_population,'smallest' as flag
from cbsa
join population
using(fipscounty)
group by cbsaname
order by total_population 
limit 1 
)
order by total_population desc
;


--5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
select  f1.county 
	,	p1.population
from fips_county as f1
join population p1
on f1.fipscounty=p1.fipscounty 

left join cbsa c1
on f1.fipscounty=c1.fipscounty
where f1.state = 'TN' and c1.fipscounty is null
--group by c1.cbsa,p1.population
order by p1.population desc
;

--not in
select  f1.county 
	,	p1.population
from fips_county as f1
join population p1
on f1.fipscounty=p1.fipscounty 

/*left join cbsa c1
on f1.fipscounty=c1.fipscounty */
where f1.state = 'TN' and f1.fipscounty NOT IN (
    SELECT fipscounty
    FROM cbsa)
--group by c1.cbsa,p1.population
order by p1.population desc
;
--6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select * from prescription

select  drug_name
	,	sum(total_claim_count) as total_claims
from prescription 
where total_claim_count >=3000
group by drug_name
order by total_claims desc
;
--6.b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

select  p1.drug_name
	,	sum(p1.total_claim_count) as total_claims
	,	d1.opioid_drug_flag as drug_in_opioid
from prescription as p1
join drug as d1
on p1.drug_name=d1.drug_name
where p1.total_claim_count >=3000 and d1.opioid_drug_flag ='Y'
group by p1.drug_name,drug_in_opioid
order by total_claims desc
;
--6.c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
select * from prescriber
where  npi = 1912011792
--nppes_provider_last_org_name ilike '%coffey%' and npi = 1912011792

select * from prescription
where npi=1912011792 order by drug_name

 
 select * from drug where drug_name = 'OXYCODONE HCL'

select  p1.drug_name
	,	sum(p1.total_claim_count) as total_claims
	,	d1.opioid_drug_flag as drug_in_opioid
	,	nppes_provider_first_name as firstname
	,	nppes_provider_last_org_name as lastname
from prescription as p1
join drug  d1
on p1.drug_name=d1.drug_name
join prescriber p2
using(npi) 
where p1.total_claim_count >=3000 and d1.opioid_drug_flag ='Y'
group by p1.drug_name,drug_in_opioid,firstname,lastname
order by total_claims desc
;
--7.The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
select * from prescriber where specialty_description ilike '%pain management' and nppes_provider_city ='NASHVILLE'

select * from drug where opioid_drug_flag ='Y'
--7.a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

select p1.npi,d1.drug_name
from prescriber p1
cross join drug d1
where p1.specialty_description ilike 'pain management' and p1.nppes_provider_city ='NASHVILLE' and d1.opioid_drug_flag ='Y'
--group by p1.npi,d1.drug_name
;
--7.b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

select p1.npi,d1.drug_name,sum(pres.total_claim_count) as total
from prescriber p1
cross join drug d1
left join prescription pres
on d1.drug_name=pres.drug_name
where p1.specialty_description ilike 'pain management' and p1.nppes_provider_city ='NASHVILLE' and d1.opioid_drug_flag ='Y'
group by p1.npi,d1.drug_name
;


--7.c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

select p1.npi,d1.drug_name,coalesce(sum(pres.total_claim_count),0) as total
from prescriber p1
cross join drug d1
left join prescription pres
on d1.drug_name=pres.drug_name
where p1.specialty_description ilike 'pain management' and p1.nppes_provider_city ='NASHVILLE' and d1.opioid_drug_flag ='Y'
group by p1.npi,d1.drug_name
;
