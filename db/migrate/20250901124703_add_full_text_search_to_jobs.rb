class AddFullTextSearchToJobs < ActiveRecord::Migration[8.0]
  def up
    # Enable pg_trgm extension for fuzzy string matching
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    # Add search vector column
    execute "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS search_vector tsvector;"

    # Create GIN indexes for full-text search
    execute "CREATE INDEX IF NOT EXISTS index_jobs_on_search_vector ON jobs USING GIN(search_vector);"
    execute "CREATE INDEX IF NOT EXISTS index_jobs_on_title_trgm ON jobs USING gin (title gin_trgm_ops);"
    execute "CREATE INDEX IF NOT EXISTS index_jobs_on_description_trgm ON jobs USING gin (description gin_trgm_ops);"
    execute "CREATE INDEX IF NOT EXISTS index_jobs_on_location_trgm ON jobs USING gin (location gin_trgm_ops);"

    # Create function to update search vector
    execute <<-SQL
      CREATE OR REPLACE FUNCTION jobs_search_vector_update() RETURNS trigger AS $$
      begin
        new.search_vector :=
          to_tsvector('english',#{' '}
            coalesce(new.title,'') || ' ' ||#{' '}
            coalesce(new.description,'') || ' ' ||#{' '}
            coalesce(new.location,'') || ' ' ||
            coalesce(new.employment_type,'')
          );
        return new;
      end
      $$ LANGUAGE plpgsql;
    SQL

    # Create trigger to auto-update search vector
    execute <<-SQL
      CREATE TRIGGER jobs_search_vector_trigger
      BEFORE INSERT OR UPDATE ON jobs
      FOR EACH ROW EXECUTE PROCEDURE jobs_search_vector_update();
    SQL

    # Update existing records
    execute <<-SQL
      UPDATE jobs SET search_vector = to_tsvector('english',#{' '}
        coalesce(title,'') || ' ' ||#{' '}
        coalesce(description,'') || ' ' ||#{' '}
        coalesce(location,'') || ' ' ||
        coalesce(employment_type,'')
      );
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS jobs_search_vector_trigger ON jobs;"
    execute "DROP FUNCTION IF EXISTS jobs_search_vector_update();"
    execute "DROP INDEX IF EXISTS index_jobs_on_location_trgm;"
    execute "DROP INDEX IF EXISTS index_jobs_on_description_trgm;"
    execute "DROP INDEX IF EXISTS index_jobs_on_title_trgm;"
    execute "DROP INDEX IF EXISTS index_jobs_on_search_vector;"
    execute "ALTER TABLE jobs DROP COLUMN IF EXISTS search_vector;"
    execute "DROP EXTENSION IF EXISTS pg_trgm;"
  end
end
