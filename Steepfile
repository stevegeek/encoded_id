# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  # Use File.expand_path to avoid duplicate declaration errors.
  # Something to do with Steep having multiple ways of loading signature files, depending on whether
  # they're loaded on initialisation or loaded on change. And in one case the paths are expanded and
  # in another they're not. So relative paths end up looking like two different paths for the same file
  # when added to the 'environment' (Environment#add_source) ...
  # eg
  # DEBUG: DuplicatedDeclarationError for ::Sqids::DEFAULT_BLOCKLIST
  # Number of declarations: 2
  #   [0] RBS::AST::Declarations::Constant
  #       Location: sig/generated/encoded_id.rbs:35
  #       Buffer name class: Pathname
  #       Buffer name inspect: #<Pathname:sig/generated/encoded_id.rbs>
  #       Source: "DEFAULT_BLOCKLIST: Array[String]"
  #   [1] RBS::AST::Declarations::Constant
  #       Location: /workspaces/gems/encoded_id/sig/generated/encoded_id.rbs:35
  #       Buffer name class: Pathname
  #       Buffer name inspect: #<Pathname:/workspaces/gems/encoded_id/sig/generated/encoded_id.rbs>
  #       Source: "DEFAULT_BLOCKLIST: Array[String]"
  #   Backtrace (top 15):
  #     [0] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:352:in 'Class#new'
  #     [1] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:352:in 'RBS::Environment#insert_rbs_decl'
  #     [2] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:325:in 'block in RBS::Environment#insert_rbs_decl'
  #     [3] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/ast/declarations.rb:26:in 'block in RBS::AST::Declarations::NestedDeclarationHelper#each_decl'
  #     [4] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/ast/declarations.rb:24:in 'Array#each'
  #     [5] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/ast/declarations.rb:24:in 'RBS::AST::Declarations::NestedDeclarationHelper#each_decl'
  #     [6] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:324:in 'RBS::Environment#insert_rbs_decl'
  #     [7] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:459:in 'block in RBS::Environment#add_source'
  #     [8] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:458:in 'Array#each'
  #     [9] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/gems/rbs-4.0.0.dev.4/lib/rbs/environment.rb:458:in 'RBS::Environment#add_source'
  #     [10] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/bundler/gems/steep-c3253a8c5199/lib/steep/services/signature_service.rb:300:in 'block (3 levels) in Steep::Services::SignatureService#update_env'
  #     [11] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/bundler/gems/steep-c3253a8c5199/lib/steep/services/signature_service.rb:296:in 'Hash#each_value'
  #     [12] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/bundler/gems/steep-c3253a8c5199/lib/steep/services/signature_service.rb:296:in 'block (2 levels) in Steep::Services::SignatureService#update_env'
  #     [13] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/bundler/gems/steep-c3253a8c5199/lib/steep.rb:220:in 'Steep.measure'
  #     [14] /.jbdevcontainer/data/mise/installs/ruby/3.4.2/lib/ruby/gems/3.4.0/bundler/gems/steep-c3253a8c5199/lib/steep/services/signature_service.rb:295:in 'block in Steep::Services::SignatureService#update_env'
  #
  # Bug exists in BOTH Steep 1.10.0 and 2.0.0.dev
  # signature "sig/generated"
  # signature "sig/patches"
  # Here is the workaround:
  signature File.expand_path("sig/generated", __dir__)
  signature File.expand_path("sig/patches", __dir__)

  check "lib"

  ignore "lib/generators"

  # Configure strict diagnostics
  configure_code_diagnostics(D::Ruby.strict)
end
