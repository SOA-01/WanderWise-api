# frozen_string_literal: true

require_relative 'progress_publisher'

module WanderWise
  # Reports job progress to the client
  class JobReporter
    attr_accessor :request_id

    def initialize(request_json, config)
      request = JSON.parse(request_json)
      @request_id = request['id']
      @publisher = ProgressPublisher.new(config, @request_id)
    end

    def report(message)
      @publisher.publish(message)
    end

    def report_each_second(seconds, &operation)
      seconds.times do
        sleep(1)
        report(operation.call)
      end
    end
  end
end
