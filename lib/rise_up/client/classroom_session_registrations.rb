module RiseUp
  class Client
    module ClassroomSessionRegistrations
      BASE = '/classroomsessionregistrations'


        def create_classroom_session_registrations(user_id, classroom_session_id, options = {})
        request(ApiResource::ClassroomSessionRegistration) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.merge(iduser: user_id, idsession: classroom_session_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def retrieve_classrroom_session_registrations_by_session_id(session_id)
         request(ApiResource::SessionSubscription) do
           self.class.get("#{@base_uri}/#{BASE}?idsession=#{session_id}", {
                                       headers: {
                                          'Authorization' => "Bearer #{access_token}",
                                         'Content-Type' => 'application/json'
                                       }
                                     })
         end
      end

      def delete_classroom_session_registrations(classroom_session_registration_id)
        self.class.delete("#{@base_uri}/#{BASE}/#{classroom_session_registration_id}", {
                          headers: {
                            'Authorization' => "Bearer #{access_token}",
                            'Content-Type' => 'application/json'
                          }
                        })
      end
    end
  end
end
