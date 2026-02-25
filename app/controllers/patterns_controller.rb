class PatternsController < ApplicationController
  def index
  end

  def create
    pattern_name = params[:pattern_name]
    width = params[:width].to_i.clamp(GRID_SIZE_RANGE)
    height = params[:height].to_i.clamp(GRID_SIZE_RANGE)

    client = OpenAI::Client.new
    prompt = <<~PROMPT
    You are generating pixel art for crochet filet patterns.

    GOAL:
    Create a #{width}x#{height} grid representing a clear typical silhouette of "#{pattern_name}".

    STRICT REQUIREMENTS:

    1. Output ONLY valid JSON.
    2. The result must be an array with exactly #{height} rows.
    3. Each row must contain exactly #{width} integers.
    4. Only use 0 and 1.
    5. Do not include explanations.
    6. Do not include markdown.
    7. Do not include text outside the JSON.

    DESIGN RULES:

    - The shape must be centered horizontally and vertically.
    - The design must use symmetry whenever appropriate.
    - The shape must occupy 60–80% of the grid area.
    - Do NOT leave the grid mostly empty.
    - Do NOT touch the borders unless the shape naturally requires it.
    - The result must look like clear pixel-art silhouette, not abstract noise.

    SHAPE-SPECIFIC RULES:

    If the pattern is:
    - "heart": classic symmetrical heart with rounded lobes and pointed bottom.
    - "flower": circular center with evenly spaced rounded petals.
    - "dog": side-profile silhouette with head, ear, body, legs, and tail clearly visible.
    - "star": 5-point symmetrical star.
    - "moon": crescent shape.

    Return ONLY the JSON grid.
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-5.1",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1
      }
    )

    content = response.dig("choices", 0, "message", "content")

    @grid = JSON.parse(content)
    session[:grid] = @grid
    session[:pattern_name] = pattern_name
    render :result
  end

  def download_pdf
    grid = session[:grid]

    pdf = Prawn::Document.new(
      page_size: "A4",
      page_layout: :portrait,
      margin: 50
    )

    cell_size = 20
    gap = 2
    start_x = 50
    start_y = pdf.cursor

    grid.first.size.times do |col_index|
      x = start_x + (cell_size + gap) * (col_index + 1) 
      y = start_y
      pdf.text_box "#{col_index + 1}",
                  at: [x, y],
                  width: cell_size,
                  height: cell_size,
                  align: :center,
                  valign: :center,
                  style: :bold,
                  color: "000000"
    end

    grid.each_with_index do |row, row_index|
      y = start_y - (cell_size + gap) * (row_index + 1)

      row.each_with_index do |cell, col_index|
        x = start_x + (cell_size + gap) * (col_index + 1)
        pdf.fill_color cell == 1 ? "FF69B4" : "FFEFF5"
        pdf.fill_rectangle [x, y], cell_size, cell_size

        pdf.stroke_color "FFB6C1"
        pdf.stroke_rectangle [x, y], cell_size, cell_size
      end

      pdf.fill_color "000000"
      pdf.stroke_color "000000"
      pdf.text_box "#{row_index + 1}",
                  at: [start_x, y],
                  width: cell_size,
                  height: cell_size,
                  align: :center,
                  valign: :center,
                  style: :bold,
                  color: "000000"
    end

    title_x = 50                          
    title_y = start_y + cell_size + 10   

    pdf.text_box session[:pattern_name],
                at: [title_x, title_y],
                width: (cell_size + gap) * (grid.first.size + 1), 
                align: :center,
                size: 18,
                style: :bold,
                color: "FF69B4"

    send_data pdf.render,
              filename: "#{session[:pattern_name]}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end
end