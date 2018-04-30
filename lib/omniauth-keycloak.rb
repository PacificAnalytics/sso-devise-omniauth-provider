require 'omniauth'

module OmniAuth
  module Strategies
    class OmniAuthKeycloak
      include OmniAuth::Strategy

      def request_phase
        redirect "http://localhost:8180/auth/realms/pacific-analytics/protocol/openid-connect/auth?response_type=code&client_id=arvados&redirect_uri=http://localhost:3002/users/omniauth_callbacks/keycloak/&secret=729200d8-b236-4650-b814-a05a7346b0be&scope=openid"
      end

      def callback_phase
        render html: "Got here"
      end

    end
  end
end

