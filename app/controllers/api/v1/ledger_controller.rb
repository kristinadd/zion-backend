module Api
  module V1
    class LedgerController < ApplicationController
      def available_balances
        ledger_service = LedgerService.new
        result = ledger_service.available_balances

        if result[:success]
          render json: result[:data], status: :ok
        else
          log_ledger_error(result)
          render json: error_response(result), status: http_status_for_error(result[:error_type])
        end
      end

      def create_entry_set
        ledger_service = LedgerService.new
        result = ledger_service.create_entry_set(entry_set_params)

        if result[:success]
          render json: result[:data], status: :ok
        else
          log_ledger_error(result)
          render json: error_response(result), status: http_status_for_error(result[:error_type])
        end
      end

      private

      def log_ledger_error(result)
        log_data = {
          error_type: result[:error_type],
          error: result[:error],
          upstream_status: result[:status_code],
          message: result[:message]
        }.compact

        Rails.logger.error("Ledger service error: #{log_data.to_json}")
      end

      def error_response(result)
        response = { error: result[:error] }
        response[:message] = result[:message] if result[:message]
        response[:upstream_status] = result[:status_code] if result[:status_code]
        response
      end

      def http_status_for_error(error_type)
        case error_type
        when :client_error
          :internal_server_error
        when :server_error
          :bad_gateway
        when :connection_refused
          :service_unavailable
        when :connection_timeout, :read_timeout
          :gateway_timeout
        when :network_error, :http_error, :unexpected_response
          :bad_gateway
        else
          :internal_server_error
        end
      end

      def entry_set_params
        params.permit(:idempotency_key, :committed_at, :description, entries: [ :namespace, :name, :amount, :currency, :legal_entity, :account_id ])
      end
    end
  end
end
