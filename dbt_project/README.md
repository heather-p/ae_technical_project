### General process notes, limitations, and enhancements I would add if I had more time
- I added the data as seeds due to spreadsheet format; actual ingestion type would vary depending on real data source
  - I manually unmerged the merged cells in a copy of the google sheet to handle that data issue
  - Since this is not intended to be a static data source, seeds would be a poor choice in actual implementation
- I used an in-memory database (`DuckDB`) and `dbt Power User` `VSCode` extension to run and test the models locally, so I could see data output
  - However, that doesn't show data type, so I had to do some trial and error on that, and best guess for intended format for empty columns
  - In a real-world case, I would work with upstream teams or relevant stakeholders to determine expected data
    - On that note, I commented out two columns is `src_source2` which look to have bad data; I would need more context/discuss with upstream team to figure out the intended data for those columns
- Some functions I'm used to weren't available in the syntax available to me with `DuckDB` (e.g., `initcap`)
- The data cleaning I would do would depend on the actual data source. I don't trust spreadsheets/human input, so `nullif(trim(), '')` abounds (although I didn't add that on columns that looked like they would be system-generated)
- There’s some cleaning that I didn’t apply to every similar column (e.g., split part with zip codes) based on available data, but I recognize that data could change and the cleaning should be more broadly applied unless upstream sources have hard-coded format restriction (and maybe even then, for healthy paranoia - upstream source configurations can change, after all)
- I would usually reorganize columns in a more logical order or alphabetize them - whatever style is preferred - usually with the primary key first (both in sql and yml file)
- For timestamp casting, I would confirm source timestamp and desired timestamp (e.g., source in pacific time, desired in UTC)
- I would flesh out the documentation and tests more (I ran out of time for that as well):
  - I would use a package like `dbt-osmosis` to help propagate documentation (including documentation of column data type)
  - I would use the `dbt-utils` package to expand testing functionality, and add custom tests as needed
  - If I had greater understanding of the data, I would add additional tests (such as `accepted_values`)
- I would also have explored combining/normalizing school age (infant, preschool, etc.) info from source2 and source3
- I did not account for file schema changes - see `Future considerations` section for how I would account for those

### The stage model that was meant to be (I ran out of time)
- The stage model would have all four sources outer joined, so we could see duplicates and deltas
- I added a qualify to deduplicate in the `src` models, but would usually leave those with all records (to facilitate data exploration/troubleshooting as needed) and only deduplicate at the `stg` level; I ran out of time for the stage model and wanted to include at least one window function (since it would've been present in the stage level)
  - I realized belatedly that I only deduplicated based on phone number (I cleaned up the primary phone numbers to be the same format with that in mind), rather than phone number _and_ address information
    - I would have liked to select the data in CTEs in a stage model, and normalize the address format such that it could be (semi-) confidently compared (e.g., concatenate address components (handling for nulls in the concatenation), all upper or lowercase) for a qualify and/or join
- If the data did result in true duplicates (phone number and address) and therefore caused row expansion, I would consider a few options:
  - Use a `qualify` to deduplicate
  - `array_agg` or `object_agg` the differing information for the duplicate phone numbers, such that there is only one row per phone number + address
  - Leave the row expansion in place if that's what desired (although I don't think that's a good option)
- Would add timestamp for data load to help confirm what data has changed

### Future considerations
- As mentioned above, a seed is a poor format for a regularly updated data source; I would opt for an incremental model instead, given that the file refreshes would refresh new _and_ existing records
  - Type of ingestion would depend on what's available in the data stack, and exactly how/where the data is loaded (does it make sense to ingest via `Fivetran`/`Stitch`? Does it make sense to write a script to ingest from upload location on a scheduled basis?)
  - With large file size, would want to consider performance (threads allocated/memory size for automated job, table materialization, etc.)
- I manually unmerged the merged cells in a copy of the google sheet to handle that particular data issue, but would need to do that in a more automated/programmatic way when receiving regular real data
- I would normalize state/territory and country format (I know `Snowflake` has some built in data sources that can easily facilitate this mapping; I'm unsure of `Redshift`'s offerings)
- For handling file schema changes, the `dbt-utils` package has a `dbt_utils.star` macro that selects all columns from a source and has an `except` option; at my most recent company, one of my team members wrote a `star_include` macro that emulated some of that function (added `include`, not just `except`), but allowed for listing specific columns to include _without_ breaking if those columns get dropped or names changed. With some effort to recreate that, it would be very handy for this use case
- For making leads available for outreach, I would ensure the final data is in a dashboard-ready format to serve up relevant information to stakeholders: contact first/last name, phone number, email, pipeline stage, etc., supplemented by information received from additional sources
- I discussed several data cleaning/validation options in my first section, because that is a heavy focus of mine; I like to ensure clean data makes its way through the pipeline, and appropriate constraints and tests are applied for data validation (including tests from additional packages and custom tests). Part of that would also include working with stakeholders as needed to understand upstream data
  - Macros can be useful here as well, to reference commonly repeated blocks of code without needing to retype it (or copy/paste) every time, to help reduce the possibility of human error
  - For QA testing, of course while building models I'm a fan of testing as I go, but for continued testing, I would consider some options:
    - A regularly scheduled job (e.g., in `Airflow`) to run all dbt tests, to surface any newly failing tests that would reveal a problem with upstream data or the way it's being transformed
    - Monitoring tools such as Monte Carlo, to test for things such as unexpected changes in row counts (table suddenly dropped a lot of rows incorrectly - would want to be alerted!)
- If any of the lead data moves to `HubSpot`, it would be great to enrich this data with `HubSpot` data - there are some great dbt packages for `HubSpot` as well. I could see a whole customer journey being modeled when enriching with that data - from first lead, sales pipeline progression, usage of the app and contact with customer service even after converted to customer. It could potentially help surface some pain points and room for growth (depending on what data is tracked in HubSpot - obviously I'm not privy to that at this time! Just providing ideas based on what I've done previously with `HubSpot` data)
  - On the customer lifecycle front, would be nice to include billing/financial details as well
  - This enrichment would make sense to include in additional downstream models as well - not just a model to assist sales team and marketing with outreach, but customer lifecycle models, financial models, geographic data to visualize where brightwheel has the most impact as well as the most opportunity, etc.
- I would also build an aggregate model selecting from the "one row per lead" stage model to help answer additional business questions - net new leads, number of conversions (if there's a timestamp associated with that), best performing leads, etc.
  - That would be an all-time aggregate model, but I see value in visualizing smaller chunks of time too - are there times of the year (quarters, months) that tend to be associated with more successful leads? Why is that and how can that be changed/capitalized on? Not only what percentage of existing leads were worked today/last week, but what percent weren't, and is there something tracking why (deal lost could be one, but also lead contact on vacation, etc. - one of those is more concerning than the other)?
