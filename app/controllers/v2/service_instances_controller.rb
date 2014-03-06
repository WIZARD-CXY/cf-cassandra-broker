class V2::ServiceInstancesController < V2::BaseController
  # Now is free plan
  def update
    #quota = Settings['services'][0]['max_keyspace_per_node']
    #existing_instances = ServiceInstance.get_number_of_existing_instances

    #if !quota or existing_instances < quota
    instance = ServiceInstance.new(id: params.fetch(:id))
    instance.save

      render status: 201, json: instance
    #else
    #  render status: 409, json: {}
    #end

  end

  def destroy
    if instance = ServiceInstance.find_by_id(params.fetch(:id))
      instance.destroy
      status = 200
    else
      status = 410
    end

    render status: status, json: {}
  end
end
