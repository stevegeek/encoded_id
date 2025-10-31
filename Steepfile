# frozen_string_literal: true

D = Steep::Diagnostic

target :app do
  signature "sig/generated"

  check "lib"

  # Configure strict diagnostics
  configure_code_diagnostics(D::Ruby.strict)
end
