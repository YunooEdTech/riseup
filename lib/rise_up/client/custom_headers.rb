# frozen_string_literal: true

module RiseUp
  class Client
    module CustomHeaders
      BASE = '/customheader'

      def create_custom_header(options = {})
        request(ApiResource::CustomHeader) do
          self.class.post("#{@base_uri}/#{BASE}", {
                            body: options.to_json,
                            headers: {
                              'Authorization' => "Bearer #{access_token}",
                              'Content-Type' => 'application/json'
                            }
                          })
        end
      end

      def get_custom_header(custom_header_id)
        request(ApiResource::CustomHeader) do
          self.class.get("#{@base_uri}/#{BASE}/#{custom_header_id}", {
                                      headers: {
                                        'Authorization' => "Bearer #{access_token}",
                                        'Content-Type' => 'application/json'
                                      }
                                    })
        end
     end


      def retrieve_custom_headers(options = {})
        request(ApiResource::CustomHeader) do
         self.class.get("#{@base_uri}/#{BASE}", {

                                     query: options,
                                     headers: {
                                       'Authorization' => "Bearer #{access_token}",
                                       'Content-Type' => 'application/json'
                                     }
                                   })
         end
      end

      def retrieve_all_pages_custom_headers(options={})
        retrieve_with_pagination(BASE, options, ApiResource::CustomHeader)
      end
      # PUT: Update an existing custom header
      def update_custom_header(id, options = {})
        url = "#{@base_uri}/#{BASE}/#{id}"
        request(ApiResource::CustomHeader) do
          self.class.put(url, {
            body: options.to_json,
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          })
        end
      end

      # DELETE: Delete a custom header (wrap_response so caller gets .code; body is nil for 204)
      def delete_custom_header(id)
        url = "#{@base_uri}/#{BASE}/#{id}"
        request(nil, wrap_response: true) do
          self.class.delete(
            url,
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
        end
      end
    end
  end
end
