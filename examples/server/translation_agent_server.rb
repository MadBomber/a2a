#!/usr/bin/env ruby
# Example 7: Translation Agent Server
# A functional A2A server that provides translation services between languages.
# Demonstrates how to build a domain-specific agent with specialized skills.
#
# Features:
# - Translation between multiple languages (Spanish, French, German, Italian)
# - Returns both translated text and metadata (confidence, language codes)
# - Demonstrates multi-part responses (TextPart + DataPart)
#
# Usage:
#   ruby translation_agent_server.rb
#   # Server starts on port 4567
#
# Example queries:
#   "Translate 'Hello' to Spanish"
#   "Convert 'Good morning' to French"
#   "Say 'Thank you' in German"

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'sinatra/base'
require 'a2a'
require 'json'
require 'concurrent'
require 'logger'

require_relative 'production_server'

class TranslationProcessor
  LANGUAGES = {
    'es' => 'Spanish',
    'fr' => 'French',
    'de' => 'German',
    'it' => 'Italian'
  }

  def skills
    [
      {
        id: 'translate',
        name: 'Translation',
        description: 'Translate text between languages',
        tags: ['translation', 'i18n'],
        examples: [
          "Translate 'Hello' to Spanish",
          "Convert 'Good morning' to French"
        ]
      }
    ]
  end

  def process(task)
    text = task.status.message.parts.first.text
    target_lang = extract_target_language(text)

    translation = translate(text, target_lang)

    [
      A2A::Models::TextPart.new(text: translation),
      A2A::Models::DataPart.new(
        data: {
          source_language: 'en',
          target_language: target_lang,
          confidence: 0.95
        }
      )
    ]
  end

  private

  def extract_target_language(text)
    LANGUAGES.each do |code, name|
      return code if text.downcase.include?(name.downcase)
    end

    'es' # Default to Spanish
  end

  def translate(text, target_lang)
    # Simple mock translation dictionary
    translations = {
      'es' => { 'hello' => 'hola', 'goodbye' => 'adiós', 'thank you' => 'gracias' },
      'fr' => { 'hello' => 'bonjour', 'goodbye' => 'au revoir', 'thank you' => 'merci' },
      'de' => { 'hello' => 'hallo', 'goodbye' => 'auf wiedersehen', 'thank you' => 'danke' },
      'it' => { 'hello' => 'ciao', 'goodbye' => 'arrivederci', 'thank you' => 'grazie' }
    }

    # Extract words to translate (simple approach)
    words = text.downcase.scan(/\w+/)
    translated = words.map { |w| translations.dig(target_lang, w) || w }

    translated.join(' ').capitalize
  end
end

# Run the server
if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
  end

  logger.info "Starting Translation Agent Server..."

  processor = TranslationProcessor.new
  app = ProductionA2AApp.new(processor: processor)

  logger.info "Translation skills loaded:"
  processor.skills.each do |skill|
    logger.info "  - #{skill[:name]}: #{skill[:description]}"
    skill[:examples]&.each do |example|
      logger.info "    Example: #{example}"
    end
  end

  app.run!
end
