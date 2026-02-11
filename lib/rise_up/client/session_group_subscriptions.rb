module RiseUp
  class Client
    module SessionGroupSubscriptions
      BASE = '/trainingsessionregistrations'

      def create_session_group_subscription(user_id, session_group_id, options = {})
        request(ApiResource::SessionGroupSubscription) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.merge(iduser: user_id, idsessiongroup: session_group_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def delete_session_group_subscription(session_group_subscription_id)
        request(nil) do
          self.class.delete("#{@base_uri}/#{BASE}/#{session_group_subscription_id}", {
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def get_module(session_group_subscription_id)
        request(ApiResource::SessionGroupSubscription) do
          self.class.get("#{@base_uri}/#{BASE}/#{session_group_subscription_id}", {
                                      headers: {
                                        'Authorization' => "Bearer #{access_token}",
                                        'Content-Type' => 'application/json'
                                      }
                                    })
        end
     end

      def retrieve_all_pages_session_group_subscriptions(options={})
        retrieve_with_pagination(BASE, options, ApiResource::SessionGroupSubscription)
      end

      def retrieve_session_group_subscriptions(options = {})
        request(ApiResource::SessionGroupSubscription) do
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
