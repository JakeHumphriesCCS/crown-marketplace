require 'rails_helper'

RSpec.describe OmniAuth::Strategies::Cognito do
  let(:strategy) do
    app = ->(_env) { [200, {}, ['']] }
    described_class.new(app, callback_path: 'callback-path')
  end

  it 'presents the token subject as the uid' do
    cognito_id_token = {
      'sub' => 'uuid-of-authenticated-user'
    }
    allow(strategy).to receive(:validated_id_token).and_return(cognito_id_token)
    expect(strategy.uid).to eq('uuid-of-authenticated-user')
  end

  it 'includes email address from cognito in the info hash' do
    cognito_id_token = {
      'email' => 'email-of-authenticated-user'
    }
    allow(strategy).to receive(:validated_id_token).and_return(cognito_id_token)
    expect(strategy.info[:email]).to eq('email-of-authenticated-user')
  end

  it 'does not verify token' do
    allow(strategy).to receive(:id_token).and_return('id-token')
    allow(JWT).to receive(:decode).with('id-token', nil, false).and_return(['decoded-payload', 'decoded-header'])

    token = strategy.send(:validated_id_token)
    expect(token).to eq('decoded-payload')
  end
end
