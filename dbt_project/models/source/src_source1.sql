select
    nullif(trim("Name"), '') as name,
    nullif(trim("Credential Type"), '') as credential_type,
    nullif(trim("Credential Number"), '') as credential_number,
    "Status" as status,
    strptime("Expiration Date", '%-m/%-d/%y')::date as expiration_date,
    "Disciplinary Action" as disciplinary_action,
    nullif(trim("Address"), '') as address,
    nullif(trim("State"), '') as address_state,
    nullif(trim("County"), '') as county,
    regexp_replace("Phone", '[^0-9]', '', 'g') as phone,
    strptime("First Issue Date", '%-m/%-d/%y')::date as first_issue_date,
    nullif(trim("Primary Contact Name"), '') as primary_contact_name,
    nullif(trim("Primary Contact Role"), '') as primary_contact_role
from {{ ref('source1') }}
qualify row_number() over (partition by phone order by first_issue_date asc) = 1
