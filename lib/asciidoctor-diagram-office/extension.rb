require 'asciidoctor-diagram/extensions'
require 'asciidoctor-diagram/util/cli'
require 'asciidoctor-diagram/util/cli_generator'
require 'asciidoctor-diagram/util/platform'
require 'asciidoctor-diagram/util/which'

module Asciidoctor
  module Diagram
    # @private
    module OfficeServer
        def self.listen
        unless defined?(@office_listener) && @office_listener
          pid = spawn('unoconv --listener')
          thr = Process.detach(pid)
          at_exit do
            begin
              Process.kill(:TERM, pid)
            rescue => e
            end
          end
          @office_listener = true
        end
      end
    end

    # @private
    module Office
      include CliGenerator
      include Which

      def self.included(mod)
        [:png, :svg].each do |f|
          mod.register_format(f, :image) do |parent, source|
            office(parent, source, f)
          end
        end
      end

      def office(parent_block, source, format)
        inherit_prefix = name

        options = {}

        unoconv = which(parent_block, 'unoconv', :raise_on_error => false)
        if unoconv
          OfficeServer.listen
          options[:page] = source.attr('page', '1', inherit_prefix)
          run_unoconv(unoconv, source, format, options)
        end
      end

      private
      def run_unoconv(unoconv, source, format, options = {})
        # office document => PDF
        pdf = generate_file(unoconv, 'unoconv', 'pdf', source.to_s) do |tool_path, input_path, output_path|
          args = [tool_path, '-f', 'pdf', '-e', "PageRange=#{options[:page]}-#{options[:page]}", '-o', Platform.native_path(output_path), Platform.native_path(input_path)]
          args
        end
        
        # PDF => target format
        generate_file(unoconv, 'unoconv', format.to_s, pdf) do |tool_path, input_path, output_path|
          args = [tool_path, '-f', format.to_s, '-o', Platform.native_path(output_path), Platform.native_path(input_path)]
          args
        end
      end

      class Source < Extensions::FileSource
        def initialize(parent_block, file_name, attributes)
          super(parent_block, file_name, attributes)
        end

        def image_name
          name = super
          page = attr('page', 1, @parent_block) 
          name + '-' + page
        end

        def code
          File.read(@file_name)
        end
      end
    end

    class OfficeBlockProcessor < Extensions::DiagramBlockProcessor
      include Office

      def create_source(parent, target, attributes)
        Office::Source.new(parent, apply_target_subs(parent, target), attributes)
      end
    end

    class OfficeBlockMacroProcessor < Extensions::DiagramBlockMacroProcessor
      include Office

      def create_source(parent, target, attributes)
        p target
        p apply_target_subs(parent, target)
        Office::Source.new(parent, apply_target_subs(parent, target), attributes)
      end
    end
  end
end

