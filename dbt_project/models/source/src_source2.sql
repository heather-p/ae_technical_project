with
cleaned as (
    select
        nullif(trim("Type License"), '') as type_license,
        nullif(trim("Company"), '') as company,
        nullif(trim("Accepts Subsidy"), '') as accepts_subsidy,
        nullif(trim("Year Round"), '') as year_round,
        nullif(trim("Daytime Hours"), '') as daytime_hours,
        nullif(trim("Star Level"), '') as star_level,
        nullif(trim("Mon"), '') as monday,
        nullif(trim("Tues"), '') as tuesday,
        nullif(trim("Wed"), '') as wednesday,
        nullif(trim("Thurs"), '') as thursday,
        nullif(trim("Friday"), '') as friday,
        nullif(trim("Saturday"), '') as saturday,
        nullif(trim("Sunday"), '') as sunday,
        split_part(nullif(trim("Primary Caregiver"), ''), ' ', 1) as primary_contact_first_name,
        split_part(nullif(trim("Primary Caregiver"), ''), ' ', 2) as primary_contact_last_name,
        replace(nullif(trim("Primary Caregiver"), ''), concat(primary_contact_first_name, ' ', primary_contact_last_name), '') as primary_contact_role,
        regexp_replace("Phone", '[^0-9]', '', 'g') as phone,
        nullif(trim("Email"), '') as email,
        nullif(trim("Address1"), '') as street_address,
        nullif(trim("Address2"::varchar), '') as address_line_2,
        nullif(trim("City"), '') as address_city,
        nullif(trim("State"), '') as address_state,
        nullif(trim("Zip"::varchar), '') as postal_code,
        split_part(nullif(trim("Subsidy Contract Number"), ''), ': ', 2) as subsidy_contract_number,
        "Total Cap" as total_cap,
        nullif(trim("Ages Accepted 1"), '') as ages_accepted_1,
        nullif(trim("AA2"), '') as ages_accepted_2,
        nullif(trim("AA3"), '') as ages_accepted_3,
        nullif(trim("AA4"), '') as ages_accepted_4,
        strptime(split_part(nullif(trim("License Monitoring Since"), ''), ' ', 3), '%x')::date as license_monitoring_since_date
        -- "School Year Only" as school_year_only,
        -- "Evening Hours" as evening_hours
    from {{ ref('source2') }}
    qualify row_number() over (partition by phone order by license_monitoring_since_date asc) = 1
),

subset_for_unpivot as (
    select
        phone,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday
    from cleaned
),

weekly_schedule_unpivoted as (
    from subset_for_unpivot unpivot (
        hours
        for day in (monday, tuesday, wednesday, thursday, friday, saturday, sunday)
    )
),

agged as (
    select
        phone,
        array_agg(concat(day, ' - ', hours)) as weekly_schedule
    from weekly_schedule_unpivoted
    group by phone
)

select
    cleaned.* exclude (
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday
    ),
    agged.weekly_schedule
from cleaned
left join agged on agged.phone = cleaned.phone
