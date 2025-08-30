class HomeController < ApplicationController
  def index
    # Set page-specific meta data
    @page_title = "Welcome"
    @page_description = "Find your dream job or hire top talent with OpenRoles"
    @page_keywords = "jobs, careers, employment, hiring, recruitment"
  end

  def sample
    @page_title = "Sample Page"
    @page_description = "This is a sample page description."
    @page_keywords = "sample, example, demo"
  end
end
