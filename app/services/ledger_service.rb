class LedgerService
  include HTTParty
  base_uri ENV.fetch("LEDGER_SERVICE_URL", "http://localhost:15001")

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

  def available_balances
    response = self.class.get("/api/v1/balances/available", options)
    handle_response(response)
  rescue HTTParty::Error => e
    {
      success: false,
      error_type: :http_error,
      error: "HTTP request failed: #{e.message}"
    }
  rescue SocketError => e
    {
      success: false,
      error_type: :network_error,
      error: "Network error (DNS/socket): #{e.message}"
    }
  rescue Errno::ECONNREFUSED => e
    {
      success: false,
      error_type: :connection_refused,
      error: "Ledger service unavailable (connection refused)"
    }
  rescue Net::OpenTimeout => e
    {
      success: false,
      error_type: :connection_timeout,
      error: "Connection timeout - service may be down"
    }
  rescue Net::ReadTimeout => e
    {
      success: false,
      error_type: :read_timeout,
      error: "Read timeout - service is too slow"
    }
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
        error_type: :client_error,
        status_code: response.code,
        error: "Client error: #{response.code}",
        message: response.parsed_response
      }
    when 500..599
      {
        success: false,
        error_type: :server_error,
        status_code: response.code,
        error: "Upstream server error: #{response.code}",
        message: response.parsed_response
      }
    else
      {
        success: false,
        error_type: :unexpected_response,
        status_code: response.code,
        error: "Unexpected response: #{response.code}"
      }
    end
  end
end
