module Plutoprint
  module HTMLPreprocessor
    def self.process(html, root_url, protocol)
      html = translate_relative_paths(html, root_url) if root_url
      html = translate_relative_protocols(html, protocol) if protocol
      html
    end

    def self.translate_relative_paths(html, root_url)
      html.gsub(%r{(href|src)=(['"])/([^/"']([^"']*|[^"']*))?['"]}, "\\1=\\2#{root_url}\\3\\2")
    end
    private_class_method :translate_relative_paths

    def self.translate_relative_protocols(html, protocol)
      html.gsub(%r{(href|src)=(['"])//([^"']*|[^"']*)['"]}, "\\1=\\2#{protocol}://\\3\\2")
    end
    private_class_method :translate_relative_protocols
  end
end
