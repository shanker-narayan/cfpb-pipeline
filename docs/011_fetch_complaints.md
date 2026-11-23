#011 Fetch Complaints Notebook - Notes

### NOTE: 12-month backfill (2025-11-23 -> 2026-11-22) completed as one-time job
###### ~7.1 M rows, 4.25 MB, 18 min 15 sec

### 011 · Fetch CFPB complaints → landing volume

Pulls consumer complaints from the CFPB public API and saves them as raw files in the
landing volume (`/Volumes/<catalog>/bronze/landing/complaints/`), which is backed by the
S3 bucket `shanker-cfpb-pipeline`.

- **Output:** one file per day of `date_received`, named `complaints_YYYY-MM-DD.json`
- **Format:** newline-delimited JSON (one complaint per line), so COPY INTO and Spark can read it directly
- **Used for:** the one-time 12-month backfill *and* the daily incremental run. Same code, only the date parameters change.
- **Next step:** `012_bronze_copy_into` loads these files into the bronze table.


### 2 · API functions
Two helper functions. Nothing runs until Cell 4 calls them.

**`get_page(day, search_after)`** requests one page (up to 10,000 complaints) for a single day.
- `date_received_min` and `date_received_max` are both set to the same day because the API treats max as **inclusive** (tested 11/23).
- Retries up to 3 times with a growing pause if the request fails (timeouts, temporary server errors).
- A 400 error stops immediately, since retrying a bad request won't fix it.

**`fetch_day(day)`** gets *every* complaint for one day by looping through pages.
- **Why paging is needed:** a busy day has ~20–28K complaints, but one request returns at most 10,000.
- **Why not `frm` (offset) paging:** the API rejects `frm` values above 10,000 (tested 11/23).
- **Cursor paging instead:** each result carries a `sort` value. Passing the last result's value as
  `search_after` tells the API "start after this one," which has no depth limit.
- Stores complaints in a dict keyed by `complaint_id`, which removes any duplicates.
- **Safety check:** stops with an error if a page returns no new IDs (the cursor isn't advancing).
- Returns the API's reported total *and* the complaints actually fetched, so Cell 4 can compare them.


### 3 · Parameters
Creates the notebook parameters (shown in the **Parameters panel**, the `{ }` icon in the left sidebar).
When run as a job, the job's parameters override these defaults.

| Parameter | Meaning |
|---|---|
| `catalog` | Which environment to write to (`cfpb_dev` now, `cfpb_prod` later) |
| `start_date` / `end_date` | Inclusive date range to fetch, e.g. 12 months for the backfill, 1 day for daily runs |
| `overwrite` | `false` = skip days already saved (safe to rerun). `true` = re-fetch and replace them. |

Also builds the output folder path from the catalog name and creates it if it doesn't exist.
### 4 · Fetch and write files (4 days in parallel)
For each day in the date range: fetch all complaints, then write them to `complaints_YYYY-MM-DD.json`.

- **Parallel:** 4 days are fetched at once using threads. The work is mostly waiting on the
  CFPB server (~11 sec per query), so overlapping requests cut the backfill from ~2 hrs to ~30 min.
  Kept at 4 to avoid overloading a free public API.
- **Skip existing:** if a day's file already exists and `overwrite = false`, it's skipped, so a
  crashed run can just be rerun and picks up where it left off.
- **Safe writes:** writes to a `.tmp` file first, then renames it. A half-written file never
  appears in the landing folder (important once COPY INTO starts reading from it).
- **Failures don't stop the run:** a failed day is recorded and reported at the end, and a rerun fetches only the missing days.
- **Output order is jumbled** because days finish at different times. That's expected.

**Summary at the end:**
- `Count mismatches` = days where fetched ≠ API total (should be `none`)
- `Failures` = days that errored (should be `none`; rerun the cell to retry them)