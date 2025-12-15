# frozen_string_literal: true

module YamlText
  DEFAULT_WIDTH = 70

  # Emit a folded YAML block (>-), as text
  #
  # key    – YAML key, including indentation (e.g. "f_text" or "  f_text")
  # text   – string content
  # indent – indentation of block content (spaces)
  # width  – wrap width
  #
  def self.folded(key, text, indent: 2, width: DEFAULT_WIDTH)
    ind = " " * indent

    lines =
      text
        .strip
        .scan(/.{1,#{width}}(?:\s|$)/)
        .map(&:strip)

    <<~YAML.chomp
    #{key}: >-
    #{lines.map { |l| "#{ind}#{l}" }.join("\n")}
    YAML
  end
  # Emit folded lines only (no key, no >-)
  #
  # Used when embedding folded text inside a larger YAML structure
  #
  def self.folded_lines(text, indent:, width: DEFAULT_WIDTH)
    ind = " " * indent

    text
      .strip
      .scan(/.{1,#{width}}(?:\s|$)/)
      .map(&:strip)
      .map { |line| "#{ind}#{line}" }
      .join("\n")
  end

end
