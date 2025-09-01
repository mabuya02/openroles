# Enhanced Database Schema and Models Summary

## 🎯 Overview
This document summarizes the database schema enhancements and model updates implemented to support scalable job indexing, alerts, and search functionality.

## 🗄️ Database Schema Changes

### 1. Enhanced `jobs` Table
**New Fields Added:**
- `external_id` (string) - Unique identifier from external APIs (Jooble, Adzuna, etc.)
- `source` (string) - Data source identifier ('jooble', 'adzuna', 'manual', etc.)
- `fingerprint` (string) - SHA256 hash for deduplication when external_id is not available
- `posted_at` (datetime) - Original job posting date
- `apply_url` (string) - Direct application URL
- `raw_payload` (jsonb) - Full API response storage for reference
- `salary_min` / `salary_max` (decimal) - Separate min/max salary fields
- `search_vector` (tsvector) - Full-text search vector for PostgreSQL

**New Indexes:**
- Unique composite index on `[source, external_id]`
- Unique index on `fingerprint`
- GIN index on `search_vector` for full-text search
- GIN trigram indexes on `title`, `description`, and `location`
- Index on salary range fields

### 2. Enhanced `companies` Table
**New Fields Added:**
- `slug` (string) - URL-friendly identifier

**New Indexes:**
- Unique index on `slug`

### 3. Enhanced `alerts` Table
**New Fields Added:**
- `frequency` (string) - Notification frequency ('daily', 'weekly', 'monthly')
- `last_notified_at` (datetime) - Timestamp of last notification
- `unsubscribe_token` (string) - Unique token for unsubscription

**New Indexes:**
- Index on `frequency`
- Index on `last_notified_at`
- Unique index on `unsubscribe_token`

### 4. New `alerts_tags` Join Table
**Purpose:** Many-to-many relationship between alerts and tags
**Fields:**
- `alert_id` (uuid, foreign key)
- `tag_id` (uuid, foreign key)
- `created_at` / `updated_at` (timestamps)

**Indexes:**
- Unique composite index on `[alert_id, tag_id]`

### 5. PostgreSQL Extensions and Triggers
- Enabled `pg_trgm` extension for fuzzy string matching
- Created automatic search vector update trigger for jobs table

## 🔧 Model Enhancements

### 1. Job Model (`app/models/job.rb`)
**New Features:**
- Automatic fingerprint generation for deduplication
- Full-text search scopes (`search`, `fuzzy_search`)
- Salary range filtering scopes
- Source and date filtering scopes
- URL validation for apply_url
- Automatic posted_at timestamp

**Key Methods:**
```ruby
# Scopes
Job.published          # Published jobs only
Job.search('ruby')     # Full-text search
Job.with_salary_range(50000, 80000)  # Salary filtering
Job.from_source('linkedin')          # Source filtering

# Instance methods
job.generate_fingerprint  # Auto fingerprint generation
```

### 2. Company Model (`app/models/company.rb`)
**New Features:**
- Automatic slug generation from company name
- URL-friendly parameter method
- Website URL validation

**Key Methods:**
```ruby
# Scopes
Company.active        # Active companies only
Company.with_jobs     # Companies that have jobs

# Instance methods
company.to_param      # Returns slug for URLs
```

### 3. Alert Model (`app/models/alert.rb`)
**New Features:**
- Tag-based filtering through many-to-many relationship
- Advanced job matching algorithm
- Notification frequency management
- Unsubscribe token generation

**Key Methods:**
```ruby
# Scopes
Alert.active                           # Active alerts only
Alert.ready_for_notification('daily')  # Due for notification

# Instance methods
alert.should_notify?     # Check if notification is due
alert.mark_as_notified!  # Update notification timestamp
alert.matching_jobs      # Find jobs matching alert criteria
```

### 4. Tag Model (`app/models/tag.rb`)
**New Features:**
- Automatic name normalization (lowercase, trimmed)
- Alert relationship support
- Popularity scopes

**Key Methods:**
```ruby
# Scopes
Tag.popular           # Popular tags based on job count
Tag.for_alerts        # Tags used in alerts

# Instance methods
tag.to_param          # URL-friendly parameter
```

### 5. AlertsTag Model (`app/models/alerts_tag.rb`)
**Purpose:** Join table model for alert-tag relationships
- Ensures unique alert-tag combinations
- Proper foreign key relationships

## 🔍 Search Capabilities

### 1. Full-Text Search
- PostgreSQL's tsvector for natural language search
- Automatic search vector updates via database triggers
- Support for English language stemming and ranking

### 2. Fuzzy Search
- Trigram matching for typo-tolerant searches
- Similarity scoring for better results

### 3. Advanced Filtering
- Salary range filtering
- Location-based filtering
- Employment type filtering
- Source-based filtering
- Date range filtering

## 📊 Alert System

### 1. Personalized Criteria
- JSON-based criteria storage for flexibility
- Tag-based filtering for categorization
- Multi-field search support

### 2. Notification Management
- Configurable frequency (daily, weekly, monthly)
- Automatic duplicate prevention
- Unsubscribe functionality

### 3. Job Matching Algorithm
- Combines criteria-based and tag-based filtering
- Respects notification frequency
- Only shows new jobs since last notification

## 🚀 Performance Optimizations

### 1. Database Indexes
- Proper indexing for all search operations
- Composite indexes for multi-field queries
- GIN indexes for full-text and trigram search

### 2. Query Optimization
- Efficient scopes and relationships
- Minimal N+1 query potential
- Proper eager loading support

### 3. Caching-Ready
- Search vectors computed once and cached
- Slug generation for URL optimization
- Efficient job matching algorithms

## 🧪 Testing Results

All enhanced features have been tested and verified:
- ✅ Company slug generation working
- ✅ Job fingerprint generation working
- ✅ Full-text search operational
- ✅ Alert creation and token generation working
- ✅ Tag normalization functioning
- ✅ Job-tag associations working
- ✅ Alert-tag associations working
- ✅ Salary range filtering operational
- ✅ Search scopes and filtering working

## 📋 Next Steps

The database layer is now ready for:
1. **Job Import Services** - Build services to import from external APIs
2. **Search Controllers** - Create API endpoints for job search
3. **Alert Processing Jobs** - Background jobs for alert notifications
4. **Email Templates** - Design notification email templates
5. **Admin Interface** - Tools for managing jobs, companies, and alerts

## 🏗️ Migration Files Created

1. `20250901123344_enhance_jobs_for_indexing.rb`
2. `20250901123419_add_slug_to_companies.rb`
3. `20250901123513_enhance_alerts_for_personalization.rb`
4. `20250901124423_create_alerts_tags.rb`
5. `20250901124703_add_full_text_search_to_jobs.rb`

All migrations have been successfully applied and the schema is up to date.
