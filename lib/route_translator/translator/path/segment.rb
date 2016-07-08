module RouteTranslator
  module Translator
    module Path
      module Segment
        class << self
          def translate_string(str, locale, scope)
            locale = locale.to_s.gsub('native_', '')
            opts = { scope: scope, locale: locale }
            res = I18n.translate(str, opts)

            if RouteTranslator.config.disable_fallback && locale.to_s != I18n.default_locale.to_s
              opts[:fallback] = true
            else
              opts[:default] = str
            end

            if res.starts_with?('translation missing') || res.is_a?(Hash)
              opts[:scope] = [:routes]
              res = I18n.translate(str, opts)
            end

            URI.escape(res)
          end
        end

        module_function

        # Translates a single path segment.
        #
        # If the path segment contains something like an optional format
        # "people(.:format)", only "people" will be translated.
        # If there is no translation, the path segment is blank, begins with a
        # ":" (param key) or "*" (wildcard), the segment is returned untouched.
        def translate(segment, locale, scope)
          return segment if segment.empty?
          named_param, hyphenized = segment.split('-'.freeze, 2) if segment.starts_with?(':'.freeze)
          return "#{named_param}-#{translate(hyphenized.dup, locale, scope)}" if hyphenized
          return segment if segment.starts_with?('('.freeze) || segment.starts_with?('*'.freeze) || segment.include?(':'.freeze)

          appended_part = segment.slice!(/(\()$/)
          match = TRANSLATABLE_SEGMENT.match(segment)[1] if TRANSLATABLE_SEGMENT.match(segment)

          (translate_string(match, locale, scope) || segment) + appended_part.to_s
        end
      end
    end
  end
end
