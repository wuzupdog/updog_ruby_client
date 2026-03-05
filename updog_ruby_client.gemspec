Gem::Specification.new do |spec|
  spec.name          = "updog_ruby_client"
  spec.version       = "0.1.0"
  spec.authors       = ["Updog"]
  spec.email         = ["support@wuzupdog.com"]

  spec.summary       = "Ruby error reporting client for Updog"
  spec.description   = "Lightweight Ruby client for sending error notices to Updog with context and breadcrumbs."
  spec.homepage      = "https://github.com/swanny85/updog_ruby_client"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb", "README.md", "LICENSE", "Rakefile"]
  end

  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
