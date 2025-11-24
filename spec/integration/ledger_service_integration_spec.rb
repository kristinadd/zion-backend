require "rails_helper"

RSpec.describe "LedgerService Integration", type: :integration do
  let(:service) { LedgerService.new }

  describe "real HTTP calls to ledger service" do
    context "when ledger service is running" do
      before do
        begin
          Net::HTTP.get_response(URI("http://localhost:3000/api/v1/balances/available"))
        rescue Errno::ECONNREFUSED
          skip "Ledger service is not running on localhost:3000"
        end
      end

      it "successfully fetches available balances from real service" do
        result = service.available_balances

        expect(result[:success]).to be true
        expect(result[:data]).to have_key("balances")
        expect(result[:data]["balances"]).to be_an(Array)

        expect(result[:data]["balances"]).to include(
          "customer_facing_balance",
          "interest_chargeable_balance"
        )
      end
    end
  end
end
