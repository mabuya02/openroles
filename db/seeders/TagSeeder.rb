class TagSeeder
  def self.seed
    puts "Seeding Tags..."

    # Use the existing method from Tag model that's designed for your table structure
    result = Tag.create_industry_seed_data

    puts "\nUsing Tag model seeding method:"
    puts "Created: #{result[:created]} new tags"
    puts "Existing: #{result[:existing]} tags were already present"
    puts "Total tags in database: #{result[:total]}"

    # Comprehensive tags for better job fetching - only using name and description
    additional_tags = [
      # Programming Languages
      { name: "Ruby", description: "Dynamic programming language focused on simplicity and productivity" },
      { name: "Python", description: "High-level programming language for web development, data science, and automation" },
      { name: "JavaScript", description: "Programming language for web browsers and server-side development" },
      { name: "Java", description: "Object-oriented programming language for enterprise applications" },
      { name: "PHP", description: "Server-side scripting language for web development" },
      { name: "Go", description: "Compiled programming language designed for simplicity and efficiency" },
      { name: "Rust", description: "Systems programming language focused on safety and performance" },
      { name: "TypeScript", description: "Typed superset of JavaScript that compiles to plain JavaScript" },
      { name: "C#", description: "Object-oriented programming language developed by Microsoft" },
      { name: "Swift", description: "Programming language for iOS and macOS app development" },
      { name: "Kotlin", description: "Modern programming language for Android development and more" },
      { name: "C++", description: "General-purpose programming language with object-oriented features" },
      { name: "Scala", description: "Programming language that combines object-oriented and functional programming" },
      { name: "R", description: "Programming language for statistical computing and data analysis" },
      { name: "HTML", description: "Markup language for creating web pages and web applications" },
      { name: "CSS", description: "Style sheet language for describing web page presentation" },
      { name: "SQL", description: "Domain-specific language for managing relational databases" },

      # Frameworks & Technologies
      { name: "React", description: "JavaScript library for building user interfaces with component-based architecture" },
      { name: "Vue.js", description: "Progressive JavaScript framework for building user interfaces" },
      { name: "Angular", description: "TypeScript-based web application framework by Google" },
      { name: "Node.js", description: "JavaScript runtime environment for server-side development" },
      { name: "Rails", description: "Ruby web application framework following convention over configuration" },
      { name: "Django", description: "High-level Python web framework for rapid development" },
      { name: "Laravel", description: "PHP web application framework with expressive syntax" },
      { name: "Spring Boot", description: "Java framework for creating stand-alone Spring applications" },
      { name: "Flutter", description: "Google's UI toolkit for building cross-platform applications" },
      { name: "React Native", description: "Framework for building mobile apps using React" },
      { name: "Express.js", description: "Minimal and flexible Node.js web application framework" },
      { name: "Flask", description: "Lightweight Python web framework for building web applications" },
      { name: "FastAPI", description: "Modern Python web framework for building APIs with type hints" },
      { name: "Next.js", description: "React framework for production-ready web applications" },

      # Technology Roles
      { name: "Software Engineer", description: "Professional who designs, develops, and maintains software systems" },
      { name: "Frontend Developer", description: "Developer focused on user interface and user experience" },
      { name: "Backend Developer", description: "Developer focused on server-side logic and infrastructure" },
      { name: "Full Stack Developer", description: "Developer proficient in both frontend and backend technologies" },
      { name: "DevOps Engineer", description: "Professional bridging development and operations teams" },
      { name: "Data Scientist", description: "Professional who analyzes complex data to help businesses make decisions" },
      { name: "Machine Learning Engineer", description: "Engineer who designs and implements ML systems and algorithms" },
      { name: "Product Manager", description: "Professional who guides product development and strategy" },
      { name: "UI/UX Designer", description: "Designer focused on user interface and user experience design" },
      { name: "QA Engineer", description: "Professional responsible for software quality assurance and testing" },
      { name: "Mobile Developer", description: "Developer specializing in mobile application development" },
      { name: "Cloud Engineer", description: "Professional who designs and manages cloud infrastructure" },
      { name: "Security Engineer", description: "Professional focused on cybersecurity and system protection" },
      { name: "Database Administrator", description: "Professional responsible for database management and optimization" },
      { name: "Site Reliability Engineer", description: "Engineer ensuring system reliability and performance" },
      { name: "Data Engineer", description: "Professional who builds and maintains data infrastructure" },
      { name: "AI Engineer", description: "Engineer specializing in artificial intelligence systems" },
      { name: "Blockchain Developer", description: "Developer working with blockchain and cryptocurrency technologies" },
      { name: "Research Scientist", description: "Professional conducting research and scientific investigations" },
      { name: "Technical Writer", description: "Professional creating technical documentation and content" },
      { name: "Solutions Architect", description: "Professional designing technical solutions and system architecture" },
      { name: "Platform Engineer", description: "Engineer building and maintaining development platforms" },
      { name: "Release Engineer", description: "Professional managing software releases and deployment pipelines" },
      { name: "Performance Engineer", description: "Specialist optimizing system and application performance" },

      # Non-Tech Professional Disciplines
      { name: "Marketing Manager", description: "Professional managing marketing campaigns and strategies" },
      { name: "Sales Representative", description: "Professional responsible for selling products and services" },
      { name: "Account Manager", description: "Professional managing client relationships and accounts" },
      { name: "Business Analyst", description: "Professional analyzing business processes and requirements" },
      { name: "Project Manager", description: "Professional coordinating projects and team deliverables" },
      { name: "Operations Manager", description: "Professional overseeing daily business operations" },
      { name: "Human Resources", description: "Professional managing employee relations and company culture" },
      { name: "Finance Manager", description: "Professional managing financial planning and analysis" },
      { name: "Legal Counsel", description: "Professional providing legal advice and compliance guidance" },
      { name: "Customer Success", description: "Professional ensuring customer satisfaction and retention" },
      { name: "Content Creator", description: "Professional creating digital content and media" },
      { name: "Social Media Manager", description: "Professional managing social media presence and engagement" },
      { name: "Brand Manager", description: "Professional managing brand identity and marketing" },
      { name: "Recruiter", description: "Professional finding and hiring talent for organizations" },
      { name: "Training Specialist", description: "Professional developing and delivering training programs" },
      { name: "Consultant", description: "Professional providing expert advice and recommendations" },
      { name: "Analyst", description: "Professional analyzing data and providing insights" },
      { name: "Coordinator", description: "Professional organizing and coordinating activities and events" },
      { name: "Administrator", description: "Professional managing administrative tasks and processes" },
      { name: "Specialist", description: "Professional with expertise in a specific area or field" },

      # Creative & Design Disciplines
      { name: "Graphic Designer", description: "Professional creating visual designs and graphics" },
      { name: "Web Designer", description: "Professional designing website layouts and user interfaces" },
      { name: "Product Designer", description: "Professional designing user-centered products and experiences" },
      { name: "Motion Graphics", description: "Professional creating animated graphics and visual effects" },
      { name: "Creative Director", description: "Professional leading creative vision and design strategy" },
      { name: "Art Director", description: "Professional overseeing visual aspects of creative projects" },
      { name: "Copywriter", description: "Professional writing persuasive and engaging content" },
      { name: "Video Editor", description: "Professional editing and producing video content" },
      { name: "Photographer", description: "Professional capturing and editing photographs" },
      { name: "Illustrator", description: "Professional creating illustrations and visual artwork" },

      # Healthcare & Medical
      { name: "Nurse", description: "Healthcare professional providing patient care and medical support" },
      { name: "Physician", description: "Medical doctor diagnosing and treating patients" },
      { name: "Pharmacist", description: "Healthcare professional managing medications and prescriptions" },
      { name: "Physical Therapist", description: "Healthcare professional helping patients recover mobility" },
      { name: "Medical Assistant", description: "Healthcare support professional assisting medical staff" },
      { name: "Healthcare Administrator", description: "Professional managing healthcare facility operations" },
      { name: "Medical Technician", description: "Professional operating medical equipment and conducting tests" },
      { name: "Clinical Research", description: "Professional conducting medical research and clinical trials" },

      # Education & Training
      { name: "Teacher", description: "Professional educating students in academic subjects" },
      { name: "Professor", description: "Academic professional teaching and conducting research" },
      { name: "Instructor", description: "Professional providing instruction and training" },
      { name: "Curriculum Developer", description: "Professional designing educational programs and materials" },
      { name: "Academic Advisor", description: "Professional guiding students in academic decisions" },
      { name: "Education Technology", description: "Professional implementing technology in educational settings" },
      { name: "Learning Designer", description: "Professional creating effective learning experiences" },

      # Manufacturing & Engineering
      { name: "Mechanical Engineer", description: "Engineer designing and developing mechanical systems" },
      { name: "Electrical Engineer", description: "Engineer working with electrical systems and components" },
      { name: "Civil Engineer", description: "Engineer designing infrastructure and construction projects" },
      { name: "Chemical Engineer", description: "Engineer applying chemistry to industrial processes" },
      { name: "Industrial Engineer", description: "Engineer optimizing processes and systems efficiency" },
      { name: "Quality Engineer", description: "Engineer ensuring product quality and standards" },
      { name: "Manufacturing", description: "Professional involved in production and manufacturing processes" },
      { name: "Supply Chain", description: "Professional managing logistics and supply chain operations" },
      { name: "Production Manager", description: "Professional overseeing manufacturing and production" },

      # Financial Services
      { name: "Financial Advisor", description: "Professional providing financial planning and investment advice" },
      { name: "Investment Banker", description: "Professional facilitating financial transactions and investments" },
      { name: "Accountant", description: "Professional managing financial records and tax preparation" },
      { name: "Auditor", description: "Professional examining financial records for accuracy and compliance" },
      { name: "Risk Manager", description: "Professional identifying and managing financial risks" },
      { name: "Actuary", description: "Professional analyzing financial risk using mathematics and statistics" },
      { name: "Credit Analyst", description: "Professional evaluating creditworthiness of individuals and businesses" },
      { name: "Financial Analyst", description: "Professional analyzing financial data and market trends" },
      { name: "Insurance", description: "Professional working in insurance industry and risk management" },
      { name: "Banking", description: "Professional working in banking and financial services" },

      # Technology Industries
      { name: "Fintech", description: "Financial technology companies and digital financial services" },
      { name: "Healthcare Tech", description: "Technology solutions for healthcare and medical industries" },
      { name: "E-commerce", description: "Online retail and digital commerce platforms" },
      { name: "EdTech", description: "Educational technology and digital learning platforms" },
      { name: "Gaming", description: "Video game development and interactive entertainment" },
      { name: "SaaS", description: "Software as a Service and cloud-based applications" },
      { name: "Blockchain", description: "Distributed ledger technology and cryptocurrency" },
      { name: "AI/ML", description: "Artificial intelligence and machine learning technologies" },
      { name: "Cybersecurity", description: "Information security and cyber threat protection" },
      { name: "IoT", description: "Internet of Things and connected device technologies" },
      { name: "Startup", description: "Early-stage companies and entrepreneurial ventures" },
      { name: "Enterprise", description: "Large-scale business software and enterprise solutions" },
      { name: "AdTech", description: "Advertising technology and digital marketing platforms" },
      { name: "PropTech", description: "Property technology and real estate innovation" },
      { name: "LegalTech", description: "Legal technology and law firm software solutions" },
      { name: "InsurTech", description: "Insurance technology and digital insurance platforms" },
      { name: "RetailTech", description: "Retail technology and e-commerce solutions" },
      { name: "FoodTech", description: "Food technology and restaurant industry innovation" },
      { name: "AgriTech", description: "Agricultural technology and farming innovation" },
      { name: "CleanTech", description: "Clean technology and environmental solutions" },
      { name: "SpaceTech", description: "Space technology and aerospace industry" },
      { name: "AutoTech", description: "Automotive technology and transportation innovation" },
      { name: "TravelTech", description: "Travel technology and hospitality innovation" },
      { name: "SportsTech", description: "Sports technology and fitness industry innovation" },
      { name: "MedTech", description: "Medical technology and healthcare device innovation" },
      { name: "GovTech", description: "Government technology and public sector solutions" },
      { name: "Non-profit", description: "Non-profit organizations and social impact companies" },
      { name: "Consulting", description: "Management consulting and professional services" },
      { name: "Telecommunications", description: "Telecom industry and communication technology" },
      { name: "Media", description: "Media industry including publishing and broadcasting" },
      { name: "Entertainment", description: "Entertainment industry including film and music" },
      { name: "Energy", description: "Energy sector including renewable and traditional energy" },
      { name: "Construction", description: "Construction and building industry" },
      { name: "Transportation", description: "Transportation and logistics industry" },
      { name: "Aerospace", description: "Aerospace and aviation industry" },
      { name: "Defense", description: "Defense and military technology sector" },

      # Skills & Tools
      { name: "AWS", description: "Amazon Web Services cloud computing platform" },
      { name: "Azure", description: "Microsoft cloud computing services and platform" },
      { name: "Google Cloud", description: "Google's cloud computing and storage services" },
      { name: "Docker", description: "Containerization platform for application deployment" },
      { name: "Kubernetes", description: "Container orchestration system for automated deployment" },
      { name: "PostgreSQL", description: "Advanced open-source relational database system" },
      { name: "MongoDB", description: "NoSQL document-oriented database program" },
      { name: "Redis", description: "In-memory data structure store and caching system" },
      { name: "MySQL", description: "Open-source relational database management system" },
      { name: "Git", description: "Distributed version control system for tracking code changes" },
      { name: "CI/CD", description: "Continuous integration and continuous deployment practices" },
      { name: "Terraform", description: "Infrastructure as code software tool" },
      { name: "Jenkins", description: "Open-source automation server for CI/CD pipelines" },
      { name: "Ansible", description: "Open-source automation tool for configuration management" },
      { name: "Jira", description: "Project management and issue tracking software" },
      { name: "Slack", description: "Team collaboration and communication platform" },
      { name: "Figma", description: "Collaborative interface design and prototyping tool" },
      { name: "Adobe Creative Suite", description: "Collection of graphic design and video editing software" },
      { name: "Salesforce", description: "Customer relationship management (CRM) platform" },
      { name: "HubSpot", description: "Inbound marketing and sales platform" },
      { name: "Tableau", description: "Data visualization and business intelligence software" },
      { name: "Power BI", description: "Business analytics and data visualization tool" },
      { name: "Excel", description: "Spreadsheet software for data analysis and calculations" },
      { name: "Google Analytics", description: "Web analytics service for tracking website traffic" },
      { name: "SEO", description: "Search engine optimization for improving website visibility" },
      { name: "SEM", description: "Search engine marketing and paid advertising" },
      { name: "PPC", description: "Pay-per-click advertising and campaign management" },
      { name: "CRM", description: "Customer relationship management systems and strategies" },
      { name: "ERP", description: "Enterprise resource planning software and systems" },
      { name: "Agile", description: "Agile development methodology and project management" },
      { name: "Scrum", description: "Scrum framework for agile software development" },
      { name: "Kanban", description: "Visual workflow management methodology" },
      { name: "Six Sigma", description: "Quality management methodology for process improvement" },
      { name: "Lean", description: "Lean methodology for eliminating waste and improving efficiency" },
      { name: "ITIL", description: "IT service management framework and best practices" },
      { name: "PMP", description: "Project Management Professional certification and methodology" },
      { name: "Cloud Computing", description: "Distributed computing and cloud-based services" },
      { name: "Microservices", description: "Architectural approach using small, independent services" },
      { name: "API Development", description: "Application programming interface design and development" },
      { name: "REST API", description: "Representational State Transfer web service architecture" },
      { name: "GraphQL", description: "Query language and runtime for APIs" },
      { name: "Blockchain", description: "Distributed ledger technology and cryptocurrency development" },
      { name: "Machine Learning", description: "Algorithms that learn from data without explicit programming" },
      { name: "Deep Learning", description: "Neural networks with multiple layers for complex pattern recognition" },
      { name: "Artificial Intelligence", description: "Computer systems performing tasks requiring human intelligence" },
      { name: "Data Science", description: "Extracting insights and knowledge from data using scientific methods" },
      { name: "Big Data", description: "Large and complex datasets requiring specialized tools and techniques" },
      { name: "Analytics", description: "Systematic analysis of data to discover meaningful patterns" },
      { name: "Business Intelligence", description: "Technologies and strategies for analyzing business information" },
      { name: "Cybersecurity", description: "Protection of digital systems from cyber threats and attacks" },
      { name: "Network Security", description: "Protection of computer networks and network-accessible resources" },
      { name: "Information Security", description: "Protection of information and information systems" },
      { name: "Penetration Testing", description: "Authorized testing of computer systems for security vulnerabilities" },
      { name: "Compliance", description: "Adherence to regulatory requirements and industry standards" },
      { name: "GDPR", description: "General Data Protection Regulation compliance and privacy" },
      { name: "SOX", description: "Sarbanes-Oxley Act compliance for financial reporting" },

      # Experience Levels
      { name: "Junior", description: "Entry-level professionals with 0-2 years of experience" },
      { name: "Mid-level", description: "Experienced professionals with 2-5 years of experience" },
      { name: "Senior", description: "Experienced professionals with 5+ years of experience" },
      { name: "Lead", description: "Leadership roles with team management responsibilities" },
      { name: "Principal", description: "Senior technical leadership and architecture roles" },
      { name: "Entry Level", description: "Beginning career positions requiring minimal experience" },
      { name: "Intern", description: "Temporary positions for students or recent graduates" },
      { name: "Executive", description: "C-level and senior executive management positions" },
      { name: "Manager", description: "Management positions with team leadership responsibilities" },
      { name: "Director", description: "Senior leadership roles overseeing departments or divisions" },
      { name: "VP", description: "Vice President level executive positions" },
      { name: "C-Level", description: "Chief executive officer, CTO, CFO, and other C-suite roles" },

      # Work Types
      { name: "Remote", description: "Work from home or any location outside traditional office" },
      { name: "Hybrid", description: "Combination of remote and in-office work arrangements" },
      { name: "On-site", description: "Traditional office-based work arrangement" },
      { name: "Contract", description: "Fixed-term employment or project-based work" },
      { name: "Full-time", description: "Standard 40-hour work week employment" },
      { name: "Part-time", description: "Less than full-time hour employment arrangements" },
      { name: "Freelance", description: "Independent contractor and self-employed work" },
      { name: "Temporary", description: "Short-term employment arrangements" },
      { name: "Seasonal", description: "Employment tied to specific seasons or periods" },
      { name: "Volunteer", description: "Unpaid work for charitable or community organizations" },
      { name: "Apprenticeship", description: "Training programs combining work with formal education" },
      { name: "Fellowship", description: "Specialized training or research positions" },
      { name: "Residency", description: "Specialized training positions in professional fields" },

      # Location Types
      { name: "New York", description: "Jobs located in New York City and surrounding areas" },
      { name: "San Francisco", description: "Jobs located in San Francisco Bay Area" },
      { name: "Los Angeles", description: "Jobs located in Los Angeles and Southern California" },
      { name: "Chicago", description: "Jobs located in Chicago and surrounding areas" },
      { name: "Boston", description: "Jobs located in Boston and New England area" },
      { name: "Austin", description: "Jobs located in Austin, Texas and surrounding areas" },
      { name: "Seattle", description: "Jobs located in Seattle and Pacific Northwest" },
      { name: "Denver", description: "Jobs located in Denver and Colorado area" },
      { name: "Miami", description: "Jobs located in Miami and South Florida" },
      { name: "Atlanta", description: "Jobs located in Atlanta and Georgia area" },
      { name: "Dallas", description: "Jobs located in Dallas-Fort Worth area" },
      { name: "Philadelphia", description: "Jobs located in Philadelphia and surrounding areas" },
      { name: "Washington DC", description: "Jobs located in Washington DC metro area" },
      { name: "Toronto", description: "Jobs located in Toronto and Ontario, Canada" },
      { name: "London", description: "Jobs located in London, United Kingdom" },
      { name: "Berlin", description: "Jobs located in Berlin, Germany" },
      { name: "Amsterdam", description: "Jobs located in Amsterdam, Netherlands" },
      { name: "Singapore", description: "Jobs located in Singapore" },
      { name: "Sydney", description: "Jobs located in Sydney, Australia" },
      { name: "International", description: "Jobs with international scope or multiple locations" },
      { name: "Global", description: "Positions with worldwide responsibilities or remote teams" },
      { name: "Europe", description: "Jobs located in European countries" },
      { name: "Asia Pacific", description: "Jobs located in Asia Pacific region" },
      { name: "North America", description: "Jobs located in North American countries" },

      # Soft Skills
      { name: "Leadership", description: "Ability to guide and influence teams and organizations" },
      { name: "Communication", description: "Effective verbal and written communication skills" },
      { name: "Problem Solving", description: "Analytical thinking and solution-finding abilities" },
      { name: "Teamwork", description: "Collaborative work and team participation skills" },
      { name: "Time Management", description: "Efficient organization and prioritization abilities" },
      { name: "Critical Thinking", description: "Analytical reasoning and evaluation skills" },
      { name: "Creativity", description: "Innovative thinking and creative problem-solving" },
      { name: "Adaptability", description: "Flexibility and adjustment to changing situations" },
      { name: "Customer Service", description: "Client relations and customer satisfaction skills" },
      { name: "Public Speaking", description: "Presentation and public communication abilities" },

      # Company Sizes
      { name: "Small Business", description: "Companies with fewer than 100 employees" },
      { name: "Mid-size", description: "Companies with 100-1000 employees" },
      { name: "Large Enterprise", description: "Companies with 1000+ employees" },
      { name: "Fortune 500", description: "Top 500 largest US companies by revenue" },
      { name: "Scale-up", description: "Fast-growing companies in expansion phase" },

      # Benefits & Perks
      { name: "Health Insurance", description: "Medical, dental, and vision coverage benefits" },
      { name: "401k", description: "Retirement savings plan with employer matching" },
      { name: "Stock Options", description: "Equity compensation and ownership opportunities" },
      { name: "Professional Development", description: "Training, conferences, and skill development support" },
      { name: "Flexible Hours", description: "Adaptable work schedule and time arrangements" },
      { name: "Unlimited PTO", description: "Unlimited paid time off and vacation policies" },
      { name: "Work Life Balance", description: "Healthy balance between work and personal life" },
      { name: "Parental Leave", description: "Time off for new parents and family care" }
    ]

    created_count = 0
    skipped_count = 0

    additional_tags.each do |tag_data|
      existing_tag = Tag.find_by("LOWER(name) = LOWER(?)", tag_data[:name])

      if existing_tag.nil?
        tag = Tag.create!(
          name: tag_data[:name],
          description: tag_data[:description]
        )
        created_count += 1
        puts "Created tag: #{tag.name}"
      else
        skipped_count += 1
        puts "Skipped existing tag: #{existing_tag.name}"
      end
    end

    puts "\nAdditional tag seeding complete!"
    puts "Created: #{created_count} new tags"
    puts "Skipped: #{skipped_count} existing tags"
    puts "Total tags in database: #{Tag.count}"
  end
end
