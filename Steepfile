# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature "sig/generated"
  signature "sig/patches"

  check "lib"

  ignore "lib/generators"

  # Configure strict diagnostics
  configure_code_diagnostics(D::Ruby.strict)
end
