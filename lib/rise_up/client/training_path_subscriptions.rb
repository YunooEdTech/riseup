# frozen_string_literal: true

module RiseUp
  class Client
    module TrainingPathSubscriptions
      BASE = '/trainingpathsubscriptions'
      
      def create_training_path_subscription(user_id, training_path_id, options = {})
        request(ApiResource::TrainingPathSubscription) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.merge(iduser: user_id, idpath: training_path_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end


      def delete_training_path_subscription(training_path_subscription_id)
        request(nil) do
          self.class.delete("#{@base_uri}/#{BASE}/#{training_path_subscription_id}", {
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def retrieve_training_path_subscription(training_path_subscription_id, options={})
        request(ApiResource::TrainingPathSubscription) do
        self.class.get("#{@base_uri}/#{BASE}/#{training_path_subscription_id}", {
                                    query: options,
                                    headers: {
                                      'Authorization' => "Bearer #{access_token}",
                                      'Content-Type' => 'application/json'
                                    }
                                  })
        end
      end

      def retrieve_all_pages_training_path_subscriptions(options={})
        retrieve_with_pagination(BASE, options, ApiResource::TrainingPathSubscription)
      end

      def retrieve_training_path_subscriptions(options = {})
        request(ApiResource::TrainingPathSubscription) do
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
