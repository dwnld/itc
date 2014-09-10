require 'active_support/all'

module Itc
  class Response
    attr_reader :data
    def initialize(body)
      @json = JSON.parse(body)
      @data = @json['data']
    end

    def raise_if_errors
      # TODO Check which fields have a sectionErrorKey
      error_messages = []
      error_messages << @data['sectionErrorKeys'] if @data.try(:[], 'sectionErrorKeys').presence
      error_messages << @json['messages']['error'] if @json['messages'].try(:[], 'error').presence
      raise ItunesError(error_messages) if error_messages.present?
    end

  end

  class ItunesError < StandardError; end
end
