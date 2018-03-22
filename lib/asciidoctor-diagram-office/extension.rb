require 'timeout'
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
          pid = spawn('unoconv --listener > /dev/null 2>&1')
          thr = Process.detach(pid)
          is_port_open?

          at_exit do
            begin
              Process.kill(:TERM, pid)
            rescue => e
            end
          end
          @office_listener = true
        end
      end

      def self.is_port_open?()
        begin
          Timeout::timeout(10) do
            begin
              s = TCPSocket.open('localhost', 2002)
              s.close
              return true
            rescue
              sleep(1)
              retry
            end
          end
        rescue Timeout::Error
          raise 'Failed to start office listener'
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
        inkscape = which(parent_block, 'inkscape', :raise_on_error => false)

        if unoconv
          OfficeServer.listen
          options[:page] = source.attr('page', '1', inherit_prefix)
          run_convert(unoconv, inkscape, source, format, options)
        end
      end

      private
      def run_convert(unoconv, inkscape, source, format, options = {})
        # office document => PDF
        pdf = generate_file(unoconv, 'office', 'pdf', source.to_s) do |tool_path, input_path, output_path|
          args = [tool_path, '-f', 'pdf', '-e', "PageRange=#{options[:page]}-#{options[:page]}", '-o', Platform.native_path(output_path), Platform.native_path(input_path)]
          args
        end
        
        # PDF => target format
        if inkscape
          generate_file(inkscape, 'pdf', format.to_s, pdf) do |tool_path, input_path, output_path|
            case format.to_s
            when 'png'
              args = [tool_path, '-f', Platform.native_path(input_path), '-e', Platform.native_path(output_path)]
            when 'svg'
              args = [tool_path, '-f', Platform.native_path(input_path), '-l', Platform.native_path(output_path)]
            end
            args
          end
        else
          generate_file(unoconv, 'pdf', format.to_s, pdf) do |tool_path, input_path, output_path|
            args = [tool_path, '-f', format.to_s, '-o', Platform.native_path(output_path), Platform.native_path(input_path)]
            args
          end
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
        image_file = parent.normalize_system_path(target, parent.attr('imagesdir'))
        Office::Source.new(parent, image_file, attributes)
      end
    end

    class OfficeBlockMacroProcessor < Extensions::DiagramBlockMacroProcessor
      include Office

      def create_source(parent, target, attributes)
        image_file = parent.normalize_system_path(target, parent.attr('imagesdir'))
        Office::Source.new(parent, image_file, attributes)
      end
    end
  end
end

