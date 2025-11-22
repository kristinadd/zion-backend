module Api
  module V1
    class LedgerController < ApplicationController
      def available_balances
        ledger_service = LedgerService.new
        result = ledger_service.get_available_balances

        if result[:success]
          render json: result[:data], status: :ok
        else
          render json: { error: result[:error], message: result[:message] }, status: :bad_gateway
        end
      end
    end
  end
end
