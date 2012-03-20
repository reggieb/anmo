module Anmo
  class ApplicationDataStore
    class << self
      attr_accessor :stored_objects, :stored_requests
    end
  end

  class Application
    def initialize
      ApplicationDataStore.stored_objects = []
      ApplicationDataStore.stored_requests = []
    end

    def call env
      request = Rack::Request.new(env)

      if request.path_info == "/__CREATE__"
        create request
      elsif request.path_info == "/__DELETE_ALL__"
        delete_all_objects
      elsif request.path_info == "/__REQUESTS__"
        requests
      elsif request.path_info == "/__DELETE_ALL_REQUESTS__"
        delete_all_requests
      elsif request.path_info == "/__STORED_OBJECTS__"
        stored_objects
      else
        ApplicationDataStore.stored_requests << request.env
        process_normal_request request
      end
    end

    private

      def create request
        request_info = JSON.parse(read_request_body(request))
        ApplicationDataStore.stored_objects.unshift(request_info)
        [201, {}, [""]]
      end

      def delete_all_objects
        ApplicationDataStore.stored_objects = []
        [200, {}, [""]]
      end

      def process_normal_request request
        if found_request = find_stored_request(request)
          [Integer(found_request["status"]||200), {"Content-Type" => "text/html"}, [found_request["body"]]]
        else
          [404, {"Content-Type" => "text/html"}, ["Not Found"]]
        end
      end

      def requests
        [200, {"Content-Type" => "application/json"}, [(ApplicationDataStore.stored_requests || []).to_json]]
      end

      def delete_all_requests
        ApplicationDataStore.stored_requests = []
        [200, {}, ""]
      end

      def stored_objects
        [200, {"Content-Type" => "application/json"}, [ApplicationDataStore.stored_objects.to_json]]
      end

      def find_stored_request actual_request
        actual_request_url = actual_request.path_info
        if actual_request.query_string != ""
          actual_request_url << "?" + actual_request.query_string
        end

        found_request = ApplicationDataStore.stored_objects.find {|r| r["path"] == actual_request_url}
        if found_request
          if found_request["method"]
            if actual_request.request_method != found_request["method"].upcase
              return
            end
          end

          required_headers = found_request["required_headers"] || []
          required_headers.each do |name, value|
            if actual_request.env[convert_header_name_to_rack_style_name(name)] != value
              found_request = nil
              break
            end
          end
        end
        found_request
      end

      def convert_header_name_to_rack_style_name name
        name = "HTTP_#{name}"
        name.gsub!("-", "_")
        name.upcase!
        name
      end

      def read_request_body request
        request.body.rewind
        request.body.read
      end
  end
end
