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
  
  # Clean, strip, and wrap content without adding YAML key/block formatting.
  #
  # This is used to reformat data read from other YAML files (like XPath or
  # large rule messages) to ensure they respect the width constraint before
  # being dumped by to_yaml (which will then correctly apply |- or >-).
  #
  def self.wrapped_content(text, width: DEFAULT_WIDTH)
    return text if text.nil? || text.empty?
    
    # 1. Fjern alle eksisterende linjeskift, innrykk og erstatt med et enkelt mellomrom.
    # Dette sikrer at koden (f.eks. XPath) blir en flytende, ren streng.
    clean_text = text.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ').strip

    # 2. Bryt strengen på nytt ved maksimal bredde (70 tegn).
    # Vi bruker regex for å bryte ved ordgrenser (mellomrom).
    clean_text
      .scan(/.{1,#{width}}(?:\s|$)/)
      .map(&:strip)
      .join("\n")
  end
  def self.force_folded_content(text, width: DEFAULT_WIDTH)
    return text if text.nil? || (text.respond_to?(:empty?) && text.empty?)
    
    # Denne klassen instruerer Psych dumperen om å bruke den spesifikke stilen.
    # Vi bruker Block Style Folded, som er >-
    Psych::Nodes::Scalar.new(
      text,
      nil, # tag
      nil, # anchor
      :fold, # style: :fold tvinger >-
      nil, # scalar
      width # bredde
    )
  end
  
  # Ny versjon av wrapped_content, som vi kun bruker på meldinger
  def self.wrapped_prose(text, width: DEFAULT_WIDTH)
    return text if text.nil? || (text.respond_to?(:empty?) && text.empty?)
    
    # 1. Fjern alle linjeskift og innrykk for å lage én flytende streng.
    clean_text = text.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ').strip

    return clean_text if clean_text.empty?

    # 2. Bryt strengen på nytt ved maksimal bredde (70 tegn).
    # Vi bruker regex for å bryte ved ordgrenser (mellomrom).
    broken_text = clean_text
      .scan(/.{1,#{width}}(?:\s|$)/)
      .map(&:strip)
      .join("\n")
      
    # Tving >-
    self.force_folded_content(broken_text, width: width)
  end

end
