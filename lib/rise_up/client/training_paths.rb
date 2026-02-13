# frozen_string_literal: true

module RiseUp
  class Client
    module TrainingPaths
      BASE = '/trainingpaths'


      def get_training_path(training_path_id)
        request(ApiResource::TrainingPath) do
          self.class.get("#{@base_uri}/#{BASE}/#{training_path_id}", {
                                      headers: {
                                        'Authorization' => "Bearer #{access_token}",
                                        'Content-Type' => 'application/json'
                                      }
                                    })
        end
      end

      def retrieve_training_paths(options = {})
        request(ApiResource::TrainingPath) do
         self.class.get("#{@base_uri}/#{BASE}", {
                                     query: options,
                                     headers: {
                                       'Authorization' => "Bearer #{access_token}",
                                       'Content-Type' => 'application/json'
                                     }
                                   })
         end
      end

      def retrieve_all_pages_training_paths(options={})
        retrieve_with_pagination(BASE, options, ApiResource::TrainingPath)
      end

      def create_training_paths(options = {})
        request(ApiResource::TrainingPath) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end
    end
  end
end
