class LedgerService
  include HTTParty
  base_uri ENV.fetch("LEDGER_SERVICE_URL", "http://localhost:3000")

  attr_reader :options

  def initialize
    @options = {
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      timeout: 10
    }
  end

  def get_available_balances
    response = self.class.get("/api/v1/balances/available", options)
    handle_response(response)
  end

  private

  def handle_response(response)
    case response.code
    when 200..299
      {
        success: true,
        data: response.parsed_response
      }
    when 400..499
      {
        success: false,
        error: "Client error: #{response.code}",
        message: response.parsed_response
      }
    when 500..599
      {
        success: false,
        error: "Server error: #{response.code}",
        message: response.parsed_response
      }
    else
      {
        success: false,
        error: "Unexpected response: #{response.code}"
      }
    end
  rescue HTTParty::Error, StandardError => e
    {
      success: false,
      error: "Request failed: #{e.message}"
    }
  end
end
