import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "clear"]
  static values = { 
    url: String,
    searchUrl: String,
    debounce: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
    this.currentQuery = ""
    this.hideResults()
    
    // Bind the outside click handler
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
  }

  disconnect() {
    this.clearTimeout()
    // Remove the outside click listener
    document.removeEventListener('click', this.boundHandleOutsideClick)
  }

  input(event) {
    const query = event.target.value.trim()
    
    // Clear previous timeout
    this.clearTimeout()
    
    // Hide results if query is too short
    if (query.length < 2) {
      this.hideResults()
      this.currentQuery = ""
      return
    }

    // Skip if query hasn't changed
    if (query === this.currentQuery) {
      return
    }

    this.currentQuery = query
    
    // Debounce the search
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceValue)
  }

  clear() {
    this.inputTarget.value = ""
    this.hideResults()
    this.currentQuery = ""
    this.inputTarget.focus()
  }

  selectSuggestion(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.url
    if (url) {
      window.location.href = url
    }
  }

  searchAll(event) {
    event.preventDefault()
    const query = this.inputTarget.value.trim()
    if (query) {
      const searchUrl = this.searchUrlValue || `/jobs/search?q=${encodeURIComponent(query)}`
      // If searchUrl doesn't contain a query parameter, add it
      const separator = searchUrl.includes('?') ? '&' : '?'
      const fullUrl = searchUrl.includes('q=') ? searchUrl : `${searchUrl}${separator}q=${encodeURIComponent(query)}`
      window.location.href = fullUrl
    }
  }

  async performSearch(query) {
    try {
      this.showLoading()
      
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error('Search request failed')
      }

      const data = await response.json()
      this.displayResults(data, query)
      
    } catch (error) {
      console.error('Live search error:', error)
      this.showError()
    }
  }

  displayResults(data, query) {
    const suggestions = data.suggestions || []
    const metadata = data.metadata || {}
    
    if (suggestions.length === 0) {
      this.showNoResults(query)
      return
    }

    let html = '<div class="live-search-results">'
    
    // Show search insights if available
    if (metadata.parsed_data && Object.keys(metadata.parsed_data).length > 0) {
      html += '<div class="search-insights p-2 border-bottom bg-light">'
      html += '<small class="text-muted"><i class="iconoir-brain me-1"></i>Smart search detected: '
      
      const insights = []
      if (metadata.parsed_data.company) insights.push(`Company: ${metadata.parsed_data.company}`)
      if (metadata.parsed_data.remote) insights.push('Remote work')
      if (metadata.parsed_data.employment_type) insights.push(`Type: ${metadata.parsed_data.employment_type.replace('_', ' ')}`)
      if (metadata.parsed_data.industry) insights.push(`Industry: ${metadata.parsed_data.industry}`)
      
      html += insights.join(', ')
      html += '</small></div>'
    }
    
    // Show suggestions
    suggestions.forEach(suggestion => {
      html += `
        <div class="search-suggestion p-3 border-bottom" data-action="click->live-search#selectSuggestion" data-url="${suggestion.url}">
          <div class="d-flex align-items-start">
            <div class="flex-grow-1">
              <h6 class="mb-1 fw-medium">${this.escapeHtml(suggestion.title)}</h6>
              <p class="mb-1 text-muted small">
                <i class="iconoir-building me-1"></i>
                <a href="${suggestion.company_url}" class="text-decoration-none">${this.escapeHtml(suggestion.company)}</a>
              </p>
              <div class="d-flex flex-wrap gap-2 small text-muted">
                ${suggestion.location ? `<span><i class="iconoir-pin-alt me-1"></i>${this.escapeHtml(suggestion.location)}</span>` : ''}
                ${suggestion.employment_type ? `<span><i class="iconoir-clock me-1"></i>${suggestion.employment_type}</span>` : ''}
                ${suggestion.salary ? `<span><i class="iconoir-dollar me-1"></i>${this.escapeHtml(suggestion.salary)}</span>` : ''}
              </div>
            </div>
            <div class="flex-shrink-0">
              <i class="iconoir-arrow-tr text-muted"></i>
            </div>
          </div>
        </div>
      `
    })
    
    // Add "View all results" option
    html += `
      <div class="search-all p-3 border-bottom bg-light" data-action="click->live-search#searchAll">
        <div class="d-flex align-items-center">
          <i class="iconoir-search me-2 text-primary"></i>
          <span class="text-primary fw-medium">View all results for "${this.escapeHtml(query)}"</span>
          <i class="iconoir-arrow-right ms-auto text-primary"></i>
        </div>
      </div>
    `
    
    html += '</div>'
    
    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  showLoading() {
    this.resultsTarget.innerHTML = `
      <div class="live-search-results">
        <div class="p-3 text-center">
          <div class="spinner-border spinner-border-sm text-primary me-2" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
          <span class="text-muted">Searching...</span>
        </div>
      </div>
    `
    this.showResults()
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="live-search-results">
        <div class="p-3 text-center">
          <i class="iconoir-warning-triangle text-warning me-2"></i>
          <span class="text-muted">Search temporarily unavailable</span>
        </div>
      </div>
    `
    this.showResults()
  }

  showNoResults(query) {
    this.resultsTarget.innerHTML = `
      <div class="live-search-results">
        <div class="p-3 text-center">
          <i class="iconoir-search-no text-muted me-2"></i>
          <span class="text-muted">No results found for "${this.escapeHtml(query)}"</span>
        </div>
        <div class="search-all p-3 border-top bg-light" data-action="click->live-search#searchAll">
          <div class="d-flex align-items-center">
            <i class="iconoir-search me-2 text-primary"></i>
            <span class="text-primary fw-medium">Search all sources for "${this.escapeHtml(query)}"</span>
            <i class="iconoir-arrow-right ms-auto text-primary"></i>
          </div>
        </div>
      </div>
    `
    this.showResults()
  }

  showResults() {
    this.resultsTarget.classList.remove('d-none')
    if (this.hasClearTarget) {
      this.clearTarget.classList.remove('d-none')
    }
  }

  hideResults() {
    this.resultsTarget.classList.add('d-none')
    if (this.hasClearTarget) {
      this.clearTarget.classList.add('d-none')
    }
  }

  clearTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Handle outside clicks to hide results
  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  connect() {
    this.timeout = null
    this.currentQuery = ""
    this.hideResults()
    
    // Bind the outside click handler
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
  }

  disconnect() {
    this.clearTimeout()
    // Remove the outside click listener
    document.removeEventListener('click', this.boundHandleOutsideClick)
  }
}
