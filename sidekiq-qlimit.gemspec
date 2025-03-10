# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sidekiq/qlimit/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-qlimit"
  spec.version       = Sidekiq::Qlimit::VERSION
  spec.authors       = ["Jeff Chan"]
  spec.email         = ["jeff@braincommerce.com"]

  spec.summary       = "Sidekiq per queue 'soft' limiting."
  spec.description   = "Sidekiq per queue 'soft' limiting. It ain't perfect, but it's enough."
  spec.homepage      = "https://github.com/braincom/sidekiq-qlimit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z lib`.split("\x0").reject do |f|
    f.match %r{^(test|spec|features|example)/}
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'sidekiq', '~> 4.0'
  spec.add_runtime_dependency 'tilt', '~> 2.6.0'
  spec.add_runtime_dependency 'sinatra', '>= 1.4.7'

  spec.add_development_dependency "bundler", "~> 1.10"

  spec.rdoc_options << '--title' << 'Sidekiq-Qlimit - A Soft Limiter' << '--main' << 'README.md' << '--exclude' << "example"
end
