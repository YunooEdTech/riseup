# frozen_string_literal: true

module RiseUp
  class Client
    module TrainingSessionRegistrations
      BASE = '/trainingsessionregistrations'
      
      def create_training_session_registration(user_id, training_session_id, options = {})
        request(ApiResource::TrainingSessionRegistration) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.merge(iduser: user_id, idpath: training_session_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end


      def delete_training_session_registration(training_session_registration_id)
        request(nil) do
          self.class.delete("#{@base_uri}/#{BASE}/#{training_session_registration_id}", {
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def retrieve_training_session_registration(training_session_registration_id, options={})
        request(ApiResource::TrainingSessionRegistration) do
        self.class.get("#{@base_uri}/#{BASE}/#{training_session_registration_id}", {
                                    query: options,
                                    headers: {
                                      'Authorization' => "Bearer #{access_token}",
                                      'Content-Type' => 'application/json'
                                    }
                                  })
        end
      end

      def retrieve_all_pages_training_session_registrations(options={})
        retrieve_with_pagination(BASE, options, ApiResource::TrainingSessionRegistration)
      end

      def retrieve_training_session_registrations(options = {})
        request(ApiResource::TrainingSessionRegistration) do
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
