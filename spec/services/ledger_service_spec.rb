require "rails_helper"

RSpec.describe LedgerService do
  let(:service) { described_class.new }

  describe "#get_available_balances" do
    context "when the request is successful" do
      let(:success_response) do
        {
          "balances" => [
            "customer_facing_balance",
            "interest_chargeable_balance"
          ]
        }
      end

      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns success with parsed data" do
        result = service.get_available_balances

        expect(result[:success]).to be true
        expect(result[:data]).to eq(success_response)
      end

      it "does not include error fields" do
        result = service.get_available_balances

        expect(result).not_to have_key(:error)
        expect(result).not_to have_key(:error_type)
      end
    end

    context "when the upstream service returns a client error (4xx)" do
      let(:error_response) { { "error" => "Invalid request" } }

      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_return(
            status: 400,
            body: error_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns failure with client_error type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:client_error)
      end

      it "includes the upstream status code" do
        result = service.get_available_balances

        expect(result[:status_code]).to eq(400)
      end

      it "includes the error message from upstream" do
        result = service.get_available_balances

        expect(result[:message]).to eq(error_response)
      end
    end

    context "when the upstream service returns a server error (5xx)" do
      let(:error_response) { { "error" => "Internal server error" } }

      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_return(
            status: 500,
            body: error_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns failure with server_error type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:server_error)
      end

      it "includes the upstream status code" do
        result = service.get_available_balances

        expect(result[:status_code]).to eq(500)
      end
    end

    context "when the connection is refused" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_raise(Errno::ECONNREFUSED)
      end

      it "returns failure with connection_refused type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:connection_refused)
      end

      it "includes a descriptive error message" do
        result = service.get_available_balances

        expect(result[:error]).to include("unavailable")
      end
    end

    context "when the connection times out" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_raise(Net::OpenTimeout)
      end

      it "returns failure with connection_timeout type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:connection_timeout)
      end
    end

    context "when reading the response times out" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_raise(Net::ReadTimeout)
      end

      it "returns failure with read_timeout type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:read_timeout)
      end
    end

    context "when there is a DNS/socket error" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_raise(SocketError)
      end

      it "returns failure with network_error type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:network_error)
      end
    end

    context "when HTTParty raises an error" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_raise(HTTParty::Error)
      end

      it "returns failure with http_error type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:http_error)
      end
    end

    context "when an unexpected status code is returned" do
      before do
        stub_request(:get, "http://localhost:3000/api/v1/balances/available")
          .to_return(status: 999)
      end

      it "returns failure with unexpected_response type" do
        result = service.get_available_balances

        expect(result[:success]).to be false
        expect(result[:error_type]).to eq(:unexpected_response)
      end

      it "includes the unexpected status code" do
        result = service.get_available_balances

        expect(result[:status_code]).to eq(999)
      end
    end

    context "with custom ledger service URL" do
      around do |example|
        original_url = ENV["LEDGER_SERVICE_URL"]
        ENV["LEDGER_SERVICE_URL"] = "http://custom-ledger:4000"
        example.run
        ENV["LEDGER_SERVICE_URL"] = original_url
      end

      before do
        stub_request(:get, "http://custom-ledger:4000/api/v1/balances/available")
          .to_return(
            status: 200,
            body: { "balances" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "uses the custom URL from environment variable" do
        result = service.get_available_balances

        expect(result[:success]).to be true
        expect(WebMock).to have_requested(:get, "http://custom-ledger:4000/api/v1/balances/available")
      end
    end
  end

  describe "request configuration" do
    it "sends appropriate headers" do
      stub_request(:get, "http://localhost:3000/api/v1/balances/available")
        .to_return(status: 200, body: {}.to_json)

      service.get_available_balances

      expect(WebMock).to have_requested(:get, "http://localhost:3000/api/v1/balances/available")
        .with(headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        })
    end

    it "has a timeout configured" do
      expect(service.options[:timeout]).to eq(10)
    end
  end
end

