# frozen_string_literal: true

RSpec.describe RiseUp do
  it "has a version number" do
    expect(RiseUp::VERSION).not_to be nil
  end

  it "can be instantiated with minimal options" do
    client = RiseUp::Client.new(public_key: "pk", private_key: "sk")

    expect(client).to be_a(RiseUp::Client)
  end
end
