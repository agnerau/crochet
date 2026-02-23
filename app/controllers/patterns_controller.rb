class PatternsController < ApplicationController
  def index
  end

  def create
    pattern_name = params[:pattern_name]
    width = params[:width].to_i
    height = params[:height].to_i

    # client = OpenAI::Client.new
    client = OpenAI::Client.new(
      request_options: { ssl: { verify: false } }
    )

    prompt = <<~PROMPT
      Create a #{width}x#{height} crochet filet pattern for "#{pattern_name}".

      Return ONLY a JSON array of arrays.
      Use 1 for filled square.
      Use 0 for empty square.

      Example for 3x3:
      [
        [0,1,0],
        [1,1,1],
        [0,1,0]
      ]
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-5.1",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3
      }
    )

    content = response.dig("choices", 0, "message", "content")

    @grid = JSON.parse(content)

    render :result
  end
end