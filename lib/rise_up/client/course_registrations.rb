# frozen_string_literal: true

module RiseUp
  class Client
    # use to be traininsubscriptions
    # now is courseregistrations
    module CourseRegistrations
      BASE = '/courseregistrations'
      def create_course_registration(user_id, course_id, options = {})
        request(ApiResource::CourseRegistration) do
          self.class.post("#{@base_uri}/courseregistrations/monetisation", {
                            body: options.merge(iduser: user_id, idtraining: course_id).to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def delete_course_registration(course_registration_id)
        request(nil) do
          self.class.delete("#{@base_uri}/#{BASE}/#{course_registration_id}", {
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def retrieve_course_registration(course_registration_id, options={})
        request(ApiResource::CourseRegistration) do
         self.class.get("#{@base_uri}/#{BASE}/#{course_registration_id}", {
                                     query: options,
                                     headers: {
                                       'Authorization' => "Bearer #{access_token}",
                                       'Content-Type' => 'application/json'
                                     }
                                   })
         end
      end

      def retrieve_all_pages_course_registrations(options={})
        retrieve_with_pagination(BASE, options, ApiResource::CourseRegistration)
      end

      def retrieve_course_registrations(options = {})
        request(ApiResource::CourseRegistration) do
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
