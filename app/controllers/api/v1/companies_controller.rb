module Api
  module V1
    class CompaniesController < ApplicationController
      before_action :set_company, only: [ :jobs ]

      def jobs
        @pagy, @jobs = pagy(@company.jobs.published.includes(:company), limit: params[:per_page] || 20)

        jobs_json = @jobs.map do |job|
          {
            id: job.id,
            title: job.title,
            description: job.description,
            location: job.location,
            employment_type: job.employment_type,
            salary_min: job.salary_min,
            salary_max: job.salary_max,
            currency: job.currency,
            apply_url: job.apply_url,
            posted_at: job.posted_at,
            created_at: job.created_at,
            remote_friendly: job.remote_friendly?,
            source: job.source,
            company: {
              id: @company.id,
              name: @company.name,
              industry: @company.industry,
              location: @company.location,
              website: @company.website,
              logo_url: @company.logo_url
            }
          }
        end

        render json: {
          company: {
            id: @company.id,
            name: @company.name,
            slug: @company.slug,
            industry: @company.industry,
            location: @company.location,
            website: @company.website,
            logo_url: @company.logo_url,
            total_jobs: @company.jobs.count,
            active_jobs: @company.jobs.published.count
          },
          jobs: jobs_json,
          pagination: {
            page: @pagy.page,
            pages: @pagy.pages,
            count: @pagy.count,
            per_page: @pagy.limit,
            prev: @pagy.prev,
            next: @pagy.next
          }
        }
      end

      private

      def set_company
        @company = Company.find_by(slug: params[:id]) || Company.find(params[:id])
        render json: { error: "Company not found" }, status: :not_found unless @company
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Company not found" }, status: :not_found
      end
    end
  end
end
