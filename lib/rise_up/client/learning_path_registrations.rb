# frozen_string_literal: true

module RiseUp
  class Client
    module LearningPathRegistrations
      BASE = '/learningpathregistrations'
      
      def create_learning_path_registration(user_id, learning_path_id, options = {})
        request(ApiResource::LearningPathRegistration) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.merge(iduser: user_id, idpath: learning_path_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end


      def delete_learning_path_registration(learning_path_registration_id)
        request(nil) do
          self.class.delete("#{@base_uri}/#{BASE}/#{learning_path_registration_id}", {
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def retrieve_learning_path_registration(learning_path_registration_id, options={})
        request(ApiResource::LearningPathRegistration) do
        self.class.get("#{@base_uri}/#{BASE}/#{learning_path_registration_id}", {
                                    query: options,
                                    headers: {
                                      'Authorization' => "Bearer #{access_token}",
                                      'Content-Type' => 'application/json'
                                    }
                                  })
        end
      end

      def retrieve_all_pages_learning_path_registrations(options={})
        retrieve_with_pagination(BASE, options, ApiResource::LearningPathRegistration)
      end

      def retrieve_learning_path_registrations(options = {})
        request(ApiResource::LearningPathRegistration) do
          self.class.get("#{@base_uri}/#{BASE}", {
                                      query: options,
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
