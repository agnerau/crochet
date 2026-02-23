OpenAI.configure do |config|
  ENV["OPENAI_API_KEY"] = Rails.application.credentials.openai[:api_key]
  config.access_token = ENV["OPENAI_API_KEY"]
end