# Turns collaborator names into links on pages built with the `cv` layout
# (cv, research, activities), using _data/collaborators.yml.
#
# Only plain text in the page body is touched: text inside existing links,
# <script>, <style> and HTML tags/attributes is left as is.
module Jekyll
  module LinkCollaborators
    SKIP_TAGS = %w[a script style].freeze

    def self.link(html, names_to_urls)
      return html if names_to_urls.empty?

      body_start = html.index(/<body[\s>]/i) || 0
      head = html[0...body_start]
      body = html[body_start..]

      pattern = Regexp.union(names_to_urls.keys.sort_by { |n| -n.length })
      skip_depth = 0

      linked = body.split(/(<[^>]+>)/).map do |token|
        if token.start_with?("<")
          if (m = token.match(%r{\A<(/?)([a-zA-Z0-9]+)}))
            closing, tag = m[1] == "/", m[2].downcase
            if SKIP_TAGS.include?(tag) && !token.end_with?("/>")
              skip_depth += closing ? -1 : 1
              skip_depth = 0 if skip_depth.negative?
            end
          end
          token
        elsif skip_depth.zero?
          token.gsub(pattern) do |name|
            %(<a class="collaborator" href="#{names_to_urls[name]}" target="_blank" rel="noopener noreferrer">#{name}</a>)
          end
        else
          token
        end
      end.join

      head + linked
    end
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.data["layout"] == "cv"

  collaborators = page.site.data["collaborators"] || []
  names_to_urls = {}
  collaborators.each do |c|
    next unless c.is_a?(Hash) && c["url"] && c["first"] && c["last"]

    names_to_urls["#{c['first']} #{c['last']}"] = c["url"]
    Array(c["aliases"]).each { |alias_name| names_to_urls[alias_name.to_s] = c["url"] }
  end

  page.output = Jekyll::LinkCollaborators.link(page.output, names_to_urls)
end
