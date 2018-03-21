require "asciidoctor-diagram-office/version"
require 'asciidoctor/extensions'

Asciidoctor::Extensions.register do
  require_relative 'asciidoctor-diagram-office/extension'

  block Asciidoctor::Diagram::OfficeBlockProcessor, :office
  block_macro Asciidoctor::Diagram::OfficeBlockMacroProcessor, :office
end
