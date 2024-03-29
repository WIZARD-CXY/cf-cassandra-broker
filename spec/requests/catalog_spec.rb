require 'spec_helper'

describe 'GET /v2/catalog' do
  it 'returns the catalog of services' do
    get '/v2/catalog'

    expect(response.status).to eq(200)
    catalog = JSON.parse(response.body)

    services = catalog.fetch('services')
    expect(services).to have(1).service

    service = services.first
    expect(service.fetch('name')).to eq('cassandra-service')
    expect(service.fetch('description')).to eq('cassandra service for cloudfoundry v2')
    expect(service.fetch('bindable')).to be_true
    expect(service.fetch('metadata')).to eq(
      {
        'provider' => { 'name' => "chenxingyu" },
        'listing' => {
          'imageUrl' => nil,
          'blurb' => 'Cassandra service for cloudfoundry v2',
        }
      }
    )

    plans = service.fetch('plans')
    expect(plans).to have(1).plan

    plan = plans.first
    expect(plan.fetch('name')).to eq('5mb')
    expect(plan.fetch('description')).to eq('Shared MySQL Server, 5mb persistent disk, 40 max concurrent connections')
    expect(plan.fetch('metadata')).to eq(
      {
        'cost' => 0.0,
        'bullets' => [
          { 'content' => 'Shared MySQL server' },
          { 'content' => '5 MB storage' },
          { 'content' => '40 concurrent connections' },
        ]
      }
    )
  end
end
