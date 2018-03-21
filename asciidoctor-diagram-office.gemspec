# -*- encoding: utf-8 -*-
require File.expand_path('lib/asciidoctor-diagram-office/version',
                         File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = 'asciidoctor-diagram-office'
  s.version     = Asciidoctor::Diagram::Office::VERSION
  s.date        = '2017-01-09'
  s.summary     = "Asciidoctor processor to use office diagrams"
  s.description = "An Asciidoctor extension to converts office document to SVG or PNG"
  s.authors     = ["Hiroyuki Wada"]
  s.email       = 'wadahiro@gmail.com'
  s.files       = `git ls-files -z`.split("\x0")
  s.homepage    =
    'https://github.com/wadahiro/asciidoctor-diagram-office'
  s.license       = 'MIT'

  s.add_dependency 'asciidoctor-diagram', '~> 1.5'
end
