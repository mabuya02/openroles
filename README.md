# OpenRoles

A modern job board platform built with Ruby on Rails that connects job seekers with exciting opportunities. OpenRoles provides a clean, intuitive interface for browsing jobs, searching with natural language, and managing job alerts.

## Table of Contents
  - [For Job Seekers](#for-job-seekers)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Database Setup](#3-database-setup)
  - [4. Environment Configuration](#4-environment-configuration)
  - [5. Start the Application](#5-start-the-application)
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
- [Contributing](#contributing)
- [License](#license)

## Features

### For Job Seekers

- **Smart Job Search**: Natural language search with intelligent query parsing and external API integration
- **Job Alerts**: Set up automated email alerts for new job postings matching your criteria
- **Company Profiles**: Detailed company information including culture, benefits, and open positions
- **Profile Management**: Create and manage your professional profile with skills and experience

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
# Database
DATABASE_URL=postgresql://username:password@localhost/openroles_development

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

**Important**: 
- **Email Server**: Configure your SMTxP settings for sending job alerts and notifications
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

## Database Schema

### Core Models

- **User**: Authentication and profile management
- **Company**: Employer profiles and information
- **Job**: Job postings with full-text search capabilities
- **Alert**: User job alerts with email notifications
- **UserProfile**: Extended user information and preferences

### Key Features
- **UUID Primary Keys**: Enhanced security and performance
- **Full-Text Search**: Optimized job search with PostgreSQL
- **Composite Indexes**: Fast query performance for job lookups
- **Email Verification**: Secure user registration process

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
- `JobFetchService` for external API integrations
- `AlertNotificationService` for email processing

**Reasoning**:
- Keeps controllers thin
- Improves testability
- Enables code reuse
- Clear separation of concerns

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

##  API Documentation

The application provides RESTful APIs for job search and company data:

```bash
# Job search API
GET /api/jobs?q=search_term

# Company API  
GET /api/companies/:id

# Jobs by company
GET /api/companies/:id/jobs
```


## License

This project is open source and available under the [MIT License](LICENSE).

---

Built with Ruby on Rails
