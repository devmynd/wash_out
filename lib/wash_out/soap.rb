require 'active_support/concern'

module WashOut
  module SOAP
    extend ActiveSupport::Concern

    module ClassMethods
      attr_accessor :soap_actions

      # Define a SOAP action +action+. The function has two required +options+:
      # :args and :return. Each is a type +definition+ of format described in
      # WashOut::Param#parse_def.
      #
      # An optional option :to can be passed to allow for names of SOAP actions
      # which are not valid Ruby function names.
      #
      # There is an optional :request_tag option to specify an alternative
      # request tag for the message.  If unspecified, the request tag will be
      # set as the :as option, which is not very clearly named and probably
      # should be deprecated.
      #
      # There is also an optional :header_return option to specify the format of the
      # SOAP response's header tag (<env:Header></env:Header>). If unspecified, there will
      # be no header tag in the response.
      def soap_action(action, options={})
        if options[:as].present? && options[:request_tag].blank?
          options[:to] ||= action
          action = options[:as]
        end

        if action.is_a?(Symbol)
          if soap_config.camelize_wsdl.to_s == 'lower'
            options[:to] ||= action.to_s
            action         = action.to_s.camelize(:lower)
          elsif soap_config.camelize_wsdl
            options[:to] ||= action.to_s
            action         = action.to_s.camelize
          end
        end

        if options[:request_tag].blank?
          if options[:as].present?
            options[:request_tag] = options[:as]
          else
            options[:request_tag] = action
          end
        end

        default_response_tag = soap_config.camelize_wsdl ? 'Response' : '_response'
        default_response_tag = action+default_response_tag

        self.soap_actions[action] = options.merge(
          :in           => WashOut::Param.parse_def(soap_config, options[:args]),
          :out          => WashOut::Param.parse_def(soap_config, options[:return]),
          :header_out   => options[:header_return].present? ? WashOut::Param.parse_def(soap_config, options[:header_return]) : nil,
          :to           => options[:to] || action,
          :response_tag => options[:response_tag] || default_response_tag
        )
      end
    end

    included do
      include WashOut::Configurable
      include WashOut::Dispatcher
      include WashOut::WsseParams
      self.soap_actions = {}
    end
  end
end
