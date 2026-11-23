# 012 · Bronze load with COPY INTO

## What it does
Loads daily CFPB JSON files from the landing volume into `<catalog>.bronze.complaints_bronze`,
adding `source_file` and `loaded_at` for lineage. The schema is inferred on first load
(`mergeSchema` in FORMAT_OPTIONS and COPY_OPTIONS).

## Why COPY INTO (not Auto Loader)
- **Scale fits:** ~365 files for the backfill + 1 per day. Databricks guidance: COPY INTO for
  thousands of files, Auto Loader for millions.
- **Simple:** one idempotent SQL statement. No streaming, checkpoints, or triggers to manage.
- **Idempotent:** already-loaded files are skipped, so the job is safe to re-run.

## Trade-offs / known limits
- **Files are tracked by name, not content.** A re-pulled file with the same name won't reload.
  CFPB publishes late-arriving complaints, so daily re-pulls must be written as *new* files
  (e.g. with a run timestamp in the name) and deduplicated on `complaint_id` in silver.
- **No rescued data column.** Malformed fields aren't captured the way Auto Loader captures them.

## Results (11/23)
- First run: 7,329,948 rows from 365 files, 0 corrupt files
- Re-run: 0 rows loaded (idempotency confirmed)
- Rows = distinct `complaint_id`

## Future
Consider migrating bronze to Auto Loader in a Lakeflow pipeline if volume grows or for schema
evolution and rescued data.

## References
- https://docs.databricks.com/aws/en/ingestion/cloud-object-storage/
- https://docs.databricks.com/aws/en/sql/language-manual/delta-copy-into