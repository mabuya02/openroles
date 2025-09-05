# OpenRoles

A modern job board platform built with Ruby on Rails that connects job seekers with exciting opportunities. OpenRoles provides a clean, intuitive interface for browsing jobs, searching with natural language, automated job alerts, and comprehensive job aggregation from multiple sources.

## Table of Contents

- [Features](#features)
  - [For Job Seekers](#for-job-seekers)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Database Setup](#3-database-setup)
  - [4. Environment Configuration](#4-environment-configuration)
  - [5. Start the Application](#5-start-the-application)
  - [6. Populate Database with External Data](#6-populate-database-with-external-data)
  - [7. Set Up Job Alerts System](#7-set-up-job-alerts-system)
- [Database Schema](#database-schema)
  - [Core Models](#core-models)
  - [Key Features](#key-features)
- [Design Decisions](#design-decisions)
  - [Architecture Choices](#architecture-choices)
  - [User Experience Decisions](#user-experience-decisions)
  - [Performance Optimizations](#performance-optimizations)
  - [Code Organization Decisions](#code-organization-decisions)
- [Testing](#testing)
- [API Documentation](#api-documentation)
- [License](#license)

## Features

### For Job Seekers

- **Smart Job Search**: Natural language search with intelligent query parsing and external API integration from multiple sources
- **Automated Job Alerts**: Set up intelligent email alerts for new job postings matching your criteria with daily, weekly, or monthly frequency
- **Multi-Source Job Aggregation**: Automatically fetch jobs from Adzuna, Jooble, RemoteOK, and Remotive APIs with smart tag-based targeting
- **Company Profiles**: Detailed company information including culture, benefits, and open positions
- **Profile Management**: Create and manage your professional profile with skills and experience
- **Remote Job Focus**: Dedicated section for remote work opportunities from around the world

## Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby**: Version 3.4.5 or higher
- **Rails**: Version 8.0.2.1 or higher  
- **PostgreSQL**: Version 13 or higher
- **Node.js**: Version 16 or higher (for asset compilation)
- **Git**: For version control

## Local Setup

### 1. Clone the Repository

```bash
git clone https://github.com/mabuya02/openroles.git
cd openroles
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

```bash
# Create and setup the database
rails db:create
rails db:migrate

# Seed with sample data (optional)
rails db:seed
```

### 4. Environment Configuration

Copy the example environment file and configure your settings:

```bash
# Copy the example environment file
cp .env.example .env
```

Then edit the `.env` file with your configuration:

```bash
# Email Configuration (required for alerts and notifications)
SMTP_ADDRESS=smtp.your-provider.com
SMTP_PORT=587
SMTP_DOMAIN=your-domain.com
SMTP_USERNAME=your-email@domain.com
SMTP_PASSWORD=your-email-password

# Job Board API Keys (required for external job fetching)
ADZUNA_APP_ID=your-adzuna-app-id
ADZUNA_API_KEY=your-adzuna-api-key
JOOBLE_API_KEY=your-jooble-api-key
REMOTEOK_API_KEY=your-remoteok-api-key

# Application Settings
SECRET_KEY_BASE=your-secret-key-base
RAILS_ENV=development
```

**Generate SECRET_KEY_BASE:**
```bash
# Generate a new secret key
rails secret
```
Copy the generated key and use it as your `SECRET_KEY_BASE` value.

**Important**: 
- **Email Server**: Configure your SMTP settings for sending job alerts and notifications
- **API Keys**: Obtain API keys from job board providers (Adzuna, Jooble, RemoteOK) to enable external job fetching
- **Without API keys**: The application will only search jobs in your local database

### 5. Start the Application

```bash
# Start the Rails server
rails server

# In another terminal, start the CSS/JS build process
rails assets:watch
```

Visit `http://localhost:3000` to see the application running!

### 6. Populate Database with External Data

Once your application is running and you have configured your API keys, you can fetch jobs and companies from external APIs:

```bash
# Fetch jobs using the tag-based system (recommended for initial setup)
bin/fetch_jobs_by_tags

# This script will:
# 1. Use the seeded tags to intelligently fetch relevant jobs
# 2. Fetch from all available APIs (Adzuna, Jooble, RemoteOK, Remotive)
# 3. Avoid duplicate job postings
# 4. Organize jobs by professional categories

# View statistics about fetched data
rails jobs:stats
```

**Available API Sources:**
- `adzuna` - General job board with wide coverage
- `jooble` - International job search engine
- `remoteok` - Remote work opportunities
- `remotive` - Remote jobs in tech

**Tips:**
- Run `rails jobs:fetch` regularly to keep your job database up-to-date
- Use specific keywords with `jobs:fetch_from` to target relevant positions
- Check `rails jobs:stats` to monitor your database growth
- Test API connections with `rails jobs:test_apis` if you encounter issues

### 7. Set Up Job Alerts System

The application includes a comprehensive job alert system that sends email notifications to users when new jobs match their criteria.

#### Seed Tag Database

First, populate the tag database for intelligent job fetching:

```bash
# Seed the comprehensive tag database (341 professional tags)
rails runner "TagSeeder.new.seed_all_tags"
```

This creates tags across categories like:
- Programming languages (Ruby, Python, JavaScript, etc.)
- Frameworks (Rails, React, Django, etc.)
- Job roles (Developer, Designer, Manager, etc.)
- Skills (Machine Learning, DevOps, etc.)

#### Background Job Processing

Configure background job processing for automated alerts:

```bash
# Start the background job processor (in production, use a process manager)
bundle exec rails solid_queue:start

# Or run jobs inline for development
rails runner 'Rails.application.config.active_job.queue_adapter = :inline'
```

#### Schedule Recurring Alerts

Set up recurring alert processing:

```bash
# Process daily alerts
rails runner 'DailyJobAlertsJob.perform_now'

# Process all pending alerts
rails runner 'BulkJobAlertsJob.perform_now'

# Check alert processing status
rails runner 'puts "Total alerts: #{Alert.active.count}"; puts "Users with alerts: #{User.joins(:alerts).distinct.count}"'
```

## Database Schema

### Core Models

- **User**: Authentication and profile management with email verification
- **Company**: Employer profiles and information with job posting capabilities
- **Job**: Job postings with full-text search capabilities and external API integration
- **Alert**: User job alerts with intelligent matching and email notifications
- **Tag**: Professional skills and technology tags for job categorization and fetching
- **UserProfile**: Extended user information and preferences
- **Background Jobs**: SolidQueue integration for alert processing and job fetching

### Key Features

- **UUID Primary Keys**: Enhanced security and performance across all models
- **Full-Text Search**: Optimized job search with PostgreSQL's built-in search capabilities
- **Composite Indexes**: Fast query performance for job lookups and alert matching
- **Email Verification**: Secure user registration and notification system
- **Multi-API Integration**: Automated job fetching from Adzuna, Jooble, RemoteOK, and Remotive
- **Intelligent Alert System**: Tag-based job matching with customizable frequency (daily/weekly/monthly)
- **Background Processing**: Automated job fetching and alert processing via SolidQueue

## Design Decisions

### Architecture Choices

#### 1. **Rails 8.0 with Modern Frontend**
**Decision**: Used Rails 8.0 with Stimulus/Turbo instead of a separate frontend framework.

**Reasoning**: 
- Faster development with Rails conventions
- Better SEO with server-side rendering
- Reduced complexity compared to API + SPA architecture
- Excellent developer experience with Hotwire

#### 2. **PostgreSQL with UUID Primary Keys**
**Decision**: Used PostgreSQL with UUID primary keys across all models.

**Reasoning**:
- Enhanced security (no predictable IDs)
- Better for distributed systems and API exposure
- Reduced enumeration attacks
- Future-proof for microservices architecture

#### 3. **Full-Text Search Implementation**
**Decision**: Built custom natural language search using PostgreSQL's full-text search.

**Reasoning**:
- No external dependencies (Elasticsearch, Solr)
- Reduced infrastructure complexity
- Excellent performance for job search use case
- Built-in ranking and relevance scoring

### User Experience Decisions

#### 1. **Natural Language Search**
**Decision**: Implemented intelligent query parsing for job search with external API integration.

**Example**: "remote python developer san francisco" → parsed into location, skills, and remote preferences + fetches from external APIs

**Reasoning**:
- More intuitive for users than complex filter forms
- Faster job discovery from multiple sources
- Better mobile experience
- Matches modern search expectations
- Expands job availability beyond local database

#### 2. **Simplified Navigation**
**Decision**: Clean, minimal navigation with focused user flows.

**Reasoning**:
- Reduced cognitive load for job seekers
- Clear call-to-action hierarchy
- Mobile-first responsive design
- Fast page transitions with Turbo

#### 3. **Company-Centric Job Browsing**
**Decision**: Emphasized company profiles in job listings and search results.

**Reasoning**:
- Job seekers care about company culture and reputation
- Builds trust through transparency
- Encourages companies to maintain quality profiles
- Differentiates from other job boards

### Performance Optimizations

#### 1. **Database Query Optimization**
**Decisions**: 
- Composite indexes on frequently queried columns
- Strategic use of `includes()` to prevent N+1 queries
- Database-level constraints for data integrity

#### 2. **Caching Strategy**
**Decisions**:
- Rails cache for expensive computations
- Database query result caching
- Fragment caching for company and job data

#### 3. **Background Job Processing**
**Decision**: Used SolidQueue for background jobs instead of Sidekiq/Resque.

**Reasoning**:
- No Redis dependency
- Simpler deployment
- Better Rails 8 integration
- Sufficient for current scale

### Code Organization Decisions

#### 1. **Service Objects for Complex Logic**
**Decision**: Extracted complex business logic into service classes.

**Examples**:
- `NaturalLanguageSearchService` for search query parsing
- `TagBasedJobFetcherService` for intelligent external API integrations with tag-based targeting
- `AlertNotificationService` for email processing and job matching
- `JobSearchService` for advanced search functionality
- `AlertMailer` for comprehensive email template system

**Reasoning**:
- Keeps controllers thin
- Improves testability and maintainability
- Enables code reuse across different parts of the application
- Clear separation of concerns
- Better error handling and logging

#### 2. **Concern-Based Model Organization**
**Decision**: Used Rails concerns for shared model behavior.

**Examples**:
- `Searchable` concern for full-text search
- `Trackable` concern for analytics
- `Cacheable` concern for cache management

#### 3. **Component-Based Views**
**Decision**: Created reusable view components and partials.

**Examples**:
- Job card components
- Company profile sections
- Search result layouts

**Reasoning**:
- Consistent UI across the application
- Easier maintenance and updates
- Better code reusability

## Testing

**Additional Testing Scripts**: Most comprehensive testing scripts are located in `script/archived/` including:
- Performance testing scripts
- Integration tests for job fetching
- API integration tests
- Email system tests
- Database optimization tests

## API Documentation

The application provides RESTful APIs for job search and company data:

### Public APIs

```bash
# Job search API with natural language support
GET /api/jobs?q=search_term

# Company API  
GET /api/companies/:id

# Jobs by company
GET /api/companies/:id/jobs

# Live search for autocomplete
GET /api/live_search?q=partial_term

# Remote jobs API
GET /api/remote_jobs?q=search_term
```

### Admin APIs

```bash
# Job fetching from external APIs
POST /admin/jobs/fetch

# Alert management
GET /admin/alerts
POST /admin/alerts/:id/test

# System statistics
GET /admin/stats
```

### Background Job APIs

The application includes several background jobs for automation:

```bash
# Daily job alerts processing
DailyJobAlertsJob.perform_now

# Bulk alert notifications
BulkJobAlertsJob.perform_now

# External job fetching
ExternalJobFetchJob.perform_now

# Email verification
EmailVerificationJob.perform_now
```


## License

This project is open source and available under the [MIT License](LICENSE).

---

Built with Ruby on Rails
