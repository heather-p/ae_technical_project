select
    "Operation" as operation,
    "Agency Number" as agency_number,
    nullif(trim("Operation Name"), '') as operation_name,
    nullif(trim("Address"), '') as street_address,
    nullif(trim("City"), '') as address_city,
    nullif(trim("State"), '') as address_state,
    nullif(trim("Zip"::varchar), '') as postal_code,
    nullif(trim("County"), '') as county,
    regexp_replace("Phone", '[^0-9]', '', 'g') as phone,
    nullif(trim("Type"), '') as type,
    nullif(trim("Status"), '') as status,
    strptime("Issue Date", '%-m/%-d/%y')::date as issue_date,
    "Capacity" as capacity,
    nullif(trim("Email Address"), '') as email_address,
    "Facility ID" as facility_id,
    "Monitoring Frequency" as monitoring_frequency,
    "Infant"::boolean as infant,
    "Toddler"::boolean as toddler,
    "Preschool"::boolean as preschool,
    "School"::boolean as school
from {{ ref('source3') }}
qualify row_number() over (partition by phone order by issue_date asc) = 1
